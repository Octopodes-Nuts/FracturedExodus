
extends Node

# setup
func _ready():
    # Register all actions
    _set_actions()
    _load_bindings()

# Gameplay settings
var FOV: int

var actions = [
    "move_forward",
    "move_backward",
    "move_left",
    "move_right",
    "jump",
    "exit"
]

# Key Bindings
func _set_actions():
    for action in actions:
        InputMap.add_action(action)

# Load Key Bindings from .json
func _load_bindings():
    InputMap.action_add_event("move_forward", InputEvent.KEY_W)
    InputMap.action_add_event("move_backward", InputEvent.KEY_S)
    InputMap.action_add_event("move_left", InputEvent.KEY_A)
    InputMap.action_add_event("move_right", InputEvent.KEY_D)
    InputMap.action_add_event("jump", InputEvent.KEY_SPACE)
    InputMap.action_add_event("exit", InputEvent.KEY_ESCAPE)

# For now, all events are set to defaults

# Graphical Settings
enum AntiAliasing {
	
}

# Load graphical settings from .json

# Audio Settings
const MAX_AUDIO: float = 100.0
const MIN_AUDIO: float = 0.0

var volume: float = MAX_AUDIO
var music_volume: float = MAX_AUDIO
var environment_volume: float = MAX_AUDIO

# Load Audio from .json
