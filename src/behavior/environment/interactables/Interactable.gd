###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Area3D

class_name Interactable

@onready var Global = get_node('/root/Global')

var interactable: bool = false
var auto_interact: bool = false
var interaction_in_process = false
var display_text = "Interact"
var interact_action = "interact"

func _physics_process(_delta):
		_local_physics_step(_delta)

# what to do upon interaction with object
func _interact(_other: Node):
	pass

# report interaction to UI, includes optional graphic or words?
func _ui_report():
	pass

func _local_physics_step(_delta):
	pass

func _is_local_player_body(body: Node) -> bool:
	if body == null:
		return false
	if not body.has_method("_is_local_player"):
		return false
	return body._is_local_player()

func _on_interactable_body_entered(body:Node):
	if not _is_local_player_body(body):
		return
	if body.has_method('register_interaction'):
		_add_interaction(body)
		body.register_interaction(self)
		Local.HUD.get_child(2).display_text(null, display_text)

func _on_interactable_body_exited(body):
	if not _is_local_player_body(body):
		return
	if body.has_method('remove_interaction'):
		body.remove_interaction(self)
		_remove_interaction(body)
		Local.HUD.get_child(2).clear()

func _refresh(body: Node):
	_on_interactable_body_entered(body)
	_on_interactable_body_exited(body)

func _remove_interaction(_node: Node):
	pass

func _add_interaction(_node: Node):
	pass
