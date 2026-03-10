extends Node2D

@export var tile_map1: TileMapLayer 
@export var tile_map2: TileMapLayer 
@export var tile_map3: TileMapLayer
@export var tile_map4: TileMapLayer

@onready var healthbar = $Healthbar
@onready var fruitbar = $Fruitbar
@onready var score_ui = $Score

@export var big_point_scene: PackedScene
@export var point_scene: PackedScene
@onready var points_container = $Points
@export var point_spacing: int = 2

var fruit_spawned_1 = false
var fruit_spawned_2 = false
@onready var level_fruit = $Fruit 
@onready var ready_label = $ReadyScreen/ReadyLabel

var astar_grid = AStarGrid2D.new()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			get_tree().quit()
	elif event is InputEventJoypadButton and event.pressed:
		var quit_buttons = [
			10, 11, 12, 
			JOY_BUTTON_GUIDE, 
			JOY_BUTTON_START, 
			JOY_BUTTON_BACK
		]
		if event.button_index in quit_buttons:
			get_tree().quit()
			
func _ready():
	Global.resetLedGameplay()
	var joypads = Input.get_connected_joypads()
	print("Verbundene Controller beim Start: ", joypads)
	
	Global.isGameStopped = true 
	Global.isIntermissionMode = false
	
	setDifficulty()
	
	if level_fruit:
		level_fruit.visible = false
		level_fruit.set_deferred("monitoring", false)
		level_fruit.set_deferred("monitorable", false)
	
	if tile_map1 and tile_map2 and tile_map3:
		setup_grid()
		spawn_points()
		restrict_grid_for_ghosts()
		
	start_ready_sequence()
	
func start_ready_sequence():
	for i in range(6):
		if ready_label:
			ready_label.visible = not ready_label.visible
		await get_tree().create_timer(0.5).timeout
		
	if ready_label:
		ready_label.visible = false
		
	Global.isGameStopped = false
	
	get_tree().call_group("PacMan", "start_moving_animation")

func _process(delta):
	if Global.dots_eaten == 138 and not fruit_spawned_1:
		fruit_spawned_1 = true
		spawn_fruit()
		
	if Global.dots_eaten == 335 and not fruit_spawned_2:
		fruit_spawned_2 = true
		spawn_fruit()
		
func setup_grid():
	var full_rect = tile_map1.get_used_rect().merge(tile_map2.get_used_rect().merge(tile_map3.get_used_rect()))
	
	astar_grid.region = full_rect
	astar_grid.cell_size = Vector2(16, 16)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	astar_grid.fill_solid_region(astar_grid.region, false)

	_add_walls_from_layer(tile_map1)
	_add_walls_from_layer(tile_map2)

func _add_walls_from_layer(layer: TileMapLayer):
	var cells = layer.get_used_cells()
	for cell in cells:
		astar_grid.set_point_solid(cell, true)

func get_path_to_pacman(ghost_global_pos: Vector2, target_global_pos: Vector2) -> Array[Vector2i]:
	var local_ghost = tile_map1.to_local(ghost_global_pos)
	var local_target = tile_map1.to_local(target_global_pos)
	
	var start_cell = tile_map1.local_to_map(local_ghost)
	var end_cell = tile_map1.local_to_map(local_target)
	
	if not astar_grid.region.has_point(start_cell) or not astar_grid.region.has_point(end_cell):
		return []

	return astar_grid.get_id_path(start_cell, end_cell)

func spawn_points():
	points_container.global_position = Vector2.ZERO
	for child in points_container.get_children():
		child.queue_free()

	var region = astar_grid.region
	var points_placed = 0

	for x in range(region.position.x, region.end.x):
		for y in range(region.position.y, region.end.y):
			var cell = Vector2i(x, y)
			
			if astar_grid.is_point_solid(cell):
				continue
				
			if tile_map3.get_cell_source_id(cell) != -1:
				continue
				
			var touches_wall = false
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					if dx == 0 and dy == 0:
						continue
					var neighbor_cell = cell + Vector2i(dx, dy)
					if astar_grid.is_in_boundsv(neighbor_cell):
						if astar_grid.is_point_solid(neighbor_cell):
							touches_wall = true
							break
				if touches_wall:
					break
			if touches_wall:
				continue
				
			points_placed += 1
		
			if Global.eaten_points_positions.has(cell):
				continue
			
			var local_center = tile_map1.map_to_local(cell)
			var current_point_pos = tile_map1.to_global(local_center)
			
			var point
			if points_placed % 60 == 0:
				point = big_point_scene.instantiate()
			else:
				point = point_scene.instantiate()
				
			points_container.add_child(point)
			point.global_position = current_point_pos
			
			point.grid_pos = cell
			Global.remainingPoints = points_placed

func restrict_grid_for_ghosts():
	var edge_cells_to_block = []
	var region = astar_grid.region
	
	for x in range(region.position.x, region.end.x):
		for y in range(region.position.y, region.end.y):
			var cell = Vector2i(x, y)
			
			if astar_grid.is_point_solid(cell):
				continue
				
			var touches_wall = false
			
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					if dx == 0 and dy == 0:
						continue
						
					var neighbor_cell = cell + Vector2i(dx, dy)
					if astar_grid.is_in_boundsv(neighbor_cell):
						if astar_grid.is_point_solid(neighbor_cell):
							touches_wall = true
							break
							
				if touches_wall:
					break
					
			if touches_wall:
				edge_cells_to_block.append(cell)
			
	for cell in edge_cells_to_block:
		astar_grid.set_point_solid(cell, true)

func checkAllPointsEaten():
	Global.remainingPoints -= 1
	
	if Global.remainingPoints <= 0:
		Global.isGameStopped = true
		get_tree().call_group("PacMan", "stop_for_level_end")
		
		await get_tree().create_timer(0.25).timeout
		
		Global.level += 1
		Global.eaten_points_positions.clear()
		Global.dots_eaten = 0
		Global.died_in_level = false
		
		fruit_spawned_1 = false
		fruit_spawned_2 = false
		
		await get_tree().create_timer(1.0).timeout
		
		get_tree().call_group("PacMan", "set", "visible", false)
		get_tree().call_group("Ghost", "set", "visible", false)
		
		for i in range(4):
			tile_map1.visible = false
			tile_map2.visible = false
			tile_map4.visible = false
			
			if healthbar: healthbar.visible = false
			if fruitbar: fruitbar.visible = false
			if score_ui: score_ui.visible = false
			
			await get_tree().create_timer(0.2).timeout
			
			tile_map1.visible = true
			tile_map2.visible = true
			tile_map4.visible = true
			
			if healthbar: healthbar.visible = true
			if fruitbar: fruitbar.visible = true
			if score_ui: score_ui.visible = true
			
			await get_tree().create_timer(0.2).timeout
			
		get_tree().change_scene_to_file("res://scenes/Cutscenes.tscn")
		
func setDifficulty():
	print("LEVEL: ", Global.level)
	print(Global.speedPlayer)
	if Global.level == 1:
		Global.speedPlayer = 1.0
		Global.speedGhost = 0.6
	elif Global.level == 2:
		Global.speedPlayer = 1.2
		Global.speedGhost = 0.6
	elif Global.level == 3:
		Global.speedPlayer = 1.4
		Global.speedGhost = 0.8
	elif Global.level == 4:
		Global.speedPlayer = 1.6
		Global.speedGhost = 1.0
	elif Global.level == 5:
		Global.speedPlayer = 1.8
		Global.speedGhost = 1.2
	elif Global.level == 6:
		Global.speedPlayer = 1.8
		Global.speedGhost = 1.4
	elif Global.level == 7:
		Global.speedPlayer = 1.8
		Global.speedGhost = 1.6
	elif Global.level == 8:
		Global.speedPlayer = 2
		Global.speedGhost = 1.6
	elif Global.level == 9:
		Global.speedPlayer = 2
		Global.speedGhost = 1.8
	elif Global.level == 10:
		Global.speedPlayer = 2.0
		Global.speedGhost = 2.0
	else:
		Global.speedPlayer = 1.8
		Global.speedGhost = 2 + (Global.level -10) / 10.0

func spawn_fruit():
	if not level_fruit: return
	
	#Textur aus Fruitbar-Skript
	if fruitbar and fruitbar.has_method("get_texture_for_level"):
		level_fruit.get_node("Sprite2D").texture = fruitbar.get_texture_for_level(Global.level)
	
	var current_score = get_fruit_score(Global.level)
	level_fruit.set_meta("score_value", current_score)
	
	#Position
	level_fruit.global_position = Vector2(480, 152) 
	
	#Frucht aktivieren
	level_fruit.visible = true
	level_fruit.set_deferred("monitoring", true)
	level_fruit.set_deferred("monitorable", true)
	
	#Timer
	await get_tree().create_timer(13.5).timeout
	
	if is_instance_valid(level_fruit) and level_fruit.visible:
		level_fruit.visible = false
		level_fruit.set_deferred("monitoring", false)
		level_fruit.set_deferred("monitorable", false)

func get_fruit_score(lvl: int) -> int:
	if lvl == 1: return 200
	elif lvl == 2: return 600
	elif lvl == 3 or lvl == 4: return 1000
	elif lvl == 5 or lvl == 6: return 1400
	elif lvl == 7 or lvl == 8: return 2000
	elif lvl == 9 or lvl == 10: return 4000
	elif lvl == 11 or lvl == 12: return 6000
	else: return 10000
