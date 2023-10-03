extends Area

# Description of what a camp should do or be

# 1. Camp needs to spawn enemies and register itself as their home
# 	a. This is more related to AI, but AI should return to camp, maybe let them
#	know that they have return when they enter

# This should change in the future to harbor different kinds of AI
# There may also be a need for camp types
var number_fractured: int
var max_fractured: int
var fractured: Array

# Placeholder for camp behavior
func _ready():
	# define random number of fractured
	# mint random number of fractured
	for ai in range(number_fractured):
		# add as child of the camp
		# set home camp
		pass
	pass # Replace with function body.
