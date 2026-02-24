extends CharacterBody2D

@export var speed: float = 160.0
@export var tile_size: int = 32

var current_direction = Vector2.RIGHT
var last_position = Vector2.ZERO

func _ready():
	randomize()
	position = (position / tile_size).floor() * tile_size + Vector2(tile_size/2, tile_size/2)
	last_position = position

func _physics_process(_delta: float) -> void:
	velocity = current_direction * speed
	move_and_slide()

	if position.distance_to(last_position) < 0.5:
		_on_stuck()
	
	last_position = position

func _on_stuck():
	var directions = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
	directions.shuffle()
	
	for dir in directions:
		if not test_move(transform, dir * 5):
			current_direction = dir
			return
