extends Gun

class_name DefaultPistol

func _init():
	faction = Factions.DEFAULT

func _ready():
	fire_sound =\
		load("res://behavior/player/weapons/guns/default_pistol/DefaultPistolShot.mp3")

