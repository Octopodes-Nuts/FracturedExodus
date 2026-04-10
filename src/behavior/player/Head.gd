extends Area3D

@onready var player = $".."

func headshot(dmg, shooter_id: int = 0):
	player.hit(dmg, shooter_id)
	
