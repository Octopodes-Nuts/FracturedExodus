extends KinematicBody

export var health: float = 100.0

func _ready():
	pass # Replace with function body.

func hit(damage: float):
	health -= damage
	if health <= 0:
		_die()

func _die():
	pass

# This step is to evaluate what the enemy can see
# And make a decision as to its current state
func evaluate():
	pass
