extends CanvasLayer

const ROW_Y := 60.0 
const GHOST_ROW_GAP := 70.0
const GH_SCALE := Vector2(2.8, 2.8)

var player_name := ""
var name_display_label: Label
var keyboard_grid: GridContainer

const KEYS = [
	"A", "B", "C", "D", "E", "F", "G",
	"H", "I", "J", "K", "L", "M", "N",
	"O", "P", "Q", "R", "S", "T", "U",
	"V", "W", "X", "Y", "Z", "<", "OK"
]

func _ready() -> void:
	Global.eaten_points_positions.clear()
	Global.isGameStopped = true
	
	Global.send_effect(Global.CHAIN_A, "fill", Color.RED, Global.SEG_ALL, 50, -1)
	Global.send_effect(Global.CHAIN_B, "fill", Color.RED, Global.SEG_ALL, 50, -1)
	
	_build_screen()

func _build_screen() -> Control:
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

	# --- 1. GEISTER PERFEKT ZENTRIEREN ---
	var ghost_scenes = [
		preload("res://scenes/Ghosts/CyanGhost.tscn"),
		preload("res://scenes/Ghosts/Reddghost.tscn"),
		preload("res://scenes/Ghosts/PinkGhost.tscn"),
		preload("res://scenes/Ghosts/OrangeGhost.tscn")
	]
	
	# Holt sich die ECHTE Breite eures Fensters, statt 960 fix zu nutzen
	var screen_width = get_viewport().get_visible_rect().size.x
	var total_ghosts = ghost_scenes.size()
	var total_spans_width = (total_ghosts - 1) * GHOST_ROW_GAP
	var start_x = (screen_width / 2.0) - (total_spans_width / 2.0)

	for i in range(total_ghosts):
		var gx = start_x + (i * GHOST_ROW_GAP)
		_spawn_ghost(ghost_scenes[i], Vector2(gx, ROW_Y), "Unten", root)

	# --- 2. TEXTE PERFEKT ZENTRIEREN (PRESET_TOP_WIDE) ---
	var title = Label.new()
	title.text = "GAME OVER"
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color.RED)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = ROW_Y + 70 
	title.offset_bottom = ROW_Y + 120

	var score_lbl = Label.new()
	score_lbl.text = "SCORE:  " + str(Global.score)
	score_lbl.add_theme_font_override("font", font)
	score_lbl.add_theme_font_size_override("font_size", 18)
	score_lbl.add_theme_color_override("font_color", Color.YELLOW)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(score_lbl)
	score_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	score_lbl.offset_top = ROW_Y + 120
	score_lbl.offset_bottom = ROW_Y + 150

	var name_label = Label.new()
	name_label.text = "ENTER YOUR NAME"
	name_label.add_theme_font_override("font", font)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(name_label)
	name_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	name_label.offset_top = ROW_Y + 170
	name_label.offset_bottom = ROW_Y + 190

	name_display_label = Label.new()
	name_display_label.text = "NAME: _"
	name_display_label.add_theme_font_override("font", font)
	name_display_label.add_theme_font_size_override("font_size", 18)
	name_display_label.add_theme_color_override("font_color", Color.WHITE)
	name_display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(name_display_label)
	name_display_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	name_display_label.offset_top = ROW_Y + 195
	name_display_label.offset_bottom = ROW_Y + 225

	# --- 3. TASTATUR PERFEKT ZENTRIEREN (PRESET_CENTER_TOP) ---
	keyboard_grid = GridContainer.new()
	keyboard_grid.columns = 7
	keyboard_grid.add_theme_constant_override("h_separation", 8)
	keyboard_grid.add_theme_constant_override("v_separation", 8)
	root.add_child(keyboard_grid)
	
	# Das ist die Magie: Godot zentriert den Container automatisch und wächst gleichmäßig in beide Richtungen
	keyboard_grid.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	keyboard_grid.grow_horizontal = Control.GROW_DIRECTION_BOTH 
	keyboard_grid.offset_top = ROW_Y + 240

	# Tasten-Design 
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.1, 0.1, 0.1) 
	style_normal.corner_radius_top_left = 3
	style_normal.corner_radius_top_right = 3
	style_normal.corner_radius_bottom_right = 3
	style_normal.corner_radius_bottom_left = 3

	var style_focus = StyleBoxFlat.new()
	style_focus.bg_color = Color(0.1, 0.1, 0.1)
	style_focus.border_color = Color.RED
	style_focus.border_width_left = 3
	style_focus.border_width_right = 3
	style_focus.border_width_top = 3
	style_focus.border_width_bottom = 3
	style_focus.corner_radius_top_left = 3
	style_focus.corner_radius_top_right = 3
	style_focus.corner_radius_bottom_right = 3
	style_focus.corner_radius_bottom_left = 3

	for key in KEYS:
		var btn = Button.new()
		btn.text = key
		btn.add_theme_font_override("font", font)
		btn.add_theme_font_size_override("font_size", 12)
		btn.custom_minimum_size = Vector2(45, 45)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.focus_mode = Control.FOCUS_ALL
		
		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("focus", style_focus) 
		btn.add_theme_stylebox_override("hover", style_focus) 
		btn.add_theme_stylebox_override("pressed", style_focus)
		
		btn.pressed.connect(_on_key_pressed.bind(key))
		keyboard_grid.add_child(btn)

	if keyboard_grid.get_child_count() > 0:
		keyboard_grid.get_child(0).call_deferred("grab_focus")

	return root

func _spawn_ghost(scene: PackedScene, pos: Vector2, anim: String, parent: Control):
	var g_inst = scene.instantiate()
	var g_anim = g_inst.get_node("AnimatedSprite2D").duplicate()
	g_anim.scale = GH_SCALE
	g_anim.z_index = 4
	g_anim.position = pos
	parent.add_child(g_anim)
	g_anim.play(anim)
	g_inst.queue_free()

func _on_key_pressed(key: String):
	if key == "<": 
		if player_name.length() > 0:
			player_name = player_name.substr(0, player_name.length() - 1)
	elif key == "OK":
		if player_name.strip_edges() != "":
			_submit_name(player_name)
	else:
		if player_name.length() < 10:
			player_name += key
			
	name_display_label.text = "NAME: " + player_name + "_"

func _submit_name(submitted_name: String):
	var pname = submitted_name.strip_edges()
	if pname == "":
		pname = "Unknown"
	Global.update_leaderboard(pname)
	
	SceneTransition.change_scene("res://scenes/UI/StartMenu.tscn")
