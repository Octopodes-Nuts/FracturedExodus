extends Node

# Class used as general interface

class_name Weapon

enum WeaponType {
	GUN,
	MELEE
}

var type: int = 0
var faction: int = 0
var active: bool = false

# perform action specified by weapon
func _use():
	pass
