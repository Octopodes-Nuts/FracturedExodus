###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends CharacterBody3D

@export var health: float = 100.0

@export var gravity = 20.0

var gravity_direction: Vector3
var movement: Vector3 = Vector3()

var home: Area3D

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
	if not is_on_floor():
		gravity_direction += Vector3.DOWN * gravity * delta
	else:
		gravity_direction = -get_floor_normal()

	movement.z = gravity_direction.z
	movement.x = gravity_direction.x
	movement.y = gravity_direction.y

	#warning-ignore:return_value_discarded
	set_velocity(movement)
	set_up_direction(Vector3.UP)
	move_and_slide()
