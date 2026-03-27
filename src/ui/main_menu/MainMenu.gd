###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

# ToDo: Add more functionality to the main menu

extends Control

class_name MainMenu

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
var party_update_interval: float = 1.0

var queued = false

# this server code will likely be moved
var active_register = 1

signal reload_ui

# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		Local.set_state("host", true)
		if not get_tree().change_scene_to_file("res://environment/maps/test_map_2/test_map_2.tscn") == OK:
			print("Error getting to file")
			
	faction_select.select(0)
	_on_option_button_item_selected(0)
	load_first_character()
	account_api.set_active_character()
	Local.connect("character_updated", account_api.set_active_character)
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
	matchmaking_api.party_faction_updated.connect(_set_current_faction)
 
	for character in Local.get_state("characters").characters.keys():
		print("Character: ", character, " Def: ", Local.get_state("characters").characters[character])


func _process(_delta: float) -> void:
	faction_select.disabled = (not Local.get_state("party_leader") and len(Local.get_state("party_members")) > 1) or queued
	queue_button.disabled = (not Local.get_state("party_leader") and len(Local.get_state("party_members")) > 1) or queued

func _set_current_faction(faction: int):
	if not Local.get_state("party_leader"):
		match faction:
			Factions.ENTENTE:
				faction_select.select(0)
				_on_option_button_item_selected(0)
			Factions.EMPIRE:
				faction_select.select(1)
				_on_option_button_item_selected(1)
			Factions.FREE_AGENTS:
				faction_select.select(2)
				_on_option_button_item_selected(2)

func load_first_character():
	if len(Local.entente_characters.characters) > 0:
		Local.set_state("selected_character_def", Local.get_state("entente_characters").characters.values()[0])

func match_found(port: int, ip: String):
	Local.set_state("port", port)
	Local.set_state("ip", ip)
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

func _on_paper_doll_weapon_change(register: int) -> void:
	active_register = register
	weapon_select.visible = true
	weapon_select.render_out(register, WeaponRegister.display_gun_register, WeaponRegister.gun_register)

func _on_weapon_select_weapon_selected(id: String) -> void:
	weapon_select.visible = false
	print("[MainMenu] weapon selected id=%s register=%d" % [id, active_register])
	if active_register == 1:
		Local.get_state("selected_character_def").Weapon1 = id
	if active_register == 2:
		Local.get_state("selected_character_def").Weapon2 = id
	if active_register == 3:
		Local.get_state("selected_character_def").Weapon3 = id
	print("[MainMenu] character def after update: W1=%s W2=%s W3=%s" % [
		Local.get_state("selected_character_def").Weapon1,
		Local.get_state("selected_character_def").Weapon2,
		Local.get_state("selected_character_def").Weapon3
	])
	Local.emit_character_updated()
	account_api.update_character(Local.get_state("session_token"), Local.get_state("selected_character_def"))


func _on_character_select_new_char_created() -> void:
	# if ResourceSaver.save(Local.get_state("characters"), "res://load/Characters.res", ResourceSaver.FLAG_NONE) == OK:
	#	character_display.reload(Local.get_state("selected_character_def"))
	pass


func _on_matchmaking_status_changed(status: String) -> void:
	queue_button.disabled = status == "searching"


func _on_ready_button_pressed() -> void:
	queue_button.disabled = true
	matchmaking_api.queue_for_match()
	queued = true


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
			if Local.get_state("selected_faction") != Factions.ENTENTE:
				Local.set_state("selected_faction", Factions.ENTENTE)
				if len(Local.get_state("entente_characters").characters) != 0:
					Local.set_state("selected_character_def", Local.get_state("entente_characters").characters.values()[0])
				else:
					Local.set_state("selected_character_def", null)
		1:
			if Local.get_state("selected_faction") != Factions.EMPIRE:
				Local.set_state("selected_faction", Factions.EMPIRE)
				if len(Local.get_state("empire_characters").characters) != 0:
					Local.set_state("selected_character_def", Local.get_state("empire_characters").characters.values()[0])
				else:
					Local.set_state("selected_character_def", null)
		2:
			if Local.get_state("selected_faction") != Factions.FREE_AGENTS:
				Local.set_state("selected_faction", Factions.FREE_AGENTS)
				if len(Local.get_state("free_agent_characters").characters) != 0:
					Local.set_state("selected_character_def", Local.get_state("free_agent_characters").characters.values()[0])
				else:
					Local.set_state("selected_character_def", null)

	reload()
	character_select.render()

func reload():
	weapon_select.hide()
	emit_signal("reload_ui")
