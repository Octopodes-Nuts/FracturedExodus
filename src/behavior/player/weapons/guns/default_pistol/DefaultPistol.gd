extends Gun

class_name DefaultPistol

func _init():
	faction = Factions.DEFAULT

func _local_ready():
	fire_sound =\
		load("res://behavior/player/weapons/guns/default_pistol/DefaultPistolShot.mp3")
	bolt_pull_sound =\
		load("res://behavior/player/weapons/guns/default_pistol/HammerCock.mp3")

