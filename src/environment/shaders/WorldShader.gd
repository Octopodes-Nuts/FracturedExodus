extends ColorRect

@export var sun: DirectionalLight3D
@onready var vignette_timer: Timer = Timer.new()
var _downed: bool = false

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	Local.shader_rect = self
	vignette_timer.one_shot = true
	vignette_timer.wait_time = 0.5
	vignette_timer.timeout.connect(_return_to_black)
	add_child(vignette_timer)

func _process(_delta: float) -> void:
	if Local.host:
		return
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

func hit_effect():
	if _downed:
		return
	(material as ShaderMaterial).set_shader_parameter("hit", 1)
	(material as ShaderMaterial).set_shader_parameter("vignette_strength", 1.0)
	vignette_timer.start()

func set_downed(downed: bool) -> void:
	_downed = downed
	if downed:
		vignette_timer.stop()
		(material as ShaderMaterial).set_shader_parameter("hit", 1)
		(material as ShaderMaterial).set_shader_parameter("vignette_strength", 1.0)
	else:
		(material as ShaderMaterial).set_shader_parameter("hit", 0)
		(material as ShaderMaterial).set_shader_parameter("vignette_strength", 0.5)

func _return_to_black():
	if _downed:
		return
	(material as ShaderMaterial).set_shader_parameter("vignette_strength", 0.5)
	(material as ShaderMaterial).set_shader_parameter("hit", 0)
