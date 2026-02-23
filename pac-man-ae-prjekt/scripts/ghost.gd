extends CharacterBody2D

@export var speed = 150.0  # How fast the ghost moves
@onready var nav_agent = $NavigationAgent2D # Reference to the "Brain" node

# Your friends will "link" the player node to this variable later
var player = 1

func _physics_process(_delta):
	if player:
		
	# 1. Tell the "Brain" where the player is currently standin
		# 2. Ask the "Brain": "Where is the next step I should take to get there?"
		var next_path_pos = nav_agent.get_next_path_position()
		
		# 3. Calculate the direction (the angle) from the ghost to that next step
		var current_direction = global_position.direction_to(next_path_pos)
		var direction = Vector2.RIGHT
		# 4. Apply the speed to that direction and move the ghost
		velocity = direction * speed
		
		# This function moves the ghost and handles wall collisions automatically
		move_and_slide()
