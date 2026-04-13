extends Area3D

class_name BodyCollider

enum BODY_PART{
	ARMS,
	HEAD,
	BODY,
	LEGS
}

@export var body_part: BODY_PART = BODY_PART.BODY

signal hit_signal(dmg: float, shooteer_id: int, body_part: BODY_PART)

func hit(dmg: float, shooter_id: int = 0):
	hit_signal.emit(dmg, shooter_id, body_part)
