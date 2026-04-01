extends Panel

class_name NewCharacterDialogue

var _class: ClassRegister.Classes = ClassRegister.Classes.INFANTRY 
var _character_name: String

@export var main_menu: MainMenu

@onready var class_name_label = $ClassNameLabel
@onready var class_summary = $ScrollContainer/VBoxContainer/ClassSummary

@onready var infantry_button = $InfantryButton
@onready var medic_button = $MedicButton
@onready var special_button = $SpecialButton
@onready var officer_button = $OfficerButton

@onready var character_name_label = $CharacterPanel/CharacterNameLabel
@onready var character_portrait = $CharacterPanel/CharacterPortrait

var last_names: PackedStringArray
var first_names: PackedStringArray

var path_to_firsts = "res://load/Names/first.txt"
var path_to_lasts = "res://load/Names/last.txt"

signal create_character(character_name: String, class_type: int)
signal closed
signal opened

func _ready() -> void:
	main_menu.reload_ui.connect(hide)
	visibility_changed.connect(func(): 
		if visible:
			render_names()
			_on_infantry_button_pressed()
			emit_signal("opened")
		else:
			emit_signal("closed")
	)
	first_names = _load_name_list(path_to_firsts, ["John", "Jane", "Alex", "Emily"])
	last_names = _load_name_list(path_to_lasts, ["Smith", "Doe", "Johnson", "Brown"])
	
	_on_infantry_button_pressed()

func _on_deploy_button_pressed() -> void:
	emit_signal("create_character", _character_name, _class)
	emit_signal("closed")
	hide()


func render_names():
	match Local.get_state("selected_faction"):
		Factions.Enum.ENTENTE:
			infantry_button.text = ClassRegister.entente_class_name_map[ClassRegister.Classes.INFANTRY]
			medic_button.text = ClassRegister.entente_class_name_map[ClassRegister.Classes.MEDIC]
			special_button.text = ClassRegister.entente_class_name_map[ClassRegister.Classes.SPECIAL]
			officer_button.text = ClassRegister.entente_class_name_map[ClassRegister.Classes.OFFICER]
		Factions.Enum.EMPIRE:
			infantry_button.text = ClassRegister.empire_class_name_map[ClassRegister.Classes.INFANTRY]
			medic_button.text = ClassRegister.empire_class_name_map[ClassRegister.Classes.MEDIC]
			special_button.text = ClassRegister.empire_class_name_map[ClassRegister.Classes.SPECIAL]
			officer_button.text = ClassRegister.empire_class_name_map[ClassRegister.Classes.OFFICER]
		Factions.Enum.FREE_AGENTS:
			infantry_button.text = ClassRegister.free_agent_class_name_map[ClassRegister.Classes.INFANTRY]
			medic_button.text = ClassRegister.free_agent_class_name_map[ClassRegister.Classes.MEDIC]
			special_button.text = ClassRegister.free_agent_class_name_map[ClassRegister.Classes.SPECIAL]
			officer_button.text = ClassRegister.free_agent_class_name_map[ClassRegister.Classes.OFFICER]

func render_class_name_and_summary():
	class_name_label.text = ClassRegister.get_class_name(Local.get_state("selected_faction"), _class)
	class_summary.text = ClassRegister.get_class_summary(Local.get_state("selected_faction"), _class)


func _on_infantry_button_pressed() -> void:
	_class = ClassRegister.Classes.INFANTRY
	render_class_name_and_summary()
	_character_name = _create_character_name()
	character_name_label.text = _character_name
	# set character portrait to infantry portrait based on faction

func _on_medic_button_pressed() -> void:
	_class = ClassRegister.Classes.MEDIC
	render_class_name_and_summary()
	_character_name = _create_character_name()
	character_name_label.text = _character_name
	# set character portrait to medic portrait based on faction


func _on_special_button_pressed() -> void:
	_class = ClassRegister.Classes.SPECIAL
	render_class_name_and_summary()
	_character_name = _create_character_name()
	character_name_label.text = _character_name
	# set character portrait to special portrait based on faction


func _on_officer_button_pressed() -> void:
	_class = ClassRegister.Classes.OFFICER
	render_class_name_and_summary()
	_character_name = _create_character_name()
	character_name_label.text = _character_name
	# set character portrait to officer portrait based on faction

func _create_character_name() -> String:
	if first_names.is_empty() or last_names.is_empty():
		return "Rookie " + str(randi_range(1000, 9999))

	var name_name = first_names[randi_range(0, len(first_names) - 1)] + " " +\
		last_names[randi_range(0, len(last_names) - 1)]
	var attempts := 0
	while name_name in Local.get_state("characters").characters and attempts < 20:
		name_name = first_names[randi_range(0, len(first_names) - 1)] + " " +\
			last_names[randi_range(0, len(last_names) - 1)]
		attempts += 1

	if name_name in Local.get_state("characters").characters:
		name_name = "Rookie " + str(randi_range(1000, 9999))
	return name_name

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

func _on_cancel_button_pressed() -> void:
	hide()
