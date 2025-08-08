###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Equipment

class_name  MedPack

@export var health_increase: int = 50

func _action():
	player.health += 50
	if player.health > player.FULL_HEALTH:
		player.health = player.FULL_HEALTH
	
	print('heal')
