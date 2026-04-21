extends RefCounted

func handle_process(controller, dt: float) -> void:
	controller.delta = dt
	if not controller._is_local_player():
		controller._update_remote_proxy(dt)
		return

	var local_input_active: bool = controller.Local.get_state("input_active")
	if Input.is_action_just_pressed("primary_weapon") and local_input_active:
		controller.swap_equipped_from_index(0, true)
	elif Input.is_action_just_pressed("secondary_weapon") and local_input_active:
		controller.swap_equipped_from_index(1, true)
	elif Input.is_action_just_pressed("tertiary_weapon") and local_input_active:
		controller.swap_equipped_from_index(2, true)
	elif Input.is_action_just_pressed("medpack") and local_input_active:
		controller.swap_equipped_from_index(3, true)
	elif Input.is_action_just_pressed("equipment_1") and local_input_active and controller.character.equipment_1.equipment_instance != null:
		controller.swap_equipped_from_index(4, true)
	elif Input.is_action_just_pressed("equipment_2") and local_input_active and controller.character.equipment_2.equipment_instance != null:
		controller.swap_equipped_from_index(5, true)
	elif Input.is_action_just_pressed("use_scanner") and controller.character.has_scanner:
		if local_input_active and controller.character.scanner != null:
			controller.swap_equipped_from_index(6, true)

	var is_sprinting: bool = Input.is_action_pressed("sprint") and local_input_active

	if Input.is_action_pressed("ads") and local_input_active and not is_sprinting:
		controller._ads(dt)
	else:
		controller._undo_ads(dt)

	if Input.is_action_pressed("ads") and local_input_active and not is_sprinting and controller.active_equipable is Weapon and controller.is_on_floor():
		controller.active_equipable.ads = true
	if (Input.is_action_just_released("ads") and local_input_active and controller.active_equipable is Weapon) or not controller.is_on_floor() or is_sprinting:
		controller.active_equipable.ads = false

	if Input.is_action_just_pressed("crouch") and local_input_active and controller.current_health > 0:
		controller._set_crouch(not controller.is_crouching)

	if Input.is_action_just_pressed("sprint") and controller.is_crouching and local_input_active:
		controller._set_crouch(false)

	if Input.is_action_just_pressed("exit"):
		_toggle_escape_menu(controller)

func handle_input_event(controller, event: InputEvent) -> void:
	if not controller._is_local_player() or controller.current_health <= 0:
		return
	if controller.Local.get_state("input_active") and event is InputEventMouseMotion:
		controller.net_yaw += deg_to_rad(-event.relative.x * controller.mouse_sensitivity)
		controller.net_pitch += deg_to_rad(-event.relative.y * controller.mouse_sensitivity)
		controller.net_pitch = clamp(controller.net_pitch, deg_to_rad(-89), deg_to_rad(89))
		controller._apply_look_rotation(controller.net_yaw, controller.net_pitch)

func _toggle_escape_menu(controller) -> void:
	if controller.Local.get_state("input_active"):
		controller.Local.set_state("input_active", false)
		controller.add_child(controller.escape_menu)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		controller.Local.set_state("input_active", true)
		controller.remove_child(controller.escape_menu)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
