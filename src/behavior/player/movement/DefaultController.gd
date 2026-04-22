###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

#TODO: Implement Crouch
extends CharacterBody3D

class_name DefaultController

var input_handler = preload("res://behavior/player/movement/DefaultControllerInput.gd").new()
var movement_handler = preload("res://behavior/player/movement/DefaultControllerMovement.gd").new()
var health_handler = preload("res://behavior/player/movement/DefaultControllerHealth.gd").new()

var DEFAULT_LERP = 20.0
const RECONCILE_DISTANCE_SQUARED = 0.04
const REMOTE_POSITION_LERP = 25.0
const REMOTE_ROTATION_LERP = 18.0
const REMOTE_EXTRAPOLATION_SEC = 0.03

@onready var WeaponRegister = get_node('/root/WeaponRegister')
@onready var Settings = get_node('/root/Settings')
@onready var Local = get_node('/root/Local')
@onready var HUD = preload('res://ui/hud/Hud.tscn').instantiate()

@onready var escape_menu = preload(
	'res://ui/escape_menu/EscapeMenu.tscn').instantiate()

@export var MAX_SPEED: float = 6.0
@export var MAX_SPRINT: float = 12.0

@export var ACCEL: float = 10.0
@export var SPRINT_ACCEL: float = 10.0

@export var DEACCEL: float = 10.0

@export var mouse_sensitivity: float = 0.03
@export var gravity: float = 25.0
@export var jump: float = 6.0

@export var step_sound: String
@export var step_volume: float
@export var ads_sway_amount: float = 1.0

@export var FULL_HEALTH: float = 100.0
var current_health: float = 100

@export var current_eqipped_key: String = ""
@export var medic_res: bool = false

var full_contact = false
var health = FULL_HEALTH

var character_id: String = ""
var down_count: int = 0

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
var net_is_using: bool = false
var net_yaw: float = 0.0
var net_pitch: float = 0.0

var is_crouching: bool = false
@export var CROUCH_SPEED: float = 2.5
@export var CROUCH_HEIGHT: float = 0.9
@export var CROUCH_NECK_Y: float = -0.3
const CROUCH_LERP: float = 12.0
var _stand_height: float = 0.0
var _stand_neck_y: float = 0.0
var _stand_collider_y: float = 0.0
var input_sequence: int = 0
var last_server_sequence: int = -1
var pending_inputs: Array = []
var has_remote_snapshot: bool = false
var remote_target_position: Vector3 = Vector3.ZERO
var remote_target_yaw: float = 0.0
var remote_target_pitch: float = 0.0
var server_spawn_assigned_by_faction: bool = false
var officer_speed_buff: float = 1.0

var jump_fatigue: float = 0.0
@export var JUMP_FATIGUE_ACCRUAL: float = 0.3
@export var JUMP_FATIGUE_DECAY: float = 2.0
@export var JUMP_FATIGUE_MIN_HEIGHT: float = 0.2
@export var JUMP_FATIGUE_MIN_SPEED: float = 0.1

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
@onready var player_model_and_hitbox = $Ch36_nonPBR


var character: Character
signal character_update(ids: Array)
var equipment: Array = []
var current_equipped_index: int = 0

func _is_local_player() -> bool:
	if multiplayer == null:
		return false
	var id := str(name).to_int()
	if id != 0:
		return id == multiplayer.get_unique_id()
	# Class scenes wrap player_body in a Node3D — check parent's name
	var p := get_parent()
	if p != null:
		id = str(p.name).to_int()
		if id != 0:
			return id == multiplayer.get_unique_id()
	return false

var _hit_lurch_yaw: float = 0.0
var _hit_lurch_pitch: float = 0.0
const HIT_LURCH_DECAY = 7.0

func _apply_look_rotation(yaw: float, pitch: float) -> void:
	rotation.y = yaw + _hit_lurch_yaw
	neck.rotation.x = clamp(pitch + _hit_lurch_pitch, deg_to_rad(-89), deg_to_rad(89))

func _apply_recoil(vertical_deg: float, horizontal_deg: float) -> void:
	net_pitch += deg_to_rad(vertical_deg)
	net_pitch = clamp(net_pitch, deg_to_rad(-89), deg_to_rad(89))
	net_yaw += deg_to_rad(randf_range(-horizontal_deg, horizontal_deg))
	_apply_look_rotation(net_yaw, net_pitch)

func _update_remote_proxy(dt: float) -> void:
	movement_handler.update_remote_proxy(self, dt)

func _enter_tree() -> void:
	set_multiplayer_authority(1)

func _get_peer_id_string() -> String:
	var id := str(name).to_int()
	if id != 0:
		return str(name)
	if get_parent() != null:
		return str(get_parent().name)
	return str(name)

func _assign_server_spawn_from_character_faction() -> bool:
	if not multiplayer.is_server():
		return false
	var peer_id_str := _get_peer_id_string()
	print("[SPAWN] peer_id_str='%s' name='%s' parent='%s' has_data=%s" % [peer_id_str, name, str(get_parent().name) if get_parent() else "none", Global.character_data.has(peer_id_str)])
	if not Global.character_data.has(peer_id_str):
		return false
	var player_payload: Variant = Global.character_data[peer_id_str]
	print("[SPAWN] faction=%s payload=%s" % [player_payload.get("faction", "MISSING") if player_payload is Dictionary else "NOT_DICT", str(player_payload)])
	if not (player_payload is Dictionary):
		return false
	if not player_payload.has("faction"):
		return false
	var spawn = Global.get_spawn(int(player_payload["faction"]))
	print("[SPAWN] spawn=%s" % [spawn])
	if spawn == null:
		return false
	print("[SPAWN] assigning global_position=%s" % [spawn.global_position])
	transform.origin = spawn.transform.origin
	global_position = spawn.global_position
	return true


func _ready():
	escape_menu.leave_button_pressed.connect(
		func():
			Global.map_root.leave_game()
	)
	add_to_group("players")
	connect("character_update", Global.emit_character_update)
	Global.connect("character_update", char_serv_update)
	res_sphere.set_player(self)
	
	if multiplayer.is_server():
		player_model_and_hitbox.report_hit.connect(func(dmg: float, shooter_id: int): hit(int(dmg), shooter_id))
		server_spawn_assigned_by_faction = _assign_server_spawn_from_character_faction()
		if not server_spawn_assigned_by_faction:
			# Keep players out of origin while waiting for authoritative faction payload.
			var fallback_spawn = Global.get_spawn(Factions.Enum.DEFAULT)
			if fallback_spawn != null:
				transform.origin = fallback_spawn.transform.origin
				global_position = fallback_spawn.global_position
		# Prevent owner transform replication from fighting local prediction.
		var owner_peer_id := str(name).to_int()
		if owner_peer_id == 0 and get_parent() != null:
			owner_peer_id = str(get_parent().name).to_int()
		if owner_peer_id > 1:
			multiplayer_sync.set_visibility_for(owner_peer_id, false)
	
	var collider = get_node_or_null("player_main_collider")
	if collider and collider.shape is CapsuleShape3D:
		collider.shape = collider.shape.duplicate()
		_stand_height = collider.shape.height
		_stand_collider_y = collider.position.y
		print("[CROUCH] peer=%s stand_height=%.3f" % [name, _stand_height])
	else:
		print("[CROUCH] peer=%s collider NOT FOUND or wrong shape type" % name)
	_stand_neck_y = neck.position.y

	if not _is_local_player(): return

	var character_model = get_node_or_null("Ch36_nonPBR")
	if character_model:
		for child in character_model.find_children("*", "MeshInstance3D", true, false):
			child.layers = 2

	Local.set_state("input_active", true)
	camera.make_current()
	if Local.get_state("terrain"):
		Local.get_state("terrain").set_camera(camera)
	add_child(HUD)
	var health_slider = HUD.get_health_slider()
	health_slider.max_value = FULL_HEALTH
	health_slider.value = current_health
	
	# set up default character
	character = Character.new()
	character.load_from_character(Local.get_state("selected_character_def"))
	var selected_character_def: CharacterDef = Local.get_state("selected_character_def")
	if selected_character_def != null:
		character_id = String(selected_character_def.ID)
	# character.primary_weapon = WeaponRegister.gun_register["DefaultGun"].instantiate()
	# character.secondary_weapon = WeaponRegister.gun_register["DefaultPistol"].instantiate()
	character.set_bullet_origin(gun_location)
	character.equipment_1.equipment_instance = Equipment.new()
	character.equipment_2.equipment_instance = Equipment.new()
	# end default character
	swap_equipped(character.primary_weapon)
	# load from character 
	Local.set_state("player", self)
	Local.set_hud(HUD)
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
	if _is_local_player():
		HUD.get_node("health_slider").value = current_health

func char_serv_update(ids: Array):
	var peer_id_str := _get_peer_id_string()
	if peer_id_str not in ids:
		return
	var payload: Variant = Global.character_data.get(peer_id_str)
	if not (payload is Dictionary) or not payload.has("wep1"):
		return
	if multiplayer.is_server() and not server_spawn_assigned_by_faction:
		server_spawn_assigned_by_faction = _assign_server_spawn_from_character_faction()
	load_from_payload(payload)


func load_from_payload(payload: Dictionary):
	if payload.has("character_id"):
		character_id = String(payload["character_id"])
	if character == null:
		character = Character.new()
	character.load_from_payload(payload)
	swap_equipped_from_index(payload["active"], false)

func _ads(dt: float):
	if active_equipable is Weapon:
		active_equipable.transform.origin = active_equipable.transform.origin.\
			lerp(active_equipable.ads_position, active_equipable.ADS_LERP * dt)
		var t := Time.get_ticks_msec() * 0.001
		camera.rotation.x += sin(t * 1.3) * 0.00015 * ads_sway_amount
		camera.rotation.y += sin(t * 0.7) * 0.0001 * ads_sway_amount
		camera.fov = lerp(camera.fov, active_equipable.ads_fov, active_equipable.ADS_LERP * dt)
		if _is_local_player():
			var hud: Control = Local.get_hud()
			if hud != null:
				hud.set_hud_visible(false)

func _undo_ads(dt: float):
	if active_equipable is Weapon:
		active_equipable.transform.origin = active_equipable.transform.origin.\
			lerp(active_equipable.default_position,
				active_equipable.ADS_LERP * dt)
		camera.fov = lerp(camera.fov, float(Settings.FOV), active_equipable.ADS_LERP * dt)
		if _is_local_player():
			var hud: Control = Local.get_hud()
			if hud != null:
				hud.set_hud_visible(true)
	elif camera.fov != float(Settings.FOV):
		camera.fov = lerp(camera.fov, float(Settings.FOV), DEFAULT_LERP * dt)

func _set_crouch(crouching: bool) -> void:
	if is_crouching == crouching:
		return
	if _stand_height <= 0.0:
		push_warning("[CROUCH] _set_crouch called before _stand_height was initialized, ignoring")
		return
	is_crouching = crouching
	var collider = get_node_or_null("player_main_collider")
	if collider and collider.shape is CapsuleShape3D:
		collider.shape.height = CROUCH_HEIGHT if crouching else _stand_height
		if not crouching:
			global_position.y += (_stand_height - CROUCH_HEIGHT) / 2.0
	var model = get_node_or_null("Ch36_nonPBR")
	if model:
		model.crouch_state = 0 if crouching else 1
	if _is_local_player():
		play_character_state.rpc(name, "crouch" if crouching else "stand")

func _process_crouch(dt: float) -> void:
	var target_neck_y := (CROUCH_NECK_Y if is_crouching else _stand_neck_y)
	neck.position.y = lerp(neck.position.y, target_neck_y, CROUCH_LERP * dt)

func ground_check():
	return movement_handler.ground_check(self)

func _process(dt: float):
	input_handler.handle_process(self, dt)
	if _is_local_player():
		_process_crouch(dt)
	if _is_local_player() and (_hit_lurch_yaw != 0.0 or _hit_lurch_pitch != 0.0):
		_hit_lurch_yaw = lerpf(_hit_lurch_yaw, 0.0, HIT_LURCH_DECAY * dt)
		_hit_lurch_pitch = lerpf(_hit_lurch_pitch, 0.0, HIT_LURCH_DECAY * dt)
		_apply_look_rotation(net_yaw, net_pitch)


func _continue_gun_audio_on_swap(gun: Gun) -> void:
	# Reparent any in-flight audio to the camera so it keeps playing after
	# the gun node leaves the scene tree. Give the gun fresh players for its next use.
	for ap in [gun.audio_player, gun.bolt_pull_stream]:
		if not ap.is_playing():
			continue
		ap.reparent(camera)
		ap.finished.connect(ap.queue_free, CONNECT_ONE_SHOT)
		var fresh := AudioStreamPlayer3D.new()
		fresh.max_distance = ap.max_distance
		fresh.attenuation_model = ap.attenuation_model
		if ap == gun.audio_player:
			gun.audio_player = fresh
		else:
			gun.bolt_pull_stream = fresh
		gun.add_child(fresh)

# @rpc("call_local", "any_peer")
func swap_equipped(equipable: Equipable):
	if active_equipable != equipable:
		if active_equipable is Gun:
			_continue_gun_audio_on_swap(active_equipable as Gun)
		if active_equipable.get_parent() == camera:
			camera.remove_child(active_equipable)
		var remaining_cycle := 0.0
		if active_equipable is Gun:
			remaining_cycle = active_equipable.current_cycle
			if _is_local_player() and active_equipable.recoil.is_connected(_apply_recoil):
				active_equipable.recoil.disconnect(_apply_recoil)
		active_equipable._set_inactive()
		# play stow animation
		active_equipable = equipable
		# play raise animation
		if equipable is Gun and remaining_cycle > 0.0:
			equipable.current_cycle = maxf(equipable.current_cycle, remaining_cycle)
		if equipable is Gun and _is_local_player():
			equipable.recoil.connect(_apply_recoil)
		camera.add_child(equipable)
		equipable.transform.origin = equipable.default_position
		equipable._set_active()
		current_eqipped_key = equipable.key

func swap_equipped_from_index(id: int, call_rpc: bool):
	var equipable = update_equipment()[id]
	if active_equipable != equipable:
		if active_equipable is Gun:
			_continue_gun_audio_on_swap(active_equipable as Gun)
		if active_equipable.get_parent() == camera:
			camera.remove_child(active_equipable)
		var remaining_cycle := 0.0
		if active_equipable is Gun:
			remaining_cycle = active_equipable.current_cycle
			if _is_local_player() and active_equipable.recoil.is_connected(_apply_recoil):
				active_equipable.recoil.disconnect(_apply_recoil)
		active_equipable._set_inactive()
		# play stow animation
		active_equipable = equipable
		# play raise animation
		if equipable is Gun and remaining_cycle > 0.0:
			equipable.current_cycle = maxf(equipable.current_cycle, remaining_cycle)
		if equipable is Gun and _is_local_player():
			equipable.recoil.connect(_apply_recoil)
		camera.add_child(equipable)
		equipable.transform.origin = equipable.default_position
		equipable._set_active()
		current_equipped_index = id
		if call_rpc:
			update_character_server.rpc_id(1, "active", id)
		if _is_local_player():
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
	input_handler.handle_input_event(self, event)

func _set_movement_input(move_x: float, move_y: float, wants_sprint: bool, jump_pressed: bool, yaw: float, pitch: float) -> void:
	movement_handler.set_movement_input(self, move_x, move_y, wants_sprint, jump_pressed, yaw, pitch)

func _clear_movement_state() -> void:
	movement_handler.clear_movement_state(self)

func _update_local_health_ui() -> void:
	health_handler.update_local_health_ui(self)

func _set_local_death_ui(dead: bool) -> void:
	health_handler.set_local_death_ui(self, dead)

func _build_local_input(dt: float) -> Dictionary:
	return movement_handler.build_local_input(self, dt)

func _apply_input_packet(input_packet: Dictionary) -> void:
	movement_handler.apply_input_packet(self, input_packet)

func _capture_and_submit_input(dt: float) -> void:
	movement_handler.capture_and_submit_input(self, dt)

@rpc("any_peer", "unreliable_ordered")
func submit_movement_input(seq: int, move_x: float, move_y: float, wants_sprint: bool, jump_pressed: bool, yaw: float, pitch: float, client_dt: float = 0.0, wants_crouch: bool = false):
	movement_handler.apply_network_input(self, seq, move_x, move_y, wants_sprint, jump_pressed, yaw, pitch, client_dt, wants_crouch)

func _create_authoritative_state() -> Dictionary:
	return movement_handler.create_authoritative_state(self)

func _restore_authoritative_state(state: Dictionary) -> void:
	movement_handler.restore_authoritative_state(self, state)

func _discard_acknowledged_inputs(sequence: int) -> void:
	movement_handler.discard_acknowledged_inputs(self, sequence)

func _replay_pending_inputs() -> void:
	movement_handler.replay_pending_inputs(self)

@rpc("authority", "unreliable_ordered")
func reconcile_movement(sequence: int, state: Dictionary):
	movement_handler.reconcile(self, sequence, state)

@rpc("authority", "unreliable_ordered")
func receive_remote_snapshot(snapshot_position: Vector3, yaw: float, pitch: float, snapshot_velocity: Vector3):
	movement_handler.receive_remote_snapshot(self, snapshot_position, yaw, pitch, snapshot_velocity)

enum WALK_STATES {
	WALK,
	RUN,
	STOP
}

func _physics_process(dt: float):
	movement_handler.handle_physics(self, dt)


func _simulate_movement(dt: float, replicate_walk_state: bool, play_walk_locally: bool) -> void:
	movement_handler.simulate(self, dt, replicate_walk_state, play_walk_locally)

@rpc("call_local", "any_peer")
func call_help(id):
	if name == id:
		audio_player.stream = helps.pick_random()
		audio_player.play()

var play_state = {}

@rpc("call_local", "any_peer")
func play_character_state(id: String, state: String) -> void:
	if name == id:
		var model = get_node_or_null("Ch36_nonPBR")
		if model == null:
			return
		match state:
			"jump":
				if model.has_method("set_jumping"): model.set_jumping()
			"land":
				if model.has_method("set_landed"): model.set_landed()
			"downed":
				if model.has_method("set_downed"): model.set_downed()
			"revived":
				if model.has_method("set_revived"): model.set_revived()
			"crouch":
				model.crouch_state = 0
			"stand":
				model.crouch_state = 1

@rpc("call_local","any_peer")
func play_walk(id, walk_state):
	if name == id:
		var model = get_node_or_null("Ch36_nonPBR")
		if model and model.has_method("set_walk_state"):
			model.set_walk_state(walk_state)
		if walk_state == WALK_STATES.STOP:
			$footsteps.stop()
			play_state[name] = WALK_STATES.STOP
		elif walk_state == WALK_STATES.WALK:
			if not $footsteps.playing or play_state.get(name) != WALK_STATES.WALK:
				$footsteps.stream = walk
				$footsteps.autoplay = true
				$footsteps.play()
				play_state[name] = WALK_STATES.WALK
		elif walk_state == WALK_STATES.RUN:
			if not $footsteps.playing or play_state.get(name) != WALK_STATES.RUN:
				$footsteps.stream = run
				$footsteps.autoplay = true
				$footsteps.play()
				play_state[name] = WALK_STATES.RUN


func register_interaction(interactable: Interactable):
	if not _is_local_player(): return
	if current_health <= 0: return
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
	var char_def: CharacterDef = Local.get_state("selected_character_def")
	print("[PAYLOAD] faction=%s class_type=%s" % [char_def.Faction, char_def.ClassType])
	return {
		"active": current_equipped_index,
		"character_id": character_id,
		"name": char_def.Name,
		"wep1": char_def.Weapon1,
		"wep2": char_def.Weapon2,
		"wep3": char_def.Weapon3,
		"eq1": char_def.Equipment1,
		"eq2": char_def.Equipment2,
		"faction": char_def.Faction,
		"class_type": char_def.ClassType,
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

func hit(dmg: int, shooter_id: int = 0):
	health_handler.handle_hit(self, dmg, shooter_id)

@rpc("authority", "reliable")
func show_hit_marker() -> void:
	if _is_local_player() and Local.has_hud():
		HUD.hit()

@rpc("authority", "reliable")
func receive_hit_feedback(hit_world_yaw: float) -> void:
	if not _is_local_player():
		return
	var relative_angle := hit_world_yaw - net_yaw
	_hit_lurch_yaw = sin(relative_angle) * deg_to_rad(4.0)
	_hit_lurch_pitch = deg_to_rad(randf_range(1.5, 3.0))
	_apply_look_rotation(net_yaw, net_pitch)
	if Local.has_hud():
		HUD.show_hit_direction(relative_angle)


@rpc("any_peer", "reliable")
func _request_damage(dmg: int, shooter_id: int = 0):
	health_handler.request_damage(self, dmg, shooter_id)

func _apply_authoritative_damage(dmg: int):
	health_handler.apply_authoritative_damage(self, dmg)

@rpc("any_peer", "reliable")
func _request_heal(requested_heal: float):
	health_handler.request_heal(self, requested_heal)

func _apply_authoritative_heal(requested_heal: float):
	health_handler.apply_authoritative_heal(self, requested_heal)

@rpc("authority", "reliable")
func _sync_damage_feedback(updated_health: float):
	print("[HIT] _sync_damage_feedback received on node=%s health=%s" % [name, updated_health])
	health_handler.sync_damage_feedback(self, updated_health)

@rpc("authority", "reliable")
func _sync_heal_feedback(updated_health: float, updated_pool: float):
	health_handler.sync_heal_feedback(self, updated_health, updated_pool)

# this will be an RPC
func extract():
	if not _is_local_player(): return
	if Global.map_root != null and Global.map_root.has_method("notify_player_extracted"):
		Global.map_root.notify_player_extracted.rpc_id(1, character_id)
	if Global.map_root != null and Global.map_root.has_method("report_match_left"):
		Global.map_root.report_match_left("extract")
	notify_extract(character.has_objective)
	#Send RPC to server to remove node from scene
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Local.set_state("input_active", false)
	multiplayer.multiplayer_peer = null
	Local.set_state("has_objective", character.has_objective)
	if not get_tree().change_scene_to_file("res://ui/extraction/Extraction.tscn") == OK:
		print("Error getting to file")
	print('extract successful')

func notify_extract(objective_left):
	if objective_left and not Local.get_state("host"):
		var hud: Control = Local.get_hud()
		if hud != null:
			hud.notify.rpc("Objective has left the mission area", 3.0)

const BLEED_OUT_TIME: float = 60.0

func _get_faction() -> int:
	var peer_id_str := _get_peer_id_string()
	if Global.character_data.has(peer_id_str):
		return int(Global.character_data[peer_id_str].get("faction", -1))
	return -1

@rpc("authority", "reliable")
func _sync_down_state(new_down_count: int, new_full_health: float) -> void:
	down_count = new_down_count
	FULL_HEALTH = new_full_health
	play_character_state.rpc(name, "downed")

func start_bleed_out_timer() -> void:
	if not multiplayer.is_server():
		return
	var timer := Timer.new()
	timer.wait_time = BLEED_OUT_TIME
	timer.one_shot = true
	timer.timeout.connect(func():
		var peer_id := _get_peer_id_string().to_int()
		if Global.map_root != null:
			Global.map_root.remove_player(peer_id)
		timer.queue_free()
	)
	add_child(timer)
	timer.start()

@rpc("any_peer", "reliable")
func res(revive_health: float, resurrector_is_medic: bool = false):
	health_handler.handle_res(self, revive_health, resurrector_is_medic)

@rpc("any_peer", "reliable")
func _res_local(revive_health: float):
	health_handler.handle_res_local(self, revive_health)
	play_character_state.rpc(name, "revived")

@rpc("any_peer", "reliable")
func set_res_sphere(active: bool):
	res_sphere.monitorable = active
	res_sphere.monitoring = active
