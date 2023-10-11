# variables local to player, this information is not
# relevent to the server
extends Node

# player ID, obtained from server
var player_id: int
var player: KinematicBody
var HUD: Control
var input_active = true

func _ready():
	_get_player_attributes()


func _get_player_attributes():
	# grab player ID from server
	# along with whatever else becomes clear later
	# this should happen once accepted into a match
	pass

