###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

# ToDo: Add more functionality to the main menu

extends Control

@onready var static_paper_doll = $static_paper_doll
@onready var paper_doll = $paper_doll
@onready var character_display = $character_display
@onready var character_select = $character_select
@onready var weapon_select = $weapon_select

# this server code will likely be moved
var active_register = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		pass
	if ResourceLoader.exists("res://load/Characters.res"):
		Local.characters = ResourceLoader.load("res://load/Characters.res")
		print("Loaded")
		if len(Local.characters.characters) > 0:
			Local.char_id = Local.characters.characters.keys()[0]
			Local.selected_character_def = Local.characters.characters[Local.char_id]
	else:
		var characters: CharactersResource = CharactersResource.new()
		characters.make()
		if ResourceSaver.save(characters, "res://load/Characters.res") == OK:
			Local.char_id = characters.characters.keys()[0]
			Local.selected_character_def = characters.characters[Local.char_id]


func _on_test_scene_btn_pressed():
	if not get_tree().change_scene_to_file("res://environment/maps/test_map/TestMap.tscn") == OK:
		print("Error getting to file")


func _on_test_scene_btn_2_pressed() -> void:
	if not get_tree().change_scene_to_file("res://environment/maps/test_map_2/test_map_2.tscn") == OK:
		print("Error getting to file")
		


func _on_quit_pressed() -> void:
	get_tree().quit()
		

func _on_character_display_character_select() -> void:
	character_select.visible = true


func _on_character_select_new_char_selected() -> void:
	character_select.visible = false
	character_display.reload(Local.selected_character_def)


func _on_paper_doll_weapon_change(register: int) -> void:
	active_register = register
	weapon_select.visible = true
	if register == 1:
		weapon_select.render_out(WeaponRegister.display_gun_register)
	if register == 2:
		weapon_select.render_out(WeaponRegister.display_gun_register)
		


func _on_weapon_select_weapon_selected(id: String) -> void:
	weapon_select.visible = false
	if active_register == 1:
		Local.selected_character_def.Weapon1 = id
	if active_register == 2:
		Local.selected_character_def.Weapon2 = id
	
	if ResourceSaver.save(Local.characters, "res://load/Characters.res", ResourceSaver.FLAG_NONE) == OK:
		character_display.reload(Local.selected_character_def)


func _on_character_select_new_char_created() -> void:
	if ResourceSaver.save(Local.characters, "res://load/Characters.res", ResourceSaver.FLAG_NONE) == OK:
		character_display.reload(Local.selected_character_def)
