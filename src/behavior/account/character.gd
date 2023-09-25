extends Node

class_name Character

enum ClassType {
	DEFAULT,
	RIFLEMAN,
	MEDIC,
	CHASSEUR,
	LIEUTENANT,
	FUSILER,
	MEDZIN,
	LEUTNANT,
	JAEGER,
	RECRUIT,
	CAPTAIN,
	SHARPSHOOTER,
	JUGGERNAUT
}

var class_type: int # ClassType
var experience: int
var primary_weapon: Weapon
var secondary_weapon: Weapon
var tertiary_weapon: Weapon
var equipment: Array # Array of Equipment

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
