extends Resource

class_name SettingsRes

@export var volume: float = 0.5
@export var music_volume: float = 0.5
@export var sfx_volume: float = 0.5
@export var fullscreen: bool = true
@export var resolution: Vector2i = Vector2i(1920, 1080)
@export var language: String = "en"
@export var show_tutorials: bool = true

@export var key_binds: Dictionary = {
		"move_forward":     "KEY_W",
		"move_backward":    "KEY_S",
		"move_left":        "KEY_A",
		"move_right":       "KEY_D",
		"interact":         "KEY_E",
		"fire":             "MOUSE_BUTTON_LEFT",
		"jump":             "KEY_SPACE",
		"sprint":           "KEY_SHIFT",
		"crouch":           "KEY_C",
		"exit":             "KEY_ESC",
		"ads":              "MOUSE_BUTTON_RIGHT",
		"use_scanner":      "KEY_F",
		"primary_weapon":   "KEY_1",
		"secondary_weapon": "KEY_2",
		"tertiary_weapon":  "KEY_3",
		"reload":           "KEY_R",
		"medpack":			"KEY_4",
		"equipment_1":      "KEY_5",
		"equipment_2":      "KEY_6"
}

var default_key_binds: Dictionary = {
		"move_forward":     "KEY_W",
		"move_backward":    "KEY_S",
		"move_left":        "KEY_A",
		"move_right":       "KEY_D",
		"interact":         "KEY_E",
		"fire":             "MOUSE_BUTTON_LEFT",
		"jump":             "KEY_SPACE",
		"sprint":           "KEY_SHIFT",
		"crouch":           "KEY_C",
		"exit":             "KEY_ESC",
		"ads":              "MOUSE_BUTTON_RIGHT",
		"use_scanner":      "KEY_F",
		"primary_weapon":   "KEY_1",
		"secondary_weapon": "KEY_2",
		"tertiary_weapon":  "KEY_3",
		"reload":           "KEY_R",
		"medpack":			"KEY_4",
		"equipment_1":      "KEY_5",
		"equipment_2":      "KEY_6"
}

var languages: Array = ["en", "es", "fr", "de", "it", "jp", "cn", "kr"]
var resolutions: Array = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]
