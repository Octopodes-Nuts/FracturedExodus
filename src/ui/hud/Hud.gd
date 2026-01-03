###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Control

@onready var crosshair = $crosshair
@onready var death_text = $death_text
@onready var health_slider = $health_slider
@onready var display_text = $Notification


@onready var Local = get_node('/root/Local')
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var clear_text = false
var clear_text_delta = 0.0

# Called when the node enters the scene tree for the first time.
#func _ready():
#	Local.HUD = self

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _process(delta):
	if clear_text:
		if clear_text_delta > 0.0:
			clear_text_delta -= delta
		else:
			display_text.text = ""
			clear_text = false

func display_ammo(ammo):
	$AmmoCounter.set_ammo(ammo[0], ammo[1])

func show_crosshair():
	pass

func hide_crosshair():
	pass

@rpc("any_peer")
func notify(txt: String, time: float):
	clear_text = true
	display_text.text = txt
	clear_text_delta = time
