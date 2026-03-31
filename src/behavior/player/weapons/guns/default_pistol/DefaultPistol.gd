###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Gun

class_name DefaultPistol

func _init():
	slots[ClassRegister.Classes.DEFAULT] = [1,2]
	key = "DefaultPistol"

func _local_ready():
	fire_sound =\
		load("res://behavior/player/weapons/guns/default_pistol/DefaultPistolShot.mp3")
	bolt_pull_sound =\
		load("res://behavior/player/weapons/guns/default_pistol/HammerCock.mp3")
