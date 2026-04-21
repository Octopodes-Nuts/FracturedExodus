###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Node3D

class_name Equipable

var active: bool = false
var ads: bool = false
var key: String = ""
var continuous_usage: bool = false
var cool_down: bool = false

@export var default_position: Vector3 = Vector3.ZERO
@export var use_speed: float = 3.0


# this is for a good reason anthony. This active setting needs
# to be an event
func _set_active():
	active = true

func _set_inactive():
	active = false

func get_ammo():
	return [0, 0]
