###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Node

var settings_res: SettingsRes

# setup
func _ready():

	if ResourceLoader.exists("res://load/Settings.res"):
		settings_res = ResourceLoader.load("res://load/Settings.res")
	else:
		settings_res = SettingsRes.new()
		ResourceSaver.save(settings_res, "res://load/Settings.res")
	
	key_binds = settings_res.key_binds
	volume = settings_res.volume
	music_volume = settings_res.music_volume
	environment_volume = settings_res.sfx_volume

	_set_actions()
	_load_bindings()
		

# Gameplay settings
var FOV: int = 70
var key_binds: Dictionary
var volume: float
var music_volume: float
var environment_volume: float

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
	"equipment_2",
	"medpack",
	"help"
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

	#function keys
	"KEY_F1": KEY_F1,
	"KEY_F2": KEY_F2,
	"KEY_F3": KEY_F3,
	"KEY_F4": KEY_F4,
	"KEY_F5": KEY_F5,
	"KEY_F6": KEY_F6,
	"KEY_F7": KEY_F7,
	"KEY_F8": KEY_F8,
	"KEY_F9": KEY_F9,
	"KEY_F10": KEY_F10,
	"KEY_F11": KEY_F11,
	"KEY_F12": KEY_F12,
	"KEY_F13": KEY_F13,
	"KEY_F14": KEY_F14,
	"KEY_F15": KEY_F15,
	"KEY_F16": KEY_F16,
	"KEY_F17": KEY_F17,
	"KEY_F18": KEY_F18,
	"KEY_F19": KEY_F19,
	"KEY_F20": KEY_F20,
	"KEY_F21": KEY_F21,
	"KEY_F22": KEY_F22,
	"KEY_F23": KEY_F23,
	"KEY_F24": KEY_F24,
	"KEY_F25": KEY_F25,
	"KEY_F26": KEY_F26,
	"KEY_F27": KEY_F27,
	"KEY_F28": KEY_F28,
	"KEY_F29": KEY_F29,
	"KEY_F30": KEY_F30,
	"KEY_F31": KEY_F31,
	"KEY_F32": KEY_F32,
	"KEY_F33": KEY_F33,
	"KEY_F34": KEY_F34,
	"KEY_F35": KEY_F35,

	"MOUSE_BUTTON_LEFT": MOUSE_BUTTON_LEFT,
	"MOUSE_BUTTON_RIGHT": MOUSE_BUTTON_RIGHT,
	"MOUSE_BUTTON_MIDDLE": MOUSE_BUTTON_MIDDLE,
	"MOUSE_BUTTON_WHEEL_DOWN": MOUSE_BUTTON_WHEEL_DOWN,
	"MOUSE_BUTTON_WHEEL_UP": MOUSE_BUTTON_WHEEL_UP,
	"MOUSE_BUTTON_WHEEL_LEFT": MOUSE_BUTTON_WHEEL_LEFT,
	"MOUSE_BUTTON_WHEEL_RIGHT": MOUSE_BUTTON_WHEEL_RIGHT,
	"MOUSE_BUTTON_XBUTTON1": MOUSE_BUTTON_XBUTTON1,
	"MOUSE_BUTTON_XBUTTON2": MOUSE_BUTTON_XBUTTON2
}

# Load Key Bindings from .json
func _load_bindings():
	var controls = key_binds
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

# Load Audio from .json
