extends Node

class_name Character

enum ClassType {
	DEFAULT,
	RIFLEMAN,
	MEDIC,
	CHASSEUR,
	LIEUTENANT,
	FUSILER,
	MEDZIN,
	LEUTNANT,
	JAEGER,
	RECRUIT,
	CAPTAIN,
	SHARPSHOOTER,
	JUGGERNAUT
}

var class_type: int # ClassType
var experience: int
var primary_weapon: Weapon = Weapon.new()
var secondary_weapon: Weapon = Weapon.new()
var tertiary_weapon: Weapon = Weapon.new()
var equipment: Array # Array of Equipment

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# set all weapons inactive
func set_weapons_inactive():
	primary_weapon.active = false
	secondary_weapon.active = false
	tertiary_weapon.active = false

func set_bullet_origin(spatial: Spatial):
	if primary_weapon.is_class("Gun"):
		primary_weapon.muzzle_end = spatial
	if secondary_weapon.is_class("Gun"):
		secondary_weapon.muzzle_end = spatial
	if tertiary_weapon.is_class("Gun"):
		tertiary_weapon.muzzle_end = spatial


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
