@tool
extends EditorScript

const SOURCE := "res://debug/models/player/BaseModelClothingAnimClothinJoined.blend"
const OUTPUT := "res://load/character/skin_data/Default.res"

func _run() -> void:
	var scene = load(SOURCE).instantiate()
	var skel: Skeleton3D = scene.find_child("Skeleton3D")
	var data := SkinData.new()

	for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D"):
		if mi.skin == null:
			push_warning("Skipping unskinned mesh: " + mi.name)
			continue
		data.meshes.append(mi.mesh.duplicate())
		data.skins.append(mi.skin.duplicate())

	for i in skel.get_bone_count():
		data.rests.append(skel.get_bone_rest(i))

	ResourceSaver.save(data, OUTPUT)
	scene.free()
	print("Baked %d parts to %s" % [data.meshes.size(), OUTPUT])
