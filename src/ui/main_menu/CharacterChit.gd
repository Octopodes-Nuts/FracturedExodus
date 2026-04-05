extends Button
class_name CharacterChit


@onready var _name = $name
@onready var _class = $class
@onready var _img = $img

var _def: CharacterDef
var pos: int
var account_api: AccountAPI

signal character_selected

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
		account_api.set_active_character(_def)
		emit_signal("character_selected")
