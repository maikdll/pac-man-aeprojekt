extends CharacterBody2D

var current_direction = Vector2.RIGHT
var next_direction = Vector2.RIGHT
var is_invincible = false
var isDying = false
var intermission_time_left = 0.0

@export var spawn_position: Vector2 = Vector2(400, 600)

func ready():
	get_tree().call_group("Main", "setDifficulty")
	global_position = spawn_position

func _process(delta):
	if intermission_time_left > 0:
		intermission_time_left -= delta
		if intermission_time_left <= 0:
			Global.isIntermissionMode = false
			get_tree().call_group("Main", "setDifficulty")

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
		print("Big point eaten!")
		$AudioIntermission.play()
		Global.isIntermissionMode = true
		Global.speedGhost = Global.speedGhost / 2
		intermission_time_left = 7.0
		get_tree().call_group("Ghost", "start_wave", 1, 10.0) # 1 = Scatter Mode
		
		
		
func _on_area_2d_body_entered(body: Node2D) -> void:
	if isDying:
		return
	if not body.is_in_group("Ghost"):
		return
	
	if Global.isIntermissionMode == false:
		isDying = true
		Global.health -= 1
		get_tree().call_group("ui", "update_healthbar", Global.health)
		global_position = spawn_position
		await get_tree().create_timer(1.0).timeout
		isDying = false
	
	elif body.is_in_group("RedGhost"):
		get_tree().call_group("RedGhost", "get_eaten")
	elif body.is_in_group("PinkGhost"):
		get_tree().call_group("PinkGhost", "get_eaten")
	elif body.is_in_group("CyanGhost"):
		get_tree().call_group("CyanGhost", "get_eaten")
	elif body.is_in_group("OrangeGhost"):
		get_tree().call_group("OrangeGhost", "get_eaten")
