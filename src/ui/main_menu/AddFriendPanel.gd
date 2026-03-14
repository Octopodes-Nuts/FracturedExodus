extends Panel

@onready var accept_button = $accept_button
@onready var friend_code = $friend_code

signal friend_request_ready(friend_code: String)

func _ready() -> void:
	accept_button.pressed.connect(_emit_friend_request_ready)
	
func _emit_friend_request_ready():
	emit_signal("friend_request_ready", friend_code.text)
	hide()
