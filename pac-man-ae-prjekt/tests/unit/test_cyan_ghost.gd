extends GutTest

# =============================================================================
# test_cyan_ghost.gd — Unit tests for CyanGhost.gd (Inky)
#
# TESTED:     get_speed_multiplier(), get_custom_target() flanking algorithm,
#             _on_wave_timeout()
# NOT TESTED: pick_new_scatter_target (TileMap), _custom_ready (get_tree)
#
# Flanking formula (stationary pacman, direction=ZERO):
#   target = blinky_pos + (pacman_pos - blinky_pos) * 2
# =============================================================================

var _Script = load("res://scripts/Ghosts/CyanGhost.gd")
var ghost
var fake_pacman
var fake_blinky

func before_each() -> void:
	ghost = partial_double(_Script).new()
	stub(ghost, "_ready").to_do_nothing()
	stub(ghost, "_process").to_do_nothing()
	stub(ghost, "update_path").to_do_nothing()
	stub(ghost, "pick_new_scatter_target").to_do_nothing()
	add_child_autoqfree(ghost)

	fake_pacman = add_child_autoqfree(Node2D.new())
	fake_blinky = add_child_autoqfree(Node2D.new())
	ghost.pacman = fake_pacman
	ghost.current_scatter_target = Vector2(1000.0, 1000.0)
	ghost.current_mode = ghost.Mode.CHASE


# -----------------------------------------------------------------------------
# get_speed_multiplier() — Inky uses Global.speedGhostCyan
# -----------------------------------------------------------------------------
func test_speed_multiplier() -> void:
	Global.speedGhostCyan = 1.3
	assert_eq(ghost.get_speed_multiplier(), 1.3)
	Global.speedGhostCyan = 1.0


# -----------------------------------------------------------------------------
# get_custom_target() — CHASE without Blinky: fallback to pacman position
# -----------------------------------------------------------------------------
func test_chase_without_blinky_returns_pacman_pos() -> void:
	ghost.blinky = null
	fake_pacman.global_position = Vector2(200.0, 150.0)
	assert_eq(ghost.get_custom_target(), fake_pacman.global_position)


# -----------------------------------------------------------------------------
# get_custom_target() — CHASE with Blinky: flanking calculation
# -----------------------------------------------------------------------------
# Why:  Inky's target is on the OPPOSITE side of pacman from Blinky.
#       This is the most complex targeting in the game.
# -----------------------------------------------------------------------------
func test_flanking_horizontal() -> void:
	ghost.blinky = fake_blinky
	fake_pacman.global_position = Vector2(100.0, 0.0)
	fake_blinky.global_position = Vector2(0.0, 0.0)
	# target = (0,0) + ((100,0)-(0,0))*2 = (200, 0)
	assert_eq(ghost.get_custom_target(), Vector2(200.0, 0.0))

func test_flanking_opposite_side() -> void:
	ghost.blinky = fake_blinky
	fake_pacman.global_position = Vector2(200.0, 0.0)
	fake_blinky.global_position = Vector2(500.0, 0.0)
	# target = (500,0) + ((200,0)-(500,0))*2 = (-100, 0)
	assert_eq(ghost.get_custom_target(), Vector2(-100.0, 0.0))


# -----------------------------------------------------------------------------
# get_custom_target() — SCATTER: returns scatter target, ignores pacman
# -----------------------------------------------------------------------------
func test_scatter_returns_scatter_target() -> void:
	ghost.current_mode = ghost.Mode.SCATTER
	assert_eq(ghost.get_custom_target(), ghost.current_scatter_target)


# -----------------------------------------------------------------------------
# _on_wave_timeout() — simple SCATTER <-> CHASE toggle (no permanent chase)
# -----------------------------------------------------------------------------
func test_wave_timeout_toggles_mode() -> void:
	ghost.current_mode = ghost.Mode.SCATTER
	ghost._on_wave_timeout()
	assert_eq(ghost.current_mode, ghost.Mode.CHASE)

	ghost._on_wave_timeout()
	assert_eq(ghost.current_mode, ghost.Mode.SCATTER)
