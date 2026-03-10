extends BaseGhost

@export var ambush_distance = 300.0 

func get_speed_multiplier() -> float:
	return Global.speedGhostPink

func _on_wave_timeout():
	if current_mode == Mode.SCATTER:
		print("Pinky: Hinterhalt")
		start_wave(Mode.CHASE, 15.0) 
	else:
		print("Pinky: Wandern")
		start_wave(Mode.SCATTER, 10.0)
		
	if current_mode == Mode.SCATTER:
		pick_new_scatter_target()
		
	update_path()

func get_custom_target() -> Vector2:
	if current_mode == Mode.CHASE:
		var pacman_direction = Vector2.ZERO
		if "direction" in pacman:
			pacman_direction = pacman.direction.normalized()
		elif "velocity" in pacman and pacman.velocity.length() > 0:
			pacman_direction = pacman.velocity.normalized()
		return pacman.global_position + (pacman_direction * ambush_distance)
	else:
		if global_position.distance_to(current_scatter_target) < 32.0:
			pick_new_scatter_target()
		return current_scatter_target
