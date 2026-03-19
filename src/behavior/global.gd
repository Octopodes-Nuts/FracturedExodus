###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Node

# Script containing variables that are global to each match
var chipsites: Array = []
var spawns: Array = []
var empire_spawns: Array = []
var entente_spawns: Array = []
var free_agent_spawns: Array = []
var used_spawns: Array = []
var chipsite_spawns: Array = []

# Map Root is the top level of a map
var map_root: WorldEnvironment

# Local Variables are Mapped by player
var player_huds: Dictionary

var character_data: Dictionary = {}

var spawn_parent: Node
var bullet_spawn: Node

signal character_update(ids: Array)

# Deal with adding and removing chipsites from active list
# Basically just dealing with addtl context that may become
# clearer down the line
func add_chipsite(chipsite: Node3D):
	chipsites.append(chipsite)

func remove_chipsite(chipsite: Node):
	chipsites.erase(chipsite)

func add_spawn(spawn: Spawn):
	match spawn.faction:
		Spawn.Faction.DEFAULT:
			spawns.append(spawn)
		Spawn.Faction.ENTETNE:
			entente_spawns.append(spawn)
		Spawn.Faction.EMPIRE:
			empire_spawns.append(spawn)
		Spawn.Faction.FREE_AGENTS:
			free_agent_spawns.append(spawn)

func _get_spawn_pool_for_faction(faction: int) -> Array:
	match faction:
		Factions.ENTENTE:
			return entente_spawns
		Factions.EMPIRE:
			return empire_spawns
		Factions.FREE_AGENTS:
			return free_agent_spawns
		_:
			return spawns

func get_spawn(faction: int = Factions.DEFAULT):
	var pool: Array = _get_spawn_pool_for_faction(faction)
	if pool.is_empty():
		pool = spawns

	if pool.is_empty():
		push_warning("[Global] No available spawn points.")
		return null

	var available_spawns: Array = []
	for spawn in pool:
		if spawn not in used_spawns:
			available_spawns.append(spawn)

	# Recycle only this faction's pool once all of its points have been used.
	if available_spawns.is_empty():
		for spawn in pool:
			used_spawns.erase(spawn)
		available_spawns = pool.duplicate()

	var selected_spawn = available_spawns[randi() % len(available_spawns)]
	used_spawns.append(selected_spawn)
	return selected_spawn

func emit_character_update(ids: Array):
	emit_signal("character_update", ids)
