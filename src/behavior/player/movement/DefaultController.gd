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
@export var gravity: float = 15.0
@export var jump: float = 10.0

@export var step_sound: String
@export var step_volume: float

@export var FULL_HEALTH: float = 100.0
var current_health: float = FULL_HEALTH

@export var current_eqipped_key: String = ""

var full_contact = false
var health = FULL_HEALTH

var direction = Vector3()
var horizantal_velocity = Vector3()
var movement = Vector3()
var gravity_direction = Vector3()
var current_interaction: Interactable
var delta: float

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
signal character_update(ids: Array)
var equipment: Array = []
var current_equipped_index: int = 0

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

#This should be changed to be more global
func _ready():
	connect("character_update", Global.emit_character_update)
	Global.connect("character_update", char_serv_update)
	
	if not is_multiplayer_authority(): return
	
	Local.input_active = true
	head.make_current()
	if Local.terrain:
		Local.terrain.set_camera(head)
	add_child(HUD)
	# set up default character
	character = Character.new()
	character.load_from_character(Local.selected_character_def)
	# character.primary_weapon = WeaponRegister.gun_register["DefaultGun"].instantiate()
	# character.secondary_weapon = WeaponRegister.gun_register["DefaultPistol"].instantiate()
	character.set_bullet_origin(gun_location)
	character.medkit = MedPack.new()
	character.equipment_1.equipment_instance = Equipment.new()
	character.equipment_2.equipment_instance = Equipment.new()
	# end default character
	swap_equipped(character.primary_weapon)
	# load from character 
	Local.player = self
	Local.HUD = HUD
	transform.origin = Global.get_spawn().transform.origin
	send_character_data.rpc_id(1, _character_payload())
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func char_serv_update(ids: Array):
	
	if name in ids:
		load_from_payload(Global.character_data[name])


func load_from_payload(payload: Dictionary):

	character = Character.new()
	character.load_from_payload(payload)
	swap_equipped_from_index(payload["active"], false)

@rpc("call_local")
func _ads(delta):
	if active_equipable is Weapon:
		active_equipable.transform.origin = active_equipable.transform.origin.\
			lerp((active_equipable.ads_position - head.transform.origin),
				active_equipable.ADS_LERP * delta)
		head.fov = lerp(head.fov, active_equipable.ads_fov, active_equipable.ADS_LERP * delta)
		if is_multiplayer_authority():
			Local.HUD.set_visible(false)

@rpc("call_local")
func _undo_ads(delta):
	if active_equipable is Weapon:
		active_equipable.transform.origin = active_equipable.transform.origin.\
			lerp((active_equipable.default_position - head.transform.origin),
				active_equipable.ADS_LERP * delta)
		head.fov = lerp(head.fov, float(Settings.FOV), active_equipable.ADS_LERP * delta)
		if is_multiplayer_authority():
			Local.HUD.set_visible(true)
	elif head.fov != float(Settings.FOV):
		head.fov = lerp(head.fov, float(Settings.FOV), DEFAULT_LERP * delta)

func ground_check():

	return ground_check_0.is_colliding() or \
		   ground_check_1.is_colliding() or \
		   ground_check_2.is_colliding() or \
		   ground_check_3.is_colliding() or \
		   ground_check_4.is_colliding()

func _process(delta):
	if not is_multiplayer_authority(): return
	# set cycle time ? so that you can't just keep
	# shifting weapons but maybe not
	if Input.is_action_just_pressed("primary_weapon") and\
			Local.input_active:
		swap_equipped_from_index(0, true)
	elif Input.is_action_just_pressed("secondary_weapon") and\
			Local.input_active:
		swap_equipped_from_index(1, true)
	elif Input.is_action_just_pressed("tertiary_weapon") and\
			Local.input_active:
		swap_equipped_from_index(2, true)
	elif Input.is_action_just_pressed("medpack") and\
		Local.input_active:
		swap_equipped_from_index(3, true)
	elif Input.is_action_just_pressed("equipment_1") and\
		Local.input_active and character.equipment_1.equipment_instance != null:
			swap_equipped_from_index(4, true)
	elif Input.is_action_just_pressed("equipment_2") and\
		Local.input_active and character.equipment_2.equipment_instance != null:
			swap_equipped_from_index(5, true)
	elif Input.is_action_just_pressed("use_scanner") and character.has_scanner:
		if Local.input_active and character.scanner != null:
			swap_equipped_from_index(6, true)

	if Input.is_action_pressed("ads") and\
			Local.input_active:
		_ads.rpc(delta)
	else:
		_undo_ads.rpc(delta)
	if Input.is_action_pressed("ads") and\
			Local.input_active and\
			active_equipable is Weapon and\
			is_on_floor():
		active_equipable.ads = true
	if Input.is_action_just_released("ads") and\
			Local.input_active and\
			active_equipable is Weapon or not is_on_floor():
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

# @rpc("call_local", "any_peer")
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
		current_eqipped_key = equipable.key

func swap_equipped_from_index(id: int, call_rpc: bool):
	var equipable = update_equipment()[id]
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
		current_equipped_index = id
		if call_rpc:
			update_character_server.rpc_id(1, "active", id)

func update_equipment():
	return [
		character.primary_weapon,
		character.secondary_weapon,
		character.tertiary_weapon,
		character.medkit,
		character.equipment_1,
		character.equipment_2,
		character.scanner
	]

func _input(event):
	if not is_multiplayer_authority() or current_health <= 0: return
	if Local.input_active:
		if event is InputEventMouseMotion:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
			head.rotate_x(deg_to_rad((-event.relative.y * mouse_sensitivity)))
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta):
	if not is_multiplayer_authority() or current_health <= 0: return
	var speed = 0.0
	var accel = DEACCEL
	var forward = false
	
	self.delta = delta

	direction = Vector3()

	if ground_check():
		full_contact = true
	else:
		full_contact = false
		
	if not is_on_floor():
		gravity_direction += Vector3.DOWN * gravity * delta
	#elif is_on_floor() and full_contact:
	#	gravity_direction = -get_floor_normal() * gravity
	##	gravity_direction = -get_floor_normal()

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
	
	if Input.is_action_pressed("interact") && current_interaction:
		if current_interaction.has_method("interact"):
			current_interaction.interact(self)
			
	if Input.is_action_just_pressed('fire') and\
		Local.input_active:
		if active_equipable.has_method("use"):
			active_equipable.use(self)
	
	if Input.is_action_just_pressed('reload') and\
		Local.input_active:
		if active_equipable.has_method("_reload"):
			active_equipable._reload()

func register_interaction(interactable: Interactable):
	if not is_multiplayer_authority(): return
	current_interaction = interactable
	if interactable.auto_interact:
		interactable._interact(self)
	print(interactable.name)

func remove_interaction(interactable: Interactable):
	if not is_multiplayer_authority(): return
	if current_interaction == interactable:
		current_interaction = Interactable.new()

@rpc("any_peer", "reliable")
func  send_character_data(payload: Dictionary):
	var sender_id := str(multiplayer.get_remote_sender_id())
	Global.character_data[sender_id] = payload
	Global.map_root.broadcast_character_data.rpc(Global.character_data)
	emit_signal("character_update", [sender_id])


func _character_payload() -> Dictionary:
	
	return {
		"active": current_equipped_index,
		"name": Local.selected_character_def.Name,
		"wep1": Local.selected_character_def.Weapon1,
		"wep2": Local.selected_character_def.Weapon2,
		"wep3": Local.selected_character_def.Weapon3,
		"eq1": Local.selected_character_def.Equipment1,
		"eq2": Local.selected_character_def.Equipment2,
		"faction": Local.selected_character_def.Faction,
		"scanner": character.has_scanner,
		"obj": character.has_objective
	}

@rpc("any_peer", "reliable")
func update_character_server(field: String, val):
	var sender_id = str(multiplayer.get_remote_sender_id())
	Global.character_data[sender_id][field] = val
	Global.map_root.broadcast_character_data_update.rpc(sender_id, field, val)
	emit_signal("character_update", [sender_id])

func get_scanner():
	character.has_scanner = true
	update_character_server.rpc_id(1, "scanner", true)
	swap_equipped_from_index(6, true)

func lose_scanner():
	character.has_scanner = false
	if current_equipped_index == 6:
		swap_equipped_from_index(3, true)
	update_character_server.rpc_id(1, "scanner", false)

func get_objective():
	character.has_objective = true
	update_character_server.rpc_id(1, "obj", true)

func lose_objective():
	character.has_objective = false
	update_character_server.rpc_id(1, "obj", false)

func hit(dmg: int):
	_hit_local.rpc_id(name.to_int(), dmg)

@rpc("any_peer")
func _hit_local(dmg: int):
	current_health -= dmg
	Local.HUD.health_slider.value = ( current_health / FULL_HEALTH ) * 100
	if current_health <= 0:
		Local.HUD.crosshair.visible = false
		Local.HUD.death_text.visible = true

# this will be an RPC
func extract():
	if not is_multiplayer_authority(): return
	#Send RPC to server to remove node from scene
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Local.input_active = false
	multiplayer.multiplayer_peer = null
	Local.has_objective = character.has_objective
	if not get_tree().change_scene_to_file("res://ui/extraction/Extraction.tscn") == OK:
		print("Error getting to file")
	print('extract successful')
