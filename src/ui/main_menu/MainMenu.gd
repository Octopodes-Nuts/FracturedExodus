###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

# ToDo: Add more functionality to the main menu

extends Control

# this server code will likely be moved

# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		pass

	pass # Replace with function body.


func _on_test_scene_btn_pressed():
	if not get_tree().change_scene_to_file("res://environment/maps/test_map/TestMap.tscn") == OK:
		print("Error getting to file")
