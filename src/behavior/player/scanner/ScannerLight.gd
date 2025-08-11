###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Node3D

class_name ScannerLight

var _intensity: float = 0.0
@onready var light = $light

func notify(intensity: float):
	# increase brightness of scanners light based on how close the scanner
	# is to pointing directly at the chipsite
	_intensity = intensity # just stop the warning
	light.light_energy = _intensity
	pass
