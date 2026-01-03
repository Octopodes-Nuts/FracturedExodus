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

enum WeaponType {
	NONE,
	GUN,
	MELEE
}

var type: int = WeaponType.NONE
var faction: int = Types.Factions.FACTION_DEFAULT
var classes: Array[Types.Classes] = [Types.Classes.CLASS_DEFAULT]

var slots: Dictionary = {
	Types.Classes.CLASS_DEFAULT: [1, 2]
}

# perform action specified by weapon
func use(parent: DefaultController):
	muzzle_end = parent.gun_location
	if active:
		_use()

func _use():
	pass
