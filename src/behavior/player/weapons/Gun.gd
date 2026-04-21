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
var current_reserve: int

@export var model: Mesh
@export var fire_sound: AudioStream
@export var bolt_pull_sound: AudioStream
@export var reload_animation: String = "none"
@export var cycle_time: float = 0.7

@export var bullet_lifetime: float
@export var bullet_spread: float # the hipfire spread for this gun

var current_cycle: float = 0.0
var muzzle_smoke: GPUParticles3D
var muzzle_blast: GPUParticles3D

var _anim_tree: AnimationTree
var _sm: AnimationNodeStateMachinePlayback
var _pending_fire: bool = false
const RUN_SPEED_THRESHOLD: float = 5.0

signal recoil(vertical: float, horizontal: float)

func _ready():
	super._ready()
	# set up envrionment
	audio_player.max_distance = 1200
	audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
	audio_player.unit_size = 75
	audio_player.panning_strength = 2
	bolt_pull_stream.max_distance = 10
	current_clip = clip_size
	current_reserve = ammo_pool
	self.add_child(audio_player)
	self.add_child(bolt_pull_stream)
	muzzle_smoke = get_node_or_null("MuzzleSmoke")
	muzzle_blast = get_node_or_null("MuzzleBlast")
	_local_ready()
	_anim_tree = $GunInHand/AnimationTree
	_sm = _anim_tree.get("parameters/playback")
	
func _local_ready():
	pass

func _set_active():
	super._set_active()
	_use_parent = get_parent().get_parent().get_parent() as DefaultController
	var gun_in_hand = get_node_or_null("GunInHand")
	if gun_in_hand:
		gun_in_hand.visible = _use_parent != null and _use_parent._is_local_player()
	if _sm:
		_sm.start("Raise")

func _set_inactive():
	super._set_inactive()
	_pending_fire = false
	if _sm:
		_sm.travel("Stow")

func _process(delta):
	if current_cycle > 0:
		current_cycle -= delta
	if not active or not _sm:
		return
	var current := _sm.get_current_node()
	if ads and current in ["Idle", "Fire"]:
		_sm.travel("ADS")
	elif not ads and current == "ADS":
		_sm.travel("Idle")
	if not _use_parent:
		return
	var speed := _use_parent.velocity.length()
	if current == "Idle" and speed > RUN_SPEED_THRESHOLD:
		_sm.travel("Run")
	elif current == "Run" and speed <= RUN_SPEED_THRESHOLD:
		_sm.travel("Idle")
	if _pending_fire:
		if not Input.is_action_pressed("fire"):
			_pending_fire = false
		elif speed <= RUN_SPEED_THRESHOLD:
			_pending_fire = false
			_use()

@rpc("call_local","any_peer")
func play_sounds_and_anims():
	audio_player.stream = fire_sound
	bolt_pull_stream.stream = bolt_pull_sound
	audio_player.play()
	bolt_pull_stream.play()

func _use():
	if _use_parent and _use_parent.velocity.length() > RUN_SPEED_THRESHOLD:
		_pending_fire = true
		return
	if current_clip > 0 and current_cycle <= 0:
		if _sm:
			_sm.travel("Fire")
		play_sounds_and_anims.rpc()
		if muzzle_smoke:
			muzzle_smoke.restart()
			muzzle_smoke.emitting = true
		if muzzle_blast:
			muzzle_blast.restart()
			muzzle_blast.emitting = true
		current_cycle = cycle_time

		assert(definition != null, "[GUN] definition is null on '%s' (definition_path='%s') — set definition_path in the scene" % [name, definition_path])
		print("[GUN] client sending _spawn_bullet RPC — gun=%s dmg=%.1f speed=%.1f origin=%s" % [name, definition.base_damage, definition.muzzle_velocity, muzzle_end.global_transform.origin])
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
		if definition != null:
			recoil.emit(float(definition.vertical_recoil), float(definition.horizantal_recoil))

	else:
		# player play weapon click
		pass

@rpc("any_peer")
func _spawn_bullet(dict: Dictionary):
	print("[GUN] _spawn_bullet received on peer=%d is_server=%s gun=%s origin=%s" % [multiplayer.get_unique_id(), multiplayer.is_server(), name, dict.get("origin", "?")])
	if not multiplayer.is_server():
		push_warning("[GUN] _spawn_bullet called on non-server peer — ignoring")
		return
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
	_sm.travel(reload_animation)
	# increase weapon inside animation, but that is too 
	# involved for this point
	if (clip_size - current_clip) > current_reserve:
		current_clip = current_reserve + current_clip
		current_reserve = 0
	else:
		current_reserve -= (clip_size - current_clip)
		current_clip = clip_size
		
	
func get_ammo():
	return [current_clip, current_reserve]
