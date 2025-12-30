extends Node

var PlayerIDs: Dictionary[String, bool]

@onready var map = $".."

signal start

func _on_player_join(id: String):
	
	# add player to list
	# check player ID off list
	
	if id in PlayerIDs.keys():
		PlayerIDs[id] = true
	else:
		# panic! this player should not have joined
		pass

	if false not in PlayerIDs.values():
		emit_signal("start")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	map.player_added.connect(_on_player_join)
