extends Interactable

var player: Node

@export var RES_TIME = 5.0
var current_res = 0

func _ready():
	display_text = "Revive Teammate"

func can_interact(body: Node) -> bool:
	if not player or not player.has_method("_get_faction"):
		return false
	if not body.has_method("_get_faction"):
		return false
	return body._get_faction() == player._get_faction()

func set_player(node: Node):
	player = node

func interact(other: Node):
	current_res += other.delta
	if current_res >= RES_TIME:
		var is_medic: bool = other.medic_res if "medic_res" in other else false
		if multiplayer.is_server():
			player.res(50.0, is_medic)
		else:
			player.res.rpc_id(1, 50.0, is_medic)
		_refresh(other)
	var hud := Local.get_hud()
	if hud != null:
		hud.set_progress_percent((current_res / RES_TIME) * 100)

func _add_interaction(_node: Node):
	current_res = 0.0
	var hud := Local.get_hud()
	if hud != null:
		hud.set_progress_percent((current_res / RES_TIME) * 100)
		hud.set_progress_visible(true)

func _remove_interaction(_other: Node):
	var hud := Local.get_hud()
	if hud != null:
		hud.set_progress_visible(false)
