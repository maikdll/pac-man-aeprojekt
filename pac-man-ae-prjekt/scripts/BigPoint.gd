extends Area2D

@onready var sprite = $Sprite2D 

func _ready():
	var blink_timer = Timer.new()
	blink_timer.wait_time = 0.25 
	blink_timer.autostart = true
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	add_child(blink_timer)

func _on_blink_timer_timeout():
	if sprite != null:
		sprite.visible = not sprite.visible

func _on_body_entered(body: Node2D) -> void:
	if body.name == "PacMan":
		Global.score += 50
		queue_free()
