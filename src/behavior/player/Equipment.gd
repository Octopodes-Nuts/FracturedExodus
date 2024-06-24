###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

# This may require a reference to the player who has the item 
# equipped.

extends Equipable

class_name Equipment

# if equipment is consumable, the equipment slot will be freed when
# all charges are used. Otherwise, charges can be picked up during a 
# resupply
@export var consumable: bool = true
# if equipment is throwable, the player will throw it
# the other option is player use, where an animation of the player
# using it on himself or a teammate, but the item will not leave
# the player's hand
@export var throwable: bool = false
# the number of charges a piece of equipment has
@export var charges: int = 1
# use time is the time it takes to use. If the item is throwable, this timer is not
# controllable.
@export var use_time: float = 1.0
var charge_use_time: float

var player: DefaultController

# if the throwable has been lit, this is true
var started: bool = false

func _init(controller: DefaultController):
	player = controller

"""
This occurs when trigger use_time runs out
"""
signal triggered

func _process(delta):

	if active:
		if Input.is_action_just_pressed("fire"):
			charge_use_time = use_time
			if throwable:
				started = true
		elif Input.is_action_pressed("fire") and not throwable:
			charge_use_time -= delta
		elif Input.is_action_just_released("fire") and\
				not throwable:
			charge_use_time = use_time
		
		if charge_use_time <= 0 and _isvalid():
			triggered.emit()
			charges -= 1
			# add a cool down here
			charge_use_time = use_time
			_action()
	
	if throwable and started:
		charge_use_time -= delta

func _set_inactive():
	super._set_inactive()

	if throwable and started:
		_drop()

"""
This is the action that is performed at the end of the countdown.
"""
func _action():
	pass

# drop this equipment on the ground
func _drop():
	pass

func throw():
	pass


func _isvalid():
	return true 