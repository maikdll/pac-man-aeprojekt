extends GutTest

# =============================================================================
# test_pacman.gd
# =============================================================================
# WHAT we test:
#   ✅ get_intermission_times(level) - pure function, no scene dependencies.
#      This is the duration ghosts stay "blue" after a power pellet.
#      Key insight: blink is ALWAYS = total / 2 (one test covers all levels).
#   ✅ Default variable values.
#
# WHAT we do NOT test and why:
#   ❌ killPacman()       - uses await + $AudioDeath + $AnimatedSprite2D
#   ❌ _physics_process() - depends on Input + TileMap collisions
#   ❌ _on_area_2d_*()    - requires real Area2D nodes / group calls
# =============================================================================

var _PacManScript = load("res://scripts/PacMan.gd")
var pacman

func before_each() -> void:
	# partial_double stubs _ready/_process without affecting other methods.
	pacman = partial_double(_PacManScript).new()
	stub(pacman, "_ready").to_do_nothing()
	stub(pacman, "_process").to_do_nothing()
	stub(pacman, "_physics_process").to_do_nothing()
	add_child_autoqfree(pacman)


# ──────────────────────────────────────────────
# Initial state
# ──────────────────────────────────────────────
func test_initial_is_not_dying() -> void:
	assert_false(pacman.isDying)

func test_initial_is_not_invincible() -> void:
	assert_false(pacman.is_invincible)

func test_initial_current_direction_is_right() -> void:
	assert_eq(pacman.current_direction, Vector2.RIGHT)

func test_initial_next_direction_is_right() -> void:
	assert_eq(pacman.next_direction, Vector2.RIGHT)

func test_initial_intermission_time_left_is_zero() -> void:
	assert_eq(pacman.intermission_time_left, 0.0)

func test_initial_intermission_blink_time_is_zero() -> void:
	assert_eq(pacman.intermission_blink_time, 0.0)

func test_spawn_position_default() -> void:
	assert_eq(pacman.spawn_position, Vector2(400.0, 600.0))


# -----------------------------------------------------------------------------
# get_intermission_times() - ghost blue duration per level tier
# Pure logic, ideal for unit testing.
# -----------------------------------------------------------------------------

# Check exact values for each difficulty tier

func test_level_1() -> void:
	var t: Dictionary = pacman.get_intermission_times(1)
	assert_eq(t["total"], 10.0, "Level 1: total")

func test_level_2() -> void:
	var t: Dictionary = pacman.get_intermission_times(2)
	assert_eq(t["total"], 9.0, "Level 2: total")

func test_level_3() -> void:
	var t: Dictionary = pacman.get_intermission_times(3)
	assert_eq(t["total"], 8.0, "Level 3: total")

func test_level_4() -> void:
	var t: Dictionary = pacman.get_intermission_times(4)
	assert_eq(t["total"], 7.0, "Level 4: total")

func test_levels_5_to_8_same() -> void:
	# Levels 5-8 share the same duration
	var t5: Dictionary = pacman.get_intermission_times(5)
	var t8: Dictionary = pacman.get_intermission_times(8)
	assert_eq(t5["total"], 6.0, "Level 5: total")
	assert_eq(t5["total"], t8["total"], "Level 5 and 8 must match")

func test_levels_9_to_16_same() -> void:
	# Levels 9-16 share the same duration
	var t9: Dictionary  = pacman.get_intermission_times(9)
	var t16: Dictionary = pacman.get_intermission_times(16)
	assert_eq(t9["total"], 5.0, "Level 9: total")
	assert_eq(t9["total"], t16["total"], "Level 9 and 16 must match")

func test_level_17_and_above_minimum() -> void:
	# After level 17 the duration no longer decreases
	var t17: Dictionary = pacman.get_intermission_times(17)
	var t99: Dictionary = pacman.get_intermission_times(99)
	assert_eq(t17["total"], 4.0, "Level 17: total")
	assert_eq(t99["total"], 4.0, "Level 99: total should equal level 17")

func test_blink_is_always_half_of_total() -> void:
	# Key invariant: blink always equals total / 2.
	# One test replaces all individual blink tests per level.
	for lvl in [1, 2, 3, 4, 5, 8, 9, 16, 17, 99]:
		var t: Dictionary = pacman.get_intermission_times(lvl)
		assert_eq(t["blink"], t["total"] / 2.0,
				"Level %d: blink should be total/2" % lvl)

func test_time_never_increases_with_level() -> void:
	# Duration must decrease or stay the same as level increases.
	var prev: float = pacman.get_intermission_times(1)["total"]
	for lvl in [2, 3, 4, 5, 9, 17]:
		var curr: float = pacman.get_intermission_times(lvl)["total"]
		assert_lte(curr, prev, "Level %d should not increase time vs previous" % lvl)
		prev = curr
