extends Control

const LOCAL_ICON_SIZE    := Vector2(40.0, 40.0)
const FRIENDLY_ICON_SIZE := Vector2(38.0, 38.0)

## Texture pixels per world unit (1024px texture / 512 world units = 2.0).
@export var pixels_per_world_unit: float = 2.0
## Where world position (0,0,0) maps to in texture pixel space.
## X and Y are independent — the map origin is not centered. Calibrated from (-49.3,-27.6)→(370,469).
@export var map_world_origin: Vector2 = Vector2(469.0, 524.0)

@onready var Local  = get_node("/root/Local")
@onready var Global = get_node("/root/Global")

@export var _map_texture: TextureRect

@export var friendly_texture: Texture2D
@export var ping_texture: Texture2D
@export var self_texture: Texture2D


var _local_icon: TextureRect
var _friendly_icons: Array[TextureRect] = []
var _coord_label: Label


func _ready() -> void:
	visible = false
	if _map_texture == null:
		push_error("[TabMap] _map_texture not assigned in inspector")
		return
	_local_icon = _make_icon(self_texture, LOCAL_ICON_SIZE)
	_map_texture.add_child(_local_icon)
	_local_icon.size = LOCAL_ICON_SIZE
	_local_icon.pivot_offset = LOCAL_ICON_SIZE / 2.0

	_coord_label = Label.new()
	_coord_label.position = Vector2(8, 8)
	_coord_label.add_theme_font_size_override("font_size", 14)
	add_child(_coord_label)


func _make_icon(tex: Texture2D, size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = tex
	# EXPAND_IGNORE_SIZE lets us set any size freely without the texture forcing its own.
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	return rect


func _apply_icon_size(icon: TextureRect, size: Vector2) -> void:
	icon.size = size
	icon.pivot_offset = size / 2.0


func _world_to_map(world_pos: Vector3) -> Vector2:
	return Vector2(
		world_pos.x * pixels_per_world_unit + map_world_origin.x,
		world_pos.z * pixels_per_world_unit + map_world_origin.y
	)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("map"):
		visible = not visible

	if not visible or _map_texture == null or _local_icon == null:
		return

	var local_player = Local.get_state("player")
	if local_player == null:
		return

	_apply_icon_size(_local_icon, LOCAL_ICON_SIZE)
	var world_pos = local_player.global_position
	_local_icon.position = _world_to_map(world_pos) - _local_icon.pivot_offset
	_coord_label.text = "world: (%.1f, %.1f)  map_px: (%.0f, %.0f)" % [
		world_pos.x, world_pos.z,
		_local_icon.position.x + _local_icon.pivot_offset.x,
		_local_icon.position.y + _local_icon.pivot_offset.y,
	]

	var local_faction := -1
	var char_def = Local.get_state("selected_character_def")
	if char_def != null:
		local_faction = int(char_def.Faction)

	var friendly_positions: Array[Vector3] = []
	for player in get_tree().get_nodes_in_group("players"):
		if player == local_player:
			continue
		var peer_id_str := str(player.name)
		if peer_id_str.to_int() == 0 and player.get_parent() != null:
			peer_id_str = str(player.get_parent().name)
		var data = Global.character_data.get(peer_id_str)
		if data is Dictionary and int(data.get("faction", -1)) == local_faction:
			friendly_positions.append(player.global_position)

	while _friendly_icons.size() < friendly_positions.size():
		var icon := _make_icon(friendly_texture, FRIENDLY_ICON_SIZE)
		_map_texture.add_child(icon)
		_apply_icon_size(icon, FRIENDLY_ICON_SIZE)
		_friendly_icons.append(icon)

	for i in range(_friendly_icons.size()):
		if i < friendly_positions.size():
			_apply_icon_size(_friendly_icons[i], FRIENDLY_ICON_SIZE)
			_friendly_icons[i].position = _world_to_map(friendly_positions[i]) - _friendly_icons[i].pivot_offset
			_friendly_icons[i].visible = true
		else:
			_friendly_icons[i].visible = false
