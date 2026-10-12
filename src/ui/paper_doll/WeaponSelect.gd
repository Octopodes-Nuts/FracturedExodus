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
	var current_key := _current_weapon_key(register, char_def)
	var current_def: WeaponDefinition = definitions.get(current_key)
	var current_cost := current_def.devotion_cost if current_def != null else 0
	var available_devotion: int = int(char_def.Devotion) + current_cost

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
		li.load_from(item, definitions, weapon_def.devotion_cost <= available_devotion)
		li.connect("weapon_selected", emit_weapon_selected)

# The weapon currently occupying this register — its cost is refunded if the
# player swaps away from it, so it counts toward what they can afford next.
func _current_weapon_key(register: int, char_def: CharacterDef) -> String:
	match register:
		1: return char_def.Weapon1
		2: return char_def.Weapon2
		3: return char_def.Weapon3
	return ""


func _on_cancel_button_pressed() -> void:
	hide()
