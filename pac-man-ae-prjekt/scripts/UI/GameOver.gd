extends CanvasLayer

func _on_ready() -> void:
	hide()

func setGameOver() -> void:
	Global.isGameStopped = true
	show()
	$NameInput.grab_focus()


func _on_button_pressed() -> void:
	enter_name()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		enter_name()
		
func enter_name():
	var player_name = $NameInput.text
	if player_name == "": player_name = "Unknown"
	Global.update_leaderboard(player_name)
	print("Change Scene!")
	get_tree().change_scene_to_file("res://scenes/UI/StartMenu.tscn")
	
