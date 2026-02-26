extends CharacterBody2D

@export var speed = 80.0
var current_path: Array[Vector2i] = []
var target_position: Vector2

@onready var main_node = get_tree().root.get_node("Main")
@onready var pacman = get_tree().get_first_node_in_group("PacMan")

func _ready():
	await get_tree().create_timer(0.1).timeout
	update_path()
	
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.timeout.connect(update_path)
	add_child(timer)

func update_path():
	var new_path = main_node.get_path_to_pacman(global_position, pacman.global_position)
	
	if new_path.is_empty():
		return
	
	new_path.pop_front()
	
	if not new_path.is_empty():
		current_path = new_path
		set_next_target()

func set_next_target():
	if current_path.is_empty(): return
	var next_cell = current_path[0]
	
	var local_pos = main_node.tile_map.map_to_local(next_cell)
	target_position = main_node.tile_map.to_global(local_pos)

func _process(delta):
	if current_path.is_empty(): return
	
	global_position = global_position.move_toward(target_position, speed * delta)
	
	if global_position.distance_to(target_position) < 1.0:
		current_path.pop_front()
		if not current_path.is_empty():
			set_next_target()
