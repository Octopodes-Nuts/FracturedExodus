extends KinematicBody

export var health: float = 100.0

export var gravity = 20.0

var gravity_vec: Vector3
var movement: Vector3 = Vector3()

var home: Area

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
		gravity_vec += Vector3.DOWN * gravity * delta
	else:
		gravity_vec = -get_floor_normal()

	movement.z = gravity_vec.z
	movement.x = gravity_vec.x
	movement.y = gravity_vec.y

	#warning-ignore:return_value_discarded
	move_and_slide(movement, Vector3.UP)
