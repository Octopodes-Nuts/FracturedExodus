extends Node

@onready var block = $scroll_container/block
var account_api: AccountAPI

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
	for chit in character_chits:
		chit.queue_free()
	character_chits.clear()

	var characters_to_render: CharactersResource

	if Local.selected_faction == Factions.ENTENTE:
		characters_to_render = Local.entente_characters
	elif Local.selected_faction == Factions.EMPIRE:
		characters_to_render = Local.empire_characters
	elif Local.selected_faction == Factions.FREE_AGENTS:
		characters_to_render = Local.free_agent_characters
	else:
		characters_to_render = Local.characters

	if Local.selected_character_def and characters_to_render != null:
		var pos = 0
		for chr in characters_to_render.characters.keys():
			# Skip empty character names
			if chr.is_empty() or characters_to_render.characters[chr].Name.is_empty():
				continue
			var chit: CharacterChit = Chit.instantiate()
			character_chits.append(chit)
			chit.position = Vector2(170.0 + ((329 - 170) * pos), 18.0)
			block.add_child(chit)
			chit._def = characters_to_render.characters[chr]
			chit.pos = pos
			chit.render()
			_conntect_to_pressed(chit)
			pos += 1
		rendered = true

var create_character_connected = false

func _on_new_btn_pressed() -> void:
	var char_def = CharacterDef.new()
	char_def.Faction = Local.selected_faction
	if not create_character_connected:
		account_api.character_created.connect(_on_character_created)
		create_character_connected = true
	# prevent name collisions here
	char_def.Name = get_name_name()
	account_api.create_character(Local.session_token, char_def)
	# ID needs to be saved here
	emit_signal("new_char_created")

func _on_character_created():
	render()
	
func get_name_name():
	var name_name = first_names[randi_range(0, len(first_names) - 1)] + " " +\
		last_names[randi_range(0, len(last_names) - 1)]
	while name_name in Local.characters.characters:
		name_name = first_names[randi_range(0, len(first_names) - 1)] + " " +\
			last_names[randi_range(0, len(last_names) - 1)]
	return name_name
