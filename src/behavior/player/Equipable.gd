###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Node3D

class_name Equipable

var active: bool = false

@export var default_position: Vector3 = Vector3.ZERO