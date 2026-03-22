extends Weapon

@onready var animation_player = $AnimationPlayer
@onready var hitbox: CollisionShape3D = $CollisionShape3D
@onready var sword_mesh: Node3D = $Sword
@onready var hilt_mesh: Node3D = $Hilt

@export var damage: float = 20.0
@export var model_yaw_offset_degrees: float = 180.0

var owner_enemy: Node
var hit_targets: Dictionary = {}

func _ready() -> void:
	_apply_model_orientation_offset()

func _apply_model_orientation_offset() -> void:
	var yaw := deg_to_rad(model_yaw_offset_degrees)
	sword_mesh.rotation.y = yaw
	hilt_mesh.rotation.y = yaw
	hitbox.rotation.y = yaw

func use(parent = null):
	owner_enemy = parent
	hit_targets.clear()
	_play_swing.rpc()

@rpc("authority", "reliable", "call_local")
func _play_swing() -> void:
	if not animation_player.has_animation("Swing"):
		push_warning("[AI SWORD] Missing Swing animation")
		return
	animation_player.active = true
	print("[AI SWORD] Swinging sword")
	animation_player.stop()
	animation_player.play("Swing")

func _on_body_entered(body: Node) -> void:
	if not is_multiplayer_authority():
		return
	if hitbox.disabled:
		return
	if owner_enemy != null and is_instance_valid(owner_enemy):
		if body == owner_enemy:
			return
	if body == null or not is_instance_valid(body):
		return
	var body_id := body.get_instance_id()
	if hit_targets.has(body_id):
		return
	hit_targets[body_id] = true
	if body.has_method("hit"):
		body.call("hit", damage)
		print("[AI SWORD] Hit target: %s" % body.name)
