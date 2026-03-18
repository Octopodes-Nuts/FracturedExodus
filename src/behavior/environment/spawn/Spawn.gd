extends Node

class_name Spawn

enum Faction {
	DEFAULT,
	ENTETNE,
	EMPIRE,
	FREE_AGENTS
}

@export var enabled: bool = true
@export var faction: Faction = Faction.DEFAULT

func _ready():
	if enabled:
		Global.add_spawn(self)
