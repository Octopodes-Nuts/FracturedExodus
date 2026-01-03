###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Weapon

class_name Melee

@export var swing_animation: String
@export var stab_animation: String
@export var damage: float = 105

func _init():
	type = WeaponType.MELEE

var _stab := false

func _ready():
	pass # Replace with function body.

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_released("ads") and active:
		_stab = true
		_use()

func _use():
	if _stab:
		pass
		_stab = false
	else:
		#swing
		pass
