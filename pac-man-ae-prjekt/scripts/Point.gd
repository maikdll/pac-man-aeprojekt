extends Area2D

var grid_pos: Vector2i

func _on_body_entered(body: Node2D) -> void:
	if body.name == "PacMan":
		Global.eaten_points_positions.append(grid_pos)
		Global.score += 10
		Global.dots_eaten += 1
		queue_free()
