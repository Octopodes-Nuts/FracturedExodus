###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Interactable

const OBTAIN_TIME_TARGET = 35.0

var obtain_time = 0.0
var extracted = false

func _ready():
	Global.add_chipsite(self)

# Start extraction of resource
func interact(other):
	if not extracted:
		obtain_time += other.delta
		print("Obtain Time: " + str(obtain_time))
		if obtain_time >= OBTAIN_TIME_TARGET:
			print("Chip Extracted")
