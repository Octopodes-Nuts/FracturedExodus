###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends DefaultController

class_name OfficerController

# Movement speed multiplier applied to nearby squadmates
@export var speed_buff: float = 1.1
# Radius within which the speed buff applies
@export var speed_buff_radius: float = 10.0

var _aura_timer: float = 0.0
const _AURA_INTERVAL: float = 0.15

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not multiplayer.is_server():
		return
	_aura_timer += delta
	if _aura_timer < _AURA_INTERVAL:
		return
	_aura_timer = 0.0
	_apply_aura()

func _apply_aura() -> void:
	var max_nearby_sprint := MAX_SPRINT
	var my_faction: int = _get_faction()
	for node in get_tree().get_nodes_in_group("players"):
		if node == self or not node is DefaultController:
			continue
		if node._get_faction() != my_faction:
			continue
		var dist: float = global_position.distance_to(node.global_position)
		if dist > speed_buff_radius:
			if node.officer_speed_buff > 1.0:
				node.officer_speed_buff = 1.0
			continue
		node.officer_speed_buff = speed_buff
		var eff := _effective_sprint(node)
		if eff > max_nearby_sprint:
			max_nearby_sprint = eff
	# Officer matches the fastest nearby player's speed
	officer_speed_buff = max(speed_buff, max_nearby_sprint / MAX_SPRINT)

func _effective_sprint(player: DefaultController) -> float:
	var base := player.MAX_SPRINT
	if player is InfantryController and player.current_equipped_index == 2:
		base *= player.stowed_speed_buff
	return base * player.officer_speed_buff
