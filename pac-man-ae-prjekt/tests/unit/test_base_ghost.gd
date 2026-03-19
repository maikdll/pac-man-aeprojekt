extends GutTest

# =============================================================================
# test_base_ghost.gd — Unit tests for BaseGhost.gd
#
# TESTED:     initial state, start_wave(), get_speed_multiplier(),
#             on_power_pellet_eaten()
# NOT TESTED: leave_house, update_path, get_eaten, get_direction (scene nodes)
# =============================================================================

var _Script = load("res://scripts/Ghosts/BaseGhost.gd")
var ghost

func before_each() -> void:
	ghost = partial_double(_Script).new()
	stub(ghost, "_ready").to_do_nothing()
	stub(ghost, "_process").to_do_nothing()
	stub(ghost, "update_path").to_do_nothing()
	stub(ghost, "pick_new_scatter_target").to_do_nothing()
	add_child_autoqfree(ghost)


# -----------------------------------------------------------------------------
# Initial state — ghost must start inside house, in SCATTER mode, not eaten
# -----------------------------------------------------------------------------
func test_initial_state() -> void:
	assert_true(ghost.is_in_house, "Ghost must start inside the house")
	assert_false(ghost.is_eaten, "Ghost must not be eaten at start")
	assert_false(ghost.is_immune, "Ghost must not be immune at start")
	assert_eq(ghost.current_mode, ghost.Mode.SCATTER, "Ghost must start in SCATTER mode")


# -----------------------------------------------------------------------------
# start_wave() — switches between SCATTER and CHASE modes
# -----------------------------------------------------------------------------
func test_start_wave_switches_mode() -> void:
	ghost.start_wave(ghost.Mode.CHASE, 20.0)
	assert_eq(ghost.current_mode, ghost.Mode.CHASE)

	ghost.start_wave(ghost.Mode.SCATTER, 10.0)
	assert_eq(ghost.current_mode, ghost.Mode.SCATTER)


# -----------------------------------------------------------------------------
# get_speed_multiplier() — base class always returns 1.0
# -----------------------------------------------------------------------------
func test_base_speed_multiplier_is_one() -> void:
	assert_eq(ghost.get_speed_multiplier(), 1.0)


# -----------------------------------------------------------------------------
# on_power_pellet_eaten() — resets immunity when ghost is NOT eaten
# -----------------------------------------------------------------------------
# Why:  When PacMan eats a big dot, all ghosts become vulnerable again.
#       But if a ghost is already eaten (returning home), it stays immune.
# -----------------------------------------------------------------------------
func test_power_pellet_resets_immunity() -> void:
	ghost.is_immune = true
	ghost.is_eaten = false
	ghost.on_power_pellet_eaten()
	assert_false(ghost.is_immune, "Immunity must reset after power pellet")

func test_power_pellet_does_not_affect_eaten_ghost() -> void:
	ghost.is_eaten = true
	ghost.is_immune = true
	ghost.on_power_pellet_eaten()
	assert_true(ghost.is_immune, "Eaten ghost must keep immunity")
