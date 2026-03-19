extends Node3D

class_name ChipsiteSpawn

func _ready() -> void:
	Global.chipsite_spawns.append(self)

func _exit_tree() -> void:
	if Global != null:
		Global.chipsite_spawns.erase(self)
