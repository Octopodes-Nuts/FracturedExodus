extends Node3D

@onready var hitbox: CollisionShape3D = $collision/collider
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var damage: float = 20.0

var owner_enemy: Node = null
var hit_targets: Dictionary = {}

func _ready() -> void:
	hitbox.disabled = true
	animation_player.animation_finished.connect(_on_animation_finished)

func use(parent = null) -> void:
	owner_enemy = parent
	hit_targets.clear()
	hitbox.disabled = false
	animation_player.stop()

func _on_animation_finished(_anim_name: StringName) -> void:
	hitbox.disabled = true

func enable() -> void:
	hitbox.disabled = false

func disable() -> void:
	hitbox.disabled = true


func _on_collision_body_entered(body: Node3D) -> void:
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
