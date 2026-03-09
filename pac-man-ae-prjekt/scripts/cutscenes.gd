extends Node

func _ready() -> void:
	await get_tree().create_timer(0.5).timeout
	$AudioStreamPlayer2D.play()
	if Global.level == 2: #This means Level 1
		$VideoStreamPlayer.play()
		await $VideoStreamPlayer.finished
		await get_tree().create_timer(1.5).timeout
	elif Global.level == 3:
		$VideoStreamPlayer2.play()
		await $VideoStreamPlayer2.finished
	elif Global.level == 4:
		$VideoStreamPlayer3.play()
		await $VideoStreamPlayer3.finished
		await get_tree().create_timer(1.5).timeout
	elif Global.level == 5:
		$VideoStreamPlayer4.play()
		await $VideoStreamPlayer4.finished
		await get_tree().create_timer(0.5).timeout
	elif Global.level == 6:
		$VideoStreamPlayer5.play()
		await $VideoStreamPlayer5.finished
		await get_tree().create_timer(1.5).timeout
	elif Global.level == 7:
		$VideoStreamPlayer6.play()
		await $VideoStreamPlayer6.finished
	
	await get_tree().create_timer(1).timeout
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
