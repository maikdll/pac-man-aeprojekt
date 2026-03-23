extends CanvasLayer

@onready var label = $Label
var current_displayed_score = -1

func _process(_delta):
	if Global.score != current_displayed_score:
		current_displayed_score = Global.score
		label.text = str(current_displayed_score)
