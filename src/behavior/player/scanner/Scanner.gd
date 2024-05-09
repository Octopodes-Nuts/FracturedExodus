###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Node3D

@onready var Global = get_node("/root/Global")
@onready var notifier: ScannerLight = $notifier

var detected: bool = false

func _physics_process(_delta):
	notifier.notify(_detect())

func _detect():
	if Global.chipsites.size() < 1:
		return -1.0

	for site in Global.chipsites:
		
		var x = site.transform.origin.x - transform.origin.x
		var z = site.transform.origin.z - transform.origin.z

		var angle = rad_to_deg(atan(x / z))

		if x < 0:
			if z < 0:
				angle = -angle #correct
			else:
				angle = 180 - angle
		else:
			if z < 0:
				angle = -angle
			else:
				angle = -180 - angle #correct
		
		if rotation_degrees.y > (angle - 5)\
			and rotation_degrees.y < (angle + 5):
			return 1.0
		else:
			return -1.0

