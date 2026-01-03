extends Area3D

@onready var player = $".."

func headshot(dmg):
	print("HEADSHOT")
	player.hit(
		dmg
	)
	
