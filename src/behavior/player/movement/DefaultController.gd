extends KinematicBody


export var MAX_SPEED: float = 6.0
export var MAX_SPRINT: float = 12.0

export var ACCEL: float = 2.0
export var SPRINT_ACCEL: float = 10.0

export var DEACCEL: float = 10.0

export var mouse_sensitivity: float = 0.03
export var gravity: float = 20.0
export var jump: float = 10.0

export var FULL_HEALTH: float = 100.0

var full_contact = false
var health =FULL_HEALTH

var direction = Vector3()
var horizantal_velocity = Vector3()
var movement = Vector3()
var gravity_vec = Vector3()

onready var head = $camera_head
onready var ground_check = $ground_check

#This should be changed to be more global
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg2rad((-event.relative.y * mouse_sensitivity)))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))

func _physics_process(delta):
	var speed = 0
	var accel = DEACCEL
	var forward = false

	direction = Vector3()

	if ground_check.is_colliding():
		full_contact = true
	else:
		full_contact = false
	
	if not is_on_floor():
		gravity_vec += Vector3.DOWN * gravity * delta
	elif is_on_floor() and full_contact:
		gravity_vec = -get_floor_normal() * gravity
	else:
		gravity_vec = get_floor_normal()

	if Input.is_action_just_pressed("jump") and is_on_floor()\
		and full_contact:
		gravity_vec = Vector3.UP * jump

	if Input.is_action_just_pressed("move_forward"):
		direction -= transform.basis.z
		forward = true
	if Input.is_action_just_pressed("move_backward"):
		forward = false
		direction += transform.basis.z
	if Input.is_action_just_pressed("move_left"):
		direction -= transform.basis.x
	if Input.is_action_just_pressed("move_right"):
		direction += transform.basis.x

	# This must be changed as well
	if Input.is_action_just_pressed("exit"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		#BRING UP ESCAPE MENU
	
	if direction != Vector3.ZERO:
		if Input.is_action_just_pressed("sprint") and forward:
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