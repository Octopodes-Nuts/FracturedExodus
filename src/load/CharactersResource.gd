extends Resource

class_name  CharactersResource

var characters: Dictionary = {}

func _init() -> void:
	var minsung = CharacterDef.new()
	minsung.Name = "Dirk MinSung"
	minsung.Weapon1 = "DefaultShotgun"
	minsung.Weapon2 = "DefaultPistol"
	minsung.Weapon3 = ""
	minsung.Equipment1 = ""
	minsung.Equipment2 = ""
	characters["MinSung"] = minsung
