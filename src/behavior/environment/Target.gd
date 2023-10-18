extends StaticBody3D

@export var hit_time: float = 1.0
var current_hit: float = 0.0

var hit_color: Material = load('res://debug/materials/debug_yellow.tres')
var start_color: Material

@onready var mesh: MeshInstance3D = $mesh

# Called when the node enters the scene tree for the first time.
func _ready():
	start_color = mesh.get_surface_override_material(0)


func _process(delta):
	if current_hit > 0.0:
		current_hit -= delta
		if current_hit <= 0.0:
			mesh.set_surface_override_material(0, start_color)

func hit(_damage: float):
	current_hit = hit_time
	mesh.set_surface_override_material(0, hit_color)
	
