extends Area2D

@export var target_spawn: Marker2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("PacMan") or body.is_in_group("Ghost"):
		if target_spawn != null:
			body.global_position = target_spawn.global_position
