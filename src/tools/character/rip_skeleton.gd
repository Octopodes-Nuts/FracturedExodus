@tool
extends EditorScript

const SOURCE := "res://debug/models/player/BaseModelClothingAnim.blend"
const OUTPUT := "res://assets/skeletons/BaseRig.tscn"

func _run() -> void:
	var scene = load(SOURCE).instantiate()
	var skel: Skeleton3D = scene.find_child("Skeleton3D")
	var armature := skel.get_parent()

	# Detach Armature (keeps its transform/scale) from the imported scene
	armature.get_parent().remove_child(armature)

	# Strip everything except the Skeleton3D: meshes, extra nodes
	for c in armature.get_children():
		if c != skel:
			c.free()
	for c in skel.get_children():
		c.free()

	# Nodes must be owned by the new root to be saved
	skel.owner = armature

	var packed := PackedScene.new()
	packed.pack(armature)
	ResourceSaver.save(packed, OUTPUT)

	armature.free()
	scene.free()
	print("Saved rig to ", OUTPUT)
