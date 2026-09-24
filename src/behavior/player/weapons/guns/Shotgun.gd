extends Gun

class_name Shotgun

@export var pellet_count: int = 8

func _shoot():
	for i in range(pellet_count):
		_spawn_bullet.rpc_id(1, {
			"speed": definition.muzzle_velocity,
			"origin": muzzle_end.global_transform.origin,
			"dmg": definition.base_damage,
			"ang": muzzle_end.global_rotation,
			"lifetime": bullet_lifetime,
			"ads": ads,
			"spread": bullet_spread,
			"type": definition.gun_type,
			"shooter": multiplayer.get_unique_id()
		})
