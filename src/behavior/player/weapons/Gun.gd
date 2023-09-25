extends Node

class_name Gun

export var model: Mesh
export var ads_animation: Animation
export var fire_animation: Animation
export var cock_animation: Animation
export var reload_animation: Animation
export var cycle_time: float = 0.7

# Called when the node enters the scene tree for the first time.
func _ready():
	# set up envrionment
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
