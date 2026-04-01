###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet, Minsung Kim
###############################################################
extends CharacterBody3D

class_name BaseAI

enum AiState {
	IDLE,
	PATROL,
	AWARE,
	SCAN,
	PURSUIT,
	ATTACK,
	RETREAT,
}

@export var max_health: float = 100.0
@export var health: float = 100.0
@export var patrol_speed: float = 2.5
@export var aware_speed: float = 3.5
@export var pursuit_speed: float = 4.5
@export var retreat_speed: float = 4.0
@export var gravity: float = 20.0
@export var patrol_radius: float = 20.0
@export var patrol_reach_distance: float = 1.5
@export var aware_reach_distance: float = 2.0
@export var idle_duration_min: float = 0.75
@export var idle_duration_max: float = 2.0
@export var aware_timeout: float = 3.0
@export var pursuit_timeout: float = 1.75
@export var noise_chain_window: float = 1.0
@export var retreat_health_threshold: float = 0.25
@export var retreat_distance: float = 12.0
@export var scan_duration: float = 2.5
@export var vision_range: float = 22.0
@export var vision_fov: float = 100.0
@export var vision_eye_height: float = 1.6
@export var vision_check_interval: float = 0.25
@export var close_contact_vision_distance: float = 2.4
@export var turn_speed: float = 10.0
@export var attack_range: float = 2.2
@export var attack_cooldown: float = 0.9
@export var debug_ai: bool = false
@export var enable_ragdoll_on_death: bool = true
@export var ragdoll_simulator_path: NodePath = NodePath("debug_fractured/Armature/Skeleton3D/PhysicalBoneSimulator3D")
@export var corpse_lifetime_seconds: float = 20.0

# Subclasses bind these in their own @onready declarations
var navigation: NavigationAgent3D
var enemy_mesh: MeshInstance3D
@onready var debug_fractured_model: Node = get_node_or_null("debug_fractured")

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
var _ragdoll_visual_scale: Vector3 = Vector3.ONE

var idle_color: Material = preload("res://debug/materials/debug_teal.tres")
var patrol_color: Material = preload("res://debug/materials/debug_yellow.tres")
var aware_color: Material = preload("res://debug/materials/debug_red.tres")
var scan_color: Material = preload("res://debug/materials/debug_forest_green.tres")
var pursuit_color: Material = preload("res://debug/materials/debug_blue.tres")
var attack_color: Material = preload("res://debug/materials/debug_red.tres")
var retreat_color: Material = preload("res://debug/materials/debug_white.tres")

# --- Damage interface ---

func hit(damage: float, shooter_id: int = 0) -> void:
	if _is_dead:
		return
	_on_hit(damage)
	health = maxf(health - damage, 0.0)
	if health <= 0.0:
		if shooter_id != 0 and multiplayer.is_server():
			Global.map_root.record_ai_kill(shooter_id)
		_kill.rpc()
		return
	_on_post_hit()

# Override to apply hit effects (stagger, noise chain reset, etc.)
func _on_hit(_damage: float) -> void:
	pass

# Override for post-hit state changes
func _on_post_hit() -> void:
	if _should_retreat():
		_set_state(AiState.RETREAT)

func headshot(damage: float, shooter_id: int = 0) -> void:
	hit(damage, shooter_id)

# --- Death & ragdoll ---

@rpc("authority", "reliable", "call_local")
func _kill() -> void:
	if _is_dead:
		return
	_is_dead = true
	_on_killed()
	set_physics_process(false)
	set_process(false)
	# Handle both CollisionShape and CollisionShape3D node names
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = true
	elif has_node("CollisionShape"):
		get_node("CollisionShape").disabled = true
	if enable_ragdoll_on_death and _activate_ragdoll_on_death():
		_schedule_corpse_cleanup()
		return
	visible = false
	call_deferred("queue_free")

# Override for per-type cleanup on death (e.g. perf counter decrement)
func _on_killed() -> void:
	pass

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
		return false
	var physical_bone_count := _count_physical_bones_recursive(simulator.get_parent())
	if physical_bone_count <= 0:
		return false
	_cache_ragdoll_visual_scale()
	simulator.active = true
	if simulator.has_method("physical_bones_start_simulation"):
		simulator.call("physical_bones_start_simulation")
	elif simulator.has_method("start_simulation"):
		simulator.call("start_simulation")
	else:
		return false
	_stabilize_ragdoll_scale()
	return true

func _cache_ragdoll_visual_scale() -> void:
	if is_instance_valid(debug_fractured_model) and debug_fractured_model is Node3D:
		_ragdoll_visual_scale = (debug_fractured_model as Node3D).global_transform.basis.get_scale()

func _stabilize_ragdoll_scale() -> void:
	if not is_instance_valid(debug_fractured_model) or not (debug_fractured_model is Node3D):
		return
	var model := debug_fractured_model as Node3D
	var model_transform := model.global_transform
	var orthonormal_basis := model_transform.basis.orthonormalized()
	model.global_transform = Transform3D(orthonormal_basis.scaled(_ragdoll_visual_scale), model_transform.origin)
	call_deferred("_stabilize_ragdoll_scale_deferred")

func _stabilize_ragdoll_scale_deferred() -> void:
	if not is_instance_valid(debug_fractured_model) or not (debug_fractured_model is Node3D):
		return
	var model := debug_fractured_model as Node3D
	var model_transform := model.global_transform
	var orthonormal_basis := model_transform.basis.orthonormalized()
	model.global_transform = Transform3D(orthonormal_basis.scaled(_ragdoll_visual_scale), model_transform.origin)

func _resolve_ragdoll_simulator() -> PhysicalBoneSimulator3D:
	var by_path := get_node_or_null(ragdoll_simulator_path)
	if by_path is PhysicalBoneSimulator3D:
		return by_path as PhysicalBoneSimulator3D
	return _find_physical_bone_simulator_recursive(self)

func _find_physical_bone_simulator_recursive(node: Node) -> PhysicalBoneSimulator3D:
	if node is PhysicalBoneSimulator3D:
		return node as PhysicalBoneSimulator3D
	for child in node.get_children():
		var result := _find_physical_bone_simulator_recursive(child)
		if result != null:
			return result
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

# --- Noise ---

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

# --- Vision ---

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

# --- Navigation ---

func _update_navigation_target(target_position: Vector3) -> void:
	navigation.target_position = Vector3(target_position.x, global_position.y, target_position.z)

func _move_toward_navigation(move_speed: float) -> Vector3:
	var next_path_position := navigation.get_next_path_position()
	var move_direction := next_path_position - global_position
	move_direction.y = 0.0
	if move_direction.length_squared() <= 0.0001:
		return Vector3.ZERO
	return move_direction.normalized() * move_speed

func _is_near_position(target_position: Vector3, threshold: float) -> bool:
	var current_position_2d := Vector2(global_position.x, global_position.z)
	var target_position_2d := Vector2(target_position.x, target_position.z)
	return current_position_2d.distance_to(target_position_2d) <= threshold

# --- Movement ---

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

# --- State machine ---

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

func _apply_state_visuals() -> void:
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

func _should_retreat() -> bool:
	if max_health <= 0.0:
		return false
	return health <= max_health * retreat_health_threshold

func _should_pursue() -> bool:
	return noise_chain_count >= 2 and noise_age <= pursuit_timeout

func _should_attack() -> bool:
	return false  # override

func _should_scan() -> bool:
	return current_state == AiState.SCAN and state_time < scan_duration

func _should_investigate() -> bool:
	return noise_age <= aware_timeout

func _can_patrol() -> bool:
	return patrol_radius > 0.0

func _refresh_patrol_anchor() -> void:
	if is_instance_valid(home):
		patrol_anchor = home.global_position
	else:
		patrol_anchor = spawn_origin

func _randomize_idle_timer() -> void:
	idle_time_remaining = randf_range(idle_duration_min, idle_duration_max)

func _pick_patrol_target() -> Vector3:
	var offset_2d := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(patrol_radius * 0.35, patrol_radius)
	return patrol_anchor + Vector3(offset_2d.x, 0.0, offset_2d.y)

func _pick_retreat_target() -> Vector3:
	var retreat_origin := last_threat_position
	if retreat_origin == Vector3.ZERO:
		retreat_origin = patrol_anchor
	var away_2d := Vector2(global_position.x - retreat_origin.x, global_position.z - retreat_origin.z)
	if away_2d.length_squared() < 0.001:
		away_2d = Vector2.RIGHT.rotated(randf() * TAU)
	else:
		away_2d = away_2d.normalized()
	return global_position + Vector3(away_2d.x, 0.0, away_2d.y) * retreat_distance

# --- Behavior ticks (shared implementations) ---

func _tick_behavior_tree(_delta: float) -> Vector3:
	return Vector3.ZERO  # override

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
	_update_navigation_target(last_heard_position)
	if noise_age > pursuit_timeout:
		_set_state(AiState.SCAN)
		return Vector3.ZERO
	return _move_toward_navigation(pursuit_speed)

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
		return Vector3.ZERO
	return _move_toward_navigation(retreat_speed)
