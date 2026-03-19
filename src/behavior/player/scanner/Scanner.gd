###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Equipable

class_name Scanner

@onready var Global = get_node("/root/Global")
@onready var notifier: ScannerLight = $notifier

var detected: bool = false

func _physics_process(_delta):
	notifier.notify(_detect())

func _detect():
	if Global.chipsites.size() < 1:
		return -1.0

	# Prune stale references so scene changes or freed sites do not crash scanning.
	for i in range(Global.chipsites.size() - 1, -1, -1):
		var site_ref = Global.chipsites[i]
		if site_ref == null or not is_instance_valid(site_ref):
			Global.chipsites.remove_at(i)

	if Global.chipsites.size() < 1:
		return -1.0

	for site in Global.chipsites:
		
		var x = site.global_transform.origin.x - global_transform.origin.x
		var z = site.global_transform.origin.z - global_transform.origin.z


		var angle = rad_to_deg(atan2(-x , -z))

		# if x < 0:
		# 	if z < 0:
		# 		angle = -angle #correct
		# 	else:
		# 		angle = 180 - angle
		# else:
		# 	if z < 0:
		# 		angle = -angle
		# 	else:
		# 		angle = -180 - angle #correct
		
		if global_rotation_degrees.y > (angle - 5)\
			and global_rotation_degrees.y < (angle + 5):
			return 1.0
		else:
			return -1.0
