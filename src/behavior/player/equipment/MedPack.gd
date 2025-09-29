###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Equipment

class_name  MedPack

@export var heal_rate: int = 15
@export var health_pool: int = 150

func use(player: DefaultController):
	if player.current_health != player.FULL_HEALTH and health_pool != 0:
		var heal_amount: int = heal_rate * player.delta
		
		# Do not heal past maximum health or more than available in health pool
		if player.current_health + heal_amount > player.FULL_HEALTH:
			heal_amount = player.FULL_HEALTH - player.current_health
		if heal_amount > health_pool:
			heal_amount = health_pool
			
		player.current_health += heal_amount
		health_pool -= heal_amount
			
		print('healed ' + str(heal_amount) + ' to: '\
		 	+ str(player.current_health))
		print('health available: ' + str(health_pool))
