extends Resource

class_name  CharactersResource

@export var characters: Dictionary[String, CharacterDef] = {}

func _init():
	pass

func make() -> void:
	var minsung = CharacterDef.new()
	minsung.Name = "Dirk MinSung"
	minsung.Weapon1 = "DefaultShotgun"
	minsung.Weapon2 = "DefaultPistol"
	minsung.Weapon3 = ""
	minsung.Equipment1 = ""
	minsung.Equipment2 = ""
	characters[minsung.Name] = minsung
	
	var brevin = CharacterDef.new()
	brevin.Name = "Brevin Squad"
	brevin.Weapon1 = "DefaultGun"
	brevin.Weapon2 = "DefaultPistol"
	brevin.Weapon3 = ""
	brevin.Equipment1 = ""
	brevin.Equipment2 = ""
	characters[brevin.Name] = brevin
