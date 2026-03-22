extends CollisionShape3D

func enable_hitbox():
	print("[SWORD] hitbox enabled")
	disabled = false

func disable_hitbox():
	print("[SWORD] hitbox disabled")
	disabled = true
