extends Panel

var def: CharacterDef

@export var new_character_dialogue: NewCharacterDialogue

@onready var character_render = $character_render
@onready var character_name = $character_name

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
	else:
		character_name.text = "Select Character"

func _on_select_btn_pressed() -> void:
	emit_signal("character_select")
