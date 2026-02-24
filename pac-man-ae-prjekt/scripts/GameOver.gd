extends CanvasLayer




func _on_ready() -> void:
	hide()

func setGameOverLabel() -> void:
	show()


func _on_button_pressed() -> void:
	var player_name = $NameInput.text
	if player_name == "": player_name = "Unknown"
	Global.update_leaderboard(player_name)
	get_tree().change_scene_to_file("res://scenes/StartMenu.tscn")
	
