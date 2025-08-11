extends Node

@onready var primary_weapon = $primary_weapon
@onready var secondary_weapon = $secondary_weapon
@onready  var melee_weapon = $melee_weapon
@onready var eq_1 = $eq_1
@onready var eq_2 = $eq_2

signal swap_paper_doll


func _on_done_btn_pressed() -> void:
	emit_signal("swap_paper_doll")

func reload(def: CharacterDef):
	pass
