extends Node

var ListItem = preload("res://ui/paper_doll/ListItem.tscn")

signal weapon_selected(id: String)
signal clear

func emit_weapon_selected(id: String):
	emit_signal("weapon_selected", id)

func _ready():
	pass
	
func render_out(register: int, dict: Dictionary, restrictions: Dictionary):
	emit_signal("clear")
	var pos = 0
	for item in dict.keys():
		var weapon = restrictions[item].instantiate()
		if not register in weapon.slots[Types.Classes.CLASS_DEFAULT] or \
		   not register in weapon.slots[Local.selected_character_def.ClassType]: continue
		var li = ListItem.instantiate()
		connect("clear", li.queue_free)
		add_child(li)
		li.load_from(item, dict)
		li.position = Vector2(8, 52 + ((185 - 52) * pos))
		pos += 1
		li.connect("weapon_selected", emit_weapon_selected)
