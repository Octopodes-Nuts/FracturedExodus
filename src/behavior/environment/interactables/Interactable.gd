extends Spatial

class_name Interactable

onready var Global = get_node('/root/Global')

onready var interact_zone: Area = $area # specifies the area where interaction is possible

var interactable: bool = false

func _physics_process(_delta):
	if interactable and Input.is_action_just_pressed("interact"):
		_interact()

# what to do upon interaction with object
func _interact():
	pass

# report interaction to UI, includes optional graphic or words?
func _ui_report():
	pass