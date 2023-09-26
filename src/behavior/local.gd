# variables local to player, this information is not
# relevent to the server
extends Node

# player ID, obtained from server
var player_id: int


func _ready():
	_get_player_attributes()


func _get_player_attributes():
	# grab player ID from server
	# along with whatever else becomes clear later
	# this should happen once accepted into a match
	pass


# for purpose of display and purchase, gun types should all be manually
# registered here

const GUN_REGISTER_PATH = 'res://behavior/player/weapons/guns/'

var gun_paths = [
	'default_gun/DefaultGun.tscn',
	'default_pistol/DefualtPistol.tscn'
]

func _register_all_gun_types():
	pass
