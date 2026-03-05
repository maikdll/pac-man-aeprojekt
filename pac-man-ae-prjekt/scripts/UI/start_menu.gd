extends Control

# ─── Animation Settings ───
const ANIM_Y := 255.0
const CHASE_SPEED := 180.0
const HUNT_PAC_SPEED := 260.0
const HUNT_GHOST_SPEED := 120.0
const GHOST_GAP := 48.0
const PELLET_X := 300.0

# Manual scales: each ghost texture has different size & padding
# Target: all ~34px tall to match Pac-Man
const GH_SCALES := [
	Vector2(0.19, 0.19),   # Red     275×183  (fills canvas, wider than tall)
	Vector2(0.30, 0.30),   # Cyan    192×192  (pixel art with padding)
	Vector2(0.15, 0.15),   # Pink    223×226  (fills canvas well)
	Vector2(0.14, 0.14),   # Orange  209×241  (fills canvas well)
]
const SCARED_SCALE := Vector2(2.1, 2.1)   # 16×16
const PELLET_SCALE := Vector2(0.03, 0.03)

# Y-offset per ghost to align bottoms on same line
# Positive = shift down, Negative = shift up
const GH_Y_ADJ := [2.0, 10.0, 1.0, 2.0]

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

# ─── Nodes ───
var pac: Sprite2D
var ghosts: Array = []
var pellet_sprite: Sprite2D
var play_label: Label
var hs_label: Label
var small_dots: Array = []

# ─── Textures ───
var ghost_tex := []
var scared_tex: Texture2D
func _on_button_button_down() -> void:
	Global.score = 0
	Global.health = 3 
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _ready():
	ghost_tex = [
		load("res://assets/ghost/redGhost.png"),
		load("res://assets/ghost/blueGhost.png"),
		load("res://assets/ghost/pinkGhost.png"),
		load("res://assets/ghost/yellowGhost.png"),
	]
	scared_tex = load("res://assets/ghost/Ghost_Vulnerable_Blue_01.png")
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
	for i in range(14):
		var dot = ColorRect.new()
		dot.color = Color(1.0, 0.95, 0.6)
		dot.size = Vector2(4, 4)
		dot.position = Vector2(90 + i * 60, ANIM_Y - 2)
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
	hs_label.add_theme_font_size_override("font_size", 11)
	hs_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hs_label.position = Vector2(380, 400)
	add_child(hs_label)

# ═══════════════════════════════════════
#  ANIMATION SPRITES
# ═══════════════════════════════════════
func _build_anim_sprites():
	# Pac-Man (atlas frame: open mouth)
	pac = Sprite2D.new()
	var atlas = AtlasTexture.new()
	atlas.atlas = load("res://assets/animation/Arcade - Pac-Man.png")
	atlas.region = Rect2(32, 0, 32, 34)
	pac.texture = atlas
	pac.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pac.z_index = 5
	add_child(pac)

	# 4 Ghosts
	for i in 4:
		var g = Sprite2D.new()
		g.texture = ghost_tex[i]
		g.scale = GH_SCALES[i]
		g.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		g.z_index = 4
		add_child(g)
		ghosts.append(g)

	# Power Pellet (big ball)
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

	# Start off-screen right; ghosts follow Pac-Man
	pac_x = 870.0
	for i in 4:
		gx[i] = pac_x + GHOST_GAP * (i + 1)
		ghosts[i].visible = true
		ghosts[i].texture = ghost_tex[i]
		ghosts[i].scale = GH_SCALES[i]

	pac.scale.x = -1.0  # Face left
	pellet_sprite.visible = true
	pellet_sprite.position = Vector2(PELLET_X, ANIM_Y)

	# Restore dots
	for dot in small_dots:
		dot.visible = true

func _process(delta: float):
	# Blinking "PLAY GAME"
	blink_timer += delta
	play_label.visible = fmod(blink_timer, 1.2) < 0.9

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

	# Pac-Man eats dots he passes
	for dot in small_dots:
		if dot.visible and abs(pac_x - dot.position.x) < 12:
			dot.visible = false

	# Pac-Man reaches the power pellet
	if pac_x <= PELLET_X + 15:
		_begin_hunt()

func _begin_hunt():
	phase = Phase.HUNT
	ghosts_scared = true
	pellet_sprite.visible = false
	move_dir = 1.0
	pac.scale.x = 1.0  # Face right

	for g in ghosts:
		g.texture = scared_tex
		g.scale = SCARED_SCALE

func _do_hunt(delta: float):
	pac_x += move_dir * HUNT_PAC_SPEED * delta
	for i in 4:
		if not ghosts_eaten[i]:
			gx[i] += move_dir * HUNT_GHOST_SPEED * delta

	# Check if Pac-Man caught a ghost
	for i in 4:
		if not ghosts_eaten[i] and pac_x >= gx[i] - 12:
			_eat_ghost(i)

	# Off-screen → loop
	if pac_x > 870:
		phase = Phase.WAIT
		get_tree().create_timer(1.5).timeout.connect(_reset)

func _eat_ghost(i: int):
	ghosts_eaten[i] = true
	ghosts[i].visible = false
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
		var y_adj = GH_Y_ADJ[i] if not ghosts_scared else 0.0
		ghosts[i].position = Vector2(gx[i], ANIM_Y + y_adj)

# ═══════════════════════════════════════
#  NAVIGATION & SCORES
# ═══════════════════════════════════════
func _on_play():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _load_scores():
	Global.load_leaderboard()
	var text = "TOP 5 HIGHSCORES\n----------------\n"
	for i in range(Global.leaderboard.size()):
		var e = Global.leaderboard[i]
		text += str(i + 1) + ". " + e["name"] + ": " + str(e["score"]) + "\n"
	hs_label.text = text
