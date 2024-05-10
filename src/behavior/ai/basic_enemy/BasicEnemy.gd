###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends CharacterBody3D

@onready var navigation: NavigationAgent3D = $navigation

@export var health: float = 100.0
@export var speed: float = 40.0

@export var gravity = 20.0

var gravity_direction: Vector3
var movement: Vector3 = Vector3()

var home: Area3D

func update_target_location(location):
	location.y = 0
	navigation.target_position = location
	print(location)


# on the noise function, the creator of the noise is assigned as the target and 
# the ai should turn to look at the player and commence chase
func noise(direction: Vector3):
	update_target_location(direction)

func _ready():
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
	var heading: Vector3 = Vector3.ZERO
	if navigation.target_position != Vector3.ZERO or not navigation.target_reached:
		heading = (navigation.get_next_path_position() - current_location).normalized() * speed * delta

	if not is_on_floor():
		gravity_direction += Vector3.DOWN * gravity * delta
	else:
		gravity_direction = -get_floor_normal()

	movement.z = gravity_direction.z
	movement.x = gravity_direction.x
	movement.y = gravity_direction.y

	movement.z += heading.z
	movement.x += heading.x

	#warning-ignore:return_value_discarded
	set_velocity(movement)
	set_up_direction(Vector3.UP)
	move_and_slide()
