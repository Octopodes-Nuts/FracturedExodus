extends Node

signal new_char_selected
signal new_char_created

var Chit: = preload("res://ui/main_menu/CharacterChit.tscn")
var character_chits = []

func _conntect_to_pressed(btn: Button):
	btn.connect("pressed", _new_char_selected)
	
func _new_char_selected():
	emit_signal("new_char_selected")

var NameName = 0
var rendered = false
func _process(delta: float) -> void:
	if not rendered:
		render()

func get_characters() -> Dictionary[String, CharacterDef]:
	var d: Dictionary[String, CharacterDef] = {}
	for chit in character_chits:
		d[chit._def.Name] = chit._def
	return d

func render():
	if Local.selected_character_def and Local.characters != null:
		var pos = 0
		for char in Local.characters.characters.keys():
			var chit: CharacterChit = Chit.instantiate()
			character_chits.append(chit)
			chit.position = Vector2(170.0 + ((329 - 170) * pos), 18.0)
			add_child(chit)
			chit._def = Local.characters.characters[char]
			chit.pos = pos
			chit.render()
			_conntect_to_pressed(chit)
			pos += 1
			NameName += 1
			rendered = true

func _on_new_btn_pressed() -> void:
	var char_def = CharacterDef.new()
	char_def.Name = str(NameName)
	Local.characters.characters[char_def.Name] = char_def
	Local.selected_character_def = char_def
	emit_signal("new_char_created")
	render()
