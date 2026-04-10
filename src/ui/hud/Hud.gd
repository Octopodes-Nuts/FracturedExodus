###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Control

@onready var crosshair = $crosshair
@onready var death_text = $death_text
@onready var health_slider = $health_slider
@onready var display_text = $Notification
@onready var extract_timer = $ExtractTimer
@onready var interaction_text = $TextDisplay
@onready var ammo_counter = $AmmoCounter


@onready var Local = get_node('/root/Local')
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var clear_text = false
var clear_text_delta = 0.0

# Called when the node enters the scene tree for the first time.
#func _ready():
#	Local.set_hud(self)

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
	ammo_counter.set_ammo(ammo[0], ammo[1])

func set_interaction_text(txt: String):
	interaction_text.display_text(null, txt)

func clear_interaction_text():
	interaction_text.clear()

func set_progress_visible(show_progress: bool):
	extract_timer.visible = show_progress

func set_progress_percent(val: float):
	extract_timer.set_time_value(val)

func set_health_percent(val: float):
	health_slider.value = val

func set_dead_state(dead: bool):
	crosshair.visible = not dead
	death_text.visible = dead

func show_crosshair():
	pass

func hide_crosshair():
	pass

@rpc("any_peer")
func notify(txt: String, time: float):
	clear_text = true
	display_text.text = txt
	clear_text_delta = time
