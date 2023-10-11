extends Node

onready var character_selection = load(
	'res://debug/ui/class_selection/ClassSelector.tscn').instance()

func _on_class_selection_pressed():
	add_child(character_selection)
