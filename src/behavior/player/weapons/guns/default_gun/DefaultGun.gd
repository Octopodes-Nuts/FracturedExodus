extends Gun

class_name DefaultGun

func _init():
	faction = Factions.DEFAULT

func _ready():
	fire_sound =\
		load("res://behavior/player/weapons/guns/default_gun/DefaultGunShot.mp3")
