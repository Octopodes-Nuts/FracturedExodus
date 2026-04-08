extends ColorRect

@export var sun: DirectionalLight3D

func _process(_delta: float) -> void:
	if sun == null:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var sun_world_pos := camera.global_position - sun.global_transform.basis.z * 10000.0
	var sun_screen_pos := camera.unproject_position(sun_world_pos)
	var viewport_size := get_viewport().get_visible_rect().size
	var sun_uv := sun_screen_pos / viewport_size
	(material as ShaderMaterial).set_shader_parameter("sun_uv", sun_uv)
