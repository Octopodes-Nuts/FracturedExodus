extends Node

@onready var primary_weapon = $primary_weapon
@onready var secondary_weapon = $secondary_weapon
@onready  var melee_weapon = $melee_weapon
@onready var eq_1 = $eq_1
@onready var eq_2 = $eq_2

signal swap_paper_doll
signal weapon_change(register: int)

@onready var WeaponRegister = get_node('/root/WeaponRegister')

func _weapon_change_factory(which: int):
	return func(): emit_signal("weapon_change", which)
	
func _ready() -> void:
	primary_weapon.connect("pressed", _weapon_change_factory(1))
	secondary_weapon.connect("pressed", _weapon_change_factory(2))
	melee_weapon.connect("pressed", _weapon_change_factory(3))
	eq_1.connect("pressed", _weapon_change_factory(4))
	eq_2.connect("pressed", _weapon_change_factory(5))

var rendered = false
func _process(_delta: float) -> void:
	
	if not rendered:
		if Local.selected_character_def != null:
			reload(Local.selected_character_def)

func reload(def: CharacterDef):
	primary_weapon.load_from(def.Weapon1, WeaponRegister.display_gun_register)
	secondary_weapon.load_from(def.Weapon2, WeaponRegister.display_gun_register)
	# melee_weapon.load_from(WeaponRegister.display_gun_register[def.Weapon3]["name"])
	# eq_1.load_from(WeaponRegister.display_gun_register[def.Equipment1]["name"])
	# eq_2.load_from(WeaponRegister.display_gun_register[def.Equipment2]["name"])
	
