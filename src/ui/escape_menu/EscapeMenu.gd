###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Control

signal leave_button_pressed

func _on_quit_button_pressed():
	get_tree().quit()

func _on_leave_button_pressed() -> void:
	leave_button_pressed.emit()
