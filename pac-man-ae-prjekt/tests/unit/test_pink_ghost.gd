extends GutTest

# =============================================================================
# test_pink_ghost.gd
# =============================================================================
# WHAT we test:
#   ✅ get_speed_multiplier() - returns Global.speedGhostPink
#   ✅ ambush_distance default = 300.0
#   ✅ get_custom_target() in CHASE mode with a stationary pacman (Node2D)
#      A plain Node2D has no "direction" and no "velocity" properties,
#      so pacman_direction falls back to Vector2.ZERO.
#      Expected target = pacman.global_position + (ZERO * 300) = pacman.global_position
#   ✅ get_custom_target() in SCATTER mode - returns current_scatter_target
#      (unless ghost is within 32 units of it, which would call pick_new_scatter_target)
#
# WHAT we do NOT test and why:
#   ❌ pick_new_scatter_target()   - requires main_node.tile_map1
#   ❌ _on_wave_timeout()          - requires wave_timer node in scene
#   ❌ Ambush with a real pacman direction - would require a real Pacman scene node
# =============================================================================

var _Script = load("res://scripts/Ghosts/PinkGhost.gd")
var ghost
var fake_pacman  # Plain Node2D - only global_position is controlled


func before_each() -> void:
	ghost = partial_double(_Script).new()
	stub(ghost, "_ready").to_do_nothing()
	stub(ghost, "_process").to_do_nothing()
	stub(ghost, "update_path").to_do_nothing()
	stub(ghost, "pick_new_scatter_target").to_do_nothing()
	add_child_autoqfree(ghost)

	# Fake pacman - just a node at a controllable position
	fake_pacman = add_child_autoqfree(Node2D.new())
	ghost.pacman = fake_pacman

	ghost.global_position = Vector2.ZERO
	# Keep scatter target far enough (> 32 units) to avoid pick_new_scatter_target()
	ghost.current_scatter_target = Vector2(1000.0, 1000.0)

	# Start in CHASE mode for most tests
	ghost.current_mode = ghost.Mode.CHASE


# -----------------------------------------------------------------------------
# Default property values
# -----------------------------------------------------------------------------

func test_ambush_distance_default() -> void:
	# If someone changes the constant, this test will catch it.
	assert_eq(ghost.ambush_distance, 300.0)


# -----------------------------------------------------------------------------
# get_speed_multiplier()
# Pink ghost (Pinky) uses Global.speedGhostPink.
# -----------------------------------------------------------------------------

func test_speed_multiplier_matches_global_pink() -> void:
	Global.speedGhostPink = 1.0
	assert_eq(ghost.get_speed_multiplier(), 1.0)

func test_speed_multiplier_reflects_global_change() -> void:
	Global.speedGhostPink = 1.5
	assert_eq(ghost.get_speed_multiplier(), 1.5)
	Global.speedGhostPink = 1.0  # restore


# -----------------------------------------------------------------------------
# get_custom_target() - CHASE mode with stationary fake pacman
#
# A plain Node2D does not have "direction" or "velocity" properties.
# Both checks (line 24-27 in PinkGhost.gd) fail, so pacman_direction = ZERO.
# Result: pacman.global_position + (ZERO * 300) = pacman.global_position
# -----------------------------------------------------------------------------

func test_chase_target_equals_pacman_pos_when_stationary() -> void:
	fake_pacman.global_position = Vector2(200.0, 100.0)
	var result: Vector2 = ghost.get_custom_target()
	assert_eq(result, fake_pacman.global_position)

func test_chase_target_updates_with_pacman_position() -> void:
	fake_pacman.global_position = Vector2(500.0, 300.0)
	var result: Vector2 = ghost.get_custom_target()
	assert_eq(result, Vector2(500.0, 300.0))

func test_chase_target_at_origin() -> void:
	fake_pacman.global_position = Vector2.ZERO
	var result: Vector2 = ghost.get_custom_target()
	assert_eq(result, Vector2.ZERO)


# -----------------------------------------------------------------------------
# get_custom_target() - SCATTER mode
# Ghost should return current_scatter_target (not chase the player).
# -----------------------------------------------------------------------------

func test_scatter_returns_scatter_target() -> void:
	ghost.current_mode = ghost.Mode.SCATTER
	var result: Vector2 = ghost.get_custom_target()
	assert_eq(result, ghost.current_scatter_target)

func test_scatter_ignores_pacman_position() -> void:
	# Even if pacman is right next to the ghost, scatter mode returns scatter target.
	ghost.current_mode = ghost.Mode.SCATTER
	fake_pacman.global_position = Vector2(5.0, 0.0)  # very close
	var result: Vector2 = ghost.get_custom_target()
	assert_eq(result, ghost.current_scatter_target)
