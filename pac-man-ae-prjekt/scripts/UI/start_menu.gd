extends Control

const ANIM_Y := 255.0
const CHASE_SPEED := 180.0
const HUNT_PAC_SPEED := 260.0
const HUNT_GHOST_SPEED := 120.0
const GHOST_GAP := 48.0
const PELLET_X := 300.0

const GH_SCALE := Vector2(2.2, 2.2)
const SCARED_SCALE := Vector2(2.2, 2.2)
const PAC_SCALE := Vector2(1.2, 1.2)
const PELLET_SCALE := Vector2(0.02, 0.02)

enum Phase { CHASE, HUNT, WAIT }
var phase := Phase.WAIT
var move_dir := -1.0
var pac_x := 0.0
var gx := [0.0, 0.0, 0.0, 0.0]
var ghosts_scared := false
var ghosts_eaten := [false, false, false, false]
var eaten_count := 0
var blink_timer := 0.0

var pac_anim: AnimatedSprite2D
var ghosts_anim: Array[AnimatedSprite2D] = []
var pellet_sprite: Sprite2D
var play_label: Label
var hs_label: Label
var small_dots: Array = []

const PACMAN_SCENE = preload("res://scenes/PacMan.tscn")
const GHOST_SCENES = [
	preload("res://scenes/Ghosts/Reddghost.tscn"),
	preload("res://scenes/Ghosts/CyanGhost.tscn"),
	preload("res://scenes/Ghosts/PinkGhost.tscn"),
	preload("res://scenes/Ghosts/OrangeGhost.tscn")
]

func _on_button_button_down() -> void:
	start_game()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("start_game"):
		start_game()
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			get_tree().quit()

func start_game():
	# --- ALLES AUF ANFANG SETZEN ---
	Global.level = 15
	Global.score = 0
	Global.health = 3
	Global.dots_eaten = 0
	Global.eaten_points_positions.clear()
	Global.died_in_level = false
	Global.isIntermissionMode = false
	
	SceneTransition.change_scene("res://scenes/Main.tscn")

func _ready():
	Global.send_effect(Global.CHAIN_A, "fill", Color.YELLOW, Global.SEG_A_MARQUEE)
	Global.send_effect(Global.CHAIN_B, "rainbow", Color.BLACK, Global.SEG_ALL, 80)
	Global.send_effect(Global.CHAIN_A, "blink", Color.GREEN, Global.SEG_A_CONTROL_PANEL, 20)
	_build_ui()
	_build_anim_sprites()
	_reset()
	_load_scores()

func _build_anim_sprites():
	var pac_inst = PACMAN_SCENE.instantiate()
	pac_anim = pac_inst.get_node("AnimatedSprite2D").duplicate()
	pac_anim.scale = PAC_SCALE
	pac_anim.z_index = 5
	add_child(pac_anim)
	pac_inst.queue_free()

	for scene in GHOST_SCENES:
		var g_inst = scene.instantiate()
		var g_anim = g_inst.get_node("AnimatedSprite2D").duplicate()
		g_anim.scale = GH_SCALE
		g_anim.z_index = 4
		add_child(g_anim)
		ghosts_anim.append(g_anim)
		g_inst.queue_free()

	pellet_sprite = Sprite2D.new()
	pellet_sprite.texture = preload("res://assets/Point.png")
	pellet_sprite.scale = PELLET_SCALE
	pellet_sprite.z_index = 3
	add_child(pellet_sprite)

func _reset():
	phase = Phase.CHASE
	move_dir = -1.0
	ghosts_scared = false
	ghosts_eaten = [false, false, false, false]
	eaten_count = 0

	pac_x = 1000.0
	pac_anim.scale = Vector2(-PAC_SCALE.x, PAC_SCALE.y) 
	pac_anim.play("PacMan_Kauen") 

	for i in 4:
		gx[i] = pac_x + GHOST_GAP * (i + 1)
		ghosts_anim[i].visible = true 
		ghosts_anim[i].scale = GH_SCALE
		ghosts_anim[i].modulate = Color.WHITE
		ghosts_anim[i].play("Links")

	pellet_sprite.visible = true
	var pellet_x = randf_range(100.0, 700.0)
	pellet_sprite.position = Vector2(pellet_x, ANIM_Y)

	for dot in small_dots:
		dot.visible = true

func _process(delta: float):
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
	
	pac_anim.scale = Vector2(PAC_SCALE.x, PAC_SCALE.y) 

	for i in 4:
		ghosts_anim[i].scale = SCARED_SCALE
		ghosts_anim[i].play("Scared") 

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
	eaten_count += 1
	var scores = [200, 400, 800, 1600]
	
	ghosts_anim[i].visible = false
	_show_score(scores[eaten_count - 1], gx[i])
	
func _show_score(score: int, x_pos: float):
	var font = preload("res://assets/fonts/PressStart2P-Regular.ttf")
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
	pac_anim.position = Vector2(pac_x, ANIM_Y)
	for i in 4:
		if not ghosts_eaten[i]:
			ghosts_anim[i].position = Vector2(gx[i], ANIM_Y)

func _build_ui():
	var font = preload("res://assets/fonts/PressStart2P-Regular.ttf")

	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

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

	for i in range(19):
		var dot = ColorRect.new()
		dot.color = Color(1.0, 0.95, 0.6)
		dot.size = Vector2(4, 4)
		dot.position = Vector2(5 + i * 52, ANIM_Y - 2)
		add_child(dot)
		small_dots.append(dot)

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

	var btn = Button.new()
	btn.flat = true
	btn.position = Vector2(310, 335)
	btn.size = Vector2(340, 50)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(_on_play)
	add_child(btn)

	hs_label = Label.new()
	hs_label.add_theme_font_override("font", font)
	hs_label.add_theme_font_size_override("font_size", 12)
	hs_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hs_label.position = Vector2(380, 400)
	add_child(hs_label)

func _on_play():
	start_game()

func _load_scores():
	Global.load_leaderboard()
	var text = "TOP 5 HIGHSCORES\n----------------\n"
	for i in range(Global.leaderboard.size()):
		var e = Global.leaderboard[i]
		text += str(i + 1) + ". " + e["name"] + ": " + str(e["score"]) + "\n"
	hs_label.text = text
