extends Area3D

func _on_body_entered(body):
	if body.has_method('noise'):
		print("noise!")
		body.noise(global_transform.origin)
