###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Weapon

class_name Gun

var audio_player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
var bolt_pull_stream: AudioStreamPlayer3D = AudioStreamPlayer3D.new()

@onready var BulletScene = preload("res://behavior/player/weapons/Bullet.tscn")

@export var clip_size: int = 4
var current_clip: int
@export var ammo_pool: int = 10
var current_reserve: int = ammo_pool

@export var gun_type: WeaponRegister.GunType = WeaponRegister.GunType.RIFLE

@export var model: Mesh
@export var fire_sound: AudioStream
@export var bolt_pull_sound: AudioStream
@export var ads_animation: String = "none"
@export var fire_animation: String = "none"
@export var cock_animation: String = "none"
@export var reload_animation: String = "none"
@export var player: AnimationPlayer
@export var cycle_time: float = 0.7

@export var bullet_damage: float
@export var bullet_speed: float
@export var bullet_lifetime: float
@export var bullet_spread: float # the hipfire spread for this gun

var current_cycle: float = 0.0
var muzzle_smoke: GPUParticles3D

func _ready():
	super._ready()
	# set up envrionment
	audio_player.max_distance = 1200
	audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	bolt_pull_stream.max_distance = 10
	current_clip = clip_size
	self.add_child(audio_player)
	self.add_child(bolt_pull_stream)
	muzzle_smoke = get_node_or_null("MuzzleSmoke")
	_local_ready()
	
func _local_ready():
	pass

func _process(delta):
	if current_cycle > 0:
		current_cycle -= delta

@rpc("call_local","any_peer")
func play_sounds_and_anims():
	player.play(fire_animation)
	
	audio_player.stream = fire_sound
	bolt_pull_stream.stream = bolt_pull_sound
	audio_player.play()
	bolt_pull_stream.play()

func _use():
	if current_clip > 0 and current_cycle <= 0:

		play_sounds_and_anims.rpc()
		if muzzle_smoke:
			muzzle_smoke.restart()
			muzzle_smoke.emitting = true
		current_cycle = cycle_time

		_spawn_bullet.rpc_id(1, {
			"speed": bullet_speed,
			"origin": muzzle_end.global_transform.origin,
			"dmg": definition.base_damage,
			"ang": muzzle_end.global_rotation,
			"lifetime": bullet_lifetime,
			"ads": ads,
			"spread": bullet_spread,
			"type": gun_type,
			"shooter": multiplayer.get_unique_id()
		})

		# spawn a bullet
		# var bullet = BulletScene.instantiate()
		# Global.spawn_parent.add_child(bullet)
		# bullet.set_properties(
		# 	bullet_speed,
		# 	muzzle_end.global_transform.origin,
		# 	bullet_damage,
		# 	muzzle_end.global_rotation,
		# 	bullet_lifetime,
		# 	ads,
		# 	bullet_spread
		# )
		current_clip -= 1

	else:
		# player play weapon click
		pass

@rpc("any_peer")
func _spawn_bullet(dict: Dictionary):
	var bullet = BulletScene.instantiate()
	Global.bullet_spawn.add_child(bullet)
	bullet.set_properties(
		dict["speed"],
		dict["origin"],
		dict["dmg"],
		dict["ang"],
		dict["lifetime"],
		dict["ads"],
		dict["spread"],
		dict["type"],
		dict.get("shooter", 0)
	)

func _reload():
	player.play(reload_animation)
	# increase weapon inside animation, but that is too 
	# involved for this point
	current_clip = clip_size
	
func get_ammo():
	return [current_clip, current_reserve]
