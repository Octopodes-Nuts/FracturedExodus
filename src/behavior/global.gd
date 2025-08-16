###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Node

# Script containing variables that are global to each match
var chipsites: Array = []
var spawns: Array = []
var used_spawns: Array = []
var chipsite_spawns: Array = []

# Map Root is the top level of a map
var map_root: WorldEnvironment

# Local Variables are Mapped by player
var player_huds: Dictionary

var character_data: Dictionary = {}

var spawn_parent: Node

signal character_update(ids: Array)
# Deal with adding and removing chipsites from active list
# Basically just dealing with addtl context that may become
# clearer down the line
func add_chipsite(chipsite: Node3D):
	chipsites.append(chipsite)

func remove_chipsite(chipsite: Node):
	pass

func add_spawn(spawn: Node):
	spawns.append(spawn)

func get_spawn():
	var spawn = spawns[randi() % len(spawns)]
	while spawn in used_spawns:
		spawn = spawns[randi() % len(spawns)]
	used_spawns.append(spawn)
	return spawn

func emit_character_update(ids: Array):
	emit_signal("character_update", ids)
