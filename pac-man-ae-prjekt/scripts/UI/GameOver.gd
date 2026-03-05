extends CanvasLayer

# ─── Layout Constants ───
const VIEWPORT_W := 960.0
const ROW_Y := 200.0
const GHOST_GAP := 60.0
const GH_SCALE := Vector2(2.8, 2.8)
const PAC_SCALE := Vector2(2.8, 2.8)

const GH_COLORS := [
	Color(1, 0.65, 0),       # Orange
	Color(0, 1, 1),          # Cyan
	Color(1, 0.72, 0.84),    # Pink
	Color(1, 0, 0),          # Red
]

var name_input: LineEdit

func _on_ready() -> void:
	hide()

func setGameOver() -> void:
	Global.isGameStopped = true
	show()
	_build_screen()

# ═══════════════════════════════════════
#  BUILD SCREEN
# ═══════════════════════════════════════
func _build_screen():
	# Remove old scene-tree children (Label, NameInput, etc.)
	for child in get_children():
		child.queue_free()

	var root = Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# ── Black background ──
	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	root.add_child(bg)

	var font = load("res://assets/fonts/PressStart2P-Regular.ttf")

	# ── Pac-Man (open mouth) ──
	var pac_atlas = load("res://assets/animation/Arcade - Pac-Man.png")
	var pac_tex = AtlasTexture.new()
	pac_tex.atlas = pac_atlas
	pac_tex.region = Rect2(0, 0, 32, 34)

	var pac = Sprite2D.new()
	pac.texture = pac_tex
	pac.scale = PAC_SCALE
	pac.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pac.z_index = 5
	root.add_child(pac)

	# ── 4 Ghosts + Eyes ──
	var body_tex = load("res://assets/ghost/Ghost_Body_01.png")
	var eyes_tex = load("res://assets/ghost/Ghost_Eyes_Right.png")

	var total_width = 4 * GHOST_GAP
	var start_x = (VIEWPORT_W - total_width) / 2.0 - GHOST_GAP * 0.5
	pac.position = Vector2(start_x, ROW_Y)

	for i in 4:
		var gx = start_x + GHOST_GAP * (i + 1)

		var g = Sprite2D.new()
		g.texture = body_tex
		g.scale = GH_SCALE
		g.modulate = GH_COLORS[i]
		g.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		g.position = Vector2(gx, ROW_Y)
		g.z_index = 4
		root.add_child(g)

		var e = Sprite2D.new()
		e.texture = eyes_tex
		e.scale = GH_SCALE
		e.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		e.position = Vector2(gx, ROW_Y - 2)
		e.z_index = 5
		root.add_child(e)

	# ── "GAME OVER" ──
	var title = Label.new()
	title.text = "GAME OVER"
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = ROW_Y + 55
	title.offset_bottom = ROW_Y + 100
	root.add_child(title)

	# ── Score ──
	var score_lbl = Label.new()
	score_lbl.text = "SCORE  " + str(Global.score)
	score_lbl.add_theme_font_override("font", font)
	score_lbl.add_theme_font_size_override("font_size", 16)
	score_lbl.add_theme_color_override("font_color", Color.YELLOW)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.anchor_left = 0.0
	score_lbl.anchor_right = 1.0
	score_lbl.offset_top = ROW_Y + 110
	score_lbl.offset_bottom = ROW_Y + 135
	root.add_child(score_lbl)

	# ── "ENTER YOUR NAME" ──
	var name_label = Label.new()
	name_label.text = "ENTER YOUR NAME"
	name_label.add_theme_font_override("font", font)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.anchor_left = 0.0
	name_label.anchor_right = 1.0
	name_label.offset_top = 390
	name_label.offset_bottom = 410
	root.add_child(name_label)

	# ── Input + Button row ──
	var input_container = HBoxContainer.new()
	input_container.anchor_left = 0.5
	input_container.anchor_right = 0.5
	input_container.offset_left = -170
	input_container.offset_right = 170
	input_container.offset_top = 420
	input_container.offset_bottom = 465
	input_container.add_theme_constant_override("separation", 12)
	root.add_child(input_container)

	name_input = LineEdit.new()
	name_input.placeholder_text = "Name"
	name_input.add_theme_font_override("font", font)
	name_input.add_theme_font_size_override("font_size", 14)
	name_input.custom_minimum_size.x = 200
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

# ═══════════════════════════════════════
#  INPUT HANDLING
# ═══════════════════════════════════════
func _on_confirm():
	_submit_name(name_input.text)

func _on_name_submitted(_text: String):
	_submit_name(name_input.text)

func _submit_name(player_name: String):
	var pname = player_name.strip_edges()
	if pname == "":
		pname = "Unknown"
	Global.update_leaderboard(pname)
	get_tree().change_scene_to_file("res://scenes/UI/StartMenu.tscn")
	
