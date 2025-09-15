###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Equipment

class_name  MedPack

@export var health_increase: int = 50
"res://behavior/player/equipment/MedPack.gd"
func use(player: DefaultController):
	if player.current_health != player.FULL_HEALTH:
		player.current_health += 50
		if player.current_health > player.FULL_HEALTH:
			player.current_health = player.FULL_HEALTH
			
		print('healed to: ' + str(player.current_health))
	else:
		print('already at full health')
