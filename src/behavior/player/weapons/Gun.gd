extends Weapon

class_name Gun

onready var Global = get_node('/root/Global')
onready var Types = get_node('/root/Types')

export var model: Mesh
export var ads_animation: String
export var fire_animation: String
export var cock_animation: String
export var reload_animation: String
var player: AnimationPlayer
export var cycle_time: float = 0.7
var faction: int

onready var muzzle_end: Spatial = $muzzle_end

export var bullet_damage: float
export var bullet_speed: float
export var bullet_lifetime: float

var current_cycle: float = 0.0
var active: bool = false # test if gun is active

func _ready():
	# set up envrionment
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

	# spawn a bullet
	var bullet = Bullet.new()
	bullet.set_properties(
		bullet_speed, muzzle_end.global_transform.origin,
		bullet_damage, muzzle_end.global_rotation,
		bullet_lifetime )
	# hand the bullet to the scene as a top level child
	Global.map_root.add_child(bullet)
