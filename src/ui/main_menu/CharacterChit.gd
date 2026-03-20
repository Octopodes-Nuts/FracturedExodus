extends Button
class_name CharacterChit


@onready var _name = $name
@onready var _img = $img

var _def: CharacterDef
var pos: int

func _init(def: CharacterDef = null):
	_def = def
	
func render():
	_name.text = _def.Name

func _pressed() -> void:
	if _def != null:
		Local.selected_character_def = _def
		Local.emit_character_updated()
