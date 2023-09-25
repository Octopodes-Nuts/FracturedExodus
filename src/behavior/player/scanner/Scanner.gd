extends Spatial

onready var Global = get_node("/root/Global")

var chipsites: Array
var detected: bool = false

func _physics_process(_delta):
	if _detect():
		# display to scanner material
		pass

func _detect():
	if Global.chipsites.size() < 1:
		return false

	for site in Global.chipsites:
		
		var x = site.transform.origin.x - transform.origin.x
		var z = site.transform.origin.z - transform.origin.z

		var angle = rad2deg(atan(x / z))

		if x < 0:
			if z < 0:
				angle = -angle #correct
			else:
				angle = 180 - angle
		else:
			if z < 0:
				angle = -angle
			else:
				angle = -180 - angle #correct
		
		if rotation_degrees.y > (angle - 5)\
			and rotation_degrees.y < (angle + 5):
			return true
		else:
			return false

