extends Node

# Script containing variables that are global to each match
var chipsites: Array = []

# Map Root is the top level of a map
var map_root: Spatial

# Deal with adding and removing chipsites from active list
# Basically just dealing with addtl context that may become
# clearer down the line
func add_chipsite(chipsite: Spatial):
	chipsites.append(chipsite)

func remove_chipsite(chipsite: Node):
	chipsites.append(chipsite)
