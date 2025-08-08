###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Interactable

@export var OBTAIN_TIME_TARGET = 10.0

var obtain_time = 0.0
var extracted = false

var debug_red = preload("res://debug/materials/debug_red.tres")

func _ready():
	Global.add_chipsite(self)

# Start extraction of resource
func interact(other):
	if not extracted:
		obtain_time += other.delta
		if obtain_time >= OBTAIN_TIME_TARGET and not extracted:
			extracted = true
			$model/mesh.material_override = debug_red
			print("Chip Extracted")
			self.display_text = ""
			_refresh(other)
		Local.HUD.get_child(1).set_time_value((obtain_time / OBTAIN_TIME_TARGET) * 100)
			

func _add_interaction(node: Node):
	if not extracted:
		Local.HUD.get_child(1).set_time_value((obtain_time / OBTAIN_TIME_TARGET) * 100)
		Local.HUD.get_child(1).set_visible(true)

func _remove_interaction(node: Node):
	Local.HUD.get_child(1).set_visible(false)
