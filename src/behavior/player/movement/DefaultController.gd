###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

#TODO: Implement Crouch
extends CharacterBody3D

class_name DefaultController

var DEFAULT_LERP = 20.0
const RECONCILE_DISTANCE_SQUARED = 0.0004
const REMOTE_POSITION_LERP = 14.0
const REMOTE_ROTATION_LERP = 18.0
const REMOTE_EXTRAPOLATION_SEC = 0.03

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

var net_move_x: float = 0.0
var net_move_y: float = 0.0
var net_wants_sprint: bool = false
var net_jump_pressed: bool = false
var net_yaw: float = 0.0
var net_pitch: float = 0.0
var input_sequence: int = 0
var last_server_sequence: int = -1
var pending_inputs: Array = []
var has_remote_snapshot: bool = false
var remote_target_position: Vector3 = Vector3.ZERO
var remote_target_yaw: float = 0.0
var remote_target_pitch: float = 0.0
var server_spawn_assigned_by_faction: bool = false

@onready var camera = $neck/camera_head
@onready var neck = $neck
@onready var gun_location = $neck/camera_head/gun_location
@onready var res_sphere = $res_sphere
@onready var ground_check_0 = $ground_check_0
@onready var ground_check_1 = $ground_check_1
@onready var ground_check_2 = $ground_check_2
@onready var ground_check_3 = $ground_check_3
@onready var ground_check_4 = $ground_check_4
@onready var multiplayer_sync: MultiplayerSynchronizer = $MultiplayerSynchronizer


var character: Character
signal character_update(ids: Array)
var equipment: Array = []
var current_equipped_index: int = 0

func _is_local_player() -> bool:
	if multiplayer == null or name.is_empty():
		return false
	return str(name).to_int() == multiplayer.get_unique_id()

func _apply_look_rotation(yaw: float, pitch: float) -> void:
	rotation.y = yaw
	neck.rotation.x = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))

func _update_remote_proxy(dt: float) -> void:
	if multiplayer.is_server() or not has_remote_snapshot:
		return
	var pos_alpha := clampf(REMOTE_POSITION_LERP * dt, 0.0, 1.0)
	var rot_alpha := clampf(REMOTE_ROTATION_LERP * dt, 0.0, 1.0)
	global_position = global_position.lerp(remote_target_position, pos_alpha)
	rotation.y = lerp_angle(rotation.y, remote_target_yaw, rot_alpha)
	neck.rotation.x = lerp(neck.rotation.x, remote_target_pitch, rot_alpha)

func _enter_tree() -> void:
	set_multiplayer_authority(1)

func _assign_server_spawn_from_character_faction() -> bool:
	if not multiplayer.is_server():
		return false
	if not Global.character_data.has(name):
		return false
	var player_payload: Variant = Global.character_data[name]
	if not (player_payload is Dictionary):
		return false
	if not player_payload.has("faction"):
		return false
	var spawn = Global.get_spawn(int(player_payload["faction"]))
	if spawn == null:
		return false
	transform.origin = spawn.transform.origin
	global_position = spawn.global_position
	return true

#This should be changed to be more global
func _ready():
	connect("character_update", Global.emit_character_update)
	Global.connect("character_update", char_serv_update)
	res_sphere.set_player(self)
	
	if multiplayer.is_server():
		server_spawn_assigned_by_faction = _assign_server_spawn_from_character_faction()
		if not server_spawn_assigned_by_faction:
			# Keep players out of origin while waiting for authoritative faction payload.
			var fallback_spawn = Global.get_spawn(Factions.DEFAULT)
			if fallback_spawn != null:
				transform.origin = fallback_spawn.transform.origin
				global_position = fallback_spawn.global_position
		# Prevent owner transform replication from fighting local prediction.
		var owner_peer_id := str(name).to_int()
		if owner_peer_id > 1:
			multiplayer_sync.set_visibility_for(owner_peer_id, false)
	
	if not _is_local_player(): return
	
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
	net_yaw = rotation.y
	net_pitch = neck.rotation.x
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
		if multiplayer.is_server() and not server_spawn_assigned_by_faction:
			server_spawn_assigned_by_faction = _assign_server_spawn_from_character_faction()
		load_from_payload(Global.character_data[name])


func load_from_payload(payload: Dictionary):

	character = Character.new()
	character.load_from_payload(payload)
	swap_equipped_from_index(payload["active"], false)

func _ads(dt: float):
	if active_equipable is Weapon:
		active_equipable.transform.origin = active_equipable.transform.origin.\
			lerp((active_equipable.ads_position - camera.transform.origin),
				active_equipable.ADS_LERP * dt)
		camera.fov = lerp(camera.fov, active_equipable.ads_fov, active_equipable.ADS_LERP * dt)
		if _is_local_player():
			Local.HUD.set_visible(false)

func _undo_ads(dt: float):
	if active_equipable is Weapon:
		active_equipable.transform.origin = active_equipable.transform.origin.\
			lerp((active_equipable.default_position - camera.transform.origin),
				active_equipable.ADS_LERP * dt)
		camera.fov = lerp(camera.fov, float(Settings.FOV), active_equipable.ADS_LERP * dt)
		if _is_local_player():
			Local.HUD.set_visible(true)
	elif camera.fov != float(Settings.FOV):
		camera.fov = lerp(camera.fov, float(Settings.FOV), DEFAULT_LERP * dt)

func ground_check():

	return ground_check_0.is_colliding() or \
		   ground_check_1.is_colliding() or \
		   ground_check_2.is_colliding() or \
		   ground_check_3.is_colliding() or \
		   ground_check_4.is_colliding()

func _process(dt: float):
	self.delta = dt
	if not _is_local_player():
		_update_remote_proxy(dt)
		return
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
		_ads(dt)
	else:
		_undo_ads(dt)
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
	if not _is_local_player() or current_health <= 0: return
	if Local.input_active:
		if event is InputEventMouseMotion:
			net_yaw += deg_to_rad(-event.relative.x * mouse_sensitivity)
			net_pitch += deg_to_rad(-event.relative.y * mouse_sensitivity)
			net_pitch = clamp(net_pitch, deg_to_rad(-89), deg_to_rad(89))
			_apply_look_rotation(net_yaw, net_pitch)

func _set_movement_input(move_x: float, move_y: float, wants_sprint: bool, jump_pressed: bool, yaw: float, pitch: float) -> void:
	net_move_x = clamp(move_x, -1.0, 1.0)
	net_move_y = clamp(move_y, -1.0, 1.0)
	net_wants_sprint = wants_sprint
	if jump_pressed:
		net_jump_pressed = true
	net_yaw = yaw
	net_pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))

func _build_local_input(dt: float) -> Dictionary:
	var move_x: float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var move_y: float = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	if not Local.input_active:
		move_x = 0.0
		move_y = 0.0
	var wants_sprint: bool = Local.input_active and Input.is_action_pressed("sprint")
	var jump_pressed: bool = Local.input_active and Input.is_action_just_pressed("jump")
	return {
		"seq": input_sequence,
		"dt": dt,
		"move_x": move_x,
		"move_y": move_y,
		"wants_sprint": wants_sprint,
		"jump_pressed": jump_pressed,
		"yaw": net_yaw,
		"pitch": net_pitch,
	}

func _apply_input_packet(input_packet: Dictionary) -> void:
	_set_movement_input(
		input_packet["move_x"],
		input_packet["move_y"],
		input_packet["wants_sprint"],
		input_packet["jump_pressed"],
		input_packet["yaw"],
		input_packet["pitch"]
	)

func _capture_and_submit_input(dt: float) -> void:
	var input_packet := _build_local_input(dt)
	input_sequence += 1
	input_packet["seq"] = input_sequence
	_apply_input_packet(input_packet)

	if multiplayer.is_server():
		last_server_sequence = input_packet["seq"]
	else:
		pending_inputs.append(input_packet)
		submit_movement_input.rpc_id(
			1,
			input_packet["seq"],
			input_packet["move_x"],
			input_packet["move_y"],
			input_packet["wants_sprint"],
			input_packet["jump_pressed"],
			input_packet["yaw"],
			input_packet["pitch"]
		)

@rpc("any_peer", "unreliable_ordered")
func submit_movement_input(seq: int, move_x: float, move_y: float, wants_sprint: bool, jump_pressed: bool, yaw: float, pitch: float):
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id != str(name).to_int():
		return
	last_server_sequence = seq
	_set_movement_input(move_x, move_y, wants_sprint, jump_pressed, yaw, pitch)

func _create_authoritative_state() -> Dictionary:
	return {
		"position": global_position,
		"horizontal_velocity": horizantal_velocity,
		"gravity_direction": gravity_direction,
		"yaw": rotation.y,
		"pitch": neck.rotation.x,
	}

func _restore_authoritative_state(state: Dictionary) -> void:
	global_position = state["position"]
	horizantal_velocity = state["horizontal_velocity"]
	gravity_direction = state["gravity_direction"]
	net_yaw = state["yaw"]
	net_pitch = state["pitch"]
	_apply_look_rotation(net_yaw, net_pitch)

func _discard_acknowledged_inputs(sequence: int) -> void:
	if pending_inputs.is_empty():
		return
	var remaining_inputs: Array = []
	for input_packet in pending_inputs:
		if input_packet["seq"] > sequence:
			remaining_inputs.append(input_packet)
	pending_inputs = remaining_inputs

func _replay_pending_inputs() -> void:
	for input_packet in pending_inputs:
		_apply_input_packet(input_packet)
		_simulate_movement(input_packet["dt"], false, false)

@rpc("authority", "unreliable_ordered")
func reconcile_movement(sequence: int, state: Dictionary):
	if multiplayer.is_server() or not _is_local_player():
		return
	var authoritative_position: Vector3 = state["position"]
	var needs_reconcile := global_position.distance_squared_to(authoritative_position) > RECONCILE_DISTANCE_SQUARED
	_discard_acknowledged_inputs(sequence)
	if not needs_reconcile:
		return
	_restore_authoritative_state(state)
	if not pending_inputs.is_empty():
		_replay_pending_inputs()

@rpc("authority", "unreliable_ordered")
func receive_remote_snapshot(snapshot_position: Vector3, yaw: float, pitch: float, snapshot_velocity: Vector3):
	if multiplayer.is_server() or _is_local_player():
		return
	remote_target_position = snapshot_position + snapshot_velocity * REMOTE_EXTRAPOLATION_SEC
	remote_target_yaw = yaw
	remote_target_pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
	if not has_remote_snapshot:
		has_remote_snapshot = true
		global_position = remote_target_position
		rotation.y = remote_target_yaw
		neck.rotation.x = remote_target_pitch

enum WALK_STATES {
	WALK,
	RUN,
	STOP
}

func _physics_process(dt: float):
	if _is_local_player():
		_capture_and_submit_input(dt)
		if not multiplayer.is_server():
			_simulate_movement(dt, false, true)

	if _is_local_player() and current_health > 0:
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

	if _is_local_player() and Input.is_action_just_pressed("help") and\
		current_health <= 0 and not audio_player.playing:
			call_help.rpc(name)

	if not multiplayer.is_server():
		return

	_simulate_movement(dt, true, false)
	receive_remote_snapshot.rpc(global_position, rotation.y, neck.rotation.x, horizantal_velocity)
	if not _is_local_player() and last_server_sequence >= 0:
		reconcile_movement.rpc_id(str(name).to_int(), last_server_sequence, _create_authoritative_state())


func _simulate_movement(dt: float, replicate_walk_state: bool, play_walk_locally: bool) -> void:
	var speed = 0.0
	var accel = DEACCEL
	var forward = false
	
	self.delta = dt
	_apply_look_rotation(net_yaw, net_pitch)

	direction = Vector3()

	if ground_check():
		full_contact = true
	else:
		full_contact = false
		
		
	if not is_on_floor():
		gravity_direction += Vector3.DOWN * gravity * dt
	#elif is_on_floor() and full_contact:
	#	gravity_direction = -get_floor_normal() * gravity
	##	gravity_direction = -get_floor_normal()
	
	if current_health > 0:
		if net_jump_pressed and is_on_floor() and full_contact:
			gravity_direction = Vector3.UP * jump
			net_jump_pressed = false
	
	var walk_state = WALK_STATES.STOP

	if net_move_y < 0.0:
		direction -= transform.basis.z
		forward = true
		walk_state = WALK_STATES.WALK
	if net_move_y > 0.0:
		forward = false
		direction += transform.basis.z
		walk_state = WALK_STATES.WALK
	if net_move_x < 0.0:
		direction -= transform.basis.x
		walk_state = WALK_STATES.WALK
	if net_move_x > 0.0:
		direction += transform.basis.x
		walk_state = WALK_STATES.WALK
		
	if direction != Vector3.ZERO:
		if net_wants_sprint and forward:
			speed = MAX_SPRINT
			accel = SPRINT_ACCEL
			walk_state = WALK_STATES.RUN
		else:
			speed = MAX_SPEED
			accel = ACCEL
			walk_state = WALK_STATES.WALK
	
	if not is_on_floor():
		walk_state = WALK_STATES.STOP
	
	if replicate_walk_state:
		play_walk.rpc(name, walk_state)
	elif play_walk_locally:
		play_walk(name, walk_state)

	direction = direction.normalized()
	horizantal_velocity = horizantal_velocity.lerp(
		direction * speed, accel * dt)
	movement.z = horizantal_velocity.z + gravity_direction.z
	movement.x = horizantal_velocity.x + gravity_direction.x
	movement.y = gravity_direction.y
	
	#warning-ignore:return_value_discarded
	if current_health <= 0:
		movement = movement * Vector3.UP
	set_velocity(movement)
	set_up_direction(Vector3.UP)
	move_and_slide()

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
	if not _is_local_player(): return
	current_interaction = interactable
	if interactable.auto_interact:
		interactable._interact(self)
	print(interactable.name)

func remove_interaction(interactable: Interactable):
	if not _is_local_player(): return
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
	if not _is_local_player(): return
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
