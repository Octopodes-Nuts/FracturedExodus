extends Control

@export var SIT_TIME = 4.0
var time_sat = 0.0

func _ready() -> void:
	if Local.get_state("has_objective"):
		$text.text = "Extracted complete with objective"
		Local.set_state("has_objective", false)

func _process(delta: float) -> void:
	time_sat += delta
	
	if time_sat >= SIT_TIME:
		if not get_tree().change_scene_to_file("res://ui/main_menu/MainMenu.tscn") == OK:
			print("Error getting to file")
