###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends WorldEnvironment

@onready var Global = get_node('/root/Global')
@onready var Game = $"./Game"
@onready var MatchmakingAPI = $MatchmakingApi
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
signal match_left(reason: String)

var _match_left_reported: bool = false

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
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	set_multiplayer_authority(1)
	print("[Map] Server started%s on port %d" % [context, PORT])
	return true

# When tree is entered, set as the map root
func _ready():
	randomize()
	Global.map_root = self
	Global.bullet_spawn = $Bullet
	PlayerSpawner.spawn_function = Callable(self, "_spawn_custom_networked_node")
	connect("character_update", Global.emit_character_update)
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
			MatchmakingAPI.joined_match()
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
	pass
func _on_connection_failed():
	push_warning("[Map] Connection to server failed. Attempting local server fallback.")
	_setup_as_server(" (connection failed fallback)")

@rpc("authority", "reliable")
func broadcast_character_data(payload):
	Global.character_data = payload
	emit_signal("character_update", Global.character_data.keys())
	
@rpc("authority", "reliable")
func broadcast_character_data_update(id, field: String, val):
	Global.character_data[id][field] = val
	emit_signal("character_update", [id])

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	$Spawns.add_child(player)
	player_count += 1
	
func remove_player(peer_id):
	var player = $Spawns.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
	player_count -= 1
	if player_count == 0:
		end_match()

func end_match():
	if Local.get_state("host"):
		MatchmakingAPI.match_ended()
		MatchmakingAPI.match_ended_reported.connect(func(): get_tree().quit())
	else:
		report_match_left("end_match")

func report_match_left(reason: String = ""):
	if _match_left_reported:
		return
	_match_left_reported = true
	emit_signal("match_left", reason)

func _on_match_left(reason: String) -> void:
	if Local.get_state("host"):
		return
	if MatchmakingAPI != null:
		MatchmakingAPI.leave_match()
		print("[Map] Reported match left (%s)" % reason)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		report_match_left("wm_close_request")

func _exit_tree() -> void:
	report_match_left("map_exit_tree")

func _send_heartbeat():
	MatchmakingAPI.send_match_heartbeat()
