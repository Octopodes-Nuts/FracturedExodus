extends Gun

class_name DefaultShotgun

@export var num_pellets: int = 15

func _init():
	faction = Factions.Enum.DEFAULT
	slots[ClassRegister.Classes.DEFAULT] = [1]
	key = "DefaultShotgun"

func _local_ready():
	fire_sound =\
		load("res://behavior/player/weapons/guns/default_shotgun/default_shotgun.mp3")


func _use():

	if current_clip > 0:

		play_sounds_and_anims.rpc()
		current_cycle = cycle_time

		for i in range(num_pellets):
			_spawn_bullet.rpc_id(1, {
				"speed": bullet_speed,
				"origin": muzzle_end.global_transform.origin,
				"dmg": bullet_damage,
				"ang": muzzle_end.global_rotation,
				"lifetime": bullet_lifetime,
				"ads": ads,
				"spread": bullet_spread,
				"type": gun_type,
				"shooter": multiplayer.get_unique_id()
			})

		current_clip -= 1

	else:
		# player plays weapon click
		pass
