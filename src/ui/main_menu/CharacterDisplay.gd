extends Node

var def: CharacterDef

@onready var character_render = $character_render
@onready var character_name = $character_name

signal character_select

var rendered = false
func _process(_delta: float) -> void:
	
	if not rendered:
		if Local.selected_character_def != null:
			character_name.text = Local.selected_character_def.Name
			rendered = true

func reload(def: CharacterDef):
	character_name.text = Local.selected_character_def.Name

func _on_select_btn_pressed() -> void:
	emit_signal("character_select")
