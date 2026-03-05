extends CharacterBody2D

@export var wander_radius: float = 200.0 
@export var spawnpoint: Marker2D;

enum Mode { CHASE, SCATTER }
var current_mode = Mode.SCATTER
var wave_timer: Timer

var is_eaten = false;

var isReady = false

var current_path: Array[Vector2i] = []
var target_position: Vector2

var current_scatter_target: Vector2 = Vector2.ZERO

@onready var main_node = get_tree().root.get_node("Main")
@onready var pacman = get_tree().get_first_node_in_group("PacMan")

func _ready():
	global_position = spawnpoint.global_position
	await get_tree().create_timer(0.1).timeout
	current_scatter_target = global_position
	
	var timer = Timer.new()
	timer.wait_time = 0.3
	timer.autostart = true
	timer.timeout.connect(update_path)
	add_child(timer)
	
	wave_timer = Timer.new()
	wave_timer.one_shot = true
	wave_timer.timeout.connect(_on_wave_timeout)
	add_child(wave_timer)
	
	start_wave(Mode.SCATTER, 7.0)
	update_path()
	isReady = true

func pick_new_scatter_target():
	for i in range(30):
		var random_offset = Vector2(
			randf_range(-wander_radius, wander_radius),
			randf_range(-wander_radius, wander_radius)
		)
		var test_target = global_position + random_offset
		var local_pos = main_node.tile_map1.to_local(test_target)
		var map_pos = main_node.tile_map1.local_to_map(local_pos)
		
		if main_node.astar_grid.region.has_point(map_pos) and not main_node.astar_grid.is_point_solid(map_pos):
			current_scatter_target = test_target
			return
			
	current_scatter_target = global_position

func start_wave(mode: Mode, duration: float):
	current_mode = mode
	if isReady:
		wave_timer.start(duration)

func _on_wave_timeout():
	if current_mode == Mode.SCATTER:
		print("Blinky: Angriff")
		start_wave(Mode.CHASE, 20.0) 
	else:
		print("Blinky: Wandern")
		start_wave(Mode.SCATTER, 10.0)
		
	if current_mode == Mode.SCATTER:
		pick_new_scatter_target()
		
	update_path()

func update_path():
	if pacman == null: return
	
	var current_target = Vector2.ZERO
	
	if current_mode == Mode.CHASE:
		current_target = pacman.global_position
	else:
		if global_position.distance_to(current_scatter_target) < 32.0:
			pick_new_scatter_target()
		current_target = current_scatter_target
		
	var new_path = main_node.get_path_to_pacman(global_position, current_target)
	
	if new_path.is_empty() and current_mode == Mode.SCATTER:
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
		# 1. Der Geist bewegt sich
		global_position = global_position.move_toward(target_position, 100 * Global.speedGhostCyan * Global.speedGhost * delta)
		
		# 2. WICHTIG: Wir checken die Richtung JEDEN Frame, in dem er sich bewegt!
		get_direction()
	
	# 3. Wenn er am Ziel ankommt, holt er sich den nächsten Wegpunkt
	if global_position.distance_to(target_position) < 1.0:
		current_path.pop_front()
		if not current_path.is_empty():
			set_next_target()

func get_eaten():
	
	global_position = spawnpoint.global_position
	current_path.clear()

func get_direction():
	var direction = target_position - global_position
	
	# Kleine Sicherung: Wenn er schon quasi exakt auf dem Ziel steht, 
	# soll er sich nicht mehr drehen (verhindert wildes Flackern)
	if direction.length() < 0.5:
		return
		
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			$AnimatedSprite2D.play("Rechts")
		else:
			$AnimatedSprite2D.play("Links")
	else:
		if direction.y > 0:
			$AnimatedSprite2D.play("Unten")
		else:
			$AnimatedSprite2D.play("Oben")
