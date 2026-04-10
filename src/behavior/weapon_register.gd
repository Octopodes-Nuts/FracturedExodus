###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Node

enum GunType {
	RIFLE,
	CARBINE,
	PISTOL,
	SHOTGUN,
	REVOLVER,
}

@onready var damage_lookup = {
	GunType.RIFLE: {
		0: 1.0,
		30: 1.0,
		80: 0.8,
		200: 0.5,
		700: 0.2,
		2000: 0.0	
	},
	GunType.CARBINE: {
		0: 1.0,
		20: 1.0,
		60: 0.8,
		150: 0.5,
		500: 0.2,
		2000: 0.0
	},
	GunType.PISTOL: {
		0: 1.0,
		15: 1.0,
		40: 0.8,
		100: 0.5,
		300: 0.2,
		2000: 0.0
	},
	GunType.SHOTGUN: {
		0: 1.0,
		10: 1.0,
		15: 0.8,
		40: 0.2,
		150: 0.1,
		500: 0.0,
		2000: 0.0
	},
	GunType.REVOLVER: {
		0: 1.0,
		20: 1.0,
		60: 0.8,
		150: 0.5,
		300: 0.2,
		2000: 0.0
	}
}

@onready var weapons: WeaponDefinitions = load("res://behavior/player/weapons/Weapons.res")
