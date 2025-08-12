###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Node

class_name Character

var ScannerInstance = preload("res://behavior/player/scanner/Scanner.tscn")

var class_type: int # ClassType
var experience: int
var primary_weapon: Weapon = Weapon.new()
var secondary_weapon: Weapon = Weapon.new()
# tertiary is utility melee
var tertiary_weapon: Weapon = Weapon.new()
# quaternary is medkit
var medkit: MedPack = MedPack.new()
var scanner: Scanner


var equipment_1: EquipmentSlot = EquipmentSlot.new()
var equipment_2: EquipmentSlot = EquipmentSlot.new()

# Called when the node enters the scene tree for the first time.
func _init():
	scanner = ScannerInstance.instantiate()

# set all weapons inactive
func set_weapons_inactive():
	primary_weapon.active = false
	secondary_weapon.active = false
	tertiary_weapon.active = false

func set_bullet_origin(spatial: Node3D):
	primary_weapon.muzzle_end = spatial
	secondary_weapon.muzzle_end = spatial
	tertiary_weapon.muzzle_end = spatial

func load_from_character(character: CharacterDef):
	if character.Weapon1:
		primary_weapon = WeaponRegister.gun_register[character.Weapon1].instantiate()
	if character.Weapon2:
		secondary_weapon = WeaponRegister.gun_register[character.Weapon2].instantiate()
	if character.Weapon3:
		tertiary_weapon = WeaponRegister.melee_register[character.Weapon3].instantiate()
	# TODO: Update when we have an equipment register
	if character.Equipment1:
		equipment_1.equipment_instance = null
	if character.Equipment2:
		equipment_2.equipment_instance = null



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
