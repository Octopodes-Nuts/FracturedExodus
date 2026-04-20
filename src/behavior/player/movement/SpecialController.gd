###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends DefaultController

class_name SpecialController

# Reduced sway and increased zoom on ironsights compared to other classes
@export var ads_zoom_buff: float = 1.2
# Extra movement speed penalty while ADS — special operators commit when they aim
@export var ads_movement_penalty: float = 1.5

func _ads(dt: float):
	if active_equipable is Weapon:
		active_equipable.transform.origin = active_equipable.transform.origin.\
			lerp(active_equipable.ads_position, active_equipable.ADS_LERP * dt)
		var t := Time.get_ticks_msec() * 0.001
		camera.rotation.x += sin(t * 1.3) * 0.00015 * ads_sway_amount
		camera.rotation.y += sin(t * 0.7) * 0.0001 * ads_sway_amount
		camera.fov = lerp(camera.fov, active_equipable.ads_fov / ads_zoom_buff, active_equipable.ADS_LERP * dt)
		if _is_local_player():
			var hud: Control = Local.get_hud()
			if hud != null:
				hud.set_hud_visible(false)
