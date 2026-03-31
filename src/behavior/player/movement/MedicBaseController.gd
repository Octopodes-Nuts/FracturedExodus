###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends DefaultController

class_name MedicBaseController

# Medics revive faster and can perform advanced revives after the first down
func _ready() -> void:
	medic_res = true
	super._ready()
