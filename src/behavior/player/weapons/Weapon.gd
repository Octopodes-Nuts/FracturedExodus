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
var ads: bool = false

enum WeaponType {
	GUN,
	MELEE
}

var type: int = 0
var faction: int = 0

# perform action specified by weapon
func _use():
	pass
