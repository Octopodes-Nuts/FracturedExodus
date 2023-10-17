
extends Node

# setup
func _ready():
	# Register Inputs
	_set_actions()
	_load_bindings()

# Gameplay settings
var FOV: int = 70

var actions = [
	"move_forward",
	"move_backward",
	"move_left",
	"move_right",
	"interact",
	"fire",
	"jump",
	"sprint",
	"crouch",
	"exit",
	"ads",
	"use_scanner",
	"primary_weapon",
	"secondary_weapon",
	"tertiary_weapon",
	"heal",
	"reload"
]

# Key Bindings
func _set_actions():
	for action in actions:
		InputMap.add_action(action)
		
func _link_key(key: int):
	var event = InputEventKey.new()
	event.scancode = key
	return event

func _link_mb(mb: int):
	var event = InputEventMouseButton.new()
	event.button_index = mb
	return event

# Load Key Bindings from .json
func _load_bindings():
	InputMap.action_add_event("move_forward", _link_key(KEY_W))
	InputMap.action_add_event("move_backward", _link_key(KEY_S))
	InputMap.action_add_event("move_left", _link_key(KEY_A))
	InputMap.action_add_event("move_right", _link_key(KEY_D))
	InputMap.action_add_event("interact", _link_key(KEY_E))
	InputMap.action_add_event("fire", _link_mb(BUTTON_LEFT))
	InputMap.action_add_event("jump", _link_key(KEY_SPACE))
	InputMap.action_add_event("sprint", _link_key(KEY_SHIFT))
	InputMap.action_add_event("crouch", _link_key(KEY_CONTROL))
	InputMap.action_add_event("exit", _link_key(KEY_ESCAPE))
	InputMap.action_add_event("ads", _link_mb(BUTTON_RIGHT))
	InputMap.action_add_event("use_scanner", _link_key(KEY_Q))
	InputMap.action_add_event("primary_weapon", _link_key(KEY_1))
	InputMap.action_add_event("secondary_weapon", _link_key(KEY_2))
	InputMap.action_add_event("tertiary_weapon", _link_key(KEY_3))
	InputMap.action_add_event("heal", _link_key(KEY_4))
	InputMap.action_add_event("reload", _link_key(KEY_R))

# For now, all events are set to defaults

# Graphical Settings

# Load graphical settings from .json

# Audio Settings
const MAX_AUDIO: float = 100.0
const MIN_AUDIO: float = 0.0

var volume: float = MAX_AUDIO
var music_volume: float = MAX_AUDIO
var environment_volume: float = MAX_AUDIO

# Load Audio from .json
