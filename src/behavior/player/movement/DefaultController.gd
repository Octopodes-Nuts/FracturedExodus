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
var current_health: float = 100 : set = _set_current_health

@export var current_eqipped_key: String = ""

var full_contact = false
var health = FULL_HEALTH

#sounds
var hits = [preload("res://behavior/player/sounds/hit1.wav"),
			preload("res://behavior/player/sounds/hit2wav.wav"),
			preload("res://behavior/player/sounds/hit3.wav")]
var deaths = [preload("res://behavior/player/sounds/death1.wav")]
var groans = [preload("res://behavior/player/sounds/groan1.wav"),
			  preload("res://behavior/player/sounds/groan2.wav"),
			  preload("res://behavior/player/sounds/groan3.wav")]
var helps = [preload('res://behavior/player/sounds/help1.wav'),
			 preload('res://behavior/player/sounds/help2.wav')]
var walk = preload("res://behavior/player/sounds/walk.wav")
var run = preload("res://behavior/player/sounds/run.wav")

@onready var audio_player = $audio_player

var direction = Vector3()
var horizantal_velocity = Vector3()
var movement = Vector3()
var gravity_direction = Vector3()
var current_interaction: Interactable
var delta: float

# this needs to be set to an active equipable
var active_equipable: Equipable = Equipable.new()

@onready var camera = $neck/camera_head
@onready var neck = $neck
@onready var gun_location = $neck/camera_head/gun_location
@onready var res_sphere = $res_sphere
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
	res_sphere.set_player(self)
	
	if not is_multiplayer_authority(): return
	
	Local.input_active = true
	camera.make_current()
	if Local.terrain:
		Local.terrain.set_camera(camera)
	add_child(HUD)
	var health_slider = HUD.get_node("health_slider")
	health_slider.max_value = FULL_HEALTH
	health_slider.value = current_health
	
	# set up default character
	character = Character.new()
	character.load_from_character(Local.selected_character_def)
	# character.primary_weapon = WeaponRegister.gun_register["DefaultGun"].instantiate()
	# character.secondary_weapon = WeaponRegister.gun_register["DefaultPistol"].instantiate()
	character.set_bullet_origin(gun_location)
	character.equipment_1.equipment_instance = Equipment.new()
	character.equipment_2.equipment_instance = Equipment.new()
	# end default character
	swap_equipped(character.primary_weapon)
	# load from character 
	Local.player = self
	Local.HUD = HUD
	var faction: int = Factions.DEFAULT
	if Local.selected_character_def != null:
		faction = Local.selected_character_def.Faction
	var spawn = Global.get_spawn(faction)
	if spawn != null:
		transform.origin = spawn.transform.origin
	send_character_data.rpc_id(1, _character_payload())
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _set_current_health(updated_health: float):
	if updated_health <= 0:
		current_health = 0
	elif updated_health >= FULL_HEALTH:
		current_health = FULL_HEALTH
	else:
		current_health = updated_health
	
	HUD.get_node("health_slider").value = current_health

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
			lerp((active_equipable.ads_position - camera.transform.origin),
				active_equipable.ADS_LERP * delta)
		camera.fov = lerp(camera.fov, active_equipable.ads_fov, active_equipable.ADS_LERP * delta)
		if is_multiplayer_authority():
			Local.HUD.set_visible(false)

@rpc("call_local")
func _undo_ads(delta):
	if active_equipable is Weapon:
		active_equipable.transform.origin = active_equipable.transform.origin.\
			lerp((active_equipable.default_position - camera.transform.origin),
				active_equipable.ADS_LERP * delta)
		camera.fov = lerp(camera.fov, float(Settings.FOV), active_equipable.ADS_LERP * delta)
		if is_multiplayer_authority():
			Local.HUD.set_visible(true)
	elif camera.fov != float(Settings.FOV):
		camera.fov = lerp(camera.fov, float(Settings.FOV), DEFAULT_LERP * delta)

func ground_check():

	return ground_check_0.is_colliding() or \
		   ground_check_1.is_colliding() or \
		   ground_check_2.is_colliding() or \
		   ground_check_3.is_colliding() or \
		   ground_check_4.is_colliding()

func _process(delta):
	self.delta = delta
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
		if active_equipable.get_parent() == camera:
			camera.remove_child(active_equipable)
		active_equipable._set_inactive()
		# play stow animation
		active_equipable = equipable
		# play raise animation
		equipable._set_active()
		camera.add_child(equipable)
		equipable.transform.origin = \
		equipable.default_position - camera.transform.origin
		current_eqipped_key = equipable.key

func swap_equipped_from_index(id: int, call_rpc: bool):
	var equipable = update_equipment()[id]
	if active_equipable != equipable:
		if active_equipable.get_parent() == camera:
			camera.remove_child(active_equipable)
		active_equipable._set_inactive()
		# play stow animation
		active_equipable = equipable
		# play raise animation
		equipable._set_active()
		camera.add_child(equipable)
		equipable.transform.origin = \
		equipable.default_position - camera.transform.origin
		current_equipped_index = id
		if call_rpc:
			update_character_server.rpc_id(1, "active", id)
		HUD.display_ammo(active_equipable.get_ammo())

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
			neck.rotate_x(deg_to_rad((-event.relative.y * mouse_sensitivity)))
			neck.rotation.x = clamp(neck.rotation.x, deg_to_rad(-89), deg_to_rad(89))

enum WALK_STATES {
	WALK,
	RUN,
	STOP
}

func _physics_process(delta):
	if not is_multiplayer_authority(): return
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
	
	if current_health > 0:
		if Input.is_action_just_pressed("jump") and is_on_floor()\
			and full_contact and Local.input_active:
			gravity_direction = Vector3.UP * jump
	
	var walk_state = WALK_STATES.STOP

	if Input.is_action_pressed("move_forward") and\
			Local.input_active:
		direction -= transform.basis.z
		forward = true
		walk_state = WALK_STATES.WALK
	if Input.is_action_pressed("move_backward") and\
			Local.input_active:
		forward = false
		direction += transform.basis.z
		walk_state = WALK_STATES.WALK
	if Input.is_action_pressed("move_left") and\
			Local.input_active:
		direction -= transform.basis.x
		walk_state = WALK_STATES.WALK
	if Input.is_action_pressed("move_right") and\
			Local.input_active:
		direction += transform.basis.x
		walk_state = WALK_STATES.WALK
		
	if direction != Vector3.ZERO:
		if Input.is_action_pressed("sprint") and forward and\
				Local.input_active:
			speed = MAX_SPRINT
			accel = SPRINT_ACCEL
			walk_state = WALK_STATES.RUN
		else:
			speed = MAX_SPEED
			accel = ACCEL
			walk_state = WALK_STATES.WALK
	
	if not is_on_floor():
		walk_state = WALK_STATES.STOP
	
	play_walk.rpc(name, walk_state)

	direction = direction.normalized()
	horizantal_velocity = horizantal_velocity.lerp(
		direction * speed, accel * delta)
	movement.z = horizantal_velocity.z + gravity_direction.z
	movement.x = horizantal_velocity.x + gravity_direction.x
	movement.y = gravity_direction.y
	
	#warning-ignore:return_value_discarded
	if current_health <= 0:
		movement = movement * Vector3.UP
	set_velocity(movement)
	set_up_direction(Vector3.UP)
	move_and_slide()
	
	if current_health > 0:
		if Input.is_action_pressed("interact") && current_interaction:
			if current_interaction.has_method("interact"):
				current_interaction.interact(self)
				HUD.display_ammo(active_equipable.get_ammo())
			
		if  not active_equipable.continuous_usage and\
			Input.is_action_just_pressed('fire') and\
			Local.input_active:
			if active_equipable.has_method("use"):
				active_equipable.use(self)
				HUD.display_ammo(active_equipable.get_ammo())
			
		if active_equipable.continuous_usage and\
			Input.is_action_pressed("fire") and\
			Local.input_active:
			if not active_equipable.cool_down and\
		 	active_equipable.has_method("use"):
				active_equipable.use(self)
				HUD.display_ammo(active_equipable.get_ammo())
	
		if Input.is_action_just_pressed('reload') and\
			Local.input_active:
			if active_equipable.has_method("_reload"):
				active_equipable._reload()
				HUD.display_ammo(active_equipable.get_ammo())
		
		if Input.is_action_just_pressed("help"):
			print("help")
	
	if Input.is_action_just_pressed("help") and\
		current_health <= 0 and not audio_player.playing:
			call_help.rpc(name)

@rpc("call_local", "any_peer")
func call_help(id):
	if name == id:
		audio_player.stream = helps.pick_random()
		audio_player.play()

var play_state = {}

@rpc("call_local","any_peer")
func play_walk(id, walk_state):
	if name == id:
		if walk_state == WALK_STATES.STOP:
			$footsteps.stop()
			play_state[name] = WALK_STATES.STOP
		elif walk_state == WALK_STATES.WALK:
			if not $footsteps.playing:
				$footsteps.stream = walk
				$footsteps.autoplay = true
				$footsteps.play()
				play_state[name] = WALK_STATES.WALK
			elif play_state[name] != WALK_STATES.WALK:
				$footsteps.stream = walk
				$footsteps.autoplay = true
				$footsteps.play()
				play_state[name] = WALK_STATES.WALK
		elif walk_state == WALK_STATES.RUN:
			if not $footsteps.playing:
				$footsteps.stream = run
				$footsteps.autoplay = true
				$footsteps.play()
				play_state[name] = WALK_STATES.RUN
			elif play_state[name] != WALK_STATES.RUN:
				$footsteps.stream = run
				$footsteps.autoplay = true
				$footsteps.play()
				play_state[name] = WALK_STATES.RUN


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

@rpc("call_local", "any_peer")
func play_hit_noise(id):
	if name == id:
		print(id)
		audio_player.stream = hits.pick_random()
		audio_player.play()

func hit(dmg: int):
	_hit_local.rpc_id(name.to_int(), dmg)
	play_hit_noise.rpc(name)

@rpc("any_peer")
func _hit_local(dmg: int):
	current_health -= dmg
	Local.HUD.health_slider.value = ( current_health / FULL_HEALTH ) * 100
	if current_health <= 0:
		Local.HUD.crosshair.visible = false
		Local.HUD.death_text.visible = true
		set_res_sphere(true)
		set_res_sphere.rpc(true)

# this will be an RPC
func extract():
	if not is_multiplayer_authority(): return
	if Global.map_root != null and Global.map_root.has_method("report_match_left"):
		Global.map_root.report_match_left("extract")
	notify_extract(character.has_objective)
	#Send RPC to server to remove node from scene
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Local.input_active = false
	multiplayer.multiplayer_peer = null
	Local.has_objective = character.has_objective
	if not get_tree().change_scene_to_file("res://ui/extraction/Extraction.tscn") == OK:
		print("Error getting to file")
	print('extract successful')

func notify_extract(objective_left):
	if objective_left and not Local.host:
		Local.HUD.notify.rpc("Objective has left the mission area", 3.0)

@rpc("any_peer", "reliable")
func res(revive_health: float):
	if not multiplayer.is_server():
		return

	current_health = revive_health
	var revived_peer_id := str(name).to_int()
	if revived_peer_id == multiplayer.get_unique_id():
		_res_local(revive_health)
	else:
		_res_local.rpc_id(revived_peer_id, revive_health)

@rpc("any_peer", "reliable")
func _res_local(revive_health: float):
	current_health = revive_health
	Local.HUD.health_slider.value = ( current_health / FULL_HEALTH ) * 100
	Local.HUD.crosshair.visible = true
	Local.HUD.death_text.visible = false
	set_res_sphere(false)
	set_res_sphere.rpc(false)

@rpc("any_peer", "reliable")
func set_res_sphere(active: bool):
	res_sphere.monitorable = active
	res_sphere.monitoring = active
