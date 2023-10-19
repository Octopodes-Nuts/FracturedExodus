
extends WorldEnvironment

@onready var Global = get_node('/root/Global')

# When tree is entered, set as the map root
func _ready():
	Global.map_root = self
