extends CanvasLayer

const VIEWPORT_W := 960.0
const ROW_Y := 190.0 
const GHOST_ROW_GAP := 70.0
const GH_SCALE := Vector2(2.8, 2.8)

var name_input: LineEdit

func _ready() -> void:
	self.layer = 100 
	hide()

func setGameOver() -> void:
	Global.eaten_points_positions.clear()
	Global.isGameStopped = true
	print("isGameStopped: ", Global.isGameStopped)
	Global.send_effect(Global.CHAIN_A, "fill", Color.RED, Global.SEG_ALL, 50, -1)
	Global.send_effect(Global.CHAIN_B, "fill", Color.RED, Global.SEG_ALL, 50, -1)
	show()
	_build_screen()

func _build_screen():
	for child in get_children():
		child.queue_free()

	var root = Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	root.add_child(bg)

	var font = load("res://assets/fonts/PressStart2P-Regular.ttf")

	var ghost_scenes = [
		preload("res://scenes/Ghosts/CyanGhost.tscn"),
		preload("res://scenes/Ghosts/Reddghost.tscn"),
		preload("res://scenes/Ghosts/PinkGhost.tscn"),
		preload("res://scenes/Ghosts/OrangeGhost.tscn")
	]
	
	var total_ghosts = ghost_scenes.size()
	var total_spans_width = (total_ghosts - 1) * GHOST_ROW_GAP
	var start_x = (VIEWPORT_W / 2.0) - (total_spans_width / 2.0)

	for i in range(total_ghosts):
		var gx = start_x + (i * GHOST_ROW_GAP)
		_spawn_ghost(ghost_scenes[i], Vector2(gx, ROW_Y), "Unten", root)

	var title = Label.new()
	title.text = "GAME OVER"
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color.RED)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = ROW_Y + 60 
	title.offset_bottom = ROW_Y + 110
	root.add_child(title)

	var score_lbl = Label.new()
	score_lbl.text = "SCORE:  " + str(Global.score)
	score_lbl.add_theme_font_override("font", font)
	score_lbl.add_theme_font_size_override("font_size", 18)
	score_lbl.add_theme_color_override("font_color", Color.YELLOW)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.anchor_left = 0.0
	score_lbl.anchor_right = 1.0
	score_lbl.offset_top = ROW_Y + 120
	score_lbl.offset_bottom = ROW_Y + 150
	root.add_child(score_lbl)

	var name_label = Label.new()
	name_label.text = "ENTER YOUR NAME"
	name_label.add_theme_font_override("font", font)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.anchor_left = 0.0
	name_label.anchor_right = 1.0
	name_label.offset_top = ROW_Y + 190
	name_label.offset_bottom = ROW_Y + 210
	root.add_child(name_label)

	var input_container = HBoxContainer.new()
	input_container.anchor_left = 0.5
	input_container.anchor_right = 0.5
	input_container.offset_left = -170
	input_container.offset_right = 170
	input_container.offset_top = ROW_Y + 220
	input_container.offset_bottom = ROW_Y + 265
	input_container.add_theme_constant_override("separation", 12)
	root.add_child(input_container)

	name_input = LineEdit.new()
	name_input.placeholder_text = "Name"
	name_input.add_theme_font_override("font", font)
	name_input.add_theme_font_size_override("font_size", 14)
	name_input.custom_minimum_size.x = 200
	name_input.max_length = 15
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_container.add_child(name_input)

	var btn = Button.new()
	btn.text = "Confirm"
	btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(_on_confirm)
	input_container.add_child(btn)

	name_input.text_submitted.connect(_on_name_submitted)
	name_input.call_deferred("grab_focus")

func _spawn_ghost(scene: PackedScene, pos: Vector2, anim: String, parent: Control):
	var g_inst = scene.instantiate()
	var g_anim = g_inst.get_node("AnimatedSprite2D").duplicate()
	g_anim.scale = GH_SCALE
	g_anim.z_index = 4
	g_anim.position = pos
	parent.add_child(g_anim)
	g_anim.play(anim)
	g_inst.queue_free()

func _on_confirm():
	_submit_name(name_input.text)

func _on_name_submitted(_text: String):
	_submit_name(name_input.text)

func _submit_name(player_name: String):
	var pname = player_name.strip_edges()
	if pname == "":
		pname = "Unknown"
	Global.update_leaderboard(pname)
	
	SceneTransition.change_scene("res://scenes/UI/StartMenu.tscn")
