extends Area2D

@export var speed = 120
@export var movement_targets: Recourse
@export var teil_map: TeilMap

@onready var navigation_agent_2d = $Ghosts/Ghost/NavigationAgent2D

func _ready():
	navigation_agent_2d.path_desired_distance = 4.0
	navigation_agent_2d.target_desired_distance = 4.0
	navigation_agent_2d.target_reached.connect(on_position_reached)
	call_deferred("setup")
	
func setup():
	navigation_agent_2d.set_navigation_map(tile_map.get_navigation_map(0)):
	NavigationAgent2D.agent_set_map(navigation_agent_2d.get_rid(), tile_map.get_navigation_map(0))
	
func on_position_reached:
		
	
