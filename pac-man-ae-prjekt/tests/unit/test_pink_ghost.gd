extends GutTest

# =============================================================================
# test_pink_ghost.gd — Unit tests for PinkGhost.gd (Pinky)
#
# TESTED:     get_speed_multiplier(), get_custom_target() (ambush logic)
# NOT TESTED: pick_new_scatter_target (TileMap), _on_wave_timeout (wave_timer)
#
# Pinky aims AHEAD of pacman by ambush_distance (300).
# With a stationary fake pacman (Node2D, no direction), target = pacman_pos.
# =============================================================================

var _Script = load("res://scripts/Ghosts/PinkGhost.gd")
var ghost
var fake_pacman

func before_each() -> void:
	ghost = partial_double(_Script).new()
	stub(ghost, "_ready").to_do_nothing()
	stub(ghost, "_process").to_do_nothing()
	stub(ghost, "update_path").to_do_nothing()
	stub(ghost, "pick_new_scatter_target").to_do_nothing()
	add_child_autoqfree(ghost)

	fake_pacman = add_child_autoqfree(Node2D.new())
	ghost.pacman = fake_pacman
	ghost.global_position = Vector2.ZERO
	ghost.current_scatter_target = Vector2(1000.0, 1000.0)
	ghost.current_mode = ghost.Mode.CHASE


# -----------------------------------------------------------------------------
# get_speed_multiplier() — Pinky uses Global.speedGhostPink
# -----------------------------------------------------------------------------
func test_speed_multiplier() -> void:
	Global.speedGhostPink = 1.5
	assert_eq(ghost.get_speed_multiplier(), 1.5)
	Global.speedGhostPink = 1.0


# -----------------------------------------------------------------------------
# get_custom_target() — CHASE with stationary pacman
# -----------------------------------------------------------------------------
# Why:  Node2D has no "direction" or "velocity", so pacman_direction = ZERO.
#       Result: pacman_pos + (ZERO * 300) = pacman_pos.
# -----------------------------------------------------------------------------
func test_chase_target_equals_pacman_pos() -> void:
	fake_pacman.global_position = Vector2(200.0, 100.0)
	assert_eq(ghost.get_custom_target(), fake_pacman.global_position)


# -----------------------------------------------------------------------------
# get_custom_target() — SCATTER returns scatter target, ignores pacman
# -----------------------------------------------------------------------------
func test_scatter_returns_scatter_target() -> void:
	ghost.current_mode = ghost.Mode.SCATTER
	fake_pacman.global_position = Vector2(5.0, 0.0)  # very close, but ignored
	assert_eq(ghost.get_custom_target(), ghost.current_scatter_target)
