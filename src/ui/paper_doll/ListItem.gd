extends Button

@onready var _img: TextureRect = $img
@onready var _name = $name

var _id: String

signal weapon_selected(id: String)

#switch this to also load image
func load_from(id: String, dict: Dictionary, affordable: bool = true):
	if dict.has(id):
		var weapon_def: WeaponDefinition = dict[id]
		_name.text = weapon_def.name
		_id = id
		var gun_type_name = WeaponRegister.GunType.keys()[weapon_def.gun_type] if weapon_def.type == WeaponDefinition.Type.RANGED else "Melee"
		tooltip_text = "%s\nType: %s\nDamage: %s\nMuzzle Velocity: %s\nDevotion Cost: %d" % [weapon_def.name, gun_type_name.capitalize(), weapon_def.base_damage, weapon_def.muzzle_velocity, weapon_def.devotion_cost]
		_img.texture = weapon_def.texture
		disabled = not affordable
	else:
		_name.text = "unnassigned"
		_id = ""
		_img.texture = ImageTexture.new()
		disabled = false

func set_null():
	_name.text = "unassigned"
	_id = ""
	_img.texture = ImageTexture.new()
	disabled = false


func _pressed() -> void:
	emit_signal("weapon_selected", _id)
