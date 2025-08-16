###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Control

@onready var crosshair = $crosshair
@onready var death_text = $death_text
@onready var health_slider = $health_slider


@onready var Local = get_node('/root/Local')
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	Local.HUD = self

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func show_crosshair():
	pass

func hide_crosshair():
	pass
