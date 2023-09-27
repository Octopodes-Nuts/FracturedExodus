extends Node

# Class used as general interface

class_name Weapon

enum WeaponType {
	GUN,
	MELEE
}

var type: int = 0
var faction: int = 0

# perform action specified by weapon
func _use():
	pass
