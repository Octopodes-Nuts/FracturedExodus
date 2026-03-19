###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Interactable

@export var faction: int

@export var EXTRACT_TIME: float = 5.0
var current_extract_time: float = 0.0

var extracts: Dictionary = {}

func _init():
	display_text = ""
	auto_interact = true

func _local_physics_step(delta):
	for node in extracts.keys():
		if extracts[node] > 0:
			extracts[node] -= delta
			Local.HUD.get_child(1).set_time_value((extracts[node] / EXTRACT_TIME) * 100)
		else:
			node.extract()
			#warning-ignore:return_value_discarded
			extracts.erase(node)

func _interact(node: Node):
	# check if factions match. fcations are not yet implemented
	extracts[node] = EXTRACT_TIME
	#print(extracts)

func _add_interaction(_node: Node):
	Local.HUD.get_child(1).set_visible(true)

func _remove_interaction(node: Node):
	#warning-ignore:return_value_discarded
	extracts.erase(node)
	Local.HUD.get_child(1).set_visible(false)
	
