extends Node

signal new_char_selected
signal new_char_created

var Chit: = preload("res://ui/main_menu/CharacterChit.tscn")
var character_chits = []

var path_to_firsts = "res://load/Names/first.txt"
var path_to_lasts = "res://load/Names/last.txt"

var first_names
var last_names

func _ready() -> void:
	first_names = FileAccess.get_file_as_string(path_to_firsts).split(" ")
	last_names = FileAccess.get_file_as_string(path_to_lasts).split(" ")

func _conntect_to_pressed(btn: Button):
	btn.connect("pressed", _new_char_selected)
	
func _new_char_selected():
	emit_signal("new_char_selected")

# Make a change here to generating names
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
		for chr in Local.characters.characters.keys():
			var chit: CharacterChit = Chit.instantiate()
			character_chits.append(chit)
			chit.position = Vector2(170.0 + ((329 - 170) * pos), 18.0)
			add_child(chit)
			chit._def = Local.characters.characters[chr]
			chit.pos = pos
			chit.render()
			_conntect_to_pressed(chit)
			pos += 1
			rendered = true

func _on_new_btn_pressed() -> void:
	var char_def = CharacterDef.new()
	# prevent name collisions here
	char_def.Name = get_name_name()
	Local.characters.characters[char_def.Name] = char_def
	Local.selected_character_def = char_def
	emit_signal("new_char_created")
	render()

func get_name_name():
	var name_name = first_names[randi_range(0, len(first_names) - 1)] + " " +\
		last_names[randi_range(0, len(last_names) - 1)]
	while name_name in Local.characters.characters:
		name_name = first_names[randi_range(0, len(first_names) - 1)] + " " +\
			last_names[randi_range(0, len(last_names) - 1)]
	return name_name
