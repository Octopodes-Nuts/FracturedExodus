###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends DefaultController

class_name InfantryController

# Movement speed multiplier applied when tertiary weapon (melee/light) is equipped
@export var stowed_speed_buff: float = 1.15
