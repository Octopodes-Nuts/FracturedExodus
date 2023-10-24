###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Weapon

class_name Gun

var audio_player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
var bolt_pull_stream: AudioStreamPlayer3D = AudioStreamPlayer3D.new()

@onready var Global = get_node('/root/Global')
@onready var Types = get_node('/root/Types')
@onready var Local = get_node('/root/Local')

@export var clip_size: int = 4
var current_clip: int
@export var ammo_pool: int = 10

@export var model: Mesh
var fire_sound: AudioStreamMP3
var bolt_pull_sound: AudioStreamMP3
@export var ads_animation: String = "none"
@export var fire_animation: String = "none"
@export var cock_animation: String = "none"
@export var reload_animation: String = "none"
var player: AnimationPlayer = AnimationPlayer.new()
@export var cycle_time: float = 0.7

@export var bullet_damage: float
@export var bullet_speed: float
@export var bullet_lifetime: float
@export var bullet_spread: float # the hipfire spread for this gun

var current_cycle: float = 0.0

func _ready():
	# set up envrionment
	current_clip = clip_size
	self.add_child(audio_player)
	self.add_child(bolt_pull_stream)
	type = WeaponType.GUN
	_local_ready()
	
func _local_ready():
	pass

func _process(delta):
	if current_cycle > 0:
		current_cycle -= delta
	
	if current_cycle <= 0 and\
		Input.is_action_just_pressed('fire') and\
		active and Local.input_active:
		_use()
	
	if Input.is_action_just_pressed('reload') and\
		active and Local.input_active:
		_reload()
	

func _use():
	if current_clip > 0:

		player.play(fire_animation)
		current_cycle = cycle_time

		audio_player.stream = fire_sound
		bolt_pull_stream.stream = bolt_pull_sound
		audio_player.play()
		bolt_pull_stream.play()

		# spawn a bullet
		var bullet = Bullet.new()
		bullet.set_properties(
			bullet_speed,
			muzzle_end.global_transform.origin,
			bullet_damage,
			muzzle_end.global_rotation,
			bullet_lifetime,
			Global.map_root,
			ads,
			bullet_spread
		)
		current_clip -= 1

	else:
		# player play weapon click
		pass

func _reload():
	player.play(reload_animation)
	# increase weapon inside animation, but that is too 
	# involved for this point
	current_clip = clip_size
