###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Area3D

# Description of what a camp should do or be
var fractured_load_path: PackedScene = preload("res://behavior/ai/basic_enemy/BasicEnemy.tscn")
var wounded_load_path: PackedScene = preload("res://behavior/ai/wounded/Wounded.tscn")

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var spawns = $Spawns

# 1. Camp needs to spawn enemies and register itself as their home
# 	a. This is more related to AI, but AI should return to camp, maybe let them
#	know that they have return when they enter
# 2. Camp needs to spawn chipsire

# This should change in the future to harbor different kinds of AI
# There may also be a need for camp types
var number_fractured: int
@export var max_fractured: int = 5
@export var min_wounded: int = 1
@export var max_wounded: int = 2
var fractured: Array = []
@export var debug_spawns: bool = false

@export var min_radius: float
@export var max_radius: float
var spawn_points: Array[Vector3] = []

# Note: do not scale this node ever, it must always be set to (1,1,1)

func _get_spawn_position(index: int) -> Vector3:
	if spawn_points.size() > 0:
		return spawn_points[index % spawn_points.size()]
	return to_global(Vector3(index + 4, 2.0, index + 4))

func _cache_spawn_points() -> void:
	spawn_points.clear()
	if not is_instance_valid(spawns):
		return
	for child in spawns.get_children():
		if child is Marker3D:
			spawn_points.append((child as Marker3D).global_position)

func _project_to_ground(world_position: Vector3) -> Vector3:
	var space_state := get_world_3d().direct_space_state
	var from := world_position + Vector3.UP * 80.0
	var to := world_position + Vector3.DOWN * 400.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return world_position
	return result.get("position", world_position)

func _get_spawn_height_offset(kind: String) -> float:
	# BasicEnemy has an elevated capsule center; Wounded's capsule is centered at root.
	if kind == "wounded":
		return 1.05
	return 0.25


func _spawn_networked_ai(data: Variant) -> Node:
	if not (data is Dictionary):
		return null

	var kind := String(data.get("kind", "fractured"))
	var scene_to_spawn: PackedScene = null
	if kind == "wounded":
		scene_to_spawn = wounded_load_path
	elif kind == "fractured":
		scene_to_spawn = fractured_load_path
	if scene_to_spawn == null:
		return null

	var fractured_enemy := scene_to_spawn.instantiate()
	return fractured_enemy

func _has_property(node: Object, property_name: String) -> bool:
	for property_data in node.get_property_list():
		if String(property_data.get("name", "")) == property_name:
			return true
	return false

# Placeholder for camp behavior
func _ready():
	multiplayer_spawner.spawn_function = Callable(self, "_spawn_networked_ai")

	# define random number of fractured
	# Enemy spawing needs to be moved to LOD @MINSUNG YOU DO THIS
	if not multiplayer.is_server():
		return
	await get_tree().physics_frame
	_cache_spawn_points()

	randomize()
	number_fractured = int(randf_range(1, max_fractured + 1))
	var wounded_count := clampi(randi_range(min_wounded, max_wounded), 0, number_fractured)
	var spawned_fractured := 0
	var spawned_wounded := 0
	if debug_spawns:
		print("[CAMP SPAWN][PLAN] camp=%s total=%d fractured=%d wounded=%d" % [
			name,
			number_fractured,
			number_fractured - wounded_count,
			wounded_count,
		])
	# mint random number of fractured
	for ai in range(number_fractured):
		var enemy_kind := "fractured"
		if ai < wounded_count:
			enemy_kind = "wounded"
		var ground_position := _project_to_ground(_get_spawn_position(ai))
		var spawn_position := ground_position + Vector3.UP * _get_spawn_height_offset(enemy_kind)
		var fractured_enemy = multiplayer_spawner.spawn({
			"kind": enemy_kind,
			"position": spawn_position,
		})
		if fractured_enemy == null:
			if debug_spawns:
				print("[CAMP SPAWN][FAIL] camp=%s idx=%d kind=%s" % [name, ai, enemy_kind])
			continue
		fractured.append(fractured_enemy)
		fractured_enemy.global_position = spawn_position
		if enemy_kind == "wounded":
			spawned_wounded += 1
		else:
			spawned_fractured += 1
		if debug_spawns:
			print("[CAMP SPAWN][OK] camp=%s idx=%d kind=%s id=%s pos=%s" % [
				name,
				ai,
				enemy_kind,
				fractured_enemy.get_instance_id(),
				spawn_position,
			])
		# set location to somewhere within the player radius
		# future proof, make sure foot is on the ground in hilly areas
		# fractured also cannot spawn inside eachother
		if _has_property(fractured_enemy, "home"):
			fractured_enemy.home = self
	if debug_spawns:
		print("[CAMP SPAWN][DONE] camp=%s fractured=%d wounded=%d total=%d" % [
			name,
			spawned_fractured,
			spawned_wounded,
			spawned_fractured + spawned_wounded,
		])
