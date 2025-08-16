extends Node

@export var enabled: bool = true

func _ready():
	if enabled:
		Global.add_spawn(self)
