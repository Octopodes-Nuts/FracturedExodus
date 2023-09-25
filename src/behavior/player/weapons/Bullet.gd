extends RayCast

# Add a "damage class" that describes how bullets behave

var _speed: float
var _origin: Vector3
var _damage: float
var _angle: Vector3

# Set bullet properties
func set_properties(speed: float,
		origin: Vector3,
		damage: float,
		angle: Vector3):
	_speed = speed
	_origin = origin
	_damage = damage
	_angle = angle

func _physics_process(_delta):
	# move and stretch bullet path

	# test if hitting anything
	if is_colliding():
		var test = get_collider()

		if test.has_method("hit"):
			test.hit()
		else: # test for wall penetration
			pass