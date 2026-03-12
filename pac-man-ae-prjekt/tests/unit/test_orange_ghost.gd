extends GutTest

# =============================================================================
# test_orange_ghost.gd
# =============================================================================
# OrangeGhost (Clyde) is the most interesting ghost to test.
# Its get_custom_target() contains a PANIC state machine - pure logic
# with no dependency on AStar or TileMap.
#
# Panic logic:
#   • If pacman is closer than panic_distance (150) -> is_panicking = true
#     -> ghost flees to scatter_target (corner of the map)
#   • If pacman is farther than resume_chase_distance (500) -> is_panicking = false
#     -> ghost resumes chasing pacman
#   • In SCATTER mode -> is_panicking is always false
#
# WHAT we test:
#   ✅ Initial state (is_panicking = false)
#   ✅ Panic triggers when pacman is close (< 150)
#   ✅ Panic does not trigger when pacman is far (> 150)
#   ✅ Panic stops when pacman moves far away (> 500)
#   ✅ Panic persists while pacman has not moved far enough
#   ✅ SCATTER mode resets panic
#   ✅ Return value: scatter_target vs pacman_position
#
# WHAT we do NOT test and why:
#   ❌ pick_new_scatter_target() - requires main_node.tile_map1
#   ❌ _on_wave_timeout()        - requires wave_timer node in scene
# =============================================================================

var _Script = load("res://scripts/Ghosts/OrangeGhost.gd")
var ghost
var fake_pacman  # Node2D - simulates pacman position in world space


func before_each() -> void:
	ghost = partial_double(_Script).new()
	stub(ghost, "_ready").to_do_nothing()
	stub(ghost, "_process").to_do_nothing()
	stub(ghost, "update_path").to_do_nothing()
	# pick_new_scatter_target is called when ghost is close to scatter_target
	stub(ghost, "pick_new_scatter_target").to_do_nothing()
	add_child_autoqfree(ghost)

	# Fake pacman - just a node with a controllable position
	fake_pacman = add_child_autoqfree(Node2D.new())
	ghost.pacman = fake_pacman

	# Ghost stands at origin
	ghost.global_position = Vector2.ZERO

	# Scatter target is far away (> 32 units) - avoids calling pick_new_scatter_target()
	ghost.current_scatter_target = Vector2(1000.0, 1000.0)

	# Start in CHASE mode for most tests
	ghost.current_mode = ghost.Mode.CHASE
	ghost.is_panicking = false


# ─────────────────────────────────────────────────────────────────────────────
# Initial state
# ─────────────────────────────────────────────────────────────────────────────

func test_initial_is_not_panicking() -> void:
	assert_false(ghost.is_panicking)

func test_panic_distance_default() -> void:
	# If someone changes this constant, the test will catch it.
	assert_eq(ghost.panic_distance, 150.0)

func test_resume_chase_distance_default() -> void:
	assert_eq(ghost.resume_chase_distance, 500.0)


# ─────────────────────────────────────────────────────────────────────────────
# Panic trigger: pacman is close
# Ghost at (0,0), pacman at (100,0) -> distance 100 < 150 -> panic
# ─────────────────────────────────────────────────────────────────────────────

func test_panic_triggers_when_pacman_is_close() -> void:
	fake_pacman.global_position = Vector2(100.0, 0.0)  # 100 < 150 (panic_distance)
	ghost.get_custom_target()
	assert_true(ghost.is_panicking)

func test_panic_does_not_trigger_when_pacman_is_far() -> void:
	fake_pacman.global_position = Vector2(200.0, 0.0)  # 200 > 150
	ghost.get_custom_target()
	assert_false(ghost.is_panicking)

func test_panic_triggers_at_boundary() -> void:
	# Just below the threshold (149.0) -> panic should activate
	fake_pacman.global_position = Vector2(149.0, 0.0)
	ghost.get_custom_target()
	assert_true(ghost.is_panicking)


# ─────────────────────────────────────────────────────────────────────────────
# Leaving panic: pacman moves far away
# ─────────────────────────────────────────────────────────────────────────────

func test_panic_stops_when_pacman_moves_far_away() -> void:
	ghost.is_panicking = true
	fake_pacman.global_position = Vector2(600.0, 0.0)  # 600 > 500 (resume_chase_distance)
	ghost.get_custom_target()
	assert_false(ghost.is_panicking)

func test_panic_continues_while_pacman_nearby() -> void:
	# Panic is already active, pacman has not moved far enough yet
	ghost.is_panicking = true
	fake_pacman.global_position = Vector2(300.0, 0.0)  # 300 < 500 - not far enough
	ghost.get_custom_target()
	assert_true(ghost.is_panicking)

func test_panic_stops_exactly_at_resume_boundary() -> void:
	ghost.is_panicking = true
	fake_pacman.global_position = Vector2(501.0, 0.0)  # just past 500
	ghost.get_custom_target()
	assert_false(ghost.is_panicking)


# ─────────────────────────────────────────────────────────────────────────────
# SCATTER mode always resets panic
# ─────────────────────────────────────────────────────────────────────────────

func test_scatter_mode_resets_panic() -> void:
	ghost.is_panicking = true
	ghost.current_mode = ghost.Mode.SCATTER
	fake_pacman.global_position = Vector2(50.0, 0.0)  # very close, but SCATTER mode
	ghost.get_custom_target()
	assert_false(ghost.is_panicking)

func test_scatter_mode_keeps_non_panic() -> void:
	ghost.is_panicking = false
	ghost.current_mode = ghost.Mode.SCATTER
	ghost.get_custom_target()
	assert_false(ghost.is_panicking)


# ─────────────────────────────────────────────────────────────────────────────
# Return value of get_custom_target()
# ─────────────────────────────────────────────────────────────────────────────

func test_returns_scatter_target_when_panicking() -> void:
	# During panic - flees to scatter_target (corner), not toward pacman
	ghost.is_panicking = true
	var result: Vector2 = ghost.get_custom_target()
	assert_eq(result, ghost.current_scatter_target)

func test_returns_pacman_pos_when_chasing_normally() -> void:
	# Normal chase: pacman is far (does not trigger panic) -> target = pacman
	ghost.is_panicking = false
	fake_pacman.global_position = Vector2(200.0, 0.0)  # 200 > 150, no panic
	var result: Vector2 = ghost.get_custom_target()
	assert_eq(result, fake_pacman.global_position)

func test_returns_scatter_target_in_scatter_mode() -> void:
	ghost.current_mode = ghost.Mode.SCATTER
	var result: Vector2 = ghost.get_custom_target()
	assert_eq(result, ghost.current_scatter_target)
