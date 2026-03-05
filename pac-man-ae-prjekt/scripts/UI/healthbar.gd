extends Control

@onready var life_icons = $HBoxContainer.get_children()

func update_healthbar(current_health):
	$AudioDeath.play()
	if Global.health < 1:
		get_tree().call_group("GameOver", "setGameOver")
		
	for i in range(life_icons.size()):
		life_icons[i].visible = i < current_health
