extends Node

@onready var primary_weapon = $primary_weapon
@onready var secondary_weapon = $secondary_weapon
@onready  var melee_weapon = $melee_weapon
@onready var eq_1 = $eq_1
@onready var eq_2 = $eq_2

var rendered = false
func _process(_delta: float) -> void:
	
	if not rendered:
		if Local.get_state("selected_character_def") != null:
			reload(Local.get_state("selected_character_def"))

func reload(def: CharacterDef):
	primary_weapon.load_from(WeaponRegister.display_gun_register[def.Weapon1]["name"])
	secondary_weapon.load_from(WeaponRegister.display_gun_register[def.Weapon2]["name"])
	# melee_weapon.load_from(WeaponRegister.display_gun_register[def.Weapon3]["name"])
	# eq_1.load_from(WeaponRegister.display_gun_register[def.Equipment1]["name"])
	# eq_2.load_from(WeaponRegister.display_gun_register[def.Equipment2]["name"])
