extends Interactable

var player: Node

@export var RES_TIME = 5.0
var current_res = 0

func _ready():
	display_text = "Revive Teammate"

func set_player(node: Node):
	player = node

func interact(other: Node):
	current_res += other.delta
	if current_res >= RES_TIME:
		if multiplayer.is_server():
			player.res(50.0)
		else:
			player.res.rpc_id(1, 50.0)
		_refresh(other)
	Local.HUD.get_child(1).set_time_value((current_res / RES_TIME) * 100)

func _add_interaction(_node: Node):
	current_res = 0.0
	Local.HUD.get_child(1).set_time_value((current_res / RES_TIME) * 100)
	Local.HUD.get_child(1).set_visible(true)

func _remove_interaction(_other: Node):
	Local.HUD.get_child(1).set_visible(false)
