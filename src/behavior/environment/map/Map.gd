###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends WorldEnvironment

@onready var Global = get_node('/root/Global')
@onready var Game = $"./Game"
var Player = preload("res://behavior/player/Player.tscn")
var Chipsite = preload("res://behavior/environment/interactables/chipsite/Chipsite.tscn")

const PORT: int = 8080
var enet_peer = ENetMultiplayerPeer.new()
var player_count = 0

signal character_update(ids: Array)
signal player_added(id: String)

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
	connect("character_update", Global.emit_character_update)

	if Local.host:
		_setup_as_server(" (host mode)")
	
	else:
		multiplayer.connected_to_server.connect(_on_connection)
		multiplayer.connection_failed.connect(_on_connection_failed)
		#enet_peer.create_client("34.55.251.69", PORT)
		print("Attempting to connect to server at %s:%d" % [Local.ip, Local.port])
		var client_err = enet_peer.create_client("localhost", Local.port)
		if client_err == OK:
			multiplayer.multiplayer_peer = enet_peer
			print("[Map] Client connection request sent to localhost:%d" % [Local.port])
		else:
			push_error("[Map] Failed to create client for localhost:%d (error=%d). Falling back to server setup." % [Local.port, client_err])
			_setup_as_server(" (client creation fallback)")
			
	
	var chipsite = Chipsite.instantiate()
	chipsite.transform.origin = Global.chipsite_spawns[randi() % len(Global.chipsite_spawns)].transform.origin
	$Spawns.add_child(chipsite)

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
		# reload script
		get_tree().change_scene_to_file("res://environment/maps/test_map_2/test_map_2.tscn")
		
@rpc("any_peer")
func spawn_box(position):
	var mesh = BoxMesh.new()
	mesh.size = Vector3(1, 1, 1)
	
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	add_child(mi)
	print(mi)
	mi.global_transform.origin = position
