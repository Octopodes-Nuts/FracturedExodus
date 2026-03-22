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

@export var min_radius: float
@export var max_radius: float

# Note: do not scale this node ever, it must always be set to (1,1,1)

func _get_spawn_position(index: int) -> Vector3:
	return Vector3(index + 4, 20.0, index + 4)


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
	var spawn_position: Vector3 = data.get("position", global_position)
	fractured_enemy.set_deferred("global_position", spawn_position)
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

	randomize()
	number_fractured = int(randf_range(1, max_fractured + 1))
	var wounded_count := clampi(randi_range(min_wounded, max_wounded), 0, number_fractured)
	# mint random number of fractured
	for ai in range(number_fractured):
		var spawn_position := to_global(_get_spawn_position(ai))
		var enemy_kind := "fractured"
		if ai < wounded_count:
			enemy_kind = "wounded"
		var fractured_enemy = multiplayer_spawner.spawn({
			"kind": enemy_kind,
			"position": spawn_position,
		})
		if fractured_enemy == null:
			continue
		fractured.append(fractured_enemy)
		fractured_enemy.global_position = spawn_position
		# set location to somewhere within the player radius
		# future proof, make sure foot is on the ground in hilly areas
		# fractured also cannot spawn inside eachother
		if _has_property(fractured_enemy, "home"):
			fractured_enemy.home = self
