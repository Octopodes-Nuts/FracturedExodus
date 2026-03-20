extends RefCounted

func update_local_health_ui(controller) -> void:
	if not controller._is_local_player() or controller.Local.HUD == null:
		return
	controller.Local.HUD.health_slider.value = (controller.current_health / controller.FULL_HEALTH) * 100

func set_local_death_ui(controller, dead: bool) -> void:
	if not controller._is_local_player() or controller.Local.HUD == null:
		return
	controller.Local.HUD.crosshair.visible = not dead
	controller.Local.HUD.death_text.visible = dead

func handle_hit(controller, dmg: int) -> void:
	if controller.multiplayer.is_server():
		apply_authoritative_damage(controller, dmg)
		var damaged_peer_id := str(controller.name).to_int()
		if damaged_peer_id == controller.multiplayer.get_unique_id():
			sync_damage_feedback(controller, controller.current_health)
		else:
			controller._sync_damage_feedback.rpc_id(damaged_peer_id, controller.current_health)
		controller.play_hit_noise.rpc(controller.name)
	else:
		controller._request_damage.rpc_id(1, dmg)

func request_damage(controller, dmg: int) -> void:
	if not controller.multiplayer.is_server():
		return
	apply_authoritative_damage(controller, dmg)
	var damaged_peer_id := str(controller.name).to_int()
	if damaged_peer_id == controller.multiplayer.get_unique_id():
		sync_damage_feedback(controller, controller.current_health)
	else:
		controller._sync_damage_feedback.rpc_id(damaged_peer_id, controller.current_health)
	controller.play_hit_noise.rpc(controller.name)

func apply_authoritative_damage(controller, dmg: int) -> void:
	controller.current_health -= dmg
	if controller.current_health <= 0:
		controller._clear_movement_state()
		controller.set_res_sphere(true)
		controller.set_res_sphere.rpc(true)

func sync_damage_feedback(controller, updated_health: float) -> void:
	controller.current_health = updated_health
	update_local_health_ui(controller)
	set_local_death_ui(controller, controller.current_health <= 0)

func handle_res(controller, revive_health: float) -> void:
	if not controller.multiplayer.is_server():
		return

	controller.current_health = revive_health
	var revived_peer_id := str(controller.name).to_int()
	if revived_peer_id == controller.multiplayer.get_unique_id():
		handle_res_local(controller, revive_health)
	else:
		controller._res_local.rpc_id(revived_peer_id, revive_health)

func handle_res_local(controller, revive_health: float) -> void:
	controller.current_health = revive_health
	update_local_health_ui(controller)
	set_local_death_ui(controller, false)
	controller.set_res_sphere(false)
	controller.set_res_sphere.rpc(false)