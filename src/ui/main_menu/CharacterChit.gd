extends Button
class_name CharacterChit


@onready var _name = $name
@onready var _class = $class
@onready var _img = $img

var _def: CharacterDef
var pos: int

func _init(def: CharacterDef = null):
	_def = def
	
func render():
	_name.text = _def.Name
	var map: Dictionary = {}
	match _def.Faction:
		Factions.Enum.EMPIRE:
			map = ClassRegister.empire_class_name_map
		Factions.Enum.ENTENTE:
			map = ClassRegister.entente_class_name_map
		Factions.Enum.FREE_AGENTS:
			map = ClassRegister.free_agent_class_name_map
	_class.text = map[_def.ClassType]

func _pressed() -> void:
	if _def != null:
		Local.set_state("selected_character_def", _def)
		Local.emit_character_updated()
