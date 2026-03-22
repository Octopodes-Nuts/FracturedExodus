extends Area3D

@export var owner_path: NodePath = NodePath("..")

func _get_owner_wounded() -> Node:
	var owner_node := get_node_or_null(owner_path)
	if owner_node == null:
		owner_node = get_parent()
	return owner_node

func headshot(damage: float) -> void:
	var owner_node := _get_owner_wounded()
	if owner_node != null and owner_node.has_method("headshot"):
		owner_node.call("headshot", damage)
		return
	if owner_node != null and owner_node.has_method("hit"):
		owner_node.call("hit", damage)
