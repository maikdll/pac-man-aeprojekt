extends BaseGhost

@export var chase_distance: float = 250.0

func get_speed_multiplier() -> float:
	return Global.speedGhostRed

func _on_wave_timeout():
	if current_mode == Mode.SCATTER:
		if Global.remainingPoints < 50:
			print("Blinky: Dauerangriff")
			start_wave(Mode.CHASE, 200.0) 
			if not $AudioStreamPlayer2D.playing: $AudioStreamPlayer2D.play()
		else:
			print("Blinky: Angriff")
			start_wave(Mode.CHASE, 20.0) 
	else:
		if Global.remainingPoints < 50:
			print("Blinky: Dauerangriff")
			start_wave(Mode.CHASE, 200.0) 
			if not $AudioStreamPlayer2D.playing: $AudioStreamPlayer2D.play()
		else:
			print("Blinky: Wandern")
			start_wave(Mode.SCATTER, 10.0)
		
	if current_mode == Mode.SCATTER:
		pick_new_scatter_target()
		
	update_path()

func get_custom_target() -> Vector2:
	var distance_to_pacman = global_position.distance_to(pacman.global_position)
	var is_pacman_near = distance_to_pacman <= chase_distance

	if current_mode == Mode.CHASE and is_pacman_near:
		return pacman.global_position
	else:
		if global_position.distance_to(current_scatter_target) < 32.0:
			pick_new_scatter_target()
		return current_scatter_target
