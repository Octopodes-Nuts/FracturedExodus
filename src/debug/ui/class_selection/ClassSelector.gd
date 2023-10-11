extends Control

onready var ClassRegister = get_node('/root/ClassRegister')
onready var Global = get_node('/root/Global')
onready var Local = get_node('/root/Local')
var entente_classes: Dictionary
var empire_classes: Dictionary
var free_agent_classes: Dictionary
var player: Node

func _ready():
	entente_classes    = ClassRegister.entente_classes
	empire_classes     = ClassRegister.empire_classes
	free_agent_classes = ClassRegister.free_agent_classes
	player = Local.player
	generate_buttons(entente_classes, 0)
	generate_buttons(empire_classes, 1)
	generate_buttons(free_agent_classes, 2)

# dyncamically create buttons and link them to dynamically generated
# load actions

func generate_buttons(classes: Dictionary, row: int):
	var position = Vector2(0, row * 50)
	for key in classes.keys():
		var button = Button.new()
		button.text = key
		# do this
		button.set_size(Vector2(80, 35))
		button.set_position(position)
		# attach load_script with value to button click signal
		button.connect('button_down', self, 'load_script', [classes[key]])
		self.add_child(button)
		position += Vector2(100, 0)
		

func load_script(class_scene):
	# set player class
	Local.player.queue_free()
	var new_player =  class_scene.instance()
	Global.map_root.add_child(new_player)
	new_player.transform.origin = Vector3(0, 2, 0)
	Local.player = new_player
	get_parent().remove_child(self)
