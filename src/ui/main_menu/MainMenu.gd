###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

# ToDo: Add more functionality to the main menu

extends Control

@onready var static_paper_doll = $static_paper_doll
@onready var paper_doll = $paper_doll

# this server code will likely be moved

# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		pass
	if ResourceLoader.exists("res://load/Characters.res"):
		Local.characters = ResourceLoader.load("res://load/Characters.res")
		if len(Local.characters.characters) > 0:
			Local.selected_character_def = Local.characters.characters.values()[0]
	else:
		var characters = CharactersResource.new()
		if ResourceSaver.save(characters, "res://load/Characters.res") == OK:
			Local.selected_character_def = characters.characters.values()[0]


func _on_test_scene_btn_pressed():
	if not get_tree().change_scene_to_file("res://environment/maps/test_map/TestMap.tscn") == OK:
		print("Error getting to file")


func _on_test_scene_btn_2_pressed() -> void:
	if not get_tree().change_scene_to_file("res://environment/maps/test_map_2/test_map_2.tscn") == OK:
		print("Error getting to file")
		


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_static_paper_doll_swap_paper_doll() -> void:
	
	
	if static_paper_doll.visible:
		static_paper_doll.visible = false
		paper_doll.visible = true
		paper_doll.reload(Local.selected_character_def)
	else:
		static_paper_doll.visible = true
		paper_doll.visible = false
		static_paper_doll.reload(Local.selected_character_def)
		
