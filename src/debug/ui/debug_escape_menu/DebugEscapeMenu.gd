###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Node

const BUS_NAME = "Master"
@onready var bus_idx := AudioServer.get_bus_index(BUS_NAME)


func _on_volume_value_changed(value: float) -> void:
	var db := linear_to_db(clamp(value, 0.0, 1.0))
	AudioServer.set_bus_volume_db(bus_idx, db)
