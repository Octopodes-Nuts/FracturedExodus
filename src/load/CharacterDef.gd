extends Resource

class_name CharacterDef

func _init(first: String = "", last: String = ""):
	Name = first + " " + last

@export var Name: String = ""

@export var Date: String = ""

@export var Weapon1: String = ""

@export var Weapon2: String = ""

@export var Weapon3: String = ""

@export var Equipment1: String = ""

@export var Equipment2: String = ""

@export var Class: Types.Classes = Types.Classes.CLASS_DEFAULT

@export var Faction: int = 0
