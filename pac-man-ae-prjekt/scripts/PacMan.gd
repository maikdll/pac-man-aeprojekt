extends CharacterBody2D

var current_direction = Vector2.RIGHT
var next_direction = Vector2.RIGHT
var is_invincible = false
var isDying = false

@export var spawn_position: Vector2 = Vector2(400, 600)

func ready():
	get_tree().call_group("Main", "setDifficulty")
	global_position = spawn_position

func _physics_process(_delta: float) -> void:
	if Global.isGameStopped == false:
		if Input.is_action_pressed("ui_right"):
			next_direction = Vector2.RIGHT
		elif Input.is_action_pressed("ui_left"):
			next_direction = Vector2.LEFT
		elif Input.is_action_pressed("ui_down"):
			next_direction = Vector2.DOWN
		elif Input.is_action_pressed("ui_up"):
			next_direction = Vector2.UP
		var can_turn = not test_move(transform, next_direction * 30)
		if next_direction != current_direction and can_turn:
			velocity = (current_direction * 0.5 + next_direction).normalized() * Global.speedPlayer * 100
			current_direction = next_direction
		else:
			if is_on_wall() and can_turn:
				current_direction = next_direction
		velocity = current_direction * Global.speedPlayer * 100

	if Global.isGameStopped == false:
		if move_and_slide():
			pass
	
	if velocity.length() > 0:
		rotation = current_direction.angle()


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("Points"):
		$AudioEatingPoints.play()
		get_tree().call_group("Main", "checkAllPointsEaten")
	if area.is_in_group("Fruit"):
		$AudioEatingFruit.play()
	if area.is_in_group("BigPoint"):
		$AudioIntermission.play()
		
		
		
		
func _on_area_2d_body_entered(body: Node2D) -> void:
	if isDying:
		return
	if not body.is_in_group("Ghost"):
		return
	
	isDying = true
	Global.health -= 1
	get_tree().call_group("ui", "update_healthbar", Global.health)
	global_position = spawn_position
	await get_tree().create_timer(1.0).timeout
	isDying = false
	
