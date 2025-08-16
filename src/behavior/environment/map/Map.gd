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

# When tree is entered, set as the map root
func _ready():
	randomize()
	Global.map_root = self

	if Local.host:
		print("HOST")
		enet_peer.create_server(PORT)
		multiplayer.multiplayer_peer = enet_peer
		multiplayer.peer_connected.connect(add_player)
		multiplayer.peer_connected.connect(remove_player)
	
	else:
		enet_peer.create_client("localhost", PORT)
		multiplayer.multiplayer_peer = enet_peer
	
	var chipsite = Chipsite.instantiate()
	chipsite.transform.origin = Global.chipsite_spawns[randi() % len(Global.chipsite_spawns)].transform.origin
	$Spawns.add_child(chipsite)

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	$Spawns.add_child(player)
	
	
func remove_player(peer_id):
	var player = get_node_or_null("$Players/" + str(peer_id))
	if player:
		player.queue_free()
