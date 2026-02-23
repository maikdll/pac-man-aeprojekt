extends CharacterBody2D

@export var speed: float = 200.0
# We start by moving Right
var current_direction: Vector2 = Vector2.RIGHT

func _physics_process(_delta):
	# 1. Apply the current direction to velocity
	velocity = current_direction * speed
	
	# 2. Move the ghost. move_and_slide returns 'true' if it hit something
	move_and_slide()
	
	# 3. Check if we hit a wall in this frame
	if is_on_wall():
		# This flips the direction: if it was 1, it becomes -1. If -1, it becomes 1.
		current_direction.x *= -1 
		
		# Optional: Flip the visual sprite to face the new direction
		if has_node("Sprite2D"):
			$Sprite2D.flip_h = current_direction.x < 0
