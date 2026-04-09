extends RefCounted

const SERVER_SNAPSHOT_INTERVAL := 1.0 / 15.0

# NET PROF disabled
# const PERF_REPORT_INTERVAL_MS := 1000
# static var _perf_last_report_ms: int = 0
# static var _perf_sim_calls: int = 0
# static var _perf_sim_us_total: int = 0
# static var _perf_input_packets_received: int = 0
# static var _perf_snapshots_sent: int = 0
# static var _perf_player_ticks: int = 0
static var _snapshot_accumulator_by_player: Dictionary = {}

func update_remote_proxy(controller, dt: float) -> void:
	if controller.multiplayer.is_server() or not controller.has_remote_snapshot:
		return
	var pos_alpha := clampf(controller.REMOTE_POSITION_LERP * dt, 0.0, 1.0)
	var rot_alpha := clampf(controller.REMOTE_ROTATION_LERP * dt, 0.0, 1.0)
	controller.global_position = controller.global_position.lerp(controller.remote_target_position, pos_alpha)
	controller.rotation.y = lerp_angle(controller.rotation.y, controller.remote_target_yaw, rot_alpha)
	controller.neck.rotation.x = lerp(controller.neck.rotation.x, controller.remote_target_pitch, rot_alpha)

func ground_check(controller) -> bool:
	return controller.ground_check_0.is_colliding() or \
		controller.ground_check_1.is_colliding() or \
		controller.ground_check_2.is_colliding() or \
		controller.ground_check_3.is_colliding() or \
		controller.ground_check_4.is_colliding()

func set_movement_input(controller, move_x: float, move_y: float, wants_sprint: bool, jump_pressed: bool, yaw: float, pitch: float) -> void:
	controller.net_move_x = clamp(move_x, -1.0, 1.0)
	controller.net_move_y = clamp(move_y, -1.0, 1.0)
	controller.net_wants_sprint = wants_sprint
	if jump_pressed:
		controller.net_jump_pressed = true
	controller.net_yaw = yaw
	controller.net_pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))

func clear_movement_state(controller) -> void:
	controller.net_move_x = 0.0
	controller.net_move_y = 0.0
	controller.net_wants_sprint = false
	controller.net_jump_pressed = false
	controller.horizantal_velocity = Vector3.ZERO
	controller.movement = Vector3.ZERO
	controller.velocity = Vector3.ZERO

func build_local_input(controller, dt: float) -> Dictionary:
	var move_x: float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var move_y: float = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	if not controller.Local.get_state("input_active") or controller.current_health <= 0:
		move_x = 0.0
		move_y = 0.0
	var wants_sprint: bool = controller.Local.get_state("input_active") and controller.current_health > 0 and Input.is_action_pressed("sprint")
	var jump_pressed: bool = controller.Local.get_state("input_active") and controller.current_health > 0 and Input.is_action_just_pressed("jump")
	return {
		"seq": controller.input_sequence,
		"dt": dt,
		"move_x": move_x,
		"move_y": move_y,
		"wants_sprint": wants_sprint,
		"jump_pressed": jump_pressed,
		"yaw": controller.net_yaw,
		"pitch": controller.net_pitch,
	}

func apply_input_packet(controller, input_packet: Dictionary) -> void:
	set_movement_input(
		controller,
		input_packet["move_x"],
		input_packet["move_y"],
		input_packet["wants_sprint"],
		input_packet["jump_pressed"],
		input_packet["yaw"],
		input_packet["pitch"]
	)

func capture_and_submit_input(controller, dt: float) -> void:
	var input_packet := build_local_input(controller, dt)
	controller.input_sequence += 1
	input_packet["seq"] = controller.input_sequence
	apply_input_packet(controller, input_packet)

	if controller.multiplayer.is_server():
		controller.last_server_sequence = input_packet["seq"]
	else:
		controller.pending_inputs.append(input_packet)
		controller.submit_movement_input.rpc_id(
			1,
			input_packet["seq"],
			input_packet["move_x"],
			input_packet["move_y"],
			input_packet["wants_sprint"],
			input_packet["jump_pressed"],
			input_packet["yaw"],
			input_packet["pitch"],
			input_packet["dt"]
		)

var _pending_client_dt: Dictionary = {}

func apply_network_input(controller, seq: int, move_x: float, move_y: float, wants_sprint: bool, jump_pressed: bool, yaw: float, pitch: float, client_dt: float) -> void:
	if not controller.multiplayer.is_server():
		return
	var sender_id: int = controller.multiplayer.get_remote_sender_id()
	if sender_id != controller._get_peer_id_string().to_int():
		return
	controller.last_server_sequence = seq
	set_movement_input(controller, move_x, move_y, wants_sprint, jump_pressed, yaw, pitch)
	_pending_client_dt[controller._get_peer_id_string()] = client_dt

func create_authoritative_state(controller) -> Dictionary:
	return {
		"position": controller.global_position,
		"horizontal_velocity": controller.horizantal_velocity,
		"gravity_direction": controller.gravity_direction,
		"yaw": controller.rotation.y,
		"pitch": controller.neck.rotation.x,
	}

func restore_authoritative_state(controller, state: Dictionary) -> void:
	controller.global_position = state["position"]
	controller.horizantal_velocity = state["horizontal_velocity"]
	controller.gravity_direction = state["gravity_direction"]
	controller.net_yaw = state["yaw"]
	controller.net_pitch = state["pitch"]
	controller._apply_look_rotation(controller.net_yaw, controller.net_pitch)

func discard_acknowledged_inputs(controller, sequence: int) -> void:
	if controller.pending_inputs.is_empty():
		return
	var remaining_inputs: Array = []
	for input_packet in controller.pending_inputs:
		if input_packet["seq"] > sequence:
			remaining_inputs.append(input_packet)
	controller.pending_inputs = remaining_inputs

func replay_pending_inputs(controller) -> void:
	for input_packet in controller.pending_inputs:
		apply_input_packet(controller, input_packet)
		simulate(controller, input_packet["dt"], false, false)

func reconcile(controller, sequence: int, state: Dictionary) -> void:
	if controller.multiplayer.is_server() or not controller._is_local_player():
		return
	var authoritative_position: Vector3 = state["position"]
	var needs_reconcile = controller.global_position.distance_squared_to(authoritative_position) > controller.RECONCILE_DISTANCE_SQUARED
	discard_acknowledged_inputs(controller, sequence)
	if not needs_reconcile:
		return
	restore_authoritative_state(controller, state)
	if not controller.pending_inputs.is_empty():
		replay_pending_inputs(controller)

func receive_remote_snapshot(controller, snapshot_position: Vector3, yaw: float, pitch: float, snapshot_velocity: Vector3) -> void:
	if controller.multiplayer.is_server() or controller._is_local_player():
		return
	controller.remote_target_position = snapshot_position + snapshot_velocity * controller.REMOTE_EXTRAPOLATION_SEC
	controller.remote_target_yaw = yaw
	controller.remote_target_pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
	if not controller.has_remote_snapshot:
		controller.has_remote_snapshot = true
		controller.global_position = controller.remote_target_position
		controller.rotation.y = controller.remote_target_yaw
		controller.neck.rotation.x = controller.remote_target_pitch

func handle_physics(controller, dt: float) -> void:
	if controller._is_local_player():
		capture_and_submit_input(controller, dt)
		if not controller.multiplayer.is_server():
			simulate(controller, dt, false, true)

	if controller._is_local_player() and controller.current_health > 0:
		if Input.is_action_pressed("interact") and controller.current_interaction:
			if controller.current_interaction.has_method("interact"):
				controller.current_interaction.interact(controller)
				controller.HUD.display_ammo(controller.active_equipable.get_ammo())

		if not controller.active_equipable.continuous_usage and Input.is_action_just_pressed("fire") and controller.Local.get_state("input_active"):
			if controller.active_equipable.has_method("use"):
				controller.active_equipable.use(controller)
				controller.HUD.display_ammo(controller.active_equipable.get_ammo())

		if controller.active_equipable.continuous_usage and Input.is_action_pressed("fire") and controller.Local.get_state("input_active"):
			if not controller.active_equipable.cool_down and controller.active_equipable.has_method("use"):
				controller.active_equipable.use(controller)
				controller.HUD.display_ammo(controller.active_equipable.get_ammo())

		if Input.is_action_just_pressed("reload") and controller.Local.get_state("input_active"):
			if controller.active_equipable.has_method("_reload"):
				controller.active_equipable._reload()
				controller.HUD.display_ammo(controller.active_equipable.get_ammo())

		if Input.is_action_just_pressed("help"):
			print("help")

	if controller._is_local_player() and Input.is_action_just_pressed("help") and controller.current_health <= 0 and not controller.audio_player.playing:
		controller.call_help.rpc(controller.name)

	if not controller.multiplayer.is_server():
		return

	var player_key = controller._get_peer_id_string()
	var sim_dt := float(_pending_client_dt.get(player_key, dt))
	_pending_client_dt.erase(player_key)
	if sim_dt <= 0.0:
		sim_dt = dt
	simulate(controller, sim_dt, true, false)
	var snapshot_accumulator := float(_snapshot_accumulator_by_player.get(player_key, 0.0)) + dt
	if snapshot_accumulator >= SERVER_SNAPSHOT_INTERVAL:
		snapshot_accumulator = 0.0
		controller.receive_remote_snapshot.rpc(controller.global_position, controller.rotation.y, controller.neck.rotation.x, controller.horizantal_velocity)
		if not controller._is_local_player() and controller.last_server_sequence >= 0:
			controller.reconcile_movement.rpc_id(controller._get_peer_id_string().to_int(), controller.last_server_sequence, create_authoritative_state(controller))
	_snapshot_accumulator_by_player[player_key] = snapshot_accumulator

	# NET PROF disabled
	# var now_ms := Time.get_ticks_msec()
	# if _perf_last_report_ms == 0:
	# 	_perf_last_report_ms = now_ms
	# elif now_ms - _perf_last_report_ms >= PERF_REPORT_INTERVAL_MS:
	# 	var avg_sim_ms := 0.0
	# 	if _perf_sim_calls > 0:
	# 		avg_sim_ms = float(_perf_sim_us_total) / float(_perf_sim_calls) / 1000.0
	# 	print("[NET PROF][SERVER] player_ticks=%d input_packets=%d snapshots=%d sim_calls=%d avg_sim_ms=%.3f" % [
	# 		_perf_player_ticks,
	# 		_perf_input_packets_received,
	# 		_perf_snapshots_sent,
	# 		_perf_sim_calls,
	# 		avg_sim_ms,
	# 	])
	# 	_perf_last_report_ms = now_ms
	# 	_perf_player_ticks = 0
	# 	_perf_input_packets_received = 0
	# 	_perf_snapshots_sent = 0
	# 	_perf_sim_calls = 0
	# 	_perf_sim_us_total = 0

func simulate(controller, dt: float, replicate_walk_state: bool, play_walk_locally: bool) -> void:
	var speed = 0.0
	var accel = controller.DEACCEL
	var forward = false

	controller.delta = dt
	controller._apply_look_rotation(controller.net_yaw, controller.net_pitch)
	controller.direction = Vector3.ZERO

	controller.full_contact = ground_check(controller)

	if controller.is_on_floor():
		if controller.gravity_direction.y < 0.0:
			controller.gravity_direction.y = 0.0
	else:
		controller.gravity_direction += Vector3.DOWN * controller.gravity * dt

	if controller.current_health > 0:
		if controller.net_jump_pressed and controller.is_on_floor() and controller.full_contact:
			controller.gravity_direction = Vector3.UP * controller.jump
			controller.net_jump_pressed = false
	else:
		clear_movement_state(controller)

	var walk_state = controller.WALK_STATES.STOP

	if controller.current_health > 0 and controller.net_move_y < 0.0:
		controller.direction -= controller.transform.basis.z
		forward = true
		walk_state = controller.WALK_STATES.WALK
	if controller.current_health > 0 and controller.net_move_y > 0.0:
		forward = false
		controller.direction += controller.transform.basis.z
		walk_state = controller.WALK_STATES.WALK
	if controller.current_health > 0 and controller.net_move_x < 0.0:
		controller.direction -= controller.transform.basis.x
		walk_state = controller.WALK_STATES.WALK
	if controller.current_health > 0 and controller.net_move_x > 0.0:
		controller.direction += controller.transform.basis.x
		walk_state = controller.WALK_STATES.WALK

	if controller.direction != Vector3.ZERO:
		if controller.net_wants_sprint and forward:
			speed = controller.MAX_SPRINT
			accel = controller.SPRINT_ACCEL
			walk_state = controller.WALK_STATES.RUN
		else:
			speed = controller.MAX_SPEED
			accel = controller.ACCEL
			walk_state = controller.WALK_STATES.WALK

		# Infantry buff: faster when tertiary (melee/light) weapon is out
		if controller is InfantryController and controller.current_equipped_index == 2:
			speed *= controller.stowed_speed_buff
		# Special ADS penalty: extra slowdown when aiming down sights
		elif controller is SpecialController and controller.active_equipable.ads:
			speed /= controller.ads_movement_penalty
		# Officer aura (and other received officer buffs)
		speed *= controller.officer_speed_buff

	if not controller.is_on_floor():
		walk_state = controller.WALK_STATES.STOP

	if replicate_walk_state:
		controller.play_walk.rpc(controller.name, walk_state)
	elif play_walk_locally:
		controller.play_walk(controller.name, walk_state)

	controller.direction = controller.direction.normalized()
	controller.horizantal_velocity = controller.horizantal_velocity.lerp(controller.direction * speed, accel * dt)
	controller.movement.z = controller.horizantal_velocity.z + controller.gravity_direction.z
	controller.movement.x = controller.horizantal_velocity.x + controller.gravity_direction.x
	controller.movement.y = controller.gravity_direction.y

	controller.set_velocity(controller.movement)
	controller.set_up_direction(Vector3.UP)
	controller.move_and_slide()
