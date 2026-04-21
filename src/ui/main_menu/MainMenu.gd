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
@onready var matchmaking_api: MatchmakingAPI = $MatchmakingApi
@onready var social_panel = $social_panel
@onready var friend_request_panel = $add_friend_panel
@onready var faction_select = $FactionSelect
@onready var matchmaking_time_display = $matchmaking_time_display
@onready var party_panel = $party_panel

@onready var account_info_update_timer: Timer = Timer.new()
@onready var party_update_timer: Timer = Timer.new()
@onready var character_update_timer: Timer = Timer.new()

var account_info_update_interval: float = 5.0
var party_update_interval: float = 1.0
var character_update_interval: float = 15.0
const CHARACTER_WARMUP_INTERVAL: float = 1.0
const CHARACTER_WARMUP_POLLS: int = 5
const CHARACTER_POLL_IDLE_INTERVAL: float = 10.0
const CHARACTER_POLL_SEARCHING_INTERVAL: float = 25.0

@export var click_sound: AudioStreamPlayer2D

var queued = false
var _character_warmup_polls_left: int = 0

# this server code will likely be moved
var active_register = 1

var matchmaking_time_elapsed: float = 0.0

signal reload_ui

# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		Local.set_state("host", true)
		if not get_tree().change_scene_to_file("res://environment/maps/test_map_2/test_map_2.tscn") == OK:
			print("Error getting to file")
			
	Local.shader_rect.set_downed(false)

	Local.state_changed.connect(_on_local_state_updated)
			
	_connect_buttons_recursive(self)
	social_panel.account_api = account_api
	social_panel.matchmaking_api = matchmaking_api
	party_panel.matchmaking_api = matchmaking_api
	matchmaking_api.in_party_status_changed.connect(_determine_faction_select_state)
	matchmaking_api.in_party_status_changed.connect(_determine_queue_button_state)
	add_child(account_info_update_timer)
	add_child(party_update_timer)
	add_child(character_update_timer)
	account_info_update_timer.wait_time = account_info_update_interval
	account_info_update_timer.timeout.connect(account_api.get_account_info_update)
	account_info_update_timer.start()

	party_update_timer.wait_time = party_update_interval
	party_update_timer.timeout.connect(matchmaking_api.party_status)
	party_update_timer.start()

	character_update_timer.timeout.connect(_on_character_poll_timer_timeout)
	_start_character_polling_warmup()

	character_select.account_api = account_api
	character_select.click_sound = click_sound
	faction_select.select(0)
	_on_option_button_item_selected(0)
	account_api.character_created.connect(character_select._on_character_created)
	account_api.characters_received.connect(_on_characters_refreshed)
	matchmaking_api.match_found.connect(match_found)
	matchmaking_api.matchmaking_status_changed.connect(_on_matchmaking_status_changed)
	account_api.account_info_updated.connect(_on_account_api_account_info_updated)
	account_api.get_account_info_update()
	_schedule_next_character_poll()

	social_panel.add_friend_button_pressed.connect(_on_social_panel_add_friend_button_pressed)
	friend_request_panel.friend_request_ready.connect(_on_friend_request_panel_ready)
	matchmaking_api.party_faction_updated.connect(_set_current_faction)

	character_display.account_api = account_api
 
	for character in Local.get_state("characters").characters.keys():
		print("Character: ", character, " Def: ", Local.get_state("characters").characters[character])


func _process(_delta: float) -> void:
	if queued:
		matchmaking_time_elapsed += _delta
		matchmaking_time_display.text = str(matchmaking_time_elapsed).substr(0, 3)

func _poll_characters_in_lobby() -> void:
	var token := String(Local.get_state("session_token"))
	if token.is_empty():
		return
	account_api.get_characters(token)

func _start_character_polling_warmup() -> void:
	_character_warmup_polls_left = CHARACTER_WARMUP_POLLS
	_schedule_character_poll(CHARACTER_WARMUP_INTERVAL)

func _on_character_poll_timer_timeout() -> void:
	_poll_characters_in_lobby()
	if _character_warmup_polls_left > 0:
		_character_warmup_polls_left -= 1
	_schedule_next_character_poll()

func _schedule_next_character_poll() -> void:
	if _character_warmup_polls_left > 0:
		_schedule_character_poll(CHARACTER_WARMUP_INTERVAL)
		return
	_schedule_character_poll(_get_adaptive_character_poll_interval())

func _schedule_character_poll(interval_seconds: float) -> void:
	character_update_timer.stop()
	character_update_timer.wait_time = interval_seconds
	character_update_timer.start()

func _get_adaptive_character_poll_interval() -> float:
	if queued or String(Local.get_state("matchmaking_status")) == "searching":
		return CHARACTER_POLL_SEARCHING_INTERVAL
	return CHARACTER_POLL_IDLE_INTERVAL

func _on_characters_refreshed() -> void:
	Local.sort_characters()
	_ensure_selected_character_is_valid()
	character_select.render()
	if not character_select.visible and not character_select.new_character_dialogue.visible and not weapon_select.visible:
		reload()

func _ensure_selected_character_is_valid() -> void:
	var selected: CharacterDef = Local.get_state("selected_character_def")
	if selected == null:
		_set_first_character_for_selected_faction()
		return

	var selected_id := String(selected.ID)
	if selected_id == "":
		_set_first_character_for_selected_faction()
		return

	if Local.get_state("characters").characters.has(selected_id):
		var refreshed: CharacterDef = Local.get_state("characters").characters[selected_id]
		if refreshed != selected:
			account_api.set_active_character(refreshed)
		return

	_set_first_character_for_selected_faction()

func _set_first_character_for_selected_faction() -> void:
	var faction := int(Local.get_state("selected_faction"))
	var bucket: CharactersResource = null
	match faction:
		Factions.Enum.ENTENTE:
			bucket = Local.get_state("entente_characters")
		Factions.Enum.EMPIRE:
			bucket = Local.get_state("empire_characters")
		Factions.Enum.FREE_AGENTS:
			bucket = Local.get_state("free_agent_characters")

	if bucket != null and len(bucket.characters) > 0:
		account_api.set_active_character(bucket.characters.values()[0])
	else:
		account_api.set_active_character(null)
	
func _determine_faction_select_state(_input):
	faction_select.disabled = Local.get_state("in_party") and (not Local.get_state("party_leader") and len(Local.get_state("party_members")) > 1) or queued

func _determine_queue_button_state(_input):
	var not_leader: bool = (not Local.get_state("party_leader")) and len(Local.get_state("party_members")) > 1
	var party_not_ready: bool = Local.get_state("in_party") and not Local.get_state("all_party_members_have_character")
	var no_character := Local.get_state("selected_character_def") == null
	queue_button.disabled = not_leader or party_not_ready or no_character or queued

var _faction = Factions.Enum.DEFAULT

func _set_current_faction(faction: int):
	if not Local.get_state("party_leader"):
		if _faction == faction:
			return
		_faction = faction as Factions.Enum
		match faction:
			Factions.Enum.ENTENTE:
				faction_select.select(0)
				_on_option_button_item_selected(0)
			Factions.Enum.EMPIRE:
				faction_select.select(1)
				_on_option_button_item_selected(1)
			Factions.Enum.FREE_AGENTS:
				faction_select.select(2)
				_on_option_button_item_selected(2)

func match_found(port: int, ip: String):
	character_update_timer.stop()
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
	if register < 4:
		weapon_select.render_out(register, WeaponRegister.weapons.Definitions)
	else:
		pass

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
	queued = status == "searching"
	queue_button.disabled = queued
	_schedule_next_character_poll()


func _on_ready_button_pressed() -> void:
	queue_button.disabled = true
	matchmaking_api.queue_for_match()
	queued = true
	_schedule_next_character_poll()


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
			if Local.get_state("selected_faction") != Factions.Enum.ENTENTE:
				Local.set_state("selected_faction", Factions.Enum.ENTENTE)
				if len(Local.get_state("entente_characters").characters) != 0:
					account_api.set_active_character(Local.get_state("entente_characters").characters.values()[0])
				else:
					account_api.set_active_character(null)
		1:
			if Local.get_state("selected_faction") != Factions.Enum.EMPIRE:
				Local.set_state("selected_faction", Factions.Enum.EMPIRE)
				if len(Local.get_state("empire_characters").characters) != 0:
					account_api.set_active_character(Local.get_state("empire_characters").characters.values()[0])
				else:
					account_api.set_active_character(null)
		2:
			if Local.get_state("selected_faction") != Factions.Enum.FREE_AGENTS:
				Local.set_state("selected_faction", Factions.Enum.FREE_AGENTS)
				if len(Local.get_state("free_agent_characters").characters) != 0:
					account_api.set_active_character(Local.get_state("free_agent_characters").characters.values()[0])
				else:
					account_api.set_active_character(null)

	reload()
	character_select.render()

func _on_local_state_updated(state: String, value: Variant):
	if state == "selected_character_def":
		if value != null:
			_determine_queue_button_state(null)
		else:
			queue_button.disabled = true
	elif state == "all_party_members_have_character" or state == "party_leader":
		_determine_queue_button_state(null)

func reload():
	weapon_select.hide()
	emit_signal("reload_ui")

func _connect_buttons_recursive(node: Node) -> void:
	if node is Button and click_sound != null:
		if not node.pressed.is_connected(click_sound.play):
			node.pressed.connect(click_sound.play)
	for child in node.get_children():
		_connect_buttons_recursive(child)
