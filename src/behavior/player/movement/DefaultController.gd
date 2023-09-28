#TODO: Implement Crouch
extends KinematicBody

class_name DefaultController

onready var WeaponRegister = get_node('/root/WeaponRegister')

export var MAX_SPEED: float = 6.0
export var MAX_SPRINT: float = 12.0

export var ACCEL: float = 2.0
export var SPRINT_ACCEL: float = 10.0

export var DEACCEL: float = 10.0

export var mouse_sensitivity: float = 0.03
export var gravity: float = 20.0
export var jump: float = 10.0

export var step_sound: String
export var step_volume: float

export var FULL_HEALTH: float = 100.0

var full_contact = false
var health = FULL_HEALTH

var direction = Vector3()
var horizantal_velocity = Vector3()
var movement = Vector3()
var gravity_vec = Vector3()

onready var head = $camera_head
onready var gun_location = $camera_head/gun_location
onready var ground_check_0 = $ground_check_0
onready var ground_check_1 = $ground_check_1
onready var ground_check_2 = $ground_check_2
onready var ground_check_3 = $ground_check_3
onready var ground_check_4 = $ground_check_4


var character: Character

#This should be changed to be more global
func _ready():
	# set up default character
	character = Character.new()
	character.primary_weapon = WeaponRegister.gun_register["DefaultGun"].instance()
	character.secondary_weapon = WeaponRegister.gun_register["DefaultPistol"].instance()
	# end default character

	# load from character 

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func ground_check():

	return ground_check_0.is_colliding() or \
		   ground_check_1.is_colliding() or \
		   ground_check_2.is_colliding() or \
		   ground_check_3.is_colliding() or \
		   ground_check_4.is_colliding()

func _process(_delta):
	# set cycle time ? so that you can't just keep
	# shifting weapons but maybe not
	if Input.is_action_just_pressed("primary_weapon"):
		character.set_weapons_inactive()
		character.primary_weapon.active = true
		# play animation
	elif Input.is_action_just_pressed("secondary_weapon"):
		character.set_weapons_inactive()
		character.secondary_weapon.active = true
		character.primary_weapon.transform.origin = gun_location.transform.origin
		# play animtation
	elif Input.is_action_just_pressed("tertiary_weapon"):
		character.set_weapons_inactive()
		# play animation
		character.tertiary_weapon.active = true



func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg2rad((-event.relative.y * mouse_sensitivity)))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))

func _physics_process(delta):
	var speed = 0.0
	var accel = DEACCEL
	var forward = false

	direction = Vector3()

	if ground_check():
		full_contact = true
	else:
		full_contact = false
	
	if not is_on_floor():
		gravity_vec += Vector3.DOWN * gravity * delta
	elif is_on_floor() and full_contact:
		gravity_vec = -get_floor_normal() * gravity
	else:
		gravity_vec = -get_floor_normal()

	if Input.is_action_just_pressed("jump") and is_on_floor()\
		and full_contact:
		gravity_vec = Vector3.UP * jump

	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
		forward = true
	if Input.is_action_pressed("move_backward"):
		forward = false
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		direction += transform.basis.x

	# This must be changed as well
	if Input.is_action_just_pressed("exit"):
		#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().quit()
		#BRING UP ESCAPE MENU
	
	if direction != Vector3.ZERO:
		if Input.is_action_pressed("sprint") and forward:
			speed = MAX_SPRINT
			accel = SPRINT_ACCEL
		else:
			speed = MAX_SPEED
			accel = ACCEL

	direction = direction.normalized()
	horizantal_velocity = horizantal_velocity.linear_interpolate(
		direction * speed, accel * delta)
	movement.z = horizantal_velocity.z + gravity_vec.z
	movement.x = horizantal_velocity.x + gravity_vec.x
	movement.y = gravity_vec.y
	
	#warning-ignore:return_value_discarded
	move_and_slide(movement, Vector3.UP)
