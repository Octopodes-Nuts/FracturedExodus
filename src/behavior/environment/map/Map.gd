
extends Spatial

onready var Global = get_node('/root/Global')

# When tree is entered, set as the map root
func _enter_tree():
	Global.map_root = self

# Remove self from map_root to allow for clean destruction
func _exit_tree():
	Global.map_root = null
