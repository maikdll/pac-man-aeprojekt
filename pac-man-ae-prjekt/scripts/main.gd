extends Node2D

@export var tile_map1: TileMapLayer 
@export var tile_map2: TileMapLayer 
@export var tile_map3: TileMapLayer 

@export var point_scene: PackedScene
@onready var points_container = $Points
@export var point_spacing: int = 2

var astar_grid = AStarGrid2D.new()

func _ready():
	Global.isGameStopped = false
	if tile_map1 and tile_map2 and tile_map3:
		setup_grid()
		spawn_points()
		restrict_grid_for_ghosts()

func setup_grid():
	var full_rect = tile_map1.get_used_rect().merge(tile_map2.get_used_rect().merge(tile_map3.get_used_rect()))
	
	astar_grid.region = full_rect
	astar_grid.cell_size = Vector2(16, 16)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	astar_grid.fill_solid_region(astar_grid.region, false)

	_add_walls_from_layer(tile_map1)
	_add_walls_from_layer(tile_map2)
	_add_walls_from_layer(tile_map3)

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
						
					if astar_grid.is_point_solid(cell + Vector2i(dx, dy)):
						touches_wall = true
						break
				if touches_wall:
					break
						
			if touches_wall:
				continue
				
			var point = point_scene.instantiate()
			points_container.add_child(point)
			var local_center = tile_map1.map_to_local(cell)
			point.global_position = tile_map1.to_global(local_center)

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
						
					if astar_grid.is_point_solid(cell + Vector2i(dx, dy)):
						touches_wall = true
						break
				if touches_wall:
					break
					
			if touches_wall:
				edge_cells_to_block.append(cell)
			
	for cell in edge_cells_to_block:
		astar_grid.set_point_solid(cell, true)
