###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Node

class_name Character

var class_type: int # ClassType
var experience: int
var primary_weapon: Weapon = Weapon.new()
var secondary_weapon: Weapon = Weapon.new()
# tertiary is utility melee
var tertiary_weapon: Weapon = Weapon.new()

var equipment_1: EquipmentSlot = EquipmentSlot.new()
var equipment_2: EquipmentSlot = EquipmentSlot.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# set all weapons inactive
func set_weapons_inactive():
	primary_weapon.active = false
	secondary_weapon.active = false
	tertiary_weapon.active = false

func set_bullet_origin(spatial: Node3D):
	primary_weapon.muzzle_end = spatial
	secondary_weapon.muzzle_end = spatial
	tertiary_weapon.muzzle_end = spatial


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
