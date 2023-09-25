extends RayCast

class_name Bullet

# Add a "damage class" that describes how bullets behave

var _speed: float
var _damage: float
var _lifetime: float

# Set bullet properties
func set_properties(speed: float,
		origin: Vector3,
		damage: float,
		angle: Vector3,
		lifetime: float):
	_speed = speed
	transform.basis = origin
	_damage = damage
	rotation = angle
	_lifetime = lifetime

	# set initial properties

func _physics_process(_delta):
	# move and stretch bullet path

	# test if hitting anything
	if is_colliding():
		var test = get_collider()

		if test.has_method("hit"):
			test.hit()
		else: # test for wall penetration
			pass