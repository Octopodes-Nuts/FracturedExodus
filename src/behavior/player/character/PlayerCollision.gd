extends Node3D

const DEFAULT_SKIN := "res://load/character/skin_data/Default.res"

@onready var skeleton: Skeleton3D = $Skeleton3D

@onready var body: BodyCollider = $Skeleton3D/ChestCollision/Coll
@onready var lower_body: BodyCollider = $Skeleton3D/LowerTorsoCollision/Coll
@onready var head: BodyCollider = $Skeleton3D/HeadCollision/Coll
@onready var right_thigh: BodyCollider = $Skeleton3D/RightUpperLegCollision/Coll
@onready var left_thigh: BodyCollider = $Skeleton3D/LeftUpperLegCollision/Coll
@onready var right_shin: BodyCollider = $Skeleton3D/RightLowerLegCollision/Coll
@onready var left_shin: BodyCollider = $Skeleton3D/LeftLowerLegCollision/Coll
@onready var right_arm: BodyCollider = $Skeleton3D/RightUpperArmCollision/Coll
@onready var left_arm: BodyCollider = $Skeleton3D/LeftUpperArmCollision/Coll
@onready var right_forearm: BodyCollider = $Skeleton3D/RightForearmCollision/Coll
@onready var left_forearm: BodyCollider = $Skeleton3D/LeftForearmCollision/Coll

signal report_hit(dmg: float, shooter_id: int)

var dmg_lookup: Dictionary[BodyCollider.BODY_PART, float] = {
	BodyCollider.BODY_PART.ARMS: 0.6,
	BodyCollider.BODY_PART.LEGS: 0.5,
	BodyCollider.BODY_PART.BODY: 1.0,
	BodyCollider.BODY_PART.HEAD: 3.0,
}

var _rest_position: Vector3
var _rest_quaternion: Quaternion

# Resets the rig's own transform and root bone pose. Used when reviving a
# downed player. Pure rig/skeleton concern — no AnimationTree involved,
# that lives on player_body and is driven by DefaultControllerMovement.
func reset_to_rest() -> void:
	skeleton.reset_bone_pose(skeleton.find_bone("root"))
	position = _rest_position
	quaternion = _rest_quaternion

# Builds the visible mesh onto the (otherwise bare) skeleton from a SkinData
# resource. Runs for every player on every peer — purely a local visual
# load, same as when the meshes used to be baked into the imported model.
func load_skin(skin_data: SkinData) -> void:
	for child in skeleton.find_children("*", "MeshInstance3D", false, false):
		child.queue_free()
	if skin_data == null:
		return
	for i in skin_data.rests.size():
		if i < skeleton.get_bone_count():
			skeleton.set_bone_rest(i, skin_data.rests[i])
	for i in skin_data.meshes.size():
		var mi := MeshInstance3D.new()
		mi.mesh = skin_data.meshes[i]
		mi.skin = skin_data.skins[i]
		mi.skeleton = NodePath("..")
		skeleton.add_child(mi)

func _ready() -> void:
	_rest_position = position
	_rest_quaternion = quaternion
	load_skin(load(DEFAULT_SKIN))
	body.hit_signal.connect(_on_hit)
	head.hit_signal.connect(_on_hit)
	right_thigh.hit_signal.connect(_on_hit)
	left_thigh.hit_signal.connect(_on_hit)
	right_shin.hit_signal.connect(_on_hit)
	left_shin.hit_signal.connect(_on_hit)
	right_arm.hit_signal.connect(_on_hit)
	left_arm.hit_signal.connect(_on_hit)
	right_forearm.hit_signal.connect(_on_hit)
	left_forearm.hit_signal.connect(_on_hit)

var hit_reports: Dictionary[int, Array] # {shooter_id: [[damage, BODY_PART], ...]}

# Priority order: lower index wins
const HIT_PRIORITY: Array = [
	BodyCollider.BODY_PART.HEAD,
	BodyCollider.BODY_PART.BODY,
	BodyCollider.BODY_PART.LEGS,
	BodyCollider.BODY_PART.ARMS,
]

func _physics_process(_delta: float) -> void:
	for id in hit_reports.keys():
		var best_hit: Array = []
		var best_priority: int = HIT_PRIORITY.size()
		for hit_report in hit_reports[id]:
			var p: int = HIT_PRIORITY.find(hit_report[1])
			if p != -1 and p < best_priority:
				best_priority = p
				best_hit = hit_report
				if best_priority == 0:
					break # headshot, can't do better
		if not best_hit.is_empty():
			report_hit.emit(best_hit[0] * dmg_lookup[best_hit[1]], id)
	hit_reports.clear()

func _on_hit(dmg: float, shooter_id: int, body_part: BodyCollider.BODY_PART):
	if not hit_reports.has(shooter_id):
		hit_reports[shooter_id] = [[dmg, body_part]]
	else:
		hit_reports[shooter_id].append([dmg, body_part])
