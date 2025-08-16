extends Node

func _ready() -> void:
	Global.bullet_parent = self


func _on_bullet_spawner_spawned(node: Node) -> void:
	print("Bullet")
