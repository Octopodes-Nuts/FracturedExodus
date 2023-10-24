###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

"""
The equipment slot is a wrapper class that holds a reference to
an actual piece of equipment.
"""

extends Node

class_name EquipmentSlot

var equipment_instance: Equipment = null

func use_report() -> Dictionary:
	if equipment_instance != null:
		return {
			"throwable": equipment_instance.throwable,
			"consumable": equipment_instance.consumable
		}
	else: return {
		'null': null
	}

func use():
	if equipment_instance != null:
		equipment_instance.charges -= 1

		if equipment_instance.charges <= 0\
			and equipment_instance.consumable:

			equipment_instance.queue_free()
			equipment_instance = null
