extends Node

@onready var _img = $img
@onready var _name = $name

#switch this to also load image
func load_from(load):
	_name.text = load
