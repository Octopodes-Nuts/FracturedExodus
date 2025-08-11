###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends WorldEnvironment

@onready var Global = get_node('/root/Global')
var Player = preload("res://behavior/player/Player.tscn")
var Chipsite = preload("res://behavior/environment/interactables/chipsite/Chipsite.tscn")

# When tree is entered, set as the map root
func _ready():
	randomize()
	Global.map_root = self
	var spawn_number = randi_range(0, len(Global.spawns) - 1)
	
	var player: Node = Player.instantiate()
	player.transform.origin = Global.spawns[spawn_number].transform.origin
	$NavigationRegion3D.add_child(player)
	
	spawn_number = randi_range(0, len(Global.chipsite_spawns) - 1)
	var chipsite = Chipsite.instantiate()
	chipsite.transform.origin = Global.chipsite_spawns[spawn_number].transform.origin
	$NavigationRegion3D.add_child(chipsite)
