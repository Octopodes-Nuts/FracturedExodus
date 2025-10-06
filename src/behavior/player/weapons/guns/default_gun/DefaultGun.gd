###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Gun

class_name DefaultGun

func _init():
	faction = Factions.DEFAULT
	slots = {
		Types.Classes.CLASS_DEFAULT: [1]
	}

func _local_ready():
	fire_sound =\
		load("res://behavior/player/weapons/guns/default_gun/DefaultGunShot.mp3")
	bolt_pull_sound =\
		load("res://behavior/player/weapons/guns/default_gun/BoltPullSound.mp3")
	key = "DefaultGun"
