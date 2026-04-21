###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Equipment

class_name  MedPack

@export var heal_rate: float = 15
@export var health_pool: float = 150

@export var pre_start = 0.5

var used_this_frame: bool = false
var _ramp_timer: float = 0.0

func _init():
	continuous_usage = true

func _process(delta):
	if not Input.is_action_pressed("fire"):
		_ramp_timer = 0.0

func use(controller: DefaultController):

	if controller.current_health >= controller.FULL_HEALTH or health_pool <= 0:
		return

	_ramp_timer += controller.delta
	if _ramp_timer < pre_start:
		return

	var requested_heal: float = heal_rate * controller.delta
	if requested_heal <= 0.0:
		return

	if controller.multiplayer.is_server():
		controller._apply_authoritative_heal(requested_heal)
		controller._sync_heal_feedback(controller.current_health, health_pool)
	else:
		controller._request_heal.rpc_id(1, requested_heal)

func get_ammo():
	return [int(health_pool), 0]
