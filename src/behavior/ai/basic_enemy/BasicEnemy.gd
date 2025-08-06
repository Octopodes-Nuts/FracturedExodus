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


enum AwarenessState {
	IDLE,
	SCAN,
	PATROL,
	AWARE,
	PERSUIT,
	RETREAT
}


var Awareness: AwarenessState = AwarenessState.IDLE

# on the noise function, the creator of the noise is assigned as the target and 
# the ai should turn to look at the player and commence chase
func noise(direction: Vector3):
	if Awareness != AwarenessState.PERSUIT or \
		Awareness != AwarenessState.RETREAT:
		Awareness = AwarenessState.AWARE
		update_target_location(direction)

func _ready():
	pass # Replace with function body.

func hit(damage: float):
	health -= damage
	if health <= 0:
		_die()
	print("Hit " + str(damage))

func _die():
	queue_free()

@export var scan_time: float = 1.5
@export var current_scan_time: float = 0.0

# This step is to evaluate what the enemy can see
# And make a decision as to its current state
func evaluate(delta):
	if Awareness == AwarenessState.IDLE:
		# find a random position to move to
		randomize()
		var positive_x = randf_range(5.0, 10.0)
		var negative_x = randf_range(-10.0, -5.0)
		
		var positive_y = randf_range(5.0, 10.0)
		var negative_y = randf_range(-10.0, -5.0)
		
		var x = 0
		if abs(negative_x) > positive_x:
			x = negative_x
		else:
			x = positive_x
		
		var z = 0
		if abs(negative_y) > positive_y:
			x = negative_y
		else:
			x = positive_y
			
		Awareness = AwarenessState.PATROL

		var target = global_transform.origin + Vector3(x, 0, z)
		update_target_location(target)
		
		return (navigation.get_next_path_position() - global_transform.origin).normalized()

	elif Awareness == AwarenessState.PATROL:
		# continue along current path
		# patrolling should take place within a certain range of the AI's home location
		if navigation.distance_to_target() < 2.0:
			current_scan_time = scan_time
			Awareness = AwarenessState.SCAN
		else:
			return (navigation.get_next_path_position() - global_transform.origin).normalized()

	elif Awareness == AwarenessState.SCAN:
		current_scan_time -= delta
		if current_scan_time <= 0:
			Awareness = AwarenessState.IDLE
		
		return Vector3.ZERO

	elif Awareness == AwarenessState.AWARE:
		
		if navigation.distance_to_target() < 2.0:
			Awareness = AwarenessState.IDLE
		else:
			return (navigation.get_next_path_position() - global_transform.origin).normalized()

	elif Awareness == AwarenessState.PERSUIT:
		# actively chase player
		pass
	elif Awareness == AwarenessState.RETREAT:
		# run away from player or toward cover
		pass
		
	return Vector3.ZERO

func _physics_process(delta):
	var heading: Vector3 = Vector3.ZERO

	# this can be sped up significantly, this calculation does not have to be done every frame
	# if navigation.target_position != Vector3.ZERO or not navigation.target_reached:
	# 	heading = (navigation.get_next_path_position() - current_location).normalized() * speed * delta

	# evaluate should not happen every frame
	heading = evaluate(delta) * speed * delta

	if not is_on_floor():
		gravity_direction += Vector3.DOWN * gravity * delta
	else:
		gravity_direction = -get_floor_normal()


	
	# this movement should essential always happen
	movement.z = gravity_direction.z
	movement.x = gravity_direction.x
	movement.y = gravity_direction.y

	movement.z += heading.z
	movement.x += heading.x

	#warning-ignore:return_value_discarded
	set_velocity(movement)
	set_up_direction(Vector3.UP)
	move_and_slide()
