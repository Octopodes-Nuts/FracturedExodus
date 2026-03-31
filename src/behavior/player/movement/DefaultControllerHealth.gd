extends RefCounted

func update_local_health_ui(controller) -> void:
	if not controller._is_local_player() or not controller.Local.has_hud():
		return
	controller.Local.get_hud().set_health_percent((controller.current_health / controller.FULL_HEALTH) * 100)

func set_local_death_ui(controller, dead: bool) -> void:
	if not controller._is_local_player() or not controller.Local.has_hud():
		return
	controller.Local.get_hud().set_dead_state(dead)

func handle_hit(controller, dmg: int, shooter_id: int = 0) -> void:
	print("[HIT] is_server=%s node=%s peer_id=%s dmg=%s health_before=%s" % [
		controller.multiplayer.is_server(), controller.name,
		controller._get_peer_id_string(), dmg, controller.current_health])
	if controller.multiplayer.is_server():
		apply_authoritative_damage(controller, dmg, shooter_id)
		var damaged_peer_id = controller._get_peer_id_string().to_int()
		print("[HIT] server applied dmg, health_after=%s, sending rpc_id to peer=%s" % [controller.current_health, damaged_peer_id])
		if damaged_peer_id == controller.multiplayer.get_unique_id():
			sync_damage_feedback(controller, controller.current_health)
		else:
			controller._sync_damage_feedback.rpc_id(damaged_peer_id, controller.current_health)
		controller.play_hit_noise.rpc(controller.name)
	else:
		print("[HIT] client sending _request_damage rpc_id(1)")
		controller._request_damage.rpc_id(1, dmg, shooter_id)

func request_damage(controller, dmg: int, shooter_id: int = 0) -> void:
	if not controller.multiplayer.is_server():
		return
	var sender_id: int = controller.multiplayer.get_remote_sender_id()
	if sender_id != controller._get_peer_id_string().to_int():
		return
	apply_authoritative_damage(controller, dmg, shooter_id)
	var damaged_peer_id = controller._get_peer_id_string().to_int()
	if damaged_peer_id == controller.multiplayer.get_unique_id():
		sync_damage_feedback(controller, controller.current_health)
	else:
		controller._sync_damage_feedback.rpc_id(damaged_peer_id, controller.current_health)
	controller.play_hit_noise.rpc(controller.name)

func apply_authoritative_damage(controller, dmg: int, shooter_id: int = 0) -> void:
	controller._set_current_health(controller.current_health - dmg)
	if controller.current_health <= 0:
		controller._clear_movement_state()
		controller.set_res_sphere(true)
		controller.set_res_sphere.rpc(true)
		if shooter_id != 0:
			Global.map_root.record_kill(shooter_id, controller._get_peer_id_string().to_int())

func request_heal(controller, requested_heal: float) -> void:
	if not controller.multiplayer.is_server():
		return
	var sender_id: int = controller.multiplayer.get_remote_sender_id()
	if sender_id != controller._get_peer_id_string().to_int():
		return
	apply_authoritative_heal(controller, requested_heal)
	var healed_peer_id = controller._get_peer_id_string().to_int()
	var medpack_pool := 0.0
	if controller.active_equipable is MedPack:
		medpack_pool = controller.active_equipable.health_pool
	if healed_peer_id == controller.multiplayer.get_unique_id():
		sync_heal_feedback(controller, controller.current_health, medpack_pool)
	else:
		controller._sync_heal_feedback.rpc_id(healed_peer_id, controller.current_health, medpack_pool)

func apply_authoritative_heal(controller, requested_heal: float) -> void:
	if requested_heal <= 0.0:
		return
	if not (controller.active_equipable is MedPack):
		return
	if controller.current_health >= controller.FULL_HEALTH:
		return

	var medpack: MedPack = controller.active_equipable
	if medpack.health_pool <= 0.0:
		return

	var heal_amount := requested_heal
	heal_amount = minf(heal_amount, controller.FULL_HEALTH - controller.current_health)
	heal_amount = minf(heal_amount, medpack.health_pool)
	if heal_amount <= 0.0:
		return

	controller._set_current_health(controller.current_health + heal_amount)
	medpack.health_pool -= heal_amount

func sync_damage_feedback(controller, updated_health: float) -> void:
	print("[HIT] sync_damage_feedback node=%s health=%s is_local=%s" % [controller.name, updated_health, controller._is_local_player()])
	controller._set_current_health(updated_health)
	update_local_health_ui(controller)
	set_local_death_ui(controller, controller.current_health <= 0)

func sync_heal_feedback(controller, updated_health: float, updated_pool: float) -> void:
	controller._set_current_health(updated_health)
	if controller.active_equipable is MedPack:
		controller.active_equipable.health_pool = updated_pool
	update_local_health_ui(controller)
	set_local_death_ui(controller, false)
	if controller._is_local_player() and controller.Local.has_hud():
		controller.Local.get_hud().display_ammo(controller.active_equipable.get_ammo())

func handle_res(controller, revive_health: float) -> void:
	if not controller.multiplayer.is_server():
		return

	controller._set_current_health(revive_health)
	var revived_peer_id = controller._get_peer_id_string().to_int()
	if revived_peer_id == controller.multiplayer.get_unique_id():
		handle_res_local(controller, revive_health)
	else:
		controller._res_local.rpc_id(revived_peer_id, revive_health)

func handle_res_local(controller, revive_health: float) -> void:
	controller._set_current_health(revive_health)
	update_local_health_ui(controller)
	set_local_death_ui(controller, false)
	controller.set_res_sphere(false)
	controller.set_res_sphere.rpc(false)
