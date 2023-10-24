###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Node

@onready var empire_classes = {
	"Fusilier": load('res://behavior/player/movement/empire/fusilier/Fusilier.tscn'),
	"Jaeger": load('res://behavior/player/movement/empire/jaeger/Jaeger.tscn'),
	"Leutnant": load('res://behavior/player/movement/empire/leutnant/Leutnant.tscn'),
	"Medzin": load('res://behavior/player/movement/empire/medzin/Medzin.tscn')	
}

@onready var entente_classes = {
	"Rifleman": load('res://behavior/player/movement/entente/rifleman/Rifleman.tscn'),
	"Chasseur": load('res://behavior/player/movement/entente/chasseur/Chasseur.tscn'),
	"Medic": load('res://behavior/player/movement/entente/medic/Medic.tscn'),
	"Lieutenant": load('res://behavior/player/movement/entente/lieutenant/Lieutenant.tscn')
}

@onready var free_agent_classes = {
	"Captain": load('res://behavior/player/movement/free_agent/captain/Captain.tscn'),
	"Juggernaut": load('res://behavior/player/movement/free_agent/juggernaut/Juggernaut.tscn'),
	"Sharpshooter": load('res://behavior/player/movement/free_agent/sharpshooter/Sharpshooter.tscn'),
	"Recruit": load('res://behavior/player/movement/free_agent/recruit/Recruit.tscn')
}
