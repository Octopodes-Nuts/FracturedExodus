###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Area3D

# Description of what a camp should do or be
var ai_load_path = load('res://behavior/ai/basic_enemy/BasicEnemy.tscn')

# 1. Camp needs to spawn enemies and register itself as their home
# 	a. This is more related to AI, but AI should return to camp, maybe let them
#	know that they have return when they enter
# 2. Camp needs to spawn chipsire

# This should change in the future to harbor different kinds of AI
# There may also be a need for camp types
var number_fractured: int
@export var max_fractured: int = 5
var fractured: Array = []

@export var min_radius: float
@export var max_radius: float

# Note: do not scale this node ever, it must always be set to (1,1,1)

# Placeholder for camp behavior
func _ready():
	# define random number of fractured
	randomize()
	number_fractured = int(randf_range(1, max_fractured + 1))
	# mint random number of fractured
	for ai in range(number_fractured):
		fractured.append(ai_load_path.instantiate())
		self.add_child(fractured[ai])
		fractured[ai].transform.origin = Vector3(ai + 4, 2, ai + 4)
		# set location to somewhere within the player radius
		# future proof, make sure foot is on the ground in hilly areas
		# fractured also cannot spawn inside eachother
		fractured[ai].home = self
