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
	
func render_out(register: int, definitions: Dictionary):
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
	for item in definitions.keys():
		var weapon_def: WeaponDefinition = definitions[item]
		print("[WeaponSelect] checking weapon=%s faction=%s(%s) slots=%s" % [
			item, weapon_def.faction, typeof(weapon_def.faction), weapon_def.slots
		])
		if not char_def.Faction in weapon_def.faction and \
			not Factions.Enum.DEFAULT in weapon_def.faction:
				print("[WeaponSelect]   SKIP %s — faction mismatch" % item)
				continue
		if not register in weapon_def.slots[ClassRegister.Classes.DEFAULT] and \
		   not register in weapon_def.slots[char_def.ClassType]:
			print("[WeaponSelect]   SKIP %s — slot mismatch (DEFAULT slots=%s, class slots=%s)" % [
				item,
				weapon_def.slots.get(ClassRegister.Classes.DEFAULT, "KEY MISSING"),
				weapon_def.slots.get(char_def.ClassType, "KEY MISSING")
			])
			continue
		print("[WeaponSelect]   PASS %s" % item)
		var li = ListItem.instantiate()
		connect("clear", li.queue_free)
		scroll_container.add_child(li)
		li.load_from(item, definitions)
		li.connect("weapon_selected", emit_weapon_selected)


func _on_cancel_button_pressed() -> void:
	hide()
