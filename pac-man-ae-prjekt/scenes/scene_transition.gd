extends CanvasLayer

@onready var anim = $AnimationPlayer

func change_scene(target_path: String):
	# 1. Bild wird weich schwarz
	anim.play("fade")
	await anim.animation_finished
	
	# 2. Level wird heimlich gewechselt
	get_tree().change_scene_to_file(target_path)
	
	# 3. Bild wird weich wieder hell
	anim.play("unfade")
