extends Weapon

class_name Gun

var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()

onready var Global = get_node('/root/Global')
onready var Types = get_node('/root/Types')

export var model: Mesh
var fire_sound: AudioStreamMP3
export var ads_animation: String = "none"
export var fire_animation: String = "none"
export var cock_animation: String = "none"
export var reload_animation: String = "none"
var player: AnimationPlayer = AnimationPlayer.new()
export var cycle_time: float = 0.7

export var bullet_damage: float
export var bullet_speed: float
export var bullet_lifetime: float

var current_cycle: float = 0.0

func _ready():
	# set up envrionment
	self.add_child(audio_player)
	type = WeaponType.GUN
	

func _process(delta):
	if current_cycle > 0:
		current_cycle -= delta
	
	if current_cycle <= 0 and\
		Input.is_action_just_pressed('fire') and\
		active:
		_use()
	

func _use():
	player.play(fire_animation)
	current_cycle = cycle_time

	audio_player.stream = fire_sound
	audio_player.play()

	# spawn a bullet
	var bullet = Bullet.new()
	bullet.set_properties(
		bullet_speed,
		muzzle_end.global_transform.origin,
		bullet_damage,
		muzzle_end.global_rotation,
		bullet_lifetime,
		Global.map_root
	)
	# hand the bullet to the scene as a top level child
