extends PanelContainer

@onready var WindowMode = $VBoxContainer/ScreenSize/Panel/VBoxContainer/HBoxContainer/WindowModeButton
@onready var TAA = $VBoxContainer/MarginContainer/Panel/VBoxContainer/TAA/TAACheckbox
@onready var MSAA = $VBoxContainer/MarginContainer/Panel/VBoxContainer/MSAA/MSAAOptions
@onready var SSAA = $VBoxContainer/MarginContainer/Panel/VBoxContainer/SSAA/SSAAOptions
@onready var Resolution = $VBoxContainer/ScreenSize/Panel/VBoxContainer/HBoxContainer2/Resolution

# Index in the OptionButton -> DisplayServer/Viewport enum value, in popup order.
const WINDOW_MODES = [
	DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, # Full Screen
	DisplayServer.WINDOW_MODE_FULLSCREEN,            # Borderless
	DisplayServer.WINDOW_MODE_WINDOWED,              # Windowed
]

const MSAA_MODES = [
	Viewport.MSAA_2X,
	Viewport.MSAA_4X,
	Viewport.MSAA_8X,
	Viewport.MSAA_DISABLED,
]

# Godot has no native SMAA, so it falls back to FXAA; only "Disabled" truly disables.
const SSAA_MODES = [
	Viewport.SCREEN_SPACE_AA_FXAA, # FXAA
	Viewport.SCREEN_SPACE_AA_FXAA, # SMAA
	Viewport.SCREEN_SPACE_AA_DISABLED,
]

func _ready() -> void:
	var settings_res := Settings.settings_res
	WindowMode.select(WINDOW_MODES.find(settings_res.screen_size))
	MSAA.select(MSAA_MODES.find(settings_res.msaa))
	SSAA.select(SSAA_MODES.find(settings_res.ssaa))
	TAA.button_pressed = settings_res.TAA
	Resolution.select(settings_res.resolutions.find(settings_res.resolution))


func _save_settings() -> void:
	ResourceSaver.save(Settings.settings_res, "user://Settings.res")


func _on_ssaa_options_item_selected(index: int) -> void:
	var mode = SSAA_MODES[index]
	Settings.settings_res.ssaa = mode
	get_viewport().screen_space_aa = mode
	_save_settings()


func _on_msaa_options_item_selected(index: int) -> void:
	var mode = MSAA_MODES[index]
	Settings.settings_res.msaa = mode
	get_viewport().msaa_3d = mode
	_save_settings()


func _on_taa_checkbox_toggled(toggled_on: bool) -> void:
	Settings.settings_res.TAA = toggled_on
	get_viewport().use_taa = toggled_on
	_save_settings()


func _on_window_mode_button_item_selected(index: int) -> void:
	var mode = WINDOW_MODES[index]
	Settings.settings_res.screen_size = mode
	DisplayServer.window_set_mode(mode)
	_save_settings()


func _on_resolution_item_selected(index: int) -> void:
	var resolution = Settings.settings_res.resolutions[index]
	Settings.settings_res.resolution = resolution
	DisplayServer.window_set_size(resolution)
	_save_settings()
