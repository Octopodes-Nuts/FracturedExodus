extends CharacterBody3D

@onready var navigation: NavigationAgent3D = $Navigation
@onready var enemy_mesh: MeshInstance3D = $Model
@onready var head: Node3D = $Head
@onready var gun_location: Node3D = self
@onready var gun: Node = $debug_fractured/Armature/Skeleton3D/ModifierBoneTarget3D/BasicAiGun
@onready var debug_fractured_model: Node = get_node_or_null("debug_fractured")

enum AiState {
	IDLE,
	PATROL,
	AWARE,
	SCAN,
	PURSUIT,
	ATTACK,
	RETREAT,
}

@export var max_health: float = 70.0
@export var health: float = 70.0
@export var patrol_speed: float = 0.9
@export var aware_speed: float = 1.1
@export var pursuit_speed: float = 1.5
@export var retreat_speed: float = 2.3
@export var reposition_speed: float = 0.8
@export var gravity: float = 20.0
@export var patrol_radius: float = 8.0
@export var max_home_leash_distance: float = 14.0
@export var patrol_reach_distance: float = 1.4
@export var aware_reach_distance: float = 1.8
@export var idle_duration_min: float = 0.8
@export var idle_duration_max: float = 2.4
@export var aware_timeout: float = 4.0
@export var pursuit_timeout: float = 2.4
@export var noise_chain_window: float = 1.5
@export var retreat_health_threshold: float = 0.55
@export var retreat_distance: float = 11.0
@export var close_retreat_distance: float = 6.0
@export var scan_duration: float = 2.8
@export var vision_range: float = 28.0
@export var vision_fov: float = 100.0
@export var vision_eye_height: float = 1.4
@export var vision_check_interval: float = 0.2
@export var close_contact_vision_distance: float = 2.8
@export var turn_speed: float = 6.0
@export var attack_range: float = 20.0
@export var minimum_attack_range: float = 5.5
@export var attack_cooldown: float = 1.2
@export var hit_stagger_duration: float = 0.35
@export var headshot_multiplier: float = 1.75
@export var head_track_speed: float = 8.0
@export var head_max_yaw_degrees: float = 60.0
@export var head_max_pitch_up_degrees: float = 35.0
@export var head_max_pitch_down_degrees: float = 25.0
@export var head_aim_height_offset: float = 0.9
@export var debug_ai: bool = false
@export var enable_ragdoll_on_death: bool = true
@export var ragdoll_simulator_path: NodePath = NodePath("debug_fractured/Armature/Skeleton3D/PhysicalBoneSimulator3D")
@export var corpse_lifetime_seconds: float = 20.0

var current_state: AiState = AiState.IDLE
var home: Area3D
var gravity_velocity: Vector3 = Vector3.ZERO
var spawn_origin: Vector3 = Vector3.ZERO
var patrol_anchor: Vector3 = Vector3.ZERO
var patrol_target: Vector3 = Vector3.ZERO
var retreat_target: Vector3 = Vector3.ZERO
var last_heard_position: Vector3 = Vector3.ZERO
var last_threat_position: Vector3 = Vector3.ZERO
var idle_time_remaining: float = 0.0
var state_time: float = 0.0
var noise_age: float = INF
var noise_chain_age: float = INF
var noise_chain_count: int = 0
var has_patrol_target: bool = false
var has_retreat_target: bool = false
var tracked_player: Node3D
var _vision_timer: float = 0.0
var _attack_age: float = INF
var _is_dead: bool = false
var _hit_stagger_time: float = 0.0
var _current_debug_animation_state: StringName = &""

var idle_color: Material = preload("res://debug/materials/debug_teal.tres")
var patrol_color: Material = preload("res://debug/materials/debug_yellow.tres")
var aware_color: Material = preload("res://debug/materials/debug_red.tres")
var scan_color: Material = preload("res://debug/materials/debug_forest_green.tres")
var pursuit_color: Material = preload("res://debug/materials/debug_blue.tres")
var attack_color: Material = preload("res://debug/materials/debug_red.tres")
var retreat_color: Material = preload("res://debug/materials/debug_white.tres")

func _ready() -> void:
	set_multiplayer_authority(1)
	_configure_debug_animation_loops()
	max_health = maxf(max_health, health)
	spawn_origin = global_position
	_refresh_patrol_anchor()
	_randomize_idle_timer()
	_apply_state_visuals()

func noise(source_position: Vector3) -> void:
	if is_multiplayer_authority():
		_register_noise(source_position)
		return
	_report_noise.rpc_id(1, source_position)

@rpc("any_peer", "reliable")
func _report_noise(source_position: Vector3) -> void:
	if not is_multiplayer_authority():
		return
	_register_noise(source_position)

@rpc("authority", "unreliable_ordered")
func _sync_state(sync_position: Vector3, sync_rotation: Vector3, sync_velocity: Vector3, sync_gravity: Vector3, sync_state: int, sync_head_rotation: Vector3) -> void:
	if is_multiplayer_authority():
		return
	global_position = sync_position
	global_rotation = sync_rotation
	velocity = sync_velocity
	gravity_velocity = sync_gravity
	var incoming_state := sync_state as AiState
	if current_state != incoming_state:
		current_state = incoming_state
		_apply_state_visuals()
	if is_instance_valid(head):
		head.rotation = sync_head_rotation

@rpc("authority", "reliable")
func _sync_animation_state(sync_state: int) -> void:
	if is_multiplayer_authority():
		return
	var incoming_state := sync_state as AiState
	if current_state == incoming_state:
		return
	current_state = incoming_state
	_apply_state_visuals()

func hit(damage: float) -> void:
	if _is_dead:
		return
	_hit_stagger_time = hit_stagger_duration
	health = maxf(health - damage, 0.0)
	last_threat_position = global_position
	noise_age = 0.0
	noise_chain_age = 0.0
	noise_chain_count = maxi(noise_chain_count, 1)
	if debug_ai:
		print("[WOUNDED HIT] name=%s dmg=%.1f hp=%.1f/%.1f" % [name, damage, health, max_health])
	if health <= 0.0:
		_kill.rpc()
		return
	if _should_retreat():
		_set_state(AiState.RETREAT)

func headshot(damage: float) -> void:
	hit(damage * headshot_multiplier)

@rpc("authority", "reliable", "call_local")
func _kill() -> void:
	if _is_dead:
		return
	_is_dead = true
	set_physics_process(false)
	set_process(false)
	if has_node("CollisionShape"):
		$CollisionShape.disabled = true
	if enable_ragdoll_on_death and _activate_ragdoll_on_death():
		_schedule_corpse_cleanup()
		return
	visible = false
	call_deferred("queue_free")

func _activate_ragdoll_on_death() -> bool:
	if is_instance_valid(debug_fractured_model):
		var animation_tree: AnimationTree = debug_fractured_model.get_node_or_null("AnimationTree")
		if animation_tree != null:
			animation_tree.active = false
		var animation_player: AnimationPlayer = debug_fractured_model.get_node_or_null("AnimationPlayer")
		if animation_player != null:
			animation_player.stop()

	var simulator := _resolve_ragdoll_simulator()
	if simulator == null:
		if debug_ai:
			print("[WOUNDED AI] No PhysicalBoneSimulator3D found at path=%s; falling back to despawn." % [ragdoll_simulator_path])
		return false

	var physical_bone_count := _count_physical_bones_recursive(simulator.get_parent())
	if physical_bone_count <= 0:
		if debug_ai:
			print("[WOUNDED AI] PhysicalBoneSimulator3D found but no PhysicalBone3D nodes are present; ragdoll cannot simulate.")
		return false

	simulator.active = true

	if simulator.has_method("physical_bones_start_simulation"):
		simulator.call("physical_bones_start_simulation")
	elif simulator.has_method("start_simulation"):
		simulator.call("start_simulation")
	else:
		if debug_ai:
			print("[WOUNDED AI] Ragdoll simulator found but has no start simulation method.")
		return false

	if debug_ai:
		print("[WOUNDED AI] Ragdoll activated (physical_bones=%d)" % [physical_bone_count])
	return true

func _resolve_ragdoll_simulator() -> PhysicalBoneSimulator3D:
	var by_path := get_node_or_null(ragdoll_simulator_path)
	if by_path is PhysicalBoneSimulator3D:
		return by_path as PhysicalBoneSimulator3D
	return _find_physical_bone_simulator_recursive(self)

func _find_physical_bone_simulator_recursive(node: Node) -> PhysicalBoneSimulator3D:
	if node is PhysicalBoneSimulator3D:
		return node as PhysicalBoneSimulator3D
	for child in node.get_children():
		var match := _find_physical_bone_simulator_recursive(child)
		if match != null:
			return match
	return null

func _count_physical_bones_recursive(node: Node) -> int:
	if node == null:
		return 0
	var count := 0
	if node is PhysicalBone3D:
		count += 1
	for child in node.get_children():
		count += _count_physical_bones_recursive(child)
	return count

func _schedule_corpse_cleanup() -> void:
	if corpse_lifetime_seconds <= 0.0:
		return
	var timer := get_tree().create_timer(corpse_lifetime_seconds)
	timer.timeout.connect(_on_corpse_cleanup_timeout)

func _on_corpse_cleanup_timeout() -> void:
	if is_inside_tree():
		queue_free()

func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	if not is_multiplayer_authority():
		return

	_refresh_patrol_anchor()
	state_time += delta
	noise_age += delta
	noise_chain_age += delta
	_attack_age += delta
	_hit_stagger_time = maxf(_hit_stagger_time - delta, 0.0)
	_vision_timer -= delta
	if _vision_timer <= 0.0:
		_vision_timer = vision_check_interval
		_cast_vision_cone()
	if not is_instance_valid(tracked_player) and noise_age > aware_timeout:
		tracked_player = null

	var desired_velocity := _tick_behavior_tree(delta)
	_update_facing(delta, desired_velocity)
	_update_head_tracking(delta)

	if not is_on_floor():
		gravity_velocity += Vector3.DOWN * gravity * delta
	else:
		gravity_velocity = Vector3.ZERO

	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z
	velocity.y = gravity_velocity.y
	set_up_direction(Vector3.UP)
	move_and_slide()
	if is_on_floor() and gravity_velocity.y < 0.0:
		gravity_velocity = Vector3.ZERO

	var current_head_rotation := Vector3.ZERO
	if is_instance_valid(head):
		current_head_rotation = head.rotation
	_sync_state.rpc(global_position, global_rotation, velocity, gravity_velocity, current_state, current_head_rotation)

func _tick_behavior_tree(delta: float) -> Vector3:
	if _is_outside_home_leash():
		return _tick_return_home()
	if _should_retreat():
		return _tick_retreat()
	if _should_attack():
		return _tick_attack()
	if _should_pursue():
		return _tick_pursuit()
	if _should_scan():
		return _tick_scan()
	if _should_investigate():
		return _tick_aware()
	if current_state == AiState.PATROL:
		return _tick_patrol()
	return _tick_idle(delta)

func _tick_idle(delta: float) -> Vector3:
	if current_state != AiState.IDLE:
		_set_state(AiState.IDLE)
	idle_time_remaining -= delta
	if idle_time_remaining <= 0.0 and _can_patrol():
		_set_state(AiState.PATROL)
	return Vector3.ZERO

func _tick_patrol() -> Vector3:
	if current_state != AiState.PATROL:
		_set_state(AiState.PATROL)
	if not has_patrol_target:
		patrol_target = _pick_patrol_target()
		has_patrol_target = true
	_update_navigation_target(patrol_target)
	if _is_near_position(patrol_target, patrol_reach_distance):
		has_patrol_target = false
		_randomize_idle_timer()
		_set_state(AiState.IDLE)
		return Vector3.ZERO
	return _move_toward_navigation(patrol_speed)

func _tick_aware() -> Vector3:
	if current_state != AiState.AWARE:
		_set_state(AiState.AWARE)
	_update_navigation_target(last_heard_position)
	if _is_near_position(last_heard_position, aware_reach_distance) or state_time >= aware_timeout:
		noise_chain_count = 0
		_set_state(AiState.SCAN)
		return Vector3.ZERO
	return _move_toward_navigation(aware_speed)

func _tick_pursuit() -> Vector3:
	if current_state != AiState.PURSUIT:
		_set_state(AiState.PURSUIT)
	if is_instance_valid(tracked_player):
		last_heard_position = tracked_player.global_position
		if _is_player_in_attack_window(tracked_player.global_position) and _can_see_player(tracked_player):
			_set_state(AiState.ATTACK)
			return Vector3.ZERO
	_update_navigation_target(last_heard_position)
	if noise_age > pursuit_timeout:
		_set_state(AiState.SCAN)
		return Vector3.ZERO
	return _move_toward_navigation(pursuit_speed)

func _tick_attack() -> Vector3:
	if current_state != AiState.ATTACK:
		_set_state(AiState.ATTACK)
	if not is_instance_valid(tracked_player):
		_set_state(AiState.SCAN)
		return Vector3.ZERO

	last_heard_position = tracked_player.global_position
	if _distance_to_tracked_player() <= close_retreat_distance:
		_set_state(AiState.RETREAT)
		return Vector3.ZERO

	if _attack_age >= attack_cooldown and _can_see_player(tracked_player):
		_attempt_attack()

	if not _is_player_in_attack_window(tracked_player.global_position):
		_set_state(AiState.PURSUIT)
		return Vector3.ZERO

	if _can_see_player(tracked_player):
		return Vector3.ZERO

	_update_navigation_target(last_heard_position)
	return _move_toward_navigation(reposition_speed)

func _tick_scan() -> Vector3:
	if current_state != AiState.SCAN:
		_set_state(AiState.SCAN)
	if state_time >= scan_duration:
		_randomize_idle_timer()
		_set_state(AiState.IDLE)
	return Vector3.ZERO

func _tick_retreat() -> Vector3:
	if current_state != AiState.RETREAT or not has_retreat_target:
		_set_state(AiState.RETREAT)
	_update_navigation_target(retreat_target)
	if _is_near_position(retreat_target, patrol_reach_distance):
		_set_state(AiState.SCAN)
		return Vector3.ZERO
	return _move_toward_navigation(retreat_speed)

func _should_retreat() -> bool:
	if _distance_to_tracked_player() <= close_retreat_distance:
		return true
	if max_health <= 0.0:
		return false
	return health <= max_health * retreat_health_threshold

func _should_pursue() -> bool:
	return noise_chain_count >= 2 and noise_age <= pursuit_timeout

func _should_attack() -> bool:
	if not is_instance_valid(tracked_player):
		return false
	if noise_age > pursuit_timeout:
		return false
	if not _is_player_in_attack_window(tracked_player.global_position):
		return false
	if _distance_to_tracked_player() <= close_retreat_distance:
		return false
	if _can_see_player(tracked_player):
		return true
	var eye_position := global_position + Vector3.UP * vision_eye_height
	var target_center := tracked_player.global_position + Vector3.UP * 0.9
	return eye_position.distance_squared_to(target_center) <= close_contact_vision_distance * close_contact_vision_distance

func _should_scan() -> bool:
	return current_state == AiState.SCAN and state_time < scan_duration

func _should_investigate() -> bool:
	return noise_age <= aware_timeout

func _can_patrol() -> bool:
	return patrol_radius > 0.0

func _set_state(next_state: AiState) -> void:
	if current_state == next_state:
		return
	current_state = next_state
	state_time = 0.0
	if current_state == AiState.IDLE:
		has_patrol_target = false
		has_retreat_target = false
		_randomize_idle_timer()
	elif current_state == AiState.RETREAT:
		retreat_target = _pick_retreat_target()
		has_retreat_target = true
	_apply_state_visuals()
	if is_multiplayer_authority():
		_sync_animation_state.rpc(int(current_state))

func _apply_state_visuals() -> void:
	_sync_debug_animation_with_state()
	if not is_instance_valid(enemy_mesh):
		return
	var mesh = enemy_mesh.get_mesh()
	if not is_instance_valid(mesh) or mesh.get_surface_count() == 0:
		return
	match current_state:
		AiState.IDLE:
			enemy_mesh.set_surface_override_material(0, idle_color)
		AiState.PATROL:
			enemy_mesh.set_surface_override_material(0, patrol_color)
		AiState.AWARE:
			enemy_mesh.set_surface_override_material(0, aware_color)
		AiState.SCAN:
			enemy_mesh.set_surface_override_material(0, scan_color)
		AiState.PURSUIT:
			enemy_mesh.set_surface_override_material(0, pursuit_color)
		AiState.ATTACK:
			enemy_mesh.set_surface_override_material(0, attack_color)
		AiState.RETREAT:
			enemy_mesh.set_surface_override_material(0, retreat_color)

func _sync_debug_animation_with_state() -> void:
	match current_state:
		AiState.PATROL, AiState.AWARE:
			_play_debug_animation_state(&"Walk")
		AiState.PURSUIT, AiState.RETREAT:
			_play_debug_animation_state(&"Run")
		_:
			_play_debug_animation_state(&"Idle")

func _play_debug_animation_state(state_name: StringName) -> void:
	if _current_debug_animation_state == state_name:
		return
	if not is_instance_valid(debug_fractured_model):
		return
	var animation_tree: AnimationTree = debug_fractured_model.get_node_or_null("AnimationTree")
	if animation_tree == null:
		return
	animation_tree.active = true
	var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
	if playback == null:
		return
	playback.travel(StringName(state_name))
	_current_debug_animation_state = state_name

func _configure_debug_animation_loops() -> void:
	if not is_instance_valid(debug_fractured_model):
		return
	var animation_player: AnimationPlayer = debug_fractured_model.get_node_or_null("AnimationPlayer")
	if animation_player == null:
		return
	for clip_name in [&"Idle", &"Walk", &"Run", &"HoldingGun"]:
		var clip := animation_player.get_animation(clip_name)
		if clip == null:
			continue
		clip.loop_mode = Animation.LOOP_LINEAR

func _cast_vision_cone() -> void:
	var eye_position := global_position + Vector3.UP * vision_eye_height
	var half_fov_rad := deg_to_rad(vision_fov * 0.5)
	var forward := -global_transform.basis.z
	for candidate in get_tree().get_nodes_in_group("players"):
		if not is_instance_valid(candidate) or not (candidate is Node3D):
			continue
		var player := candidate as Node3D
		var target_center: Vector3 = player.global_position + Vector3.UP * 0.9
		var to_target: Vector3 = target_center - eye_position
		var distance_sq := to_target.length_squared()
		if distance_sq > vision_range * vision_range:
			continue
		if forward.angle_to(to_target.normalized()) > half_fov_rad and distance_sq > close_contact_vision_distance * close_contact_vision_distance:
			continue
		if _can_see_player(player):
			_spot_player(player)

func _spot_player(player: Node3D) -> void:
	tracked_player = player
	last_heard_position = player.global_position
	last_threat_position = player.global_position
	noise_age = 0.0
	noise_chain_age = 0.0
	noise_chain_count = maxi(noise_chain_count, 2)
	if _should_retreat():
		_set_state(AiState.RETREAT)
	elif _should_attack():
		_set_state(AiState.ATTACK)
	else:
		_set_state(AiState.PURSUIT)

func _register_noise(source_position: Vector3) -> void:
	last_heard_position = source_position
	last_threat_position = source_position
	if noise_chain_age > noise_chain_window:
		noise_chain_count = 0
	noise_chain_count += 1
	noise_age = 0.0
	noise_chain_age = 0.0
	if _should_retreat():
		_set_state(AiState.RETREAT)
	elif noise_chain_count >= 2:
		_set_state(AiState.PURSUIT)
	else:
		_set_state(AiState.AWARE)

func _refresh_patrol_anchor() -> void:
	if is_instance_valid(home):
		patrol_anchor = home.global_position
	else:
		patrol_anchor = spawn_origin

func _randomize_idle_timer() -> void:
	idle_time_remaining = randf_range(idle_duration_min, idle_duration_max)

func _pick_patrol_target() -> Vector3:
	var offset_2d := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(patrol_radius * 0.35, patrol_radius)
	return _clamp_to_home_leash(patrol_anchor + Vector3(offset_2d.x, 0.0, offset_2d.y))

func _pick_retreat_target() -> Vector3:
	var retreat_origin := last_threat_position
	if retreat_origin == Vector3.ZERO:
		retreat_origin = patrol_anchor
	var away_2d := Vector2(global_position.x - retreat_origin.x, global_position.z - retreat_origin.z)
	if away_2d.length_squared() < 0.001:
		away_2d = Vector2.RIGHT.rotated(randf() * TAU)
	else:
		away_2d = away_2d.normalized()
	return _clamp_to_home_leash(global_position + Vector3(away_2d.x, 0.0, away_2d.y) * retreat_distance)

func _is_outside_home_leash() -> bool:
	if max_home_leash_distance <= 0.0:
		return false
	var current_position_2d := Vector2(global_position.x, global_position.z)
	var anchor_position_2d := Vector2(patrol_anchor.x, patrol_anchor.z)
	return current_position_2d.distance_to(anchor_position_2d) > max_home_leash_distance

func _tick_return_home() -> Vector3:
	has_patrol_target = false
	has_retreat_target = false
	tracked_player = null
	noise_age = aware_timeout + 1.0
	noise_chain_age = noise_chain_window + 1.0
	noise_chain_count = 0
	if current_state != AiState.PATROL:
		_set_state(AiState.PATROL)
	_update_navigation_target(patrol_anchor)
	if _is_near_position(patrol_anchor, aware_reach_distance):
		return Vector3.ZERO
	return _move_toward_navigation(retreat_speed)

func _clamp_to_home_leash(target_position: Vector3) -> Vector3:
	if max_home_leash_distance <= 0.0:
		return target_position
	var anchor_2d := Vector2(patrol_anchor.x, patrol_anchor.z)
	var target_2d := Vector2(target_position.x, target_position.z)
	var offset := target_2d - anchor_2d
	if offset.length() <= max_home_leash_distance:
		return target_position
	var clamped_2d := anchor_2d + offset.normalized() * max_home_leash_distance
	return Vector3(clamped_2d.x, target_position.y, clamped_2d.y)

func _attempt_attack() -> void:
	if not is_instance_valid(tracked_player):
		return
	if not _can_see_player(tracked_player):
		return
	_attack_age = 0.0
	_trigger_gun_use()

func _trigger_gun_use() -> void:
	if not is_instance_valid(gun):
		if debug_ai:
			print("[WOUNDED AI] Missing gun at GunAnchor/AiGun")
		return
	if not gun.has_method("use"):
		if debug_ai:
			print("[WOUNDED AI] Gun has no use() method")
		return
	var use_arg_count := 0
	for method in gun.get_method_list():
		if method.get("name", "") == "use":
			use_arg_count = method.get("args", []).size()
			break
	if use_arg_count <= 0:
		gun.call("use")
	else:
		gun.call("use", self)

func _face_tracked_player(delta: float) -> void:
	if not is_instance_valid(tracked_player):
		return
	var target_flat := Vector3(tracked_player.global_position.x, global_position.y, tracked_player.global_position.z)
	if target_flat.distance_squared_to(global_position) <= 0.0001:
		return
	var desired_transform := global_transform.looking_at(target_flat, Vector3.UP)
	var desired_yaw := desired_transform.basis.get_euler().y
	global_rotation.y = lerp_angle(global_rotation.y, desired_yaw, clampf(delta * turn_speed, 0.0, 1.0))

func _update_facing(delta: float, desired_velocity: Vector3) -> void:
	var move_direction := Vector3(desired_velocity.x, 0.0, desired_velocity.z)
	if move_direction.length_squared() > 0.0001:
		var desired_yaw := atan2(-move_direction.x, -move_direction.z)
		global_rotation.y = lerp_angle(global_rotation.y, desired_yaw, clampf(delta * turn_speed, 0.0, 1.0))
		return
	_face_tracked_player(delta)

func _update_head_tracking(delta: float) -> void:
	if not is_instance_valid(head):
		return
	var target_yaw := 0.0
	var target_pitch := 0.0
	if is_instance_valid(tracked_player) and current_state != AiState.IDLE and current_state != AiState.PATROL:
		var aim_point := tracked_player.global_position + Vector3.UP * head_aim_height_offset
		var local_target := head.to_local(aim_point)
		var flat_distance := maxf(Vector2(local_target.x, local_target.z).length(), 0.001)
		target_yaw = atan2(-local_target.x, -local_target.z)
		target_pitch = atan2(local_target.y, flat_distance)
	var max_yaw := deg_to_rad(head_max_yaw_degrees)
	var max_pitch_up := deg_to_rad(head_max_pitch_up_degrees)
	var max_pitch_down := deg_to_rad(head_max_pitch_down_degrees)
	target_yaw = clampf(target_yaw, -max_yaw, max_yaw)
	target_pitch = clampf(target_pitch, -max_pitch_down, max_pitch_up)
	head.rotation.y = lerp_angle(head.rotation.y, target_yaw, clampf(delta * head_track_speed, 0.0, 1.0))
	head.rotation.x = lerp_angle(head.rotation.x, target_pitch, clampf(delta * head_track_speed, 0.0, 1.0))
	head.rotation.z = 0.0

func _is_player_in_attack_window(target_position: Vector3) -> bool:
	var distance := Vector2(global_position.x, global_position.z).distance_to(Vector2(target_position.x, target_position.z))
	return distance <= attack_range and distance >= minimum_attack_range

func _distance_to_tracked_player() -> float:
	if not is_instance_valid(tracked_player):
		return INF
	var self_2d := Vector2(global_position.x, global_position.z)
	var player_2d := Vector2(tracked_player.global_position.x, tracked_player.global_position.z)
	return self_2d.distance_to(player_2d)

func _can_see_player(player: Node3D) -> bool:
	if not is_instance_valid(player):
		return false
	var eye_position := global_position + Vector3.UP * vision_eye_height
	var target_center: Vector3 = player.global_position + Vector3.UP * 0.9
	if eye_position.distance_squared_to(target_center) <= close_contact_vision_distance * close_contact_vision_distance:
		return true
	var space_state := get_world_3d().direct_space_state
	var ray_offsets := [Vector3.ZERO, Vector3.UP * 0.75, Vector3.DOWN * 0.65]
	for offset in ray_offsets:
		var query := PhysicsRayQueryParameters3D.create(eye_position, target_center + offset)
		query.exclude = [get_rid()]
		var result := space_state.intersect_ray(query)
		if result.is_empty():
			continue
		var collider = result.get("collider")
		if collider == player:
			return true
		if is_instance_valid(collider) and collider.is_in_group("players"):
			return true
	return false

func _update_navigation_target(target_position: Vector3) -> void:
	navigation.target_position = Vector3(target_position.x, global_position.y, target_position.z)

func _move_toward_navigation(move_speed: float) -> Vector3:
	var next_path_position := navigation.get_next_path_position()
	var move_direction := next_path_position - global_position
	move_direction.y = 0.0
	if move_direction.length_squared() <= 0.0001:
		return Vector3.ZERO
	var adjusted_speed := move_speed
	if _hit_stagger_time > 0.0:
		adjusted_speed *= 0.45
	return move_direction.normalized() * adjusted_speed

func _is_near_position(target_position: Vector3, threshold: float) -> bool:
	var current_position_2d := Vector2(global_position.x, global_position.z)
	var target_position_2d := Vector2(target_position.x, target_position.z)
	return current_position_2d.distance_to(target_position_2d) <= threshold
