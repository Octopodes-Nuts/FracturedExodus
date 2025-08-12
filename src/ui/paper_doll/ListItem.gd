extends Button

@onready var _img = $img
@onready var _name = $name

var _id: String

signal weapon_selected(id: String)

#switch this to also load image
func load_from(id, dict):
	if id in dict:
		_name.text = dict[id]["name"]
		_id = id
	else:
		_name.text = "unnassigned"
		_id = ""

func _pressed() -> void:
	emit_signal("weapon_selected", _id)
