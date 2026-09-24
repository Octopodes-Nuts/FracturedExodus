extends Shotgun

class_name DefaultShotgun

func _init():
	faction = Factions.Enum.DEFAULT
	slots[ClassRegister.Classes.DEFAULT] = [1]
	key = "DefaultShotgun"

func _local_ready():
	fire_sound =\
		load("res://behavior/player/weapons/guns/default_shotgun/default_shotgun.mp3")
