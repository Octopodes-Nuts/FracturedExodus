extends RayCast

class_name Bullet

# Add a "damage class" that describes how bullets behave

var _speed: float
var _damage: float
var _lifetime: float = 1.0 # set to non zero number so bullet is not immediately killed
var normal_direction_ray: Vector3 = Vector3()

func _ready():
	enabled = true

# Set bullet properties
func set_properties(
		speed: float,
		origin: Vector3,
		damage: float,
		angle: Vector3,
		lifetime: float):
	_speed = speed
	transform.basis = origin
	_damage = damage
	rotation = angle
	_lifetime = lifetime
	set_norm_ray()


func _physics_process(delta):
	# move and stretch bullet path
	set_cast_to((2 * (Vector3.FORWARD * _speed * delta)) #Bullet forward
			 + Vector3.FORWARD * 2 ) #overlap
	global_transform.origin += ((normal_direction_ray) * _speed * delta )

	# test if hitting anything
	if is_colliding():
		var test = get_collider()

		if test.has_method("hit"):
			test.hit()
		else: # test for wall penetration
			pass
	_lifetime -= delta

	#kill bullet
	if _lifetime <= 0.0:
		queue_free()


func set_norm_ray():

	normal_direction_ray.x = - sin( global_rotation.y ) * cos( global_rotation.x )
	normal_direction_ray.y = sin( global_rotation.x )
	normal_direction_ray.z = - cos( global_rotation.y ) * cos( global_rotation.x ) 
	normal_direction_ray = normal_direction_ray.normalized()