extends CharacterBody2D

var current_direction = Vector2.RIGHT
var next_direction = Vector2.RIGHT
var is_invincible = false
var isDying = false
var is_ready_sequence = true
var intermission_time_left = 0.0
var intermission_blink_time = 0.0


@export var spawn_position: Vector2 = Vector2(400, 600)

func _ready():
	get_tree().call_group("Main", "setDifficulty")
	global_position = spawn_position
	
	$AnimatedSprite2D.play("Closed")

func _process(delta):
	if Global.isGameStopped:
		return
	if intermission_time_left > 0:
		intermission_time_left -= delta
		if intermission_time_left <= 0:
			Global.resetLedGameplay()
			$AudioIntermission.stop()
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
		var can_turn = not test_move(transform, next_direction * 25)
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
	# FIX: Schützt Punkte davor, im Todes-Animations-Screen oder beim "READY"-Startbildschirm gegessen zu werden.
	if isDying or is_ready_sequence:
		return

	# Normale Punkte
	if area.is_in_group("Points") and not area.is_in_group("BigPoint"):
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)
		area.visible = false
		$AudioEatingPoints.play()
		
		if "grid_pos" in area:
			Global.eaten_points_positions[area.grid_pos] = true
			
		Global.dots_eaten += 1
		Global.score += 10
		get_tree().call_group("Main", "checkAllPointsEaten")
		area.queue_free() 

	# Große Punkte (Power Pellets)
	elif area.is_in_group("BigPoint"):
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)
		area.visible = false
		print("Big point eaten!")
		
		if "grid_pos" in area:
			Global.eaten_points_positions[area.grid_pos] = true
			
		Global.dots_eaten += 1
		Global.score += 50
		get_tree().call_group("Main", "checkAllPointsEaten")
		
		var times = get_intermission_times(Global.level)
		intermission_time_left = times["total"]
		intermission_blink_time = times["blink"]
		
		if intermission_time_left > 0:
			$AudioIntermission.play()
			Global.isIntermissionMode = true
			get_tree().call_group("Ghost", "on_power_pellet_eaten")
			
			Global.eatGhostScore = 200 
			get_tree().call_group("Ghost", "start_wave", 1, 10.0)
			
		area.queue_free() 

	# Früchte
	elif area.is_in_group("Fruit"):
		$AudioEatingFruit.play()
		Global.send_effect(Global.CHAIN_A, "sparkle", Color.MAGENTA, Global.SEG_ALL, 40, 2)
		area.visible = false
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)
		
		if area.has_meta("score_value"):
			var value = area.get_meta("score_value")
			Global.score += value
			print("Frucht gefressen! +", value, " Punkte!")
		
func _on_area_2d_body_entered(body: Node2D) -> void:
	if isDying:
		return
	if not body.is_in_group("Ghost"):
		return
	
	if body.is_eaten:
		return
		
	if Global.isIntermissionMode == true and body.is_immune == false:
		Global.send_effect(Global.CHAIN_A, "sparkle", Color.WHITE, Global.SEG_ALL, 40, 5)
		$AudioEatingGhost.play()
		body.get_eaten()
		Global.score += Global.eatGhostScore
		Global.eatGhostScore *= 2
		$AudioReturnToHomeGhost.play()
		print("Geist gefressen!")
	else:
		killPacman()
				
				
func killPacman():
	if isDying: return
	Global.send_effect(Global.CHAIN_A, "chase", Color.RED, Global.SEG_ALL, 5, 2)
	Global.send_effect(Global.CHAIN_B, "blink", Color.RED, Global.SEG_ALL, 10, 2)
	
	print("Gegessene Punkte vor dem Reload: ", Global.eaten_points_positions.size())
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
		# Normaler Tod
		SceneTransition.change_scene(get_tree().current_scene.scene_file_path)
	else:
		# Game Over!
		SceneTransition.change_scene("res://scenes/UI/GameOver.tscn")
	
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
	
	
func start_moving_animation():
	is_ready_sequence = false
	$AnimatedSprite2D.play("PacMan_Kauen")
