extends GutTest

# =============================================================================
# test_start_menu.gd
# =============================================================================
# WHAT we test:
#   ✅ Constants (speeds, sizes, positions)
#   ✅ start_game() — resets all Global variables (scene change is async,
#      so assertions work before the actual swap takes place)
#   ✅ _begin_hunt() — switches phase, speed, and scared state
#   ✅ _eat_ghost() — marks the ghost as eaten, increments the counter
#
# WHAT we DO NOT test and why:
#   ❌ _build_anim_sprites() — uses preload for scenes (PacMan.tscn, Ghosts)
#   ❌ _load_scores()        — reads the leaderboard file from the disk
#   ❌ _build_ui()           — creates multiple child nodes
# =============================================================================

var _MenuScript = load("res://scripts/UI/start_menu.gd")
var menu

func before_each() -> void:
	menu = partial_double(_MenuScript).new()
	stub(menu, "_ready").to_do_nothing()
	stub(menu, "_show_score").to_do_nothing()
	stub(menu, "_sync_positions").to_do_nothing()
	add_child_autoqfree(menu)  # menu will be automatically freed after each test

	menu.phase         = menu.Phase.WAIT
	menu.move_dir      = -1.0
	menu.ghosts_scared = false
	menu.ghosts_eaten  = [false, false, false, false]
	menu.eaten_count   = 0
	menu.gx            = [200.0, 248.0, 296.0, 344.0]

	# Add nodes as children of menu — DO NOT use autofree()!
	# autofree(s) + add_child(s) = double-free: GUT and menu will both try to free 's'.
	# Child nodes are automatically freed together with their parent (menu).
	menu.pac_anim = AnimatedSprite2D.new()
	menu.add_child(menu.pac_anim)

	menu.ghosts_anim.clear()
	for i in 4:
		var s := AnimatedSprite2D.new()
		# _begin_hunt() calls s.play("Scared") — without SpriteFrames this is an engine-error.
		# Create a minimal SpriteFrames with the required animation.
		var sf := SpriteFrames.new()
		sf.add_animation("Scared")
		s.sprite_frames = sf
		menu.ghosts_anim.append(s)
		menu.add_child(s)

	menu.pellet_sprite = Sprite2D.new()
	menu.add_child(menu.pellet_sprite)
	menu.pellet_sprite.position = Vector2(300.0, 255.0)


# ──────────────────────────────────────────────
# Constants
# ──────────────────────────────────────────────
func test_constant_anim_y() -> void:
	assert_eq(menu.ANIM_Y, 255.0)

func test_constant_chase_speed() -> void:
	assert_eq(menu.CHASE_SPEED, 180.0)

func test_constant_hunt_pac_speed() -> void:
	assert_eq(menu.HUNT_PAC_SPEED, 260.0)

func test_constant_hunt_ghost_speed() -> void:
	assert_eq(menu.HUNT_GHOST_SPEED, 120.0)

func test_constant_ghost_gap() -> void:
	assert_eq(menu.GHOST_GAP, 48.0)

func test_constant_pellet_x() -> void:
	assert_eq(menu.PELLET_X, 300.0)


# ──────────────────────────────────────────────
# Initial state
# ──────────────────────────────────────────────
func test_initial_phase_is_wait() -> void:
	assert_eq(menu.phase, menu.Phase.WAIT)

func test_initial_move_dir_is_left() -> void:
	assert_eq(menu.move_dir, -1.0)

func test_initial_ghosts_not_scared() -> void:
	assert_false(menu.ghosts_scared)

func test_initial_eaten_count_zero() -> void:
	assert_eq(menu.eaten_count, 0)

func test_initial_ghosts_not_eaten() -> void:
	for i in 4:
		assert_false(menu.ghosts_eaten[i], "Ghost %d should not be eaten initially" % i)


# ──────────────────────────────────────────────
# _begin_hunt()
# ──────────────────────────────────────────────
func test_begin_hunt_changes_phase_to_hunt() -> void:
	menu.phase = menu.Phase.CHASE
	menu._begin_hunt()
	assert_eq(menu.phase, menu.Phase.HUNT)

func test_begin_hunt_sets_ghosts_scared() -> void:
	menu._begin_hunt()
	assert_true(menu.ghosts_scared)

func test_begin_hunt_reverses_move_direction() -> void:
	menu.move_dir = -1.0
	menu._begin_hunt()
	assert_eq(menu.move_dir, 1.0)

func test_begin_hunt_hides_pellet() -> void:
	menu.pellet_sprite.visible = true
	menu._begin_hunt()
	assert_false(menu.pellet_sprite.visible)


# ──────────────────────────────────────────────
# _eat_ghost()
# ──────────────────────────────────────────────
func test_eat_ghost_marks_first_ghost_eaten() -> void:
	menu._eat_ghost(0)
	assert_true(menu.ghosts_eaten[0])

func test_eat_ghost_increments_counter() -> void:
	menu._eat_ghost(0)
	assert_eq(menu.eaten_count, 1)

func test_eat_ghost_only_marks_targeted_ghost() -> void:
	menu._eat_ghost(1)
	assert_false(menu.ghosts_eaten[0])
	assert_true(menu.ghosts_eaten[1])
	assert_false(menu.ghosts_eaten[2])
	assert_false(menu.ghosts_eaten[3])

func test_eat_ghost_increments_counter_each_time() -> void:
	menu._eat_ghost(0)
	menu._eat_ghost(2)
	assert_eq(menu.eaten_count, 2)

func test_eat_ghost_all_four_marks_all_eaten() -> void:
	for i in 4:
		menu._eat_ghost(i)
	assert_eq(menu.eaten_count, 4)
	for i in 4:
		assert_true(menu.ghosts_eaten[i], "Ghost %d should be eaten" % i)

func test_eat_ghost_hides_sprite() -> void:
	menu.ghosts_anim[0].visible = true
	menu._eat_ghost(0)
	assert_false(menu.ghosts_anim[0].visible)


# ──────────────────────────────────────────────
# start_game() — Global state reset
# Note: SceneTransition.change_scene() is async so assertions
# run before the actual scene swap takes place.
# ──────────────────────────────────────────────
func test_start_game_resets_level() -> void:
	Global.level = 7
	menu.start_game()
	assert_eq(Global.level, 1)

func test_start_game_resets_score() -> void:
	Global.score = 9999
	menu.start_game()
	assert_eq(Global.score, 0)

func test_start_game_resets_health() -> void:
	Global.health = 0
	menu.start_game()
	assert_eq(Global.health, 3)

func test_start_game_resets_dots_eaten() -> void:
	Global.dots_eaten = 200
	menu.start_game()
	assert_eq(Global.dots_eaten, 0)

func test_start_game_clears_eaten_points_positions() -> void:
	Global.eaten_points_positions = {Vector2(1, 1): true, Vector2(2, 2): true}
	menu.start_game()
	assert_eq(Global.eaten_points_positions.size(), 0)

func test_start_game_resets_died_in_level() -> void:
	Global.died_in_level = true
	menu.start_game()
	assert_false(Global.died_in_level)

func test_start_game_resets_intermission_mode() -> void:
	Global.isIntermissionMode = true
	menu.start_game()
	assert_false(Global.isIntermissionMode)
