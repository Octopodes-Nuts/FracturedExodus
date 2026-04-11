extends Node3D

@onready var animation_tree: AnimationTree = $AnimationTree

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
