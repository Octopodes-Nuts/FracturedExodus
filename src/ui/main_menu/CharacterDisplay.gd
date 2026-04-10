extends Panel

var def: CharacterDef

@export var new_character_dialogue: NewCharacterDialogue

@onready var character_render = $character_render
@onready var character_name = $character_name
@onready var xp_label: Label = $VBoxContainer/XPLabel

var account_api: AccountAPI

signal character_select

var rendered = false

func _ready() -> void:
	new_character_dialogue.opened.connect(hide)
	new_character_dialogue.closed.connect(show)
	Local.state_changed.connect(reload)

func _process(_delta: float) -> void:
	pass

func reload(state: String, value: Variant):
	if state != "selected_character_def": return
	if Local.get_state("selected_character_def") != null:
		character_name.text = Local.get_state("selected_character_def").Name
		xp_label.text = "XP: %s" % Local.get_state("selected_character_def").XP
	else:
		character_name.text = "Select Character"

func _on_select_btn_pressed() -> void:
	emit_signal("character_select")


func _on_dismiss_btn_pressed() -> void:
	if Local.get_state("selected_character_def") != null:
		# Delete the character from the local state and remote server
		var char_def: CharacterDef = Local.get_state("selected_character_def")
		Local.get_state("characters").characters.erase(char_def.ID)
		account_api.delete_character(Local.get_state("session_token"), char_def.ID)
		Local.sort_characters()
		# Clear the selected character
		account_api.set_active_character(null)
