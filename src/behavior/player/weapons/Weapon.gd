###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Equipable

# Class used as general interface

class_name Weapon

@export var ADS_LERP: float = 20.0 # rate at which ADS occurs
@export var ads_position : Vector3 = Vector3.ZERO
@export var ads_fov: float = 50.0

var muzzle_end: Node3D
var _use_parent: DefaultController

enum WeaponType {
	NONE,
	GUN,
	MELEE
}

@export var definition: WeaponDefinition

@export var type: WeaponRegister.GunType = WeaponRegister.GunType.RIFLE
@export var faction: Factions.Enum = Factions.Enum.DEFAULT
@export var classes: Array[ClassRegister.Classes] = [ClassRegister.Classes.DEFAULT]

@export var slots: Dictionary[ClassRegister.Classes, Array] = {
	ClassRegister.Classes.DEFAULT: [],
	ClassRegister.Classes.INFANTRY: [],
	ClassRegister.Classes.MEDIC: [],
	ClassRegister.Classes.SPECIAL: [],
	ClassRegister.Classes.OFFICER: [],
}

# perform action specified by weapon
func use(parent: DefaultController):
	muzzle_end = parent.gun_location
	_use_parent = parent
	if active:
		_use()

func _use():
	pass
