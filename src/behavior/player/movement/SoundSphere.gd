extends Area

# this should be changed to be continuous
func _on_sound_sphere_body_entered(body):
	if body.has_method('noise'):
		body.noise(global_transform.origin)
