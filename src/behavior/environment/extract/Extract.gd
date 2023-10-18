extends Interactable

@export var faction: int

@export var EXTRACT_TIME: float = 5.0
var current_extract_time: float = 0.0

var extracts: Dictionary = {}

func _init():
	auto_interact = true

func _local_physics_step(delta):
	for node in extracts.keys():
		if extracts[node] > 0:
			extracts[node] -= delta
		else:
			node.extract()
			#warning-ignore:return_value_discarded
			extracts.erase(node)

func _interact(node: Node):
	# check if factions match. fcations are not yet implemented
	extracts[node] = EXTRACT_TIME

func _remove_interaction(node: Node):
	#warning-ignore:return_value_discarded
	extracts.erase(node)
