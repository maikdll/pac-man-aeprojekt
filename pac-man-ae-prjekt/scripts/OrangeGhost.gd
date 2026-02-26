extends CharacterBody2D

@export var speed = 80.0

# Ab hier kriegt er Panik (8 Kacheln)
@export var panic_distance = 384.0 
# Ab hier traut er sich wieder anzugreifen (Puffer-Distanz!)
@export var resume_chase_distance = 550.0 

@export var scatter_position: Vector2 = Vector2(100, 800) 

var current_path: Array[Vector2i] = []
var target_position: Vector2

# NEU: Das Gedächtnis des Geistes
var is_fleeing: bool = false 

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
	if pacman == null: return
	
	var distance_to_pacman = global_position.distance_to(pacman.global_position)
	var current_target = Vector2.ZERO
	
	# --- DIE NEUE FEIGLING-LOGIK ---
	if is_fleeing:
		# Er ist bereits im Panik-Modus.
		# Er hört erst auf zu flüchten, wenn er WIRKLICH weit weg ist!
		if distance_to_pacman > resume_chase_distance:
			is_fleeing = false # Mut wiedergefunden!
	else:
		# Er ist im Angriffs-Modus.
		# Er kriegt erst Panik, wenn er zu nah ist.
		if distance_to_pacman < panic_distance:
			is_fleeing = true # Panik!
			
	# Ziel anhand des aktuellen Zustands setzen
	if is_fleeing:
		current_target = scatter_position
	else:
		current_target = pacman.global_position
	# -------------------------------
		
	# 3. SCHRITT: Weg berechnen
	var new_path = main_node.get_path_to_pacman(global_position, current_target)
	
	# 4. SICHERHEIT: Fallback, falls die Ecke verbuggt ist
	if new_path.is_empty() and is_fleeing:
		new_path = main_node.get_path_to_pacman(global_position, pacman.global_position)
	
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
