extends Panel

@export var new_character_dialogue: NewCharacterDialogue

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
	new_character_dialogue.opened.connect(hide)
	new_character_dialogue.closed.connect(show)
	Local.state_changed.connect(_on_local_state_updated)
	Local.character_updated.connect(func(): reload(Local.get_state("selected_character_def")))

var rendered = false
func _process(_delta: float) -> void:
	pass

func _on_local_state_updated(state: String, value: Variant):
	if state != "selected_character_def":
		return
	reload(value)
	

func reload(def: CharacterDef):
	if def == null:
		primary_weapon.set_null()
		secondary_weapon.set_null()
		melee_weapon.set_null()
		eq_1.set_null()
		eq_2.set_null()
		return

	primary_weapon.load_from(def.Weapon1, WeaponRegister.weapons.Definitions)
	secondary_weapon.load_from(def.Weapon2, WeaponRegister.weapons.Definitions)
	melee_weapon.load_from(def.Weapon3, WeaponRegister.weapons.Definitions)
	eq_1.load_from(def.Equipment1, EquipmentRegister.display_equipment_register)
	eq_2.load_from(def.Equipment2, EquipmentRegister.display_equipment_register)
	
