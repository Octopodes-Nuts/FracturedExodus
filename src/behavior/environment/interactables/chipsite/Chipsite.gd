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

func _exit_tree() -> void:
	if Global != null:
		Global.remove_chipsite(self)

# Start extraction of resource
func interact(other):
	if not extracted:
		obtain_time += other.delta
		if obtain_time >= OBTAIN_TIME_TARGET and not extracted:
			_extract_chip.rpc()
			other.get_objective()
			_refresh(other)
		var hud := Local.get_hud()
		if hud != null:
			hud.set_progress_percent((obtain_time / OBTAIN_TIME_TARGET) * 100)
			

func _add_interaction(_node: Node):
	if not extracted:
		var hud := Local.get_hud()
		if hud != null:
			hud.set_progress_percent((obtain_time / OBTAIN_TIME_TARGET) * 100)
			hud.set_progress_visible(true)

func _remove_interaction(_node: Node):
	var hud := Local.get_hud()
	if hud != null:
		hud.set_progress_visible(false)

@rpc("call_local")
func _extract_chip():
	extracted = true
	$model/mesh.material_override = debug_red
	print("Chip Extracted")
	self.display_text = ""
