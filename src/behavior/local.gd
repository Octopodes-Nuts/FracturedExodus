###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

# variables local to player, this information is not
# relevent to the server
extends Node

# player ID, obtained from server
var player_id: int
var player: CharacterBody3D
var HUD: Control
var input_active = true
var terrain: Terrain3D = null
var characters: CharactersResource
var selected_character_def: CharacterDef
var char_id: String

func _ready():
	_get_player_attributes()


func _get_player_attributes():
	# grab player ID from server
	# along with whatever else becomes clear later
	# this should happen once accepted into a match
	pass
