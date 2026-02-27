extends CanvasLayer




func _on_ready() -> void:
	hide()

func setGameOver() -> void:
	Global.isGameStopped = true
	show()


func _on_button_pressed() -> void:
	var player_name = $NameInput.text
	if player_name == "": player_name = "Unknown"
	Global.update_leaderboard(player_name)
	print("Change Scene!")
	get_tree().change_scene_to_file("res://scenes/UI/StartMenu.tscn")
	
