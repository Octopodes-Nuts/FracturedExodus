extends Node

@onready var character_render = $character_render
@onready var character_name = $character_name

var rendered = false
func _process(_delta: float) -> void:
	
	if not rendered:
		if Local.selected_character_def != null:
			character_name.text = Local.selected_character_def.Name
			rendered = true
