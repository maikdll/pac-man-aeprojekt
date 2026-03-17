extends GutTest

var _MenuScript = load("res://scripts/UI/start_menu.gd")
var menu

func before_each() -> void:
	menu = partial_double(_MenuScript).new()
	stub(menu, "_ready").to_do_nothing()
	stub(menu, "_show_score").to_do_nothing()
	stub(menu, "_sync_positions").to_do_nothing()
	stub(menu, "_load_scores").to_do_nothing()
	add_child_autoqfree(menu)

	# Setup PacMan with required animation
	menu.pac_anim = AnimatedSprite2D.new()
	var pac_sf = SpriteFrames.new()
	pac_sf.add_animation("PacMan_Kauen")
	menu.pac_anim.sprite_frames = pac_sf
	menu.add_child(menu.pac_anim)

	# Setup Ghosts with required animations
	menu.ghosts_anim.clear()
	for i in 4:
		var s := AnimatedSprite2D.new()
		var sf := SpriteFrames.new()
		sf.add_animation("Scared")
		sf.add_animation("Links")
		s.sprite_frames = sf
		menu.ghosts_anim.append(s)
		menu.add_child(s)

	menu.pellet_sprite = Sprite2D.new()
	menu.add_child(menu.pellet_sprite)
	menu._reset()

# --- Tests: Hunt Logic ---
func test_begin_hunt_behavior() -> void:
	menu.phase = menu.Phase.CHASE
	menu.move_dir = -1.0
	
	menu._begin_hunt()
	
	assert_eq(menu.phase, menu.Phase.HUNT)
	assert_true(menu.ghosts_scared)
	assert_gt(menu.move_dir, 0.0) # Fixed Float/Int warning
	assert_false(menu.pellet_sprite.visible)

# --- Tests: Ghost Consumption ---
func test_eat_ghost_logic() -> void:
	menu._eat_ghost(1)
	
	assert_true(menu.ghosts_eaten[1], "Target ghost marked as eaten")
	assert_eq(menu.eaten_count, 1, "Counter incremented")
	assert_false(menu.ghosts_anim[1].visible, "Sprite hidden")
	assert_false(menu.ghosts_eaten[0], "Other ghosts unaffected")

# --- Tests: Global State Reset ---
func test_start_game_resets_globals() -> void:
	Global.level = 5
	Global.score = 1000
	Global.health = 1
	Global.isIntermissionMode = true
	
	menu.start_game()
	
	assert_eq(Global.level, 1)
	assert_eq(Global.score, 0)
	assert_eq(Global.health, 3)
	assert_false(Global.isIntermissionMode)

# --- Tests: Movement Movement ---
func test_movement_in_chase_phase() -> void:
	var initial_x = menu.pac_x
	menu._do_chase(0.1) 
	assert_lt(menu.pac_x, initial_x, "Should move left in chase")
