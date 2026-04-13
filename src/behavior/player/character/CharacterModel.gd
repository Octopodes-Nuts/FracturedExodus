extends Node3D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var skeleton: Skeleton3D = $Skeleton3D

@onready var body: BodyCollider = $Skeleton3D/BodyCollisionAttachment/Coll
@onready var head: BodyCollider = $Skeleton3D/HeadColision/Coll
@onready var right_thigh: BodyCollider = $Skeleton3D/RightThighAttachment/Coll
@onready var left_thigh: BodyCollider = $Skeleton3D/LeftThighAttachment/Coll
@onready var right_shin: BodyCollider = $Skeleton3D/RightShinAttachment/Coll
@onready var left_shin: BodyCollider = $Skeleton3D/LeftShinAttachment/Coll
@onready var right_arm: BodyCollider = $Skeleton3D/RightArmAttachment/Coll
@onready var left_arm: BodyCollider = $Skeleton3D/LeftArmAttachment/Coll
@onready var right_forearm: BodyCollider = $Skeleton3D/RightForearmAttachment/Coll
@onready var left_forearm: BodyCollider = $Skeleton3D/LeftForearmAttachment/Coll

signal report_hit(dmg: float, shooter_id: int)

var dmg_lookup: Dictionary[BodyCollider.BODY_PART, float] = {
	BodyCollider.BODY_PART.ARMS: 0.6,
	BodyCollider.BODY_PART.LEGS: 0.5,
	BodyCollider.BODY_PART.BODY: 1.0,
	BodyCollider.BODY_PART.HEAD: 3.0,
}

enum MOVE_STATE {
	IDLE,   # 0
	WALK,   # 1
	RUN,    # 2
	JUMP,   # 3
	DOWNED  # 4
}

enum CROUCH_STATE {
	CROUCH, # 0
	STAND   # 1
}

var move_state = MOVE_STATE.IDLE
var crouch_state = CROUCH_STATE.STAND

var _rest_position: Vector3
var _rest_quaternion: Quaternion

# Called by DefaultController.play_walk via RPC (WALK=0, RUN=1, STOP=2)
func set_walk_state(walk_state: int) -> void:
	match walk_state:
		0: # WALK
			move_state = MOVE_STATE.WALK
		1: # RUN
			move_state = MOVE_STATE.RUN
		2: # STOP
			if move_state != MOVE_STATE.JUMP and move_state != MOVE_STATE.DOWNED:
				move_state = MOVE_STATE.IDLE

func set_jumping() -> void:
	move_state = MOVE_STATE.JUMP

func set_landed() -> void:
	if move_state == MOVE_STATE.JUMP:
		move_state = MOVE_STATE.IDLE

func set_downed() -> void:
	move_state = MOVE_STATE.DOWNED
	animation_tree.root_motion_track = NodePath("")

func set_revived() -> void:
	move_state = MOVE_STATE.IDLE
	skeleton.reset_bone_pose(skeleton.find_bone("mixamorig1_Hips"))
	animation_tree.root_motion_track = NodePath("Skeleton3D:mixamorig1_Hips")
	position = _rest_position
	quaternion = _rest_quaternion
	
func _ready() -> void:
	_rest_position = position
	_rest_quaternion = quaternion
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
	# Drain root motion every frame to prevent accumulation
	animation_tree.get_root_motion_position()
	animation_tree.get_root_motion_rotation()

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
	
