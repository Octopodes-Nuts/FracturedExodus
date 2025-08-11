extends Node

signal swap_paper_doll

func _on_select_btn_pressed() -> void:
	emit_signal("swap_paper_doll")

func reload(def: CharacterDef):
	pass
