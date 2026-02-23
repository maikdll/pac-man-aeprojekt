extends CharacterBody2D

const SPEED = 300.0
var current_direction = Vector2.RIGHT

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("ui_right"):
		current_direction = Vector2.RIGHT
	elif Input.is_action_pressed("ui_left"):
		current_direction = Vector2.LEFT
	elif Input.is_action_pressed("ui_down"):
		current_direction = Vector2.DOWN
	elif Input.is_action_pressed("ui_up"):
		current_direction = Vector2.UP

	velocity = current_direction * SPEED

	move_and_slide()
	
	if current_direction != Vector2.ZERO:
		rotation = current_direction.angle()


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("Points"):
		$AudioStreamPlayer.play()
