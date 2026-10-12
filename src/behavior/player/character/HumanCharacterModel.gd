###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Node3D

# Drives the Human_rig AnimationTree (Character.tscn / WeaponStaging.tscn)
# from DefaultController's movement and weapon state. Exposes the same
# set_walk_state/set_jumping/set_landed/set_downed/set_revived/crouch_state
# interface as the older CharacterModel.gd (Ch36_nonPBR) so DefaultController
# can drive this model the same way.

@onready var animation_tree: AnimationTree = $AnimationTree

enum MOVE_STATE {
	IDLE,
	WALK,
	RUN,
	JUMP,
	DOWNED,
}

enum CROUCH_STATE {
	CROUCH, # 0
	STAND   # 1
}

const LOCOMOTION_BLEND := {
	MOVE_STATE.IDLE: 0.0,
	MOVE_STATE.WALK: 1.0,
	MOVE_STATE.RUN: 2.0,
}
const CROUCH_BLEND := {
	MOVE_STATE.IDLE: 0.0,
	MOVE_STATE.WALK: 1.0,
	MOVE_STATE.RUN: 1.0, # no dedicated crouch-sprint pose, hold CrouchWalk
}
const BLEND_LERP_SPEED: float = 8.0

var move_state: int = MOVE_STATE.IDLE
var crouch_state: int = CROUCH_STATE.STAND:
	set(value):
		if crouch_state == value:
			return
		crouch_state = value
		_travel_crouch()

var _stand_blend: float = 0.0
var _crouch_blend: float = 0.0
var _weapon_pose: StringName = &"rest"

var _rest_position: Vector3
var _rest_quaternion: Quaternion

func _ready() -> void:
	_rest_position = position
	_rest_quaternion = quaternion
	animation_tree.active = true
	_travel_crouch()

func _travel_crouch() -> void:
	var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/Locomotion/playback")
	if playback:
		playback.travel("Crouch" if crouch_state == CROUCH_STATE.CROUCH else "Stand")

func _process(delta: float) -> void:
	# Drain root motion every frame to prevent accumulation, in case any of
	# the Locomotion animations end up with baked root motion later.
	animation_tree.get_root_motion_position()
	animation_tree.get_root_motion_rotation()

	if move_state == MOVE_STATE.JUMP or move_state == MOVE_STATE.DOWNED:
		return # no jump/downed pose yet, hold the last locomotion blend
	_stand_blend = move_toward(_stand_blend, LOCOMOTION_BLEND[move_state], BLEND_LERP_SPEED * delta)
	_crouch_blend = move_toward(_crouch_blend, CROUCH_BLEND[move_state], BLEND_LERP_SPEED * delta)
	animation_tree.set("parameters/Locomotion/Stand/blend_position", _stand_blend)
	animation_tree.set("parameters/Locomotion/Crouch/blend_position", _crouch_blend)

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

func set_revived() -> void:
	move_state = MOVE_STATE.IDLE
	position = _rest_position
	quaternion = _rest_quaternion

# pose is one of "rest" (no weapon), "ready" (weapon out), "ads" (aiming).
func set_weapon_pose(pose: StringName) -> void:
	if _weapon_pose == pose:
		return
	_weapon_pose = pose
	animation_tree.set("parameters/WeaponPose/transition_request", pose)
