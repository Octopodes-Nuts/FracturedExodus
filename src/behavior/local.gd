# variables local to player in a match
extends Node

class_name Local

# player ID, obtained from server
var player_id: int


func _ready():
    _get_player_attributes()


func _get_player_attributes():
    # grab player ID from server
    # along with whatever else becomes clear later
    # this should happen once accepted into a match
    pass

