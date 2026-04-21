###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet, Minsung Kim
###############################################################
extends BaseAI

const PERF_REPORT_INTERVAL_MS := 1000

static var _perf_last_report_ms: int = 0
static var _perf_active_ai: int = 0
static var _perf_physics_calls: int = 0
static var _perf_physics_us_total: int = 0
static var _perf_bt_us_total: int = 0
static var _perf_move_us_total: int = 0
static var _perf_sync_rpcs: int = 0
static var _perf_vision_checks: int = 0

@onready var gun_location: Node3D = self

@export var behavior_tick_interval: float = 0.12
@export var sync_interval: float = 0.12

var sword: Node = null
var _behavior_tick_timer: float = 0.0
var _sync_timer: float = 0.0
var _cached_desired_velocity: Vector3 = Vector3.ZERO
var _cached_players: Array = []
var _player_cache_timer: float = 0.0
const _PLAYER_CACHE_INTERVAL: float = 0.5
var _can_see_tracked_player: bool = false
var _last_nav_target: Vector3 = Vector3(INF, INF, INF)

const REMOTE_POSITION_LERP: float = 12.0
const REMOTE_ROTATION_LERP: float = 16.0
const REMOTE_EXTRAPOLATION_SEC: float = 0.05
var _has_remote_snapshot: bool = false
var _remote_target_position: Vector3 = Vector3.ZERO
var _remote_target_rotation_y: float = 0.0
var _stuck_timer: float = 0.0
const _STUCK_VELOCITY_SQ: float = 0.1
const _STUCK_TIMEOUT: float = 2.0

func _ready() -> void:
	navigation = $navigation
	enemy_mesh = $enemy_mesh
	set_multiplayer_authority(1)
	set_physics_process(false)
	if multiplayer.is_server():
		_perf_active_ai += 1
	if debug_ai:
		print("[AI DEBUG][READY_ENTER] name=%s id=%s peer=%s authority=%s global_position=%s" % [
			name, get_instance_id(), multiplayer.get_unique_id(),
			get_multiplayer_authority(), global_position,
		])
	_equip_sword_if_available()
	await get_tree().physics_frame
	max_health = maxf(max_health, health)
	spawn_origin = global_position
	_refresh_patrol_anchor()
	_randomize_idle_timer()
	_apply_state_visuals()
	set_physics_process(true)
	if debug_ai:
		print("[AI DEBUG][READY_COMPLETE] name=%s id=%s peer=%s authority=%s global_position=%s" % [
			name, get_instance_id(), multiplayer.get_unique_id(),
			get_multiplayer_authority(), global_position,
		])
	_cache_ragdoll_visual_scale()

func _on_hit(_damage: float) -> void:
	last_threat_position = global_position

func _on_killed() -> void:
	if multiplayer.is_server():
		_perf_active_ai = maxi(0, _perf_active_ai - 1)
	print("[AI HIT] DEAD: disabling controller")

func _set_state(next_state: AiState) -> void:
	if current_state == next_state:
		return
	_last_nav_target = Vector3(INF, INF, INF)
	super._set_state(next_state)

func _apply_state_visuals() -> void:
	_sync_debug_animation_with_state()
	super._apply_state_visuals()

@rpc("authority", "unreliable_ordered")
func _sync_state(sync_position: Vector3, sync_rotation: Vector3, sync_velocity: Vector3, sync_gravity: Vector3, sync_state: int) -> void:
	if is_multiplayer_authority():
		return
	var flat_velocity := Vector3(sync_velocity.x, 0.0, sync_velocity.z)
	_remote_target_position = sync_position + flat_velocity * REMOTE_EXTRAPOLATION_SEC
	_remote_target_rotation_y = sync_rotation.y
	_has_remote_snapshot = true
	velocity = sync_velocity
	gravity_velocity = sync_gravity
	var new_state := sync_state as AiState
	var state_changed := new_state != current_state
	current_state = new_state
	if state_changed:
		_apply_state_visuals()

@rpc("authority", "unreliable_ordered")
func _sync_attack_swing() -> void:
	if is_multiplayer_authority():
		return
	_play_debug_animation(&"swing", true)

func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	if not is_multiplayer_authority():
		_interpolate_remote(delta)
		return
	var physics_start_us := Time.get_ticks_usec()
	state_time += delta
	noise_age += delta
	noise_chain_age += delta
	_attack_age += delta
	_vision_timer -= delta
	_behavior_tick_timer -= delta
	_sync_timer -= delta
	_player_cache_timer -= delta
	if _player_cache_timer <= 0.0:
		_player_cache_timer = _PLAYER_CACHE_INTERVAL
		_cached_players = get_tree().get_nodes_in_group("players")
	if _vision_timer <= 0.0:
		_vision_timer = vision_check_interval
		_perf_vision_checks += 1
		_cast_vision_cone()
	if not is_instance_valid(tracked_player) and noise_age > aware_timeout:
		tracked_player = null

	var desired_velocity := _cached_desired_velocity
	if _behavior_tick_timer <= 0.0:
		_behavior_tick_timer = behavior_tick_interval
		_refresh_patrol_anchor()
		var bt_start_us := Time.get_ticks_usec()
		desired_velocity = _tick_behavior_tree(delta)
		_perf_bt_us_total += Time.get_ticks_usec() - bt_start_us
		_cached_desired_velocity = desired_velocity
		_check_stuck(desired_velocity)
	_update_facing(delta, desired_velocity)

	var move_start_us := Time.get_ticks_usec()
	if not is_on_floor():
		gravity_velocity += Vector3.DOWN * gravity * delta
	else:
		gravity_velocity = Vector3.ZERO

	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z
	velocity.y = gravity_velocity.y
	set_up_direction(Vector3.UP)
	move_and_slide()
	_perf_move_us_total += Time.get_ticks_usec() - move_start_us
	if is_on_floor() and gravity_velocity.y < 0.0:
		gravity_velocity = Vector3.ZERO
	if _sync_timer <= 0.0:
		_sync_timer = sync_interval
		_sync_state.rpc(global_position, global_rotation, velocity, gravity_velocity, current_state)
		_perf_sync_rpcs += 1

	_perf_physics_calls += 1
	_perf_physics_us_total += Time.get_ticks_usec() - physics_start_us

	# AI PROF disabled
	# var now_ms := Time.get_ticks_msec()
	# if _perf_last_report_ms == 0:
	# 	_perf_last_report_ms = now_ms
	# elif now_ms - _perf_last_report_ms >= PERF_REPORT_INTERVAL_MS:
	# 	...print("[AI PROF][SERVER] ...")
	# 	_perf_last_report_ms = now_ms
	# 	_perf_physics_calls = 0
	# 	...reset counters...

func _tick_behavior_tree(_delta: float) -> Vector3:
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
	return _tick_idle(_delta)

func _tick_pursuit() -> Vector3:
	if current_state != AiState.PURSUIT:
		_set_state(AiState.PURSUIT)
	if is_instance_valid(tracked_player):
		if not _is_player_alive(tracked_player):
			tracked_player = null
		else:
			last_heard_position = tracked_player.global_position
			if _is_player_in_attack_range(tracked_player.global_position):
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
	if not _is_player_alive(tracked_player):
		tracked_player = null
		_set_state(AiState.SCAN)
		return Vector3.ZERO
	last_heard_position = tracked_player.global_position
	if _attack_age >= attack_cooldown:
		_attempt_attack()
	if not _is_player_in_attack_range(tracked_player.global_position):
		_set_state(AiState.PURSUIT)
	return Vector3.ZERO

func _should_attack() -> bool:
	if _should_retreat():
		return false
	if not _is_player_alive(tracked_player):
		return false
	if noise_age > pursuit_timeout:
		return false
	if not _is_player_in_attack_range(tracked_player.global_position):
		return false
	if _can_see_tracked_player:
		return true
	var eye_position := global_position + Vector3.UP * vision_eye_height
	var target_center := tracked_player.global_position + Vector3.UP * 0.9
	return eye_position.distance_squared_to(target_center) <= close_contact_vision_distance * close_contact_vision_distance

func _update_navigation_target(target_position: Vector3) -> void:
	var flat_target := Vector3(target_position.x, global_position.y, target_position.z)
	if flat_target.distance_squared_to(_last_nav_target) < 0.25:
		return
	_last_nav_target = flat_target
	navigation.target_position = flat_target

func _cast_vision_cone() -> void:
	_can_see_tracked_player = false
	var eye_position := global_position + Vector3.UP * vision_eye_height
	var half_fov_rad := deg_to_rad(vision_fov * 0.5)
	var forward := -global_transform.basis.z
	for candidate in _cached_players:
		if not is_instance_valid(candidate) or not (candidate is Node3D):
			continue
		if not _is_player_alive(candidate):
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
			if player == tracked_player:
				_can_see_tracked_player = true

func _spot_player(player: Node3D) -> void:
	tracked_player = player
	last_heard_position = player.global_position
	last_threat_position = player.global_position
	noise_age = 0.0
	noise_chain_age = 0.0
	noise_chain_count = maxi(noise_chain_count, 2)
	if not _should_retreat():
		if _should_attack():
			_set_state(AiState.ATTACK)
		else:
			_set_state(AiState.PURSUIT)

func _check_stuck(desired_velocity: Vector3) -> void:
	var is_movement_state := current_state in [AiState.PATROL, AiState.AWARE, AiState.PURSUIT, AiState.RETREAT]
	if not is_movement_state:
		_stuck_timer = 0.0
		return
	if Vector2(desired_velocity.x, desired_velocity.z).length_squared() >= _STUCK_VELOCITY_SQ:
		_stuck_timer = 0.0
		return
	_stuck_timer += behavior_tick_interval
	_play_debug_animation(&"idle")
	if _stuck_timer >= _STUCK_TIMEOUT:
		_stuck_timer = 0.0
		has_patrol_target = false
		_set_state(AiState.IDLE)

func _interpolate_remote(delta: float) -> void:
	if not _has_remote_snapshot:
		return
	global_position = global_position.lerp(_remote_target_position, REMOTE_POSITION_LERP * delta)
	global_rotation.y = lerp_angle(global_rotation.y, _remote_target_rotation_y, REMOTE_ROTATION_LERP * delta)

func _equip_sword_if_available() -> void:
	sword = get_node_or_null("SwordAnchor/AiSword")
	if sword == null:
		sword = find_child("aisword", true, false)
	if not is_instance_valid(sword):
		return
	if sword.has_method("_set_active"):
		sword.call("_set_active")

func _attempt_attack() -> void:
	if not is_instance_valid(tracked_player):
		return
	if not _is_player_in_attack_range(tracked_player.global_position):
		return
	if not _can_see_player(tracked_player):
		var eye_position := global_position + Vector3.UP * vision_eye_height
		var target_center := tracked_player.global_position + Vector3.UP * 0.9
		if eye_position.distance_squared_to(target_center) > close_contact_vision_distance * close_contact_vision_distance:
			return
	_attack_age = 0.0
	_play_debug_animation(&"swing", true)
	_sync_attack_swing.rpc()
	_trigger_sword_use()
	if debug_ai:
		print("[AI DEBUG][ATTACK] name=%s target=%s swing=true" % [name, tracked_player.name])

func _trigger_sword_use() -> void:
	if not is_instance_valid(sword):
		if debug_ai:
			print("[AI DEBUG][ATTACK] sword reference invalid")
		return
	if sword.has_method("use"):
		sword.call("use", self)
	elif debug_ai:
		print("[AI DEBUG][ATTACK] sword has no use() method")

func _is_player_in_attack_range(target_position: Vector3) -> bool:
	var current_position_2d := Vector2(global_position.x, global_position.z)
	var target_position_2d := Vector2(target_position.x, target_position.z)
	return current_position_2d.distance_to(target_position_2d) <= attack_range

func _sync_debug_animation_with_state() -> void:
	match current_state:
		AiState.IDLE, AiState.SCAN:
			_play_debug_animation(&"idle")
		AiState.PATROL, AiState.AWARE:
			_play_debug_animation(&"walk")
		AiState.PURSUIT, AiState.RETREAT:
			_play_debug_animation(&"run")
		AiState.ATTACK:
			_play_debug_animation(&"swing", true)

func _play_debug_animation(method_name: StringName, force_restart: bool = false) -> void:
	if not is_instance_valid(debug_fractured_model):
		return
	if not force_restart:
		var ap: AnimationPlayer = debug_fractured_model.get_node_or_null("AnimationPlayer")
		if ap != null and ap.is_playing() and ap.current_animation.to_lower() == String(method_name):
			return
	if debug_fractured_model.has_method(method_name):
		debug_fractured_model.call(method_name)
