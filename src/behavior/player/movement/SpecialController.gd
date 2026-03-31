###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends DefaultController

class_name SpecialController

# Reduced sway and increased zoom on ironsights compared to other classes
@export var ads_zoom_buff: float = 1.2
# Extra movement speed penalty while ADS — special operators commit when they aim
@export var ads_movement_penalty: float = 1.5
