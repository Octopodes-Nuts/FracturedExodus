extends Node

@onready var block = $scroll_container/block
var account_api: AccountAPI

signal new_char_selected
signal new_char_created

var Chit: = preload("res://ui/main_menu/CharacterChit.tscn")
var character_chits = []

var path_to_firsts = "res://load/Names/first.txt"
var path_to_lasts = "res://load/Names/last.txt"

const FALLBACK_FIRST_NAMES := ["Alex", "Morgan", "Riley", "Jordan"]
const FALLBACK_LAST_NAMES := ["Stone", "Vale", "Ash", "Ward"]

var first_names: PackedStringArray = PackedStringArray()
var last_names: PackedStringArray = PackedStringArray()

func _ready() -> void:
	first_names = _load_name_list(path_to_firsts, FALLBACK_FIRST_NAMES)
	last_names = _load_name_list(path_to_lasts, FALLBACK_LAST_NAMES)

func _load_name_list(path: String, fallback: Array) -> PackedStringArray:
	if not FileAccess.file_exists(path):
		push_warning("Missing name file in build: %s. Using fallback names." % path)
		return PackedStringArray(fallback)

	var raw := FileAccess.get_file_as_string(path)
	if raw.is_empty():
		push_warning("Empty name file: %s. Using fallback names." % path)
		return PackedStringArray(fallback)

	var normalized := raw.replace("\r", " ").replace("\n", " ").strip_edges()
	var names := normalized.split(" ", false)
	if names.is_empty():
		push_warning("No usable names in file: %s. Using fallback names." % path)
		return PackedStringArray(fallback)
	return PackedStringArray(names)

func _conntect_to_pressed(btn: Button):
	btn.connect("pressed", _new_char_selected)
	
func _new_char_selected():
	emit_signal("new_char_selected")

# Make a change here to generating names
var rendered = false
func _process(_delta: float) -> void:
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

func _on_new_btn_pressed() -> void:
	if account_api == null:
		push_error("AccountAPI not assigned in CharacterSelect")
		return

	var char_def = CharacterDef.new()
	char_def.Faction = Local.selected_faction
	# prevent name collisions here
	char_def.Name = get_name_name()
	account_api.create_character(Local.session_token, char_def)
	# ID needs to be saved here
	emit_signal("new_char_created")

func _on_character_created():
	render()
	
func get_name_name():
	if first_names.is_empty() or last_names.is_empty():
		return "Rookie " + str(randi_range(1000, 9999))

	var name_name = first_names[randi_range(0, len(first_names) - 1)] + " " +\
		last_names[randi_range(0, len(last_names) - 1)]
	var attempts := 0
	while name_name in Local.characters.characters and attempts < 20:
		name_name = first_names[randi_range(0, len(first_names) - 1)] + " " +\
			last_names[randi_range(0, len(last_names) - 1)]
		attempts += 1

	if name_name in Local.characters.characters:
		name_name = "Rookie " + str(randi_range(1000, 9999))
	return name_name
