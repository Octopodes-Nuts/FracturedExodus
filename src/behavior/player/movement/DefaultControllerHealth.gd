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
	var sender_id: int = controller.multiplayer.get_remote_sender_id()
	if sender_id != str(controller.name).to_int():
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

func request_heal(controller, requested_heal: float) -> void:
	if not controller.multiplayer.is_server():
		return
	var sender_id: int = controller.multiplayer.get_remote_sender_id()
	if sender_id != str(controller.name).to_int():
		return
	apply_authoritative_heal(controller, requested_heal)
	var healed_peer_id := str(controller.name).to_int()
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

	controller.current_health += heal_amount
	medpack.health_pool -= heal_amount

func sync_damage_feedback(controller, updated_health: float) -> void:
	controller.current_health = updated_health
	update_local_health_ui(controller)
	set_local_death_ui(controller, controller.current_health <= 0)

func sync_heal_feedback(controller, updated_health: float, updated_pool: float) -> void:
	controller.current_health = updated_health
	if controller.active_equipable is MedPack:
		controller.active_equipable.health_pool = updated_pool
	update_local_health_ui(controller)
	set_local_death_ui(controller, false)
	if controller._is_local_player() and controller.Local.HUD != null:
		controller.Local.HUD.display_ammo(controller.active_equipable.get_ammo())

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