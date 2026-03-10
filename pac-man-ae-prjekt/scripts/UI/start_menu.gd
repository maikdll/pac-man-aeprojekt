extends Control

# ─── Animation Settings ───
const ANIM_Y := 255.0
const CHASE_SPEED := 180.0
const HUNT_PAC_SPEED := 260.0
const HUNT_GHOST_SPEED := 120.0
const GHOST_GAP := 48.0
const PELLET_X := 300.0

# All ghosts now use 16×16 pixel art body with color modulate
const GH_SCALE := Vector2(2.2, 2.2)   # Ghost size
const SCARED_SCALE := Vector2(2.2, 2.2)
const PAC_SCALE := Vector2(1.2, 1.2)  # Pac-Man slightly bigger than ghosts
const PELLET_SCALE := Vector2(0.02, 0.02)
const GH_COLORS := [
	Color(1, 0, 0),        # Red
	Color(0, 1, 1),        # Cyan
	Color(1, 0.72, 0.84),  # Pink
	Color(1, 0.65, 0),     # Orange
]

# ─── Animation State ───
enum Phase { CHASE, HUNT, WAIT }
var phase := Phase.WAIT
var move_dir := -1.0
var pac_x := 0.0
var gx := [0.0, 0.0, 0.0, 0.0]
var ghosts_scared := false
var ghosts_eaten := [false, false, false, false]
var eaten_count := 0
var blink_timer := 0.0
var pac_frame := 0
var pac_frame_timer := 0.0
const PAC_FRAME_SPEED := 0.12
var pac_frames: Array = []

# ─── Nodes ───
var pac: Sprite2D
var ghosts: Array = []
var ghost_eyes: Array = []
var pellet_sprite: Sprite2D
var play_label: Label
var hs_label: Label
var small_dots: Array = []

# ─── Textures ───
var ghost_tex := []
var scared_tex: Texture2D
var eyes_tex: Texture2D

func _on_button_button_down() -> void:
	start_game()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		start_game()
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			get_tree().quit()
	elif event is InputEventJoypadButton and event.pressed:
		var quit_buttons = [
			10, 11, 12, 
			JOY_BUTTON_GUIDE, 
			JOY_BUTTON_START, 
			JOY_BUTTON_BACK
		]
		if event.button_index in quit_buttons:
			get_tree().quit()

func start_game():
	Global.resetLedGameplay()
	Global.score = 0
	Global.health = 3
	get_tree().call_group("Main", "setDifficulty")
	SceneTransition.change_scene("res://scenes/Main.tscn")

func _ready():
	Global.send_effect(Global.CHAIN_A, "fill", Color.YELLOW, Global.SEG_A_MARQUEE)
	Global.send_effect(Global.CHAIN_B, "rainbow", Color.BLACK, Global.SEG_ALL, 80)
	Global.send_effect(Global.CHAIN_A, "blink", Color.GREEN, Global.SEG_A_CONTROL_PANEL, 20)
	var body_tex = load("res://assets/ghost/Ghost_Body_01.png")
	for i in 4:
		ghost_tex.append(body_tex)
	scared_tex = load("res://assets/ghost/Ghost_Vulnerable_Blue_01.png")
	eyes_tex = load("res://assets/ghost/Ghost_Eyes_Left.png")
	_build_ui()
	_build_anim_sprites()
	_reset()
	_load_scores()

# ═══════════════════════════════════════
#  UI SETUP
# ═══════════════════════════════════════
func _build_ui():
	var font = load("res://assets/fonts/PressStart2P-Regular.ttf")

	# Black background
	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# Title "PAC-MAN"
	var title = Label.new()
	title.text = "PAC-MAN"
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color.YELLOW)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = 40
	title.offset_bottom = 110
	add_child(title)

	# Subtitle
	var sub = Label.new()
	sub.text = "by Schwarz Digits"
	sub.add_theme_font_override("font", font)
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.anchor_left = 0.0
	sub.anchor_right = 1.0
	sub.offset_top = 115
	sub.offset_bottom = 140
	add_child(sub)

	# Small dots in animation row
	for i in range(19):
		var dot = ColorRect.new()
		dot.color = Color(1.0, 0.95, 0.6)
		dot.size = Vector2(4, 4)
		dot.position = Vector2(5 + i * 52, ANIM_Y - 2)
		add_child(dot)
		small_dots.append(dot)

	# "PLAY GAME" blinking label
	play_label = Label.new()
	play_label.text = "PLAY  GAME"
	play_label.add_theme_font_override("font", font)
	play_label.add_theme_font_size_override("font_size", 22)
	play_label.add_theme_color_override("font_color", Color.YELLOW)
	play_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_label.anchor_left = 0.0
	play_label.anchor_right = 1.0
	play_label.offset_top = 340
	play_label.offset_bottom = 380
	add_child(play_label)

	# Invisible button over the label
	var btn = Button.new()
	btn.flat = true
	btn.position = Vector2(310, 335)
	btn.size = Vector2(340, 50)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(_on_play)
	add_child(btn)

	# Highscores (left-aligned text, block centered on screen)
	hs_label = Label.new()
	hs_label.add_theme_font_override("font", font)
	hs_label.add_theme_font_size_override("font_size", 12)
	hs_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hs_label.position = Vector2(380, 400)
	add_child(hs_label)

# ═══════════════════════════════════════
#  ANIMATION SPRITES
# ═══════════════════════════════════════
func _build_anim_sprites():
	# Pac-Man (3 frames: wide open, closed, half open)
	var pac_atlas = load("res://assets/animation/Arcade - Pac-Man.png")
	for i in 3:
		var at = AtlasTexture.new()
		at.atlas = pac_atlas
		at.region = Rect2(i * 32, 0, 32, 34)
		pac_frames.append(at)

	pac = Sprite2D.new()
	pac.texture = pac_frames[0]
	pac.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pac.scale = PAC_SCALE  # ← Pac-Man size applied here
	pac.z_index = 5
	add_child(pac)

	# 4 Ghosts
	for i in 4:
		var g = Sprite2D.new()
		g.texture = ghost_tex[i]
		g.scale = GH_SCALE
		g.modulate = GH_COLORS[i]
		g.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		g.z_index = 4
		add_child(g)
		ghosts.append(g)

		var e = Sprite2D.new()
		e.texture = eyes_tex
		e.scale = GH_SCALE
		e.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		e.z_index = 5
		add_child(e)
		ghost_eyes.append(e)

	# Power Pellet
	pellet_sprite = Sprite2D.new()
	pellet_sprite.texture = load("res://assets/Point.png")
	pellet_sprite.scale = PELLET_SCALE
	pellet_sprite.z_index = 3
	add_child(pellet_sprite)

# ═══════════════════════════════════════
#  ANIMATION LOGIC
# ═══════════════════════════════════════
func _reset():
	phase = Phase.CHASE
	move_dir = -1.0
	ghosts_scared = false
	ghosts_eaten = [false, false, false, false]
	eaten_count = 0

	pac_x = 1000.0
	for i in 4:
		gx[i] = pac_x + GHOST_GAP * (i + 1)
		ghosts[i].visible = true
		ghosts[i].texture = ghost_tex[i]
		ghosts[i].scale = GH_SCALE
		ghosts[i].modulate = GH_COLORS[i]
		ghost_eyes[i].visible = true
		ghost_eyes[i].texture = load("res://assets/ghost/Ghost_Eyes_Left.png")

	pac.scale = Vector2(-PAC_SCALE.x, PAC_SCALE.y)  # Face left, keep size
	pellet_sprite.visible = true
	var pellet_x = randf_range(100.0, 700.0)
	pellet_sprite.position = Vector2(pellet_x, ANIM_Y)

	for dot in small_dots:
		dot.visible = true

func _process(delta: float):
	blink_timer += delta
	play_label.visible = fmod(blink_timer, 1.2) < 0.9

	pac_frame_timer += delta
	if pac_frame_timer >= PAC_FRAME_SPEED:
		pac_frame_timer = 0.0
		pac_frame = (pac_frame + 1) % 3
		pac.texture = pac_frames[pac_frame]

	match phase:
		Phase.CHASE:
			_do_chase(delta)
		Phase.HUNT:
			_do_hunt(delta)

	_sync_positions()

func _do_chase(delta: float):
	var spd = CHASE_SPEED * delta
	pac_x += move_dir * spd
	for i in 4:
		gx[i] += move_dir * spd

	for dot in small_dots:
		if dot.visible and abs(pac_x - dot.position.x) < 12:
			dot.visible = false

	if pac_x <= pellet_sprite.position.x + 15:
		_begin_hunt()

func _begin_hunt():
	phase = Phase.HUNT
	ghosts_scared = true
	pellet_sprite.visible = false
	move_dir = 1.0
	pac.scale = Vector2(PAC_SCALE.x, PAC_SCALE.y)  # Face right, keep size

	for i in 4:
		ghosts[i].texture = scared_tex
		ghosts[i].scale = SCARED_SCALE
		ghosts[i].modulate = Color.WHITE
		ghost_eyes[i].visible = false

func _do_hunt(delta: float):
	pac_x += move_dir * HUNT_PAC_SPEED * delta
	for i in 4:
		if not ghosts_eaten[i]:
			gx[i] += move_dir * HUNT_GHOST_SPEED * delta

	for i in 4:
		if not ghosts_eaten[i] and pac_x >= gx[i] - 12:
			_eat_ghost(i)

	if pac_x > 1000:
		_reset()

func _eat_ghost(i: int):
	ghosts_eaten[i] = true
	ghosts[i].visible = false
	ghost_eyes[i].visible = false
	eaten_count += 1
	var scores = [200, 400, 800, 1600]
	_show_score(scores[eaten_count - 1], gx[i])

func _show_score(score: int, x_pos: float):
	var font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	var lbl = Label.new()
	lbl.text = str(score)
	lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	lbl.position = Vector2(x_pos - 25, ANIM_Y - 25)
	lbl.z_index = 10
	add_child(lbl)

	var tw = create_tween()
	tw.tween_property(lbl, "position:y", ANIM_Y - 60, 0.7)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.3)
	tw.tween_callback(lbl.queue_free)

func _sync_positions():
	pac.position = Vector2(pac_x, ANIM_Y)
	for i in 4:
		ghosts[i].position = Vector2(gx[i], ANIM_Y)
		ghost_eyes[i].position = Vector2(gx[i], ANIM_Y - 2)

# ═══════════════════════════════════════
#  NAVIGATION & SCORES
# ═══════════════════════════════════════
func _on_play():
	start_game()

func _load_scores():
	Global.load_leaderboard()
	var text = "TOP 5 HIGHSCORES\n----------------\n"
	for i in range(Global.leaderboard.size()):
		var e = Global.leaderboard[i]
		text += str(i + 1) + ". " + e["name"] + ": " + str(e["score"]) + "\n"
	hs_label.text = text
