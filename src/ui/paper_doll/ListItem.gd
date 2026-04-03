extends Button

@onready var _img = $img
@onready var _name = $name

var _id: String

signal weapon_selected(id: String)

#switch this to also load image
func load_from(id: String, dict: Dictionary):
	if dict.has(id):
		_name.text = dict[id].name
		_id = id
	else:
		_name.text = "unnassigned"
		_id = ""

func set_null():
	_name.text = "unassigned"
	_id = ""


func _pressed() -> void:
	emit_signal("weapon_selected", _id)
