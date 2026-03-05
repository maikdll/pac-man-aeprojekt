extends CharacterBody2D

@export var ambush_distance = 300.0 

@export var scatter_anchor: Vector2 = Vector2(100, 100)
@export var wander_radius: float = 200.0 

enum Mode { CHASE, SCATTER }
var current_mode = Mode.SCATTER
var wave_timer: Timer
var current_scatter_target: Vector2 = Vector2.ZERO

var current_path: Array[Vector2i] = []
var target_position: Vector2

@onready var main_node = get_tree().root.get_node("Main")
@onready var pacman = get_tree().get_first_node_in_group("PacMan")
@onready var eyes: Sprite2D = $Eyes

var eye_textures := {
	"right": preload("res://assets/ghost/Ghost_Eyes_Right.png"),
	"left": preload("res://assets/ghost/Ghost_Eyes_Left.png"),
	"up": preload("res://assets/ghost/Ghost_Eyes_Up.png"),
	"down": preload("res://assets/ghost/Ghost_Eyes_Down.png"),
}

func _ready():
	await get_tree().create_timer(0.1).timeout
	current_scatter_target = global_position
	
	var timer = Timer.new()
	timer.wait_time = 1
	timer.autostart = true
	timer.timeout.connect(update_path)
	add_child(timer)
	
	wave_timer = Timer.new()
	wave_timer.one_shot = true
	wave_timer.timeout.connect(_on_wave_timeout)
	add_child(wave_timer)
	
	start_wave(Mode.SCATTER, 10.0)
	update_path()

func pick_new_scatter_target():
	var current_dir = Vector2.ZERO
	if target_position != Vector2.ZERO and global_position.distance_to(target_position) > 0.1:
		current_dir = (target_position - global_position).normalized()
		
	var search_center = global_position + (current_dir * (wander_radius * 0.5))

	for i in range(30):
		var random_offset = Vector2(
			randf_range(-wander_radius, wander_radius),
			randf_range(-wander_radius, wander_radius)
		)
		var test_target = search_center + random_offset
		var local_pos = main_node.tile_map1.to_local(test_target)
		var map_pos = main_node.tile_map1.local_to_map(local_pos)
		
		if main_node.astar_grid.region.has_point(map_pos) and not main_node.astar_grid.is_point_solid(map_pos):
			current_scatter_target = test_target
			return
			
	current_scatter_target = global_position + (current_dir * 48.0)

func start_wave(mode: Mode, duration: float):
	current_mode = mode
	wave_timer.start(duration)

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

func update_path():
	if pacman == null: return
	
	var current_target = Vector2.ZERO
	
	if current_mode == Mode.CHASE:
		var pacman_direction = Vector2.ZERO
		if "direction" in pacman:
			pacman_direction = pacman.direction.normalized()
		elif "velocity" in pacman and pacman.velocity.length() > 0:
			pacman_direction = pacman.velocity.normalized()
			
		current_target = pacman.global_position + (pacman_direction * ambush_distance)
	else:
		if global_position.distance_to(current_scatter_target) < 32.0:
			pick_new_scatter_target()
		current_target = current_scatter_target
		
	var new_path = main_node.get_path_to_pacman(global_position, current_target)

	if current_mode == Mode.CHASE and new_path.is_empty():
		new_path = main_node.get_path_to_pacman(global_position, pacman.global_position)
	elif current_mode == Mode.SCATTER and new_path.is_empty():
		pick_new_scatter_target()
		return 
	
	if new_path.is_empty() or new_path.size() <= 1:
		return
	
	new_path.pop_front()
	
	if not new_path.is_empty():
		current_path = new_path
		set_next_target()

func set_next_target():
	if current_path.is_empty(): return
	var next_cell = current_path[0]
	
	var local_pos = main_node.tile_map1.map_to_local(next_cell)
	target_position = main_node.tile_map1.to_global(local_pos)

func _process(delta):
	if current_path.is_empty(): return

	if Global.isGameStopped == false:
		global_position = global_position.move_toward(target_position, 100 * Global.speedGhostPink * Global.speedGhost * delta)
	
	if global_position.distance_to(target_position) < 1.0:
		current_path.pop_front()
		if not current_path.is_empty():
			set_next_target()

	_update_eyes()

func _update_eyes():
	var dir = (target_position - global_position).normalized()
	if abs(dir.x) >= abs(dir.y):
		eyes.texture = eye_textures["right"] if dir.x > 0 else eye_textures["left"]
	else:
		eyes.texture = eye_textures["down"] if dir.y > 0 else eye_textures["up"]
