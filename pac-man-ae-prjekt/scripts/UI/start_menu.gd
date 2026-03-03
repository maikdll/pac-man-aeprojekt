extends Control

@onready var highscore_label = $VBoxContainer/HighscoreLabel

func _on_button_button_down() -> void:
	Global.score = 0
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _ready():
	display_leaderboard()

func display_leaderboard():
	var text = "TOP 5 HIGHSCORES\n"
	text += "----------------\n"
	
	for i in range(Global.leaderboard.size()):
		var entry = Global.leaderboard[i]
		text += str(i + 1) + ". " + entry["name"] + ": " + str(entry["score"]) + "\n"
	
	highscore_label.text = text
