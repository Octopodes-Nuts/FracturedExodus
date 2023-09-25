extends Node

onready var Global = get_node("/root/Global")

func _ready():
	Global.add_chipsite(self)

# Start extraction of resource
func interact():
	pass