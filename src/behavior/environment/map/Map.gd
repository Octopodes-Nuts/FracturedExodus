###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends WorldEnvironment

@onready var Global = get_node('/root/Global')
@onready var Game = $"./Game"
@onready var matchmaking_api: MatchmakingAPI = $MatchmakingApi
@onready var PlayerSpawner: MultiplayerSpawner = $PlayerSpawner

@onready var heartbeat_timer: Timer = Timer.new()
var heartbeat_interval: float = 15.0

var Player = preload("res://behavior/player/Player.tscn")
var Chipsite = preload("res://behavior/environment/interactables/chipsite/Chipsite.tscn")

const PORT: int = 8080
var enet_peer = ENetMultiplayerPeer.new()
var player_count = 0

signal character_update(ids: Array)
signal player_added(id: String)
signal player_left(peer_id: int, character_id: String)
signal match_left(reason: String)

var _match_left_reported: bool = false

# kill_stats: { peer_id_int -> { "kills": int, "ai_kills": int, "deaths": int } }
var kill_stats: Dictionary = {}
var early_leave_character_ids: Dictionary = {}
var extracted_character_ids: Dictionary = {}

const XP_PER_KILL: int = 100
const XP_PER_AI_KILL: int = 25
const XP_PER_DEATH: int = 10

func record_kill(shooter_id: int, victim_id: int) -> void:
	if not multiplayer.is_server():
		return
	if not kill_stats.has(shooter_id):
		kill_stats[shooter_id] = {"kills": 0, "ai_kills": 0, "deaths": 0}
	kill_stats[shooter_id]["kills"] += 1
	if not kill_stats.has(victim_id):
		kill_stats[victim_id] = {"kills": 0, "ai_kills": 0, "deaths": 0}
	kill_stats[victim_id]["deaths"] += 1

func record_ai_kill(shooter_id: int) -> void:
	if not multiplayer.is_server():
		return
	if not kill_stats.has(shooter_id):
		kill_stats[shooter_id] = {"kills": 0, "ai_kills": 0, "deaths": 0}
	kill_stats[shooter_id]["ai_kills"] += 1

func _compute_xp(stats: Dictionary) -> int:
	return stats["kills"] * XP_PER_KILL + stats["ai_kills"] * XP_PER_AI_KILL + stats["deaths"] * XP_PER_DEATH

func _collect_valid_chipsite_spawns() -> Array[Node3D]:
	var valid_chipsite_spawns: Array[Node3D] = []
	for spawn in Global.chipsite_spawns:
		if not is_instance_valid(spawn):
			continue
		if not (spawn is Node3D):
			continue
		if not spawn.is_inside_tree():
			continue
		valid_chipsite_spawns.append(spawn)
	return valid_chipsite_spawns

func _spawn_custom_networked_node(data: Variant) -> Node:
	if not (data is Dictionary):
		return null
	if String(data.get("kind", "")) != "chipsite":
		return null
	var chipsite := Chipsite.instantiate()
	var spawn_position: Vector3 = data.get("position", Vector3.ZERO)
	# This runs before the node is added to the tree, so defer global placement.
	chipsite.set_deferred("global_position", spawn_position)
	return chipsite

func _setup_as_server(context: String = ""):
	var err = enet_peer.create_server(PORT)
	if err != OK:
		push_error("[Map] Failed to create server%s on port %d (error=%d)" % [context, PORT, err])
		return false

	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	set_multiplayer_authority(1)
	print("[Map] Server started%s on port %d" % [context, PORT])
	return true
	
func leave_game():
	report_match_left("leave_game")
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file.call_deferred("res://ui/main_menu/MainMenu.tscn")

# When tree is entered, set as the map root
func _ready():
	randomize()
	Global.map_root = self
	Global.bullet_spawn = $Bullet
	PlayerSpawner.spawn_function = Callable(self, "_spawn_custom_networked_node")
	connect("character_update", Global.emit_character_update)
	player_left.connect(_on_player_left)
	match_left.connect(_on_match_left)

	if Local.get_state("host"):
		_setup_as_server(" (host mode)")
	
	else:
		multiplayer.connected_to_server.connect(_on_connection)
		multiplayer.connection_failed.connect(_on_connection_failed)
		#enet_peer.create_client("34.55.251.69", PORT)
		print("Attempting to connect to server at %s:%d" % [Local.get_state("ip"), Local.get_state("port")])
		var client_err = enet_peer.create_client(Local.get_state("server_ip"), int(Local.get_state("port")))
		# var  client_err = enet_peer.create_client("192.168.1.238", int(Local.get_state("port")))
		if client_err == OK:
			multiplayer.multiplayer_peer = enet_peer
			matchmaking_api.joined_match()
			print("[Map] Client connection request sent to localhost:%d" % [Local.get_state("port")])
			heartbeat_timer.wait_time = heartbeat_interval
			heartbeat_timer.timeout.connect(_send_heartbeat)
			add_child(heartbeat_timer)
			heartbeat_timer.start()
			return
		else:
			push_error("[Map] Failed to create client for localhost:%d (error=%d). Falling back to server setup." % [Local.get_state("port"), client_err])
			_setup_as_server(" (client creation fallback)")
			
	
	if Global.chipsite_spawns.is_empty():
		push_warning("[Map] No ChipsiteSpawn nodes registered. Skipping chipsite spawn.")
		return

	var valid_chipsite_spawns: Array[Node3D] = _collect_valid_chipsite_spawns()

	if valid_chipsite_spawns.is_empty():
		await get_tree().process_frame
		valid_chipsite_spawns = _collect_valid_chipsite_spawns()
		if valid_chipsite_spawns.is_empty():
			push_warning("[Map] ChipsiteSpawn nodes exist but none are inside tree yet. Skipping chipsite spawn.")
			return

	# Keep global registry clean so future selections don't hit stale references.
	Global.chipsite_spawns = valid_chipsite_spawns

	var selected_chipsite_spawn: Node3D = valid_chipsite_spawns[randi() % len(valid_chipsite_spawns)]
	print("[MAP][CHIPSITE SPAWN] ", selected_chipsite_spawn.global_position)
	var chipsite_spawn_position: Vector3 = selected_chipsite_spawn.global_position
	if chipsite_spawn_position.is_equal_approx(Vector3.ZERO):
		push_warning("[Map] ChipsiteSpawn is at world origin. Move the ChipsiteSpawn node in the map scene.")

	if multiplayer.is_server():
		var chipsite_payload := {
			"kind": "chipsite",
			"position": chipsite_spawn_position
		}
		var spawned_chipsite := PlayerSpawner.spawn(chipsite_payload)
		if spawned_chipsite is Node3D:
			spawned_chipsite.global_position = chipsite_spawn_position

func _on_connection():
	var char_def: CharacterDef = Local.get_state("selected_character_def")
	if char_def == null:
		push_error("[Map] No character selected, cannot register player")
		return
	register_player.rpc_id(1, int(char_def.Faction), int(char_def.ClassType), String(char_def.ID))

func _on_connection_failed():
	push_warning("[Map] Connection to server failed. Attempting local server fallback.")
	_setup_as_server(" (connection failed fallback)")
	_spawn_local_player()

@rpc("authority", "reliable")
func broadcast_character_data(payload):
	Global.character_data = payload
	emit_signal("character_update", Global.character_data.keys())
	
@rpc("authority", "reliable")
func broadcast_character_data_update(id, field: String, val):
	Global.character_data[id][field] = val
	emit_signal("character_update", [id])

@rpc("any_peer", "reliable")
func register_player(faction: int, class_type: int, character_id: String = "") -> void:
	if not multiplayer.is_server():
		return
	var sender_id := str(multiplayer.get_remote_sender_id())
	# Pre-populate faction so _assign_server_spawn_from_character_faction() works in _ready()
	Global.character_data[sender_id] = {
		"faction": faction,
		"class_type": class_type,
		"character_id": character_id,
	}
	var scene := _get_class_scene(faction, class_type)
	var player = scene.instantiate()
	_set_spawned_player_character_id(player, character_id)
	player.name = sender_id
	$Spawns.add_child(player)
	player_count += 1

func _spawn_local_player() -> void:
	var char_def: CharacterDef = Local.get_state("selected_character_def")
	if char_def == null:
		return
	var faction := int(char_def.Faction)
	var class_type := int(char_def.ClassType)
	var character_id := String(char_def.ID)
	var peer_id := str(multiplayer.get_unique_id())
	Global.character_data[peer_id] = {
		"faction": faction,
		"class_type": class_type,
		"character_id": character_id,
	}
	var scene := _get_class_scene(faction, class_type)
	var player = scene.instantiate()
	_set_spawned_player_character_id(player, character_id)
	player.name = peer_id
	$Spawns.add_child(player)
	player_count += 1

func _get_class_scene(faction: int, class_type: int) -> PackedScene:
	var scene: PackedScene
	match faction:
		Factions.Enum.ENTENTE:
			scene = ClassRegister.entente_classes.get(class_type)
		Factions.Enum.EMPIRE:
			scene = ClassRegister.empire_classes.get(class_type)
		Factions.Enum.FREE_AGENTS:
			scene = ClassRegister.free_agent_classes.get(class_type)
	return scene if scene != null else Player

func _set_spawned_player_character_id(spawned_player: Node, id: String) -> void:
	if spawned_player == null:
		return
	if spawned_player is DefaultController:
		spawned_player.character_id = id
		return
	var player_body := spawned_player.get_node_or_null("player_body")
	if player_body is DefaultController:
		player_body.character_id = id

func _on_peer_disconnected(peer_id: int) -> void:
	_mark_player_left_early(peer_id)
	remove_player(peer_id)

func _mark_player_left_early(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	var peer_key := str(peer_id)
	if not Global.character_data.has(peer_key):
		return
	var payload: Variant = Global.character_data[peer_key]
	if not (payload is Dictionary):
		return
	var character_id := String(payload.get("character_id", ""))
	if character_id.is_empty():
		return
	if extracted_character_ids.has(character_id):
		return
	if early_leave_character_ids.has(character_id):
		return
	early_leave_character_ids[character_id] = true
	print("[Map][LEAVE] peer=%s character_id=%s marked as early leave" % [peer_key, character_id])
	emit_signal("player_left", peer_id, character_id)

@rpc("any_peer", "reliable")
func notify_player_extracted(character_id: String = "") -> void:
	if not multiplayer.is_server():
		return
	var sender_id := str(multiplayer.get_remote_sender_id())
	if character_id.is_empty() and Global.character_data.has(sender_id):
		var payload: Variant = Global.character_data[sender_id]
		if payload is Dictionary:
			character_id = String(payload.get("character_id", ""))
	if character_id.is_empty():
		return
	extracted_character_ids[character_id] = true
	early_leave_character_ids.erase(character_id)
	print("[Map][EXTRACT] peer=%s character_id=%s marked extracted" % [sender_id, character_id])

func _on_player_left(_peer_id: int, character_id: String) -> void:
	if not multiplayer.is_server():
		return
	if character_id.is_empty():
		return
	if extracted_character_ids.has(character_id):
		return
	if matchmaking_api != null and matchmaking_api.has_method("delete_character_forfeit"):
		matchmaking_api.delete_character_forfeit(character_id)

func remove_player(peer_id):
	var player = $Spawns.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
	Global.character_data.erase(str(peer_id))
	player_count = maxi(player_count - 1, 0)
	if player_count == 0:
		end_match()

func end_match():
	if Local.get_state("host"):
		_broadcast_match_xp()
		matchmaking_api.match_ended()
		matchmaking_api.match_ended_reported.connect(_on_match_ended_reported)
	else:
		report_match_left("end_match")

func _on_match_ended_reported():
	var quit_timer := Timer.new()
	quit_timer.wait_time = 2.0
	quit_timer.one_shot = true
	quit_timer.timeout.connect(get_tree().quit)
	get_tree().root.add_child(quit_timer)
	quit_timer.start()

func _broadcast_match_xp() -> void:
	for peer_id_int in kill_stats:
		var xp := _compute_xp(kill_stats[peer_id_int])
		if xp <= 0:
			continue
		if peer_id_int == multiplayer.get_unique_id():
			_receive_match_xp(xp)
		else:
			_receive_match_xp.rpc_id(peer_id_int, xp)

@rpc("authority", "reliable")
func _receive_match_xp(xp: int) -> void:
	Local.set_state("pending_xp", Local.get_state("pending_xp") + xp)

func report_match_left(reason: String = ""):
	if _match_left_reported:
		return
	_match_left_reported = true
	emit_signal("match_left", reason)

func _on_match_left(reason: String) -> void:
	if Local.get_state("host"):
		return
	if matchmaking_api != null:
		matchmaking_api.leave_match()
		print("[Map] Reported match left (%s)" % reason)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		report_match_left("wm_close_request")

func _exit_tree() -> void:
	report_match_left("map_exit_tree")

func _send_heartbeat():
	matchmaking_api.send_match_heartbeat()
