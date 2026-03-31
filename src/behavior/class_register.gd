###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Node

enum Classes {
	DEFAULT,
	INFANTRY,
	MEDIC,
	SPECIAL,
	OFFICER
}

@onready var empire_classes = {
	Classes.INFANTRY: load('res://behavior/player/movement/empire/fusilier/Fusilier.tscn'),
	Classes.SPECIAL: load('res://behavior/player/movement/empire/jaeger/Jaeger.tscn'),
	Classes.OFFICER: load('res://behavior/player/movement/empire/leutnant/Leutnant.tscn'),
	Classes.MEDIC: load('res://behavior/player/movement/empire/sanitater/Sanitater.tscn')	
}

@onready var empire_class_name_map = {
	Classes.INFANTRY: "Fusilier",
	Classes.MEDIC: "Sanitäter",
	Classes.OFFICER: "Leutnant",
	Classes.SPECIAL: "Jaeger"
}

@onready var entente_classes = {
	Classes.INFANTRY: load('res://behavior/player/movement/entente/rifleman/Rifleman.tscn'),
	Classes.SPECIAL: load('res://behavior/player/movement/entente/chasseur/Chasseur.tscn'),
	Classes.MEDIC: load('res://behavior/player/movement/entente/medic/Medic.tscn'),
	Classes.OFFICER: load('res://behavior/player/movement/entente/lieutenant/Lieutenant.tscn')
}

@onready var entente_class_name_map = {
	Classes.INFANTRY: "Rifleman",
	Classes.MEDIC: "Medic",
	Classes.OFFICER: "Lieutenant",
	Classes.SPECIAL: "Chasseur"
}

@onready var free_agent_classes = {
	Classes.OFFICER: load('res://behavior/player/movement/free_agent/captain/Captain.tscn'),
	Classes.MEDIC: load('res://behavior/player/movement/free_agent/bulwark/BulwarkController.gd'),
	Classes.SPECIAL: load('res://behavior/player/movement/free_agent/sharpshooter/Sharpshooter.tscn'),
	Classes.INFANTRY: load('res://behavior/player/movement/free_agent/recruit/Recruit.tscn')
}

@onready var free_agent_class_name_map = {
	Classes.INFANTRY: "Recruit",
	Classes.MEDIC: "Bulwark",
	Classes.OFFICER: "Captain",
	Classes.SPECIAL: "Sharpshooter"
}

func get_class_name(faction: int, class_type: int) -> String:
	match faction:
		Factions.Enum.ENTENTE:
			return entente_class_name_map.get(class_type, "Unknown")
		Factions.Enum.EMPIRE:
			return empire_class_name_map.get(class_type, "Unknown")
		Factions.Enum.FREE_AGENTS:
			return free_agent_class_name_map.get(class_type, "Unknown")
	return "Unknown"

var entente_summary = "The Entente is a coalition of nations united against the aggressive expansion of the Empire. They value freedom, democracy, and the protection of their homelands. The Entente's forces are diverse, drawing from a variety of backgrounds and specialties to create a formidable resistance against the Empire's advances."

var entente_class_summaries = {
	Classes.INFANTRY: "The backbone of the Entente forces, the Rifleman is a versatile soldier equipped for a variety of combat situations.",
	Classes.MEDIC: "The Medic provides crucial support on the battlefield, healing wounds and keeping allies in the fight.",
	Classes.OFFICER: "The Lieutenant leads from the front, inspiring troops and coordinating attacks with strategic precision.",
	Classes.SPECIAL: "The Chasseur is a skilled marksman and scout, excelling in reconnaissance and long-range engagements."
}

var empire_summary = "The Empire is a powerful and authoritarian regime that seeks to dominate the world through military might and technological superiority. They are known for their disciplined forces, advanced weaponry, and ruthless tactics. The Empire's soldiers are highly trained and fiercely loyal, making them a formidable adversary on the battlefield."

var empire_class_summaries = {
	Classes.INFANTRY: "The Fusilier is the standard infantry unit of the Empire, trained for frontline combat and equipped with reliable weaponry.",
	Classes.MEDIC: "The Sanitäter is a dedicated medical specialist, providing essential care to wounded soldiers amidst the chaos of battle.",
	Classes.OFFICER: "The Leutnant commands respect on the battlefield, leading troops with discipline and tactical acumen.",
	Classes.SPECIAL: "The Jaeger is an elite marksman, adept at taking out high-value targets and excelling in stealth operations."
}

var free_agents_summary = "The Free Agents are a diverse group of mercenaries who operate outside the traditional power structures of the Entente and Empire. They are motivated by personal gain, freedom, or a desire to make their own mark on the world. The Free Agents are known for their adaptability, resourcefulness, and willingness to take on dangerous missions for the right price. Funded primarily by the American government, the Free Agents have access to a wide range of equipment and technology, making them a versatile and unpredictable force on the battlefield."

var free_agent_class_summaries = {
	Classes.INFANTRY: "The Recruit is a versatile soldier, adaptable to various combat roles and equipped with standard gear.",
	Classes.MEDIC: "The Bulwark is a heavily armored combat medic, providing both medical support and frontline resilience.",
	Classes.OFFICER: "The Captain is a charismatic leader, inspiring allies and coordinating efforts with strategic insight.",
	Classes.SPECIAL: "The Sharpshooter is a master of precision, excelling in long-range engagements and taking out targets with deadly accuracy."
}


func get_class_summary(faction: int, class_type: int) -> String:
	match faction:
		Factions.Enum.ENTENTE:
			match class_type:
				Classes.INFANTRY:
					return entente_summary + "\n" + entente_class_summaries.get(class_type, "Unknown")
				Classes.MEDIC:
					return entente_summary + "\n" + entente_class_summaries.get(class_type, "Unknown")
				Classes.OFFICER:
					return entente_summary + "\n" + entente_class_summaries.get(class_type, "Unknown")
				Classes.SPECIAL:
					return entente_summary + "\n" + entente_class_summaries.get(class_type, "Unknown")
		Factions.Enum.EMPIRE:
			match class_type:
				Classes.INFANTRY:
					return empire_summary + "\n" + empire_class_summaries.get(class_type, "Unknown")
				Classes.MEDIC:
					return empire_summary + "\n" + empire_class_summaries.get(class_type, "Unknown")
				Classes.OFFICER:
					return empire_summary + "\n" + empire_class_summaries.get(class_type, "Unknown")
				Classes.SPECIAL:
					return empire_summary + "\n" + empire_class_summaries.get(class_type, "Unknown")
		Factions.Enum.FREE_AGENTS:
			match class_type:
				Classes.INFANTRY:
					return free_agents_summary + "\n" + free_agent_class_summaries.get(class_type, "Unknown")
				Classes.MEDIC:
					return free_agents_summary + "\n" + free_agent_class_summaries.get(class_type, "Unknown")
				Classes.OFFICER:
					return free_agents_summary + "\n" + free_agent_class_summaries.get(class_type, "Unknown")
				Classes.SPECIAL:
					return free_agents_summary + "\n" + free_agent_class_summaries.get(class_type, "Unknown")
	return "Unknown"
