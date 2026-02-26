extends Control

@onready var life_icons = $HBoxContainer.get_children()

func _ready():
	Global.health = 3
	update_healthbar(Global.health)

func update_healthbar(current_health):
	if Global.health < 1:
		$AudioDeath.play()
		get_tree().call_group("GameOver", "setGameOver")
		
	for i in range(life_icons.size()):
		life_icons[i].visible = i < current_health
