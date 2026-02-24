extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "PacMan":
		Global.score += 300
		queue_free()
