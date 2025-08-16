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
var has_scanner = false


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

var instances = {}

func load_from_character(character: CharacterDef):
	if character.Weapon1:
		if character.Weapon1 in instances.keys():
			primary_weapon = instances[character.Weapon1]
		else:
			instances[character.Weapon1] = WeaponRegister.gun_register[character.Weapon1].instantiate()
			primary_weapon = instances[character.Weapon1]
	if character.Weapon2:
		if character.Weapon2 in instances.keys():
			primary_weapon = instances[character.Weapon2]
		else:
			instances[character.Weapon2] = WeaponRegister.gun_register[character.Weapon2].instantiate()
			primary_weapon = instances[character.Weapon2]
	if character.Weapon3:
		if character.Weapon3 in instances.keys():
			primary_weapon = instances[character.Weapon3]
		else:
			instances[character.Weapon3] = WeaponRegister.gun_register[character.Weapon3].instantiate()
			primary_weapon = instances[character.Weapon3]

func load_from_payload(pd: Dictionary):
	if pd["wep1"]:
		if pd["wep1"] in instances.keys():
			primary_weapon = instances[pd["wep1"]]
		else:
			instances[pd["wep1"]] = WeaponRegister.gun_register[pd["wep1"]].instantiate()
			primary_weapon = instances[pd["wep1"]]
	if pd["wep2"]:
		if pd["wep2"] in instances.keys():
			secondary_weapon = instances[pd["wep2"]]
		else:
			instances[pd["wep2"]] = WeaponRegister.gun_register[pd["wep2"]].instantiate()
			secondary_weapon = instances[pd["wep2"]]
	if pd["wep3"]:
		if pd["wep3"] in instances.keys():
			tertiary_weapon = instances[pd["wep3"]]
		else:
			instances[pd["wep3"]] = WeaponRegister.gun_register[pd["wep3"]].instantiate()
			tertiary_weapon = instances[pd["wep3"]]
	has_scanner = pd["scanner"]
	# TODO: Update when we have an equipment register
	if pd["eq1"]:
		equipment_1.equipment_instance = null
	if pd["eq2"]:
		equipment_2.equipment_instance = null



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
