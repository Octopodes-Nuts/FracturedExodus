extends Node

class_name Gun

export var model: Mesh
export var ads_animation: String
export var fire_animation: String
export var cock_animation: String
export var reload_animation: String
var player: AnimationPlayer
export var cycle_time: float = 0.7

var muzzle_end: Spatial

export var bullet_damage: float
export var bullet_speed: float
export var bullet_lifetime: float


var current_cycle: float = 0.0
# Called when the node enters the scene tree for the first time.
func _ready():
	# set up envrionment
	pass

func _process(delta):
	if current_cycle > 0:
		current_cycle -= delta

func _fire():
	player.play(fire_animation)
	current_cycle = cycle_time

	# spawn a bullet
	var bullet = Bullet.new()
	bullet.set_properties(
		bullet_speed, muzzle_end.transform.basis,
		bullet_damage, muzzle_end.rotation,
		bullet_lifetime
		)
	# hand the bullet to the scene as a top level child
