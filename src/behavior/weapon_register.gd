###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Node

# All weapons must be registeed here so that they can be loaded
# This just references preset scenes

@onready var gun_register = {
	"DefaultGun": load("res://behavior/player/weapons/guns/default_gun/DefaultGun.tscn"),
	"DefaultPistol": load("res://behavior/player/weapons/guns/default_pistol/DefaultPistol.tscn"),
	"DefaultShotgun": load("res://behavior/player/weapons/guns/default_shotgun/DefaultShotgun.tscn"),
}

@onready var display_gun_register = {
	"DefaultGun": {
		"name": "Default Gun",
		"image": "",
		"stats": "" # this will be a path to weapon stats?
	},
	"DefaultPistol": {
		"name": "Default Pistol",
		"image": "",
		"stats": ""
	},
	"DefaultShotgun": {
		"name": "Default Shotgun",
		"image": "",
		"stats": ""
	}
}

@onready var melee_register = {
	
}
