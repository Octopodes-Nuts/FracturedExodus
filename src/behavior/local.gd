###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

# variables local to player, this information is not
# relevent to the server
extends Node

signal character_updated
signal hud_changed(hud: Control)
signal state_changed(key: StringName, value: Variant)

# player ID, obtained from server
# var server_ip: String = "192.168.1.238"
# var server_ip: String = "127.0.0.1"
var server_ip: String = "172.20.10.4"
var server_port: String = "8000"
var player_id: String
var session_token: String
var friends: Array
var friend_requests: Array
var pending_friend_requests: Array
var player_level: int
var player_xp: int
var pending_xp: int = 0
var matchmaking_ticket: String = ""
var matchmaking_status: String = ""
var port: int
var ip: String
var party_invites: Array = []
var party_members: Array = []
var party_status: String = ""
var party_leader_id: String = ""
var party_leader: bool = false
var in_party: bool = false
var all_party_members_have_character: bool = false
var friend_code: String = ""

var registration_token: String = ""
var server_name: String = ""
var server_token: String = ""
var server_token_id: String = ""

var player: CharacterBody3D
var HUD: Control
var input_active = true
var terrain: Terrain3D = null
var characters: CharactersResource = CharactersResource.new()
var entente_characters: CharactersResource = CharactersResource.new()
var empire_characters: CharactersResource = CharactersResource.new()
var free_agent_characters: CharactersResource = CharactersResource.new()
var selected_character_def: CharacterDef
var selected_faction: int = Factions.Enum.DEFAULT
var char_id: String
var host: bool = false
var has_objective = false

func _ready():
	pass

func get_state(key: StringName) -> Variant:
	return get(String(key))

func set_state(key: StringName, value: Variant) -> void:
	set(String(key), value)
	emit_signal("state_changed", key, value)

func set_hud(hud: Control) -> void:
	if HUD == hud:
		return
	HUD = hud
	emit_signal("state_changed", &"HUD", HUD)
	emit_signal("hud_changed", HUD)

func clear_hud() -> void:
	set_hud(null)

func get_hud() -> Control:
	return HUD

func has_hud() -> bool:
	return HUD != null


func sort_characters():
	entente_characters.characters.clear()
	empire_characters.characters.clear()
	free_agent_characters.characters.clear()
	for agent_name in characters.characters.keys():
		var agent = characters.characters[agent_name]

		match agent.Faction:
			Factions.Enum.EMPIRE:
				empire_characters.characters[agent_name] = agent
			Factions.Enum.ENTENTE:
				entente_characters.characters[agent_name] = agent
			Factions.Enum.FREE_AGENTS:
				free_agent_characters.characters[agent_name] = agent

func emit_character_updated():
	emit_signal("character_updated")
