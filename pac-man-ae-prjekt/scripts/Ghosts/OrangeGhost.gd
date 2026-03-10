extends BaseGhost

@export var panic_distance = 150.0 
@export var resume_chase_distance = 500.0 
var is_panicking: bool = false 

func get_speed_multiplier() -> float:
	return Global.speedGhostOrange

func _on_wave_timeout():
	if current_mode == Mode.SCATTER:
		print("Clyde: Angriff")
		start_wave(Mode.CHASE, 20.0) 
	else:
		print("Clyde: Wandern")
		start_wave(Mode.SCATTER, 10.0)
		
	if current_mode == Mode.SCATTER:
		pick_new_scatter_target()
		
	update_path()

func get_custom_target() -> Vector2:
	var distance_to_pacman = global_position.distance_to(pacman.global_position)
	if current_mode == Mode.CHASE:
		if is_panicking:
			if distance_to_pacman > resume_chase_distance:
				is_panicking = false
		else:
			if distance_to_pacman < panic_distance:
				is_panicking = true
	else:
		is_panicking = false
		
	if current_mode == Mode.SCATTER or is_panicking:
		if global_position.distance_to(current_scatter_target) < 32.0:
			pick_new_scatter_target()
		return current_scatter_target
	else:
		return pacman.global_position
