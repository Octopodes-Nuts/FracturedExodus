###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends CharacterBody3D

@onready var navigation: NavigationAgent3D = $navigation

@export var health: float = 100.0
@export var speed: float = 2.0

@export var gravity = 20.0

var gravity_direction: Vector3
var movement: Vector3 = Vector3()

var home: Area3D

func update_target_location(location):
	navigation.target_position = location

func noise(direction: Vector3):
	pass

func _ready():
	update_target_location(Vector3.ZERO)
	pass # Replace with function body.

func hit(damage: float):
	health -= damage
	if health <= 0:
		_die()
	print("Hit " + str(damage))

func _die():
	pass

# This step is to evaluate what the enemy can see
# And make a decision as to its current state
func evaluate():
	pass

func _physics_process(delta):
	var current_location = global_transform.origin
	var velocity = (navigation.get_next_path_position().normalized() - current_location) * speed * delta

	if not is_on_floor():
		gravity_direction += Vector3.DOWN * gravity * delta
	else:
		gravity_direction = -get_floor_normal()

	movement.z = gravity_direction.z
	movement.x = gravity_direction.x
	movement.y = gravity_direction.y

	movement.z += velocity.z
	movement.x += velocity.x
	movement.y += velocity.y

	#warning-ignore:return_value_discarded
	set_velocity(movement)
	set_up_direction(Vector3.UP)
	move_and_slide()
