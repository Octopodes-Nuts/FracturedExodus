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
		player.res.rpc_id(1, 50, player.name)
		_refresh(other)
	Local.HUD.get_child(1).set_time_value((current_res / RES_TIME) * 100)

func _add_interaction(node: Node):
	current_res = 0.0
	Local.HUD.get_child(1).set_time_value((current_res / RES_TIME) * 100)
	Local.HUD.get_child(1).set_visible(true)

func _remove_interaction(other: Node):
	Local.HUD.get_child(1).set_visible(false)
