extends Interactable

@onready var collision := $collision
@onready var scanner_model := $scanner_model

func _ready() -> void:
	display_text = "Pick up scanner"

func _remove_interaction(_node: Node):
	pass

func _add_interaction(_node: Node):
	pass

func interact(_other: Node):
	if _other.has_method("get_scanner"):
		if not _other.character.has_scanner:
			_other.get_scanner()
			_disable_scanner_site.rpc()
		else:
			display_text = "You already have a scanner"
	_refresh(_other)

@rpc("call_local", "any_peer")
func _disable_scanner_site():
	monitoring = false
	monitorable = false
	scanner_model.visible = false
