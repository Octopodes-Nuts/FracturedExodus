###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Node

# setup
func _ready():
	# Register Inputs
	_set_actions()
	_load_bindings()

# Gameplay settings
var FOV: int = 70

var path_to_settings = "res://load/settings.json"

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
	"reload",
	"equipment_1",
	"equipment_2"
]

# Key Bindings
func _set_actions():
	for action in actions:
		InputMap.add_action(action)
		
func _link_key(key: int):
	var event = InputEventKey.new()
	event.keycode = key
	return event

func _link_mb(mb: int):
	var event = InputEventMouseButton.new()
	event.button_index = mb
	return event

var key_codes = {
	"KEY_0": KEY_0,
	"KEY_1": KEY_1,
	"KEY_2": KEY_2,
	"KEY_3": KEY_3,
	"KEY_4": KEY_4,
	"KEY_5": KEY_5,
	"KEY_6": KEY_6,
	"KEY_7": KEY_7,
	"KEY_8": KEY_8,
	"KEY_9": KEY_9,
	"KEY_A": KEY_A,
	"KEY_B": KEY_B,
	"KEY_C": KEY_C,
	"KEY_D": KEY_D,
	"KEY_E": KEY_E,
	"KEY_F": KEY_F,
	"KEY_G": KEY_G,
	"KEY_H": KEY_H,
	"KEY_I": KEY_I,
	"KEY_J": KEY_J,
	"KEY_K": KEY_K,
	"KEY_L": KEY_L,
	"KEY_M": KEY_M,
	"KEY_N": KEY_N,
	"KEY_O": KEY_O,
	"KEY_P": KEY_P,
	"KEY_Q": KEY_Q,
	"KEY_R": KEY_R,
	"KEY_S": KEY_S,
	"KEY_T": KEY_T,
	"KEY_U": KEY_U,
	"KEY_V": KEY_V,
	"KEY_W": KEY_W,
	"KEY_X": KEY_X,
	"KEY_Y": KEY_Y,
	"KEY_Z": KEY_Z,
	"KEY_SHIFT": KEY_SHIFT,
	"KEY_SPACE": KEY_SPACE,
	"KEY_CTRL": KEY_CTRL,
	"KEY_ESC": KEY_ESCAPE,

	"MOUSE_BUTTON_LEFT": MOUSE_BUTTON_LEFT,
	"MOUSE_BUTTON_RIGHT": MOUSE_BUTTON_RIGHT,
}

# Load Key Bindings from .json
func _load_bindings():
	# InputMap.action_add_event("move_forward", _link_key(KEY_W))
	# InputMap.action_add_event("move_backward", _link_key(KEY_S))
	# InputMap.action_add_event("move_left", _link_key(KEY_A))
	# InputMap.action_add_event("move_right", _link_key(KEY_D))
	# InputMap.action_add_event("interact", _link_key(KEY_E))
	# InputMap.action_add_event("fire", _link_mb(MOUSE_BUTTON_LEFT))
	# InputMap.action_add_event("jump", _link_key(KEY_SPACE))
	# InputMap.action_add_event("sprint", _link_key(KEY_SHIFT))
	# InputMap.action_add_event("crouch", _link_key(KEY_CTRL))
	# InputMap.action_add_event("exit", _link_key(KEY_ESCAPE))
	# InputMap.action_add_event("ads", _link_mb(MOUSE_BUTTON_RIGHT))
	# InputMap.action_add_event("use_scanner", _link_key(KEY_Q))
	# InputMap.action_add_event("primary_weapon", _link_key(KEY_1))
	# InputMap.action_add_event("secondary_weapon", _link_key(KEY_2))
	# InputMap.action_add_event("tertiary_weapon", _link_key(KEY_3))
	# InputMap.action_add_event("reload", _link_key(KEY_R))
	# InputMap.action_add_event("equipment_1", _link_key(KEY_4))
	# InputMap.action_add_event("equipment_2", _link_key(KEY_5))
	var settings_text = FileAccess.get_file_as_string(path_to_settings)
	var settings = JSON.parse_string(settings_text)
	var controls = settings["controls"]
	for control in controls.keys():
		if controls[control].substr(0, 3) == "KEY":
			InputMap.action_add_event(
				control, _link_key(key_codes[controls[control]]))
		else:
			InputMap.action_add_event(
				control, _link_mb(key_codes[controls[control]]))

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
