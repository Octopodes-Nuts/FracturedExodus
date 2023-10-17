extends Area

class_name Interactable

onready var Global = get_node('/root/Global')

onready var interact_zone: Area = $area # specifies the area where interaction is possible

var interactable: bool = false
var auto_interact: bool = false
var interaction_in_process = false

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

# this needs to be rethought ... it must be confirmed that
# a player that is able to interact is interacting
# the way that it will work will need to be refactored to work over
# the network. This will be done by confirming the player id
# of the one who pressed the interact button with the one that is able to interact, 
# or by handlng this interaction on the player side. May be best to do it on the player side
func _on_interactable_body_entered(body:Node):
	if body.has_method('register_interaction'):
		body.register_interaction(self)
	pass # Replace with function body.

func _on_interactable_body_exited(body):
	if body.has_method('remove_interaction'):
		body.remove_interaction(self)
		_remove_interaction(body)

func _remove_interaction(_node: Node):
	pass
