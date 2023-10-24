###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Equipable

class_name Equipment

# if equipment is consumable, the equipment slot will be freed when
# all charges are used. Otherwise, charges can be picked up during a 
# resupply
var consumable: bool = true
# if equipment is throwable, the player will throw it
# the other option is player use, where an animation of the player
# using it on himself or a teammate, but the item will not leave
# the player's hand
var throwable: bool = false
# the number of charges a piece of equipment has
var charges: int = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
