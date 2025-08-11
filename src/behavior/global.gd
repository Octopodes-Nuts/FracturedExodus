###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Node

# Script containing variables that are global to each match
var chipsites: Array = []
var spawns: Array = []
var chipsite_spawns: Array = []

# Map Root is the top level of a map
var map_root: WorldEnvironment

# Local Variables are Mapped by player
var player_huds: Dictionary

# Deal with adding and removing chipsites from active list
# Basically just dealing with addtl context that may become
# clearer down the line
func add_chipsite(chipsite: Node3D):
	chipsites.append(chipsite)

func remove_chipsite(chipsite: Node):
	pass

func add_spawn(spawn: Node):
	spawns.append(spawn)
