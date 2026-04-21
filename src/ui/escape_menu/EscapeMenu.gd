###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Control

const MASTER_BUS_NAME = "Master"

@export var MasterVolume: HSlider
@onready var master_bus_idx := AudioServer.get_bus_index(MASTER_BUS_NAME)


signal leave_button_pressed

func _ready() -> void:
	MasterVolume.value_changed.connect(_on_volume_value_changed)

func _on_quit_button_pressed():
	get_tree().quit()

func _on_leave_button_pressed() -> void:
	leave_button_pressed.emit()

func _on_volume_value_changed(value: float) -> void:
	var db := linear_to_db(clamp(value, 0.0, 1.0))
	AudioServer.set_bus_volume_db(master_bus_idx, db)
