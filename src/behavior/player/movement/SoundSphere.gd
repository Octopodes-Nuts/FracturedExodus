extends Area3D

func _on_body_entered(body):
	if body.has_method('noise'):
		body.noise(global_transform.origin)
