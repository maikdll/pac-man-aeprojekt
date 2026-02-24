extends Control

@onready var life_icons = $HBoxContainer.get_children()

func _ready():
	update_ui(Global.health)

func update_ui(current_health):
	for i in range(life_icons.size()):
		life_icons[i].visible = i < current_health
