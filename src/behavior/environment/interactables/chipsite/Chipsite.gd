###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Interactable

func _ready():
	Global.add_chipsite(self)

# Start extraction of resource
func interact():
	pass