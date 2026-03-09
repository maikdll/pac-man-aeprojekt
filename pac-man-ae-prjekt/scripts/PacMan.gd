extends CharacterBody2D

var current_direction = Vector2.RIGHT
var next_direction = Vector2.RIGHT
var is_invincible = false
var isDying = false
var intermission_time_left = 0.0
var intermission_blink_time = 0.0
var is_waiting_for_start = true

@export var spawn_position: Vector2 = Vector2(400, 800)

func _ready():
	get_tree().call_group("Main", "setDifficulty")
	global_position = spawn_position
	velocity = Vector2.ZERO
	is_waiting_for_start = true
	$AnimatedSprite2D.play("Closed")
	
	blink_ready_label()
	
	var start_timer = Timer.new()
	start_timer.name = "AutoStartTimer"
	start_timer.wait_time = 3.0
	start_timer.one_shot = true
	start_timer.autostart = true
	add_child(start_timer)
	start_timer.timeout.connect(_on_auto_start_timeout)

func blink_ready_label():
	var ready_label = get_tree().root.find_child("ReadyLabel", true, false)
	if ready_label:
		for i in range(3):
			if not is_waiting_for_start: break
			ready_label.show()
			await get_tree().create_timer(0.5).timeout
			if not is_waiting_for_start: break
			ready_label.hide()
			await get_tree().create_timer(0.5).timeout

func _on_auto_start_timeout():
	if is_waiting_for_start:
		start_game_logic()

func start_game_logic():
	is_waiting_for_start = false
	get_tree().call_group("Ghost", "start_moving")
	$AnimatedSprite2D.play("PacMan_Kauen")
	var ready_label = get_tree().root.find_child("ReadyLabel", true, false)
	if ready_label:
		ready_label.hide()

func _process(delta):
	if intermission_time_left > 0:
		intermission_time_left -= delta
		if intermission_time_left <= 0:
			$AudioIntermission.stop()
			Global.isIntermissionMode = false
			get_tree().call_group("Main", "setDifficulty")

func _physics_process(_delta: float) -> void:
	if is_waiting_for_start:
		if Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
			start_game_logic()
		else:
			return

	if Global.isGameStopped == false:
		if Input.is_action_pressed("ui_right"):
			next_direction = Vector2.RIGHT
		elif Input.is_action_pressed("ui_left"):
			next_direction = Vector2.LEFT
		elif Input.is_action_pressed("ui_down"):
			next_direction = Vector2.DOWN
		elif Input.is_action_pressed("ui_up"):
			next_direction = Vector2.UP
		
		var can_turn = not test_move(transform, next_direction * 25)
		if next_direction != current_direction and can_turn:
			if next_direction.x != 0: global_position.y = snapped(global_position.y, 8.0)
			if next_direction.y != 0: global_position.x = snapped(global_position.x, 8.0)
			current_direction = next_direction
		
		velocity = current_direction * Global.speedPlayer * 100
		move_and_slide()
	
	if velocity.length() > 0:
		rotation = current_direction.angle()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("Points"):
		$AudioEatingPoints.play()
		get_tree().call_group("Main", "checkAllPointsEaten")
	
	if area.is_in_group("Fruit"):
		$AudioEatingFruit.play()

	if area.is_in_group("BigPoint"):
		var times = get_intermission_times(Global.level)
		intermission_time_left = times["total"]
		intermission_blink_time = times["blink"]
		
		if intermission_time_left > 0:
			$AudioIntermission.play()
			Global.isIntermissionMode = true
			
			get_tree().call_group("Ghost", "set", "is_eaten", false)
			
			Global.eatGhostScore = 200 
			Global.speedGhost = 0.5 
			
			get_tree().call_group("Ghost", "update_path")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if isDying: return
	if not body.is_in_group("Ghost"): return
	if body.is_eaten: return
		
	if Global.isIntermissionMode == true and body.is_immune == false:
		$AudioEatingGhost.play()
		body.get_eaten()
		Global.score += Global.eatGhostScore
		Global.eatGhostScore *= 2
	else:
		killPacman()

func killPacman():
	if isDying: return
	$AudioDeath.play()
	isDying = true
	Global.isGameStopped = true 
	$AnimatedSprite2D.scale = Vector2(2.5, 2.5)
	$AnimatedSprite2D.play("Death", 2.5)
	await $AnimatedSprite2D.animation_finished
	await get_tree().create_timer(1.0).timeout 
	Global.health -= 1
	get_tree().call_group("ui", "update_healthbar")
	if Global.health > 0:
		Global.died_in_level = true
		get_tree().reload_current_scene()
	else:
		get_tree().call_group("ui", "setGameOver")

func get_intermission_times(level: int) -> Dictionary:
	var total_time = 0.0
	var blink_time = 0.0
	
	if level == 1:
		total_time = 10.0; blink_time = 5.0
	elif level == 2:
		total_time = 9.0; blink_time = 4.5
	elif level == 3:
		total_time = 8.0; blink_time = 4.0
	elif level == 4:
		total_time = 7.0; blink_time = 3.5
	elif level >= 5 and level <= 8:
		total_time = 6.0; blink_time = 3.0
	elif level >= 9 and level <= 16:
		total_time = 5.0; blink_time = 2.5
	else:
		total_time = 4.0; blink_time = 2.0

	return {"total": total_time, "blink": blink_time}

func stop_for_level_end():
	$AnimatedSprite2D.play("Closed")
