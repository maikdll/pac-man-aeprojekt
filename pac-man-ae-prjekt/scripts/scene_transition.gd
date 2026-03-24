extends CanvasLayer

# Den AnimationPlayer brauchen wir nicht mehr, wir greifen direkt auf das schwarze Bild zu
@onready var color_rect = $ColorRect

func change_scene(target_path: String):
	# 1. Bild wird weich schwarz (Dauer: 0.5 Sekunden)
	var tween_in = create_tween()
	tween_in.tween_property(color_rect, "modulate:a", 1.0, 0.5)
	await tween_in.finished
	
	# 2. Level wird heimlich gewechselt
	get_tree().change_scene_to_file(target_path)
	
	# 3. Bild wird weich wieder hell (Dauer: 0.5 Sekunden)
	var tween_out = create_tween()
	tween_out.tween_property(color_rect, "modulate:a", 0.0, 0.5)
