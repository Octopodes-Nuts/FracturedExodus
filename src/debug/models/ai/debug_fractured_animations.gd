extends Node3D

@onready var animation_player = $AnimationPlayer
@onready var debug_sword = $Armature/Skeleton3D/BoneAttachment3D/aisword

func swing():
	animation_player.play("Swing")
	debug_sword.use()

func walk():
	animation_player.play("Walk")

func run():
	animation_player.play("Run")

func idle():
	animation_player.play("Idle")
