extends Resource

class_name CharacterDef

func _init(first: String = "", last: String = ""):
	Name = first + " " + last
	
@export var ID: String = ""

@export var Name: String = ""

@export var Date: String = ""

@export var Weapon1: String = ""

@export var Weapon2: String = ""

@export var Weapon3: String = ""

@export var Equipment1: String = ""

@export var Equipment2: String = ""

@export var ClassType: ClassRegister.Classes = ClassRegister.Classes.DEFAULT

@export var Faction: int = 0
