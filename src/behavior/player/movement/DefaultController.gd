###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

#TODO: Implement Crouch
extends CharacterBody3D

class_name DefaultController

var DEFAULT_LERP = 20.0

@onready var WeaponRegister = get_node('/root/WeaponRegister')
@onready var Settings = get_node('/root/Settings')
@onready var Local = get_node('/root/Local')
@onready var HUD = preload('res://ui/hud/Hud.tscn').instantiate()

@onready var escape_menu = preload(
	'res://debug/ui/debug_escape_menu/DebugEscapeMenu.tscn').instantiate()

@export var MAX_SPEED: float = 6.0
@export var MAX_SPRINT: float = 12.0

@export var ACCEL: float = 2.0
@export var SPRINT_ACCEL: float = 10.0

@export var DEACCEL: float = 10.0

@export var mouse_sensitivity: float = 0.03
@export var gravity: float = 20.0
@export var jump: float = 10.0

@export var step_sound: String
@export var step_volume: float

@export var FULL_HEALTH: float = 100.0

var full_contact = false
var health = FULL_HEALTH

var direction = Vector3()
var horizantal_velocity = Vector3()
var movement = Vector3()
var gravity_direction = Vector3()
var current_interaction: Interactable

# this needs to be set to an active equipable
var active_equipable: Equipable = Equipable.new()

@onready var head = $camera_head
@onready var gun_location = $camera_head/gun_location
@onready var ground_check_0 = $ground_check_0
@onready var ground_check_1 = $ground_check_1
@onready var ground_check_2 = $ground_check_2
@onready var ground_check_3 = $ground_check_3
@onready var ground_check_4 = $ground_check_4


var character: Character

#This should be changed to be more global
func _ready():
	add_child(HUD)
	# set up default character
	character = Character.new()
	character.primary_weapon = WeaponRegister.gun_register["DefaultGun"].instantiate()
	character.secondary_weapon = WeaponRegister.gun_register["DefaultPistol"].instantiate()
	character.set_bullet_origin(gun_location)
	character.equipment_1.equipment_instance = MedPack.new(self)
	character.equipment_2.equipment_instance = Equipment.new(self)
	# end default character
	swap_equipped(character.primary_weapon)
	# load from character 
	Local.player = self

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _ads(delta):
	if active_equipable is Weapon:
		active_equipable.transform.origin = active_equipable.transform.origin.\
			lerp((active_equipable.ads_position - head.transform.origin),
				active_equipable.ADS_LERP * delta)
		head.fov = lerp(head.fov, active_equipable.ads_fov, active_equipable.ADS_LERP * delta)

func _undo_ads(delta):
	if active_equipable is Weapon:
		active_equipable.transform.origin = active_equipable.transform.origin.\
			lerp((active_equipable.default_position - head.transform.origin),
				active_equipable.ADS_LERP * delta)
		head.fov = lerp(head.fov, float(Settings.FOV), active_equipable.ADS_LERP * delta)
	elif head.fov != float(Settings.FOV):
		head.fov = lerp(head.fov, float(Settings.FOV), DEFAULT_LERP * delta)

func ground_check():

	return ground_check_0.is_colliding() or \
		   ground_check_1.is_colliding() or \
		   ground_check_2.is_colliding() or \
		   ground_check_3.is_colliding() or \
		   ground_check_4.is_colliding()

func _process(delta):
	# set cycle time ? so that you can't just keep
	# shifting weapons but maybe not
	if Input.is_action_just_pressed("primary_weapon") and\
			Local.input_active:
		swap_equipped(character.primary_weapon)
	elif Input.is_action_just_pressed("secondary_weapon") and\
			Local.input_active:
		swap_equipped(character.secondary_weapon)
	elif Input.is_action_just_pressed("tertiary_weapon") and\
			Local.input_active:
		swap_equipped(character.tertiary_weapon)
	elif Input.is_action_just_pressed("equipment_1") and\
		Local.input_active and character.equipment_1.equipment_instance != null:
			swap_equipped(character.equipment_1.equipment_instance)
	elif Input.is_action_just_pressed("equipment_2") and\
		Local.input_active and character.equipment_2.equipment_instance != null:
			swap_equipped(character.equipment_2.equipment_instance)
	if Input.is_action_pressed("ads") and\
			Local.input_active:
		_ads(delta)
	else:
		_undo_ads(delta)
	if Input.is_action_just_pressed("ads") and\
			Local.input_active and\
			active_equipable is Weapon:
		active_equipable.ads = true
	if Input.is_action_just_released("ads") and\
			Local.input_active and\
			active_equipable is Weapon:
		active_equipable.ads = false
	if Input.is_action_just_pressed("exit"):
		if Local.input_active:
			Local.input_active = false
			self.add_child(escape_menu)
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Local.input_active = true
			self.remove_child(escape_menu)
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func swap_equipped(equipable: Equipable):
	if active_equipable != equipable:
		if active_equipable.get_parent() == head:
			head.remove_child(active_equipable)
		active_equipable._set_inactive()
		# play stow animation
		active_equipable = equipable
		# play raise animation
		equipable._set_active()
		head.add_child(equipable)
		equipable.transform.origin = \
		equipable.default_position - head.transform.origin

func _input(event):
	if Local.input_active:
		if event is InputEventMouseMotion:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
			head.rotate_x(deg_to_rad((-event.relative.y * mouse_sensitivity)))
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

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
		gravity_direction += Vector3.DOWN * gravity * delta
	elif is_on_floor() and full_contact:
		gravity_direction = -get_floor_normal() * gravity
	else:
		gravity_direction = -get_floor_normal()

	if Input.is_action_just_pressed("jump") and is_on_floor()\
		and full_contact and Local.input_active:
		gravity_direction = Vector3.UP * jump

	if Input.is_action_pressed("move_forward") and\
			Local.input_active:
		direction -= transform.basis.z
		forward = true
	if Input.is_action_pressed("move_backward") and\
			Local.input_active:
		forward = false
		direction += transform.basis.z
	if Input.is_action_pressed("move_left") and\
			Local.input_active:
		direction -= transform.basis.x
	if Input.is_action_pressed("move_right") and\
			Local.input_active:
		direction += transform.basis.x
		
	if direction != Vector3.ZERO:
		if Input.is_action_pressed("sprint") and forward and\
				Local.input_active:
			speed = MAX_SPRINT
			accel = SPRINT_ACCEL
		else:
			speed = MAX_SPEED
			accel = ACCEL

	direction = direction.normalized()
	horizantal_velocity = horizantal_velocity.lerp(
		direction * speed, accel * delta)
	movement.z = horizantal_velocity.z + gravity_direction.z
	movement.x = horizantal_velocity.x + gravity_direction.x
	movement.y = gravity_direction.y
	
	#warning-ignore:return_value_discarded
	set_velocity(movement)
	set_up_direction(Vector3.UP)
	move_and_slide()

func register_interaction(interactable: Interactable):
	current_interaction = interactable
	if interactable.auto_interact:
		interactable._interact(self)
	print(interactable.name)

func remove_interaction(interactable: Interactable):
	if current_interaction == interactable:
		current_interaction = Interactable.new()

func extract():
	print('extract successful')
