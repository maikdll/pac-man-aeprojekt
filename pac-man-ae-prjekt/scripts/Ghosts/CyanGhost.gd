extends BaseGhost

@onready var blinky = get_tree().get_first_node_in_group("RedGhost")

func get_speed_multiplier() -> float:
	return Global.speedGhostCyan

func _on_wave_timeout():
	if current_mode == Mode.SCATTER:
		print("Inky: Angriff")
		start_wave(Mode.CHASE, 15.0) 
	else:
		print("Inky: Pause")
		start_wave(Mode.SCATTER, 10.0)
		
	if current_mode == Mode.SCATTER:
		pick_new_scatter_target()
		
	update_path()

func get_custom_target() -> Vector2:
	if current_mode == Mode.CHASE:
		if blinky != null:
			var pacman_direction = Vector2.ZERO
			if "direction" in pacman:
				pacman_direction = pacman.direction.normalized()
			elif "velocity" in pacman and pacman.velocity.length() > 0:
				pacman_direction = pacman.velocity.normalized()
			var pivot_point = pacman.global_position + (pacman_direction * 96.0)
			var vector_from_blinky = pivot_point - blinky.global_position
			return blinky.global_position + (vector_from_blinky * 2.0)
		else:
			return pacman.global_position
	else:
		if global_position.distance_to(current_scatter_target) < 32.0:
			pick_new_scatter_target()
		return current_scatter_target
