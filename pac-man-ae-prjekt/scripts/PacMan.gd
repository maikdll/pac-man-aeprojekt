extends CharacterBody2D

var current_direction = Vector2.RIGHT
var next_direction = Vector2.RIGHT
var is_invincible = false
var isDying = false
var intermission_time_left = 0.0
var intermission_blink_time = 0.0

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
	if area.is_in_group("Points"):
		$AudioEatingPoints.play()
		get_tree().call_group("Main", "checkAllPointsEaten")
	if area.is_in_group("Fruit"):
		$AudioEatingFruit.play()
	if area.is_in_group("BigPoint"):
		print("Big point eaten!")
		
		# Hol dir die Zeiten für das aktuelle Level
		var times = get_intermission_times(Global.level)
		intermission_time_left = times["total"]
		intermission_blink_time = times["blink"]
		
		# Nur wenn die Zeit größer als 0 ist, schalten wir den Modus ein 
		# (Ab Level 17 passiert nämlich gar nichts mehr!)
		if intermission_time_left > 0:
			$AudioIntermission.play()
			Global.isIntermissionMode = true
			get_tree().call_group("Ghost", "set", "is_eaten", false)
			Global.eatGhostScore = 400
			Global.speedGhost = Global.speedGhost / 2
			get_tree().call_group("Ghost", "start_wave", 1, 10.0) # 1 = Scatter Mode
		
func _on_area_2d_body_entered(body: Node2D) -> void:
	if isDying:
		return
	if not body.is_in_group("Ghost"):
		return
	
	if Global.isIntermissionMode == false:
		killPacman()
		
	if Global.isIntermissionMode == true:
		if body.is_in_group("Ghost"):
			if body.is_eaten == false:
				body.get_eaten()
				body.is_eaten = true
				Global.score += Global.eatGhostScore
				Global.eatGhostScore *= 2
			elif body.is_eaten == true:
				killPacman()
				
				
func killPacman():
	isDying = true
	Global.health -= 1
	get_tree().call_group("ui", "update_healthbar", Global.health)
	global_position = spawn_position
	await get_tree().create_timer(1.0).timeout
	isDying = false
	
	
func get_intermission_times(level: int) -> Dictionary:
	var total_time = 0.0
	var blink_time = 0.0
	
	if level == 1:
		total_time = 6.0; blink_time = 2.0
	elif level == 2:
		total_time = 5.0; blink_time = 2.0
	elif level == 3:
		total_time = 4.0; blink_time = 2.0
	elif level == 4:
		total_time = 3.0; blink_time = 2.0
	elif level >= 5 and level <= 8:
		# Extrem kurz, fast sofortiges Blinken
		total_time = 2.0; blink_time = 2.0
	elif level >= 9 and level <= 16:
		# Ultra kurz
		total_time = 1.0; blink_time = 1.0
	else:
		# Level 17+: Geister werden GAR NICHT mehr blau!
		total_time = 0.0; blink_time = 0.0
		
	return {"total": total_time, "blink": blink_time}
	
	
