extends BaseAI

@onready var head: Node3D = $Head
@onready var gun_location: Node3D = self
@onready var gun: Node = $debug_fractured/Armature/Skeleton3D/ModifierBoneTarget3D/BasicAiGun

@export var reposition_speed: float = 0.8
@export var max_home_leash_distance: float = 14.0
@export var minimum_attack_range: float = 5.5
@export var close_retreat_distance: float = 6.0
@export var hit_stagger_duration: float = 0.35
@export var headshot_multiplier: float = 1.75
@export var head_track_speed: float = 8.0
@export var head_max_yaw_degrees: float = 60.0
@export var head_max_pitch_up_degrees: float = 35.0
@export var head_max_pitch_down_degrees: float = 25.0
@export var head_aim_height_offset: float = 0.9

var _hit_stagger_time: float = 0.0
var _current_debug_animation_state: StringName = &""

func _ready() -> void:
	navigation = $Navigation
	enemy_mesh = $Model
	set_multiplayer_authority(1)
	_configure_debug_animation_loops()
	max_health = maxf(max_health, health)
	spawn_origin = global_position
	_refresh_patrol_anchor()
	_randomize_idle_timer()
	_apply_state_visuals()
	_cache_ragdoll_visual_scale()

func _on_hit(_damage: float) -> void:
	_hit_stagger_time = hit_stagger_duration
	last_threat_position = global_position
	noise_age = 0.0
	noise_chain_age = 0.0
	noise_chain_count = maxi(noise_chain_count, 1)

func headshot(damage: float, shooter_id: int = 0) -> void:
	hit(damage * headshot_multiplier, shooter_id)

func _set_state(next_state: AiState) -> void:
	if current_state == next_state:
		return
	super._set_state(next_state)
	if is_multiplayer_authority():
		_sync_animation_state.rpc(int(current_state))

func _apply_state_visuals() -> void:
	_sync_debug_animation_with_state()
	super._apply_state_visuals()

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
