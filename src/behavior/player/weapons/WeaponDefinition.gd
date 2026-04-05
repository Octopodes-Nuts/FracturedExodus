extends Resource

class_name WeaponDefinition

enum Type {
	MELEE,
	RANGED
}

@export var name: String
@export var key: String
@export var scene: PackedScene
@export var texture: Texture2D

@export var type: Type
@export var gun_type: WeaponRegister.GunType
@export var base_damage: float
@export var faction: Array[Factions.Enum]

@export var slots: Dictionary[ClassRegister.Classes, Array] = {
	ClassRegister.Classes.DEFAULT: [],
	ClassRegister.Classes.INFANTRY: [],
	ClassRegister.Classes.MEDIC: [],
	ClassRegister.Classes.SPECIAL: [],
	ClassRegister.Classes.OFFICER: []
}
