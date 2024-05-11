extends Area3D

@export var sprint_size = 2.0;
@export var crouch_size = 2.0;
@export var default_size = 1.0;

func _on_body_entered(body):
	if body.has_method('noise'):
		print("noise!")
		body.noise(global_transform.origin)


func _input(_event):

	# This should be its own function that takes in the current player state during the phys
	# process

	if Input.is_action_just_pressed("sprint"):
		scale = (Vector3.ONE * sprint_size)
		print(scale)
	
	if Input.is_action_just_released("sprint"):
		scale = (Vector3.ONE * default_size)
		print(scale)


func update_state(state: int):
	pass
