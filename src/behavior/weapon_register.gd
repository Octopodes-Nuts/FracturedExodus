extends Node

# All weapons must be registeed here so that they can be loaded
# This just references preset scenes

@onready var gun_register = {
	"DefaultGun": preload("res://behavior/player/weapons/guns/default_gun/DefaultGun.tscn"),
	"DefaultPistol": preload("res://behavior/player/weapons/guns/default_pistol/DefaultPistol.tscn")
}

@onready var melee_register = {
	
}
