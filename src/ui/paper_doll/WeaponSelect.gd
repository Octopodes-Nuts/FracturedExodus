extends Node

var ListItem = preload("res://ui/paper_doll/ListItem.tscn")

signal weapon_selected(id: String)

func emit_weapon_selected(id: String):
	emit_signal("weapon_selected", id)

func _ready():
	pass
	
func render_out(dict: Dictionary):
	var pos = 0
	for item in dict.keys():
		var li = ListItem.instantiate()
		add_child(li)
		li.load_from(item, dict)
		li.position = Vector2(8, 52 + ((185 - 52) * pos))
		pos += 1
		li.connect("weapon_selected", emit_weapon_selected)
