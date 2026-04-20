extends Button

@onready var _img: TextureRect = $img
@onready var _name = $name

var _id: String

signal weapon_selected(id: String)

#switch this to also load image
func load_from(id: String, dict: Dictionary):
	if dict.has(id):
		var weapon_def: WeaponDefinition = dict[id]
		_name.text = weapon_def.name
		_id = id
		var gun_type_name = WeaponRegister.GunType.keys()[weapon_def.gun_type] if weapon_def.type == WeaponDefinition.Type.RANGED else "Melee"
		tooltip_text = "%s\nType: %s\nDamage: %s\nMuzzle Velocity: %s" % [weapon_def.name, gun_type_name.capitalize(), weapon_def.base_damage, weapon_def.muzzle_velocity]
		_img.texture = weapon_def.texture
	else:
		_name.text = "unnassigned"
		_id = ""
		_img.texture = ImageTexture.new()

func set_null():
	_name.text = "unassigned"
	_id = ""


func _pressed() -> void:
	emit_signal("weapon_selected", _id)
