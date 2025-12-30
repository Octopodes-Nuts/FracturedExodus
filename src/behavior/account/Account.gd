###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################


extends Node

# Local representation of Account information
class_name Account

var empire_funds: float
var empire_level: int
var empire_soliders: Array[CharacterDef]
var empire_guns: Array
var empire_equipment: Array

var entene_funds: float
var entente_level: int
var entente_soldiers: Array[CharacterDef]
var entente_guns: Array
var entente_equipment: Array

var free_agent_funds: float
var free_agent_level: int
var free_agent_agents: Array[CharacterDef]
var free_agent_guns: Array
var free_agent_equipment: Array

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
