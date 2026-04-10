
extends Node

class_name Lobby


@export var PORT: int
@export var MAX_CLIENTS: int
var peer = ENetMultiplayerPeer.new()


func _ready():
	# setup server
	peer.create_server(PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer
