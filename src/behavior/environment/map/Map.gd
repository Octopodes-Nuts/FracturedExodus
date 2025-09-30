###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends WorldEnvironment

@onready var Global = get_node('/root/Global')
var Player = preload("res://behavior/player/Player.tscn")
var Chipsite = preload("res://behavior/environment/interactables/chipsite/Chipsite.tscn")

const PORT: int = 7072
var enet_peer = ENetMultiplayerPeer.new()
var player_count = 0

signal character_update(ids: Array)

# When tree is entered, set as the map root
func _ready():
	randomize()
	Global.map_root = self
	Global.bullet_spawn = $Bullet
	connect("character_update", Global.emit_character_update)

	if Local.host:
		enet_peer.create_server(PORT)
		multiplayer.multiplayer_peer = enet_peer
		multiplayer.peer_connected.connect(add_player)
		multiplayer.peer_disconnected.connect(remove_player)
		set_multiplayer_authority(1)
	
	else:
		enet_peer.create_client("localhost", PORT)
		multiplayer.multiplayer_peer = enet_peer
	
	var chipsite = Chipsite.instantiate()
	chipsite.transform.origin = Global.chipsite_spawns[randi() % len(Global.chipsite_spawns)].transform.origin
	$Spawns.add_child(chipsite)

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
