###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

# ToDo: Add more functionality to the main menu

extends Control

@onready var paper_doll = $paper_doll
@onready var character_display = $character_display
@onready var character_select = $character_select
@onready var weapon_select = $weapon_select
@onready var account_api = $AccountApi
@onready var queue_button = $ready_button
@onready var matchmaking_api = $MatchmakingApi
@onready var social_panel = $social_panel
@onready var friend_request_panel = $add_friend_panel
@onready var faction_select = $FactionSelect

@onready var account_info_update_timer: Timer = Timer.new()
@onready var party_update_timer: Timer = Timer.new()
var account_info_update_interval: float = 5.0
var party_update_interval: float = 5.0

# this server code will likely be moved
var active_register = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		Local.host = true
		if not get_tree().change_scene_to_file("res://environment/maps/test_map_2/test_map_2.tscn") == OK:
			print("Error getting to file")
			
	faction_select.select(0)
	social_panel.account_api = account_api
	social_panel.matchmaking_api = matchmaking_api
	add_child(account_info_update_timer)
	add_child(party_update_timer)
	account_info_update_timer.wait_time = account_info_update_interval
	account_info_update_timer.timeout.connect(account_api.get_account_info_update)
	account_info_update_timer.start()

	party_update_timer.wait_time = party_update_interval
	party_update_timer.timeout.connect(matchmaking_api.party_status)
	party_update_timer.start()

	character_select.account_api = account_api
	account_api.character_created.connect(character_select._on_character_created)
	matchmaking_api.match_found.connect(match_found)
	matchmaking_api.matchmaking_status_changed.connect(_on_matchmaking_status_changed)
	account_api.account_info_updated.connect(_on_account_api_account_info_updated)
	account_api.get_account_info_update()

	social_panel.add_friend_button_pressed.connect(_on_social_panel_add_friend_button_pressed)
	friend_request_panel.friend_request_ready.connect(_on_friend_request_panel_ready)
	account_api.get_account_info_update()
 
	for character in Local.characters.characters.keys():
		print("Character: ", character, " Def: ", Local.characters.characters[character])


func match_found(port: int, ip: String):
	Local.port = port
	Local.ip = ip
	get_tree().change_scene_to_file("res://environment/maps/test_map_2/test_map_2.tscn")


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
	weapon_select.render_out(register, WeaponRegister.display_gun_register, WeaponRegister.gun_register)

func _on_weapon_select_weapon_selected(id: String) -> void:
	weapon_select.visible = false
	if active_register == 1:
		Local.selected_character_def.Weapon1 = id
	if active_register == 2:
		Local.selected_character_def.Weapon2 = id
	
	account_api.update_character(Local.session_token, Local.selected_character_def)
	
	if ResourceSaver.save(Local.characters, "res://load/Characters.res", ResourceSaver.FLAG_NONE) == OK:
		character_display.reload(Local.selected_character_def)


func _on_character_select_new_char_created() -> void:
	# if ResourceSaver.save(Local.characters, "res://load/Characters.res", ResourceSaver.FLAG_NONE) == OK:
	#	character_display.reload(Local.selected_character_def)
	pass


func _on_matchmaking_status_changed(status: String) -> void:
	queue_button.disabled = status == "searching"


func _on_ready_button_pressed() -> void:
	queue_button.disabled = true
	matchmaking_api.queue_for_match()


func _on_account_api_account_info_updated() -> void:
	print("Account info updated, refreshing social panel")
	social_panel.set_friend_chits()
	social_panel.set_request_chits()
	social_panel.set_invite_chits()


func _on_social_panel_add_friend_button_pressed() -> void:
	friend_request_panel.show()


func _on_friend_request_panel_ready(friend_id: String):
	account_api.send_friend_request(friend_id)


func _on_leave_party_btn_pressed() -> void:
	matchmaking_api.party_leave()


func _on_option_button_item_selected(index: int) -> void:
	match index:
		0:
			Local.selected_faction = Factions.ENTENTE
		1:
			Local.selected_faction = Factions.EMPIRE
		2:
			Local.selected_faction = Factions.FREE_AGENTS
	character_select.render()
