extends Node

@onready var gun_end: Node3D = $GunEnd
@onready var gun_fire_sound: AudioStreamPlayer3D = $GunFireSound
@onready var BulletScene = preload("res://behavior/player/weapons/Bullet.tscn")

@export var bullet_damage: float = 10.0
@export var bullet_speed: float = 80.0
@export var bullet_lifetime: float = 3.0
@export var bullet_spread: float = 0.05
@export var cycle_time: float = 0.9

var _current_cycle: float = 0.0

func _process(delta: float) -> void:
	if _current_cycle > 0.0:
		_current_cycle -= delta

func use() -> void:
	_use()

func _use() -> void:
	if _current_cycle > 0.0:
		return
	_current_cycle = cycle_time
	_play_fire_feedback.rpc()

	var bullet_data := {
		"speed": bullet_speed,
		"origin": gun_end.global_transform.origin,
		"dmg": bullet_damage,
		"ang": gun_end.global_rotation,
		"lifetime": bullet_lifetime,
		"ads": false,
		"spread": bullet_spread,
	}

	if is_multiplayer_authority():
		_spawn_bullet(bullet_data)

@rpc("call_local", "any_peer", "unreliable")
func _play_fire_feedback() -> void:
	if is_instance_valid(gun_fire_sound):
		gun_fire_sound.play()

func _spawn_bullet(dict: Dictionary) -> void:
	var bullet = BulletScene.instantiate()
	Global.bullet_spawn.add_child(bullet)
	bullet.set_properties(
		dict["speed"],
		dict["origin"],
		dict["dmg"],
		dict["ang"],
		dict["lifetime"],
		dict["ads"],
		dict["spread"]
	)
