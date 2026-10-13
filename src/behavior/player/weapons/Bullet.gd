###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends RayCast3D

class_name Bullet

# Add a "damage class" that describes how bullets behave

var _speed: float
var _damage: float
var _lifetime: float = 1.0 # set to non zero number so bullet is not immediately killed
var _type: WeaponRegister.GunType
var _origin: Vector3
var normal_direction_ray: Vector3 = Vector3()
var headshot_mult = 2.0
var _shooter_id: int = 0

func _ready():
	enabled = true
	collide_with_areas = true
	hit_from_inside = true

# Set bullet properties
func set_properties(
		speed: float,
		origin: Vector3,
		damage: float,
		angle: Vector3,
		lifetime: float,
		ads: bool = false,
		spread: float = 0.0,
		type: WeaponRegister.GunType = WeaponRegister.GunType.RIFLE,
		shooter_id: int = 0
	):
	_speed = speed
	_origin = origin
	global_transform.origin = origin
	_damage = damage
	global_rotation = angle
	if not ads:
		randomize()
		global_rotation += Vector3(
			randf_range(-spread, spread),
			randf_range(-spread, spread),
			randf_range(-spread, spread)
		)
	_lifetime = lifetime
	_type = type
	_shooter_id = shooter_id
	set_norm_ray()
	# Must cover at least one tick of travel at this speed - otherwise the
	# gap between this first ray and the first _physics_process move (which
	# advances speed * delta before any further ray is cast) goes untested.
	set_target_position(Vector3.FORWARD * _swept_segment_length(get_physics_process_delta_time()))

# Twice this tick's travel distance plus a flat overlap, so each ray
# reaches past where the NEXT move will land - overlapping the previous
# ray's reach and leaving no untested gap between ticks.
func _swept_segment_length(delta: float) -> float:
	return 2.0 * _speed * delta + 2.0

func _physics_process(delta):
	# move and stretch bullet path
	set_target_position(Vector3.FORWARD * _swept_segment_length(delta))
	global_transform.origin += ((normal_direction_ray) * _speed * delta )
	# test if hitting anything
	if is_colliding():
		var test = get_collider()
		# lookup damage multiplier based on distance and gun type
		# smooth transition between thresholds
		var distance = _origin.distance_to(get_collision_point())
		var damage_multiplier = 1.0
		var index = 0
		for dist_threshold in WeaponRegister.damage_lookup[_type].keys():
			if distance <= dist_threshold:
				var actual_mult = lerp(
					WeaponRegister.damage_lookup[_type][dist_threshold],
					WeaponRegister.damage_lookup[_type].values()[index - 1] if index > 1 else 1.0,
					(distance - WeaponRegister.damage_lookup[_type].keys()[index - 1] if index > 1 else 0) / (dist_threshold - (WeaponRegister.damage_lookup[_type].keys()[index - 2] if index > 1 else 0))
				)
				damage_multiplier = actual_mult
				break
			index += 1
		_damage *= damage_multiplier

		if test.has_method("hit"):
			test.hit(_damage, _shooter_id)
			self.queue_free()
		elif test.has_method("headshot"):
			test.headshot(_damage * headshot_mult, _shooter_id)
			self.queue_free()
		else:
			print("[BULLET] Collider has no hit/headshot methods")
	_lifetime -= delta

	#kill bullet
	if _lifetime <= 0.0:
		queue_free()
	force_raycast_update()

func set_norm_ray():

	normal_direction_ray.x = - sin( global_rotation.y ) * cos( global_rotation.x )
	normal_direction_ray.y = sin( global_rotation.x )
	normal_direction_ray.z = - cos( global_rotation.y ) * cos( global_rotation.x ) 
	normal_direction_ray = normal_direction_ray.normalized()
