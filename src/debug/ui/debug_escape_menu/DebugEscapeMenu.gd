###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Node

@onready var character_selection = load(
	'res://debug/ui/class_selection/ClassSelector.tscn').instantiate()

func _on_class_selection_pressed():
	add_child(character_selection)
