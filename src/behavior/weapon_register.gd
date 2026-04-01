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

@onready var gun_register = {
	"Kar98k": load("res://behavior/player/weapons/guns/empire/longarms/Kar98a/Kar98k.tscn"),
	"Gewehr 98": load("res://behavior/player/weapons/guns/empire/longarms/Gewehr98/Gewehr98.tscn"),
	"Reichsrevolver": load("res://behavior/player/weapons/guns/empire/sidearms/Reichsrevolver/reichsrevolver.tscn"),
	"LeeEnfield": load("res://behavior/player/weapons/guns/entente/longarms/leeenfield/leeenfield.tscn"),
	"Webley": load("res://behavior/player/weapons/guns/entente/sidearms/webley/webley.tscn"),
	"LebelCarbine": load("res://behavior/player/weapons/guns/entente/longarms/lebelcarbine/lebelcarbine.tscn"),
	"CarbineRepeater": load("res://behavior/player/weapons/guns/free_agents/longarms/carbinerepeater/carbinerepeater.tscn")
}

@onready var display_gun_register = {
	"Kar98k": {
		"name": "Kar98k",
		"image": "",
		"stats": ""
	},
	"Gewehr 98": {
		"name": "Gewehr 98",
		"image": "",
		"stats": ""
	},
	"Reichsrevolver": {
		"name": "Reichsrevolver",
		"image": "",
		"stats": ""
	},
	"LeeEnfield": {
		"name": "Lee Enfield",
		"image": "",
		"stats": ""
	},
	"Webley": {
		"name": "Webley Revolver",
		"image": "",
		"stats": ""
	},
	"LebelCarbine": {
		"name": "Lebel M1886 M93-R35 Carbine",
		"image": "",
		"stats": ""
	},
	"CarbineRepeater": {
		"name": "M1873 Carbine Repeater",
		"image": "",
		"stats": ""
	}
}

@onready var melee_register = {
	"britishtrenchknife": load("res://behavior/player/weapons/guns/entente/melee/trenchknife/trenchknife.tscn"),
}

@onready var display_melee_register = {
	"britishtrenchknife": {
		"name": "Trench Knife",
		"image": "",
		"stats": ""
	}
}
