###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Gun

class_name DefaultGun

func _init():
	faction = Factions.Enum.DEFAULT
	slots[ClassRegister.Classes.DEFAULT] =  [1]
	key = "DefaultGun"

func _local_ready():
	fire_sound =\
		load("res://behavior/player/weapons/guns/default_gun/DefaultGunShot.mp3")
	bolt_pull_sound =\
		load("res://behavior/player/weapons/guns/default_gun/BoltPullSound.mp3")
