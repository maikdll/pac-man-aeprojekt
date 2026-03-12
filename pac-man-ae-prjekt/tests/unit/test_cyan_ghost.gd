extends GutTest

# =============================================================================
# test_cyan_ghost.gd
# =============================================================================
# CyanGhost (Inky) has the most complex targeting in the game.
# Unlike other ghosts who just chase pacman, Inky uses Blinky's position
# to calculate a "flanking" target on the opposite side of pacman.
#
# Algorithm (get_custom_target in CHASE mode, blinky != null):
#   1. pivot_point  = pacman.global_position + (pacman_direction * 96)
#   2. vector       = pivot_point - blinky.global_position
#   3. target       = blinky.global_position + (vector * 2)
#
# With a stationary fake_pacman (plain Node2D):
#   pacman_direction = ZERO  (no "direction" or "velocity" property)
#   pivot_point = pacman.global_position
#   target = blinky.global_position + (pacman_pos - blinky_pos) * 2
#
# WHAT we test:
#   ✅ get_speed_multiplier()  - returns Global.speedGhostCyan
#   ✅ get_custom_target() SCATTER mode - returns current_scatter_target
#   ✅ get_custom_target() CHASE + blinky = null - returns pacman.global_position
#   ✅ get_custom_target() CHASE + blinky != null - flanking calculation
#   ✅ _on_wave_timeout() - SCATTER <-> CHASE switching (no permanent chase rule)
#
# WHAT we do NOT test and why:
#   ❌ pick_new_scatter_target() - requires main_node.tile_map1
#   ❌ _custom_ready()           - calls get_tree() which needs a real scene
# =============================================================================

var _Script = load("res://scripts/Ghosts/CyanGhost.gd")
var ghost
var fake_pacman  # Plain Node2D - controllable position, no direction/velocity
var fake_blinky  # Plain Node2D - simulates Blinky's position for the calculation


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
	ghost.global_position = Vector2.ZERO
	# Keep scatter target far enough (> 32 units) to avoid pick_new_scatter_target()
	ghost.current_scatter_target = Vector2(1000.0, 1000.0)
	ghost.current_mode = ghost.Mode.CHASE


# -----------------------------------------------------------------------------
# get_speed_multiplier()
# Cyan ghost (Inky) uses Global.speedGhostCyan.
# -----------------------------------------------------------------------------

func test_speed_multiplier_matches_global_cyan() -> void:
	Global.speedGhostCyan = 1.0
	assert_eq(ghost.get_speed_multiplier(), 1.0)

func test_speed_multiplier_reflects_global_change() -> void:
	Global.speedGhostCyan = 1.3
	assert_eq(ghost.get_speed_multiplier(), 1.3)
	Global.speedGhostCyan = 1.0  # restore


# -----------------------------------------------------------------------------
# get_custom_target() - SCATTER mode
# -----------------------------------------------------------------------------

func test_scatter_returns_scatter_target() -> void:
	ghost.current_mode = ghost.Mode.SCATTER
	var result: Vector2 = ghost.get_custom_target()
	assert_eq(result, ghost.current_scatter_target)


# -----------------------------------------------------------------------------
# get_custom_target() - CHASE mode, blinky = null
# Falls back to pacman.global_position (safe fallback when Blinky not found).
# -----------------------------------------------------------------------------

func test_chase_without_blinky_returns_pacman_pos() -> void:
	ghost.blinky = null
	fake_pacman.global_position = Vector2(200.0, 150.0)
	var result: Vector2 = ghost.get_custom_target()
	assert_eq(result, fake_pacman.global_position)

func test_chase_without_blinky_updates_with_pacman() -> void:
	ghost.blinky = null
	fake_pacman.global_position = Vector2(50.0, 80.0)
	var result: Vector2 = ghost.get_custom_target()
	assert_eq(result, Vector2(50.0, 80.0))


# -----------------------------------------------------------------------------
# get_custom_target() - CHASE mode, blinky present, stationary pacman
#
# pacman_direction = ZERO (Node2D has no "direction"/"velocity")
# pivot_point = pacman.global_position + ZERO * 96 = pacman.global_position
# vector_from_blinky = pacman_pos - blinky_pos
# target = blinky_pos + vector_from_blinky * 2
#        = blinky_pos + (pacman_pos - blinky_pos) * 2
#
# Example:
#   pacman at (100, 0), blinky at (0, 0)
#   vector = (100, 0) - (0, 0) = (100, 0)
#   target = (0, 0) + (100, 0) * 2 = (200, 0)
# -----------------------------------------------------------------------------

func test_chase_with_blinky_flanking_calculation() -> void:
	ghost.blinky = fake_blinky
	fake_pacman.global_position = Vector2(100.0, 0.0)
	fake_blinky.global_position = Vector2(0.0, 0.0)
	# pivot = (100, 0), vector = (100, 0), target = (0,0) + (100,0)*2 = (200, 0)
	var result: Vector2 = ghost.get_custom_target()
	assert_eq(result, Vector2(200.0, 0.0))

func test_chase_with_blinky_flanking_vertical() -> void:
	ghost.blinky = fake_blinky
	fake_pacman.global_position = Vector2(0.0, 100.0)
	fake_blinky.global_position = Vector2(0.0, 0.0)
	# pivot = (0,100), vector = (0,100), target = (0,0) + (0,100)*2 = (0,200)
	var result: Vector2 = ghost.get_custom_target()
	assert_eq(result, Vector2(0.0, 200.0))

func test_chase_target_is_opposite_side_of_pacman_from_blinky() -> void:
	# Inky's target is always past pacman, away from Blinky.
	# Here blinky at (500,0), pacman at (200,0) -> target at (-100, 0)
	ghost.blinky = fake_blinky
	fake_pacman.global_position = Vector2(200.0, 0.0)
	fake_blinky.global_position = Vector2(500.0, 0.0)
	# pivot=(200,0), vector=(200,0)-(500,0)=(-300,0), target=(500,0)+(-300,0)*2=(-100,0)
	var result: Vector2 = ghost.get_custom_target()
	assert_eq(result, Vector2(-100.0, 0.0))

func test_chase_blinky_and_pacman_same_position() -> void:
	# Edge case: blinky and pacman at same spot -> vector = ZERO -> target = blinky_pos
	ghost.blinky = fake_blinky
	fake_pacman.global_position = Vector2(100.0, 100.0)
	fake_blinky.global_position = Vector2(100.0, 100.0)
	var result: Vector2 = ghost.get_custom_target()
	assert_eq(result, Vector2(100.0, 100.0))


# -----------------------------------------------------------------------------
# _on_wave_timeout() - SCATTER <-> CHASE switching
# Inky has no special "permanent chase" rule like Blinky.
# -----------------------------------------------------------------------------

func test_scatter_switches_to_chase() -> void:
	ghost.current_mode = ghost.Mode.SCATTER
	ghost._on_wave_timeout()
	assert_eq(ghost.current_mode, ghost.Mode.CHASE)

func test_chase_switches_to_scatter() -> void:
	ghost.current_mode = ghost.Mode.CHASE
	ghost._on_wave_timeout()
	assert_eq(ghost.current_mode, ghost.Mode.SCATTER)

func test_wave_timeout_is_symmetric() -> void:
	# Two timeouts should return to original mode.
	ghost.current_mode = ghost.Mode.SCATTER
	ghost._on_wave_timeout()
	ghost._on_wave_timeout()
	assert_eq(ghost.current_mode, ghost.Mode.SCATTER)
