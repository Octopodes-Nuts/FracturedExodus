extends Gun

class_name DefaultShotgun

@export var num_pellets: int = 15

func _init():
	faction = Factions.DEFAULT

func _local_ready():
	fire_sound =\
		load("res://behavior/player/weapons/guns/default_shotgun/default_shotgun.mp3")
	key = "DefaultShotgun"


func _use():

	if current_clip > 0:

		player.play(fire_animation)
		current_cycle = cycle_time

		audio_player.stream = fire_sound
		bolt_pull_stream.stream = bolt_pull_sound
		audio_player.play()
		bolt_pull_stream.play()

		for i in range(num_pellets):
			_spawn_bullet.rpc_id(1, {
				"speed": bullet_speed,
				"origin": muzzle_end.global_transform.origin,
				"dmg": bullet_damage,
				"ang": muzzle_end.global_rotation,
				"lifetime": bullet_lifetime,
				"ads": ads,
				"spread": bullet_spread
			})

		current_clip -= 1

	else:
		# player plays weapon click
		pass
