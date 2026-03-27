extends Panel

class_name WeaponSelect

var ListItem = preload("res://ui/paper_doll/ListItem.tscn")
@onready var scroll_container = $scroll_container/v_box_container

signal weapon_selected(id: String)
signal clear
signal opened
signal closed

func emit_weapon_selected(id: String):
	emit_signal("weapon_selected", id)

func _ready():
	visibility_changed.connect(
		func():
			if visible:
				emit_signal("opened")
			else:
				emit_signal("closed")
	)
	
func render_out(register: int, dict: Dictionary, restrictions: Dictionary):
	if not Local.get_state("selected_character_def"):
		print("[WeaponSelect] selected_character_def is null, aborting render")
		return
	var char_def = Local.get_state("selected_character_def")
	print("[WeaponSelect] render_out register=%d faction=%s(%s) class_type=%s(%s)" % [
		register,
		char_def.Faction, typeof(char_def.Faction),
		char_def.ClassType, typeof(char_def.ClassType)
	])
	emit_signal("clear")
	for item in dict.keys():
		var weapon = restrictions[item].instantiate()
		print("[WeaponSelect] checking weapon=%s faction=%s(%s) slots=%s" % [
			item, weapon.faction, typeof(weapon.faction), weapon.slots
		])
		if not weapon.faction == char_def.Faction and \
			not weapon.faction == Factions.DEFAULT:
				print("[WeaponSelect]   SKIP %s — faction mismatch" % item)
				weapon.queue_free()
				continue
		if not register in weapon.slots[ClassRegister.Classes.DEFAULT] and \
		   not register in weapon.slots[char_def.ClassType]:
			print("[WeaponSelect]   SKIP %s — slot mismatch (DEFAULT slots=%s, class slots=%s)" % [
				item,
				weapon.slots.get(ClassRegister.Classes.DEFAULT, "KEY MISSING"),
				weapon.slots.get(char_def.ClassType, "KEY MISSING")
			])
			weapon.queue_free()
			continue
		print("[WeaponSelect]   PASS %s" % item)
		weapon.queue_free()
		var li = ListItem.instantiate()
		connect("clear", li.queue_free)
		scroll_container.add_child(li)
		li.load_from(item, dict)
		li.connect("weapon_selected", emit_weapon_selected)


func _on_cancel_button_pressed() -> void:
	hide()
