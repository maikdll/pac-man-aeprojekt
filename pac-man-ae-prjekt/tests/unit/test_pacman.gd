extends GutTest

# =============================================================================
# test_pacman.gd — Unit tests for PacMan.gd
#
# TESTED:     get_intermission_times(level)
# =============================================================================

var _PacManScript = load("res://scripts/PacMan.gd")
var pacman

func before_each() -> void:
	# Create a PacMan instance with engine callbacks disabled.
	# partial_double() creates a copy of the script where we can stub methods.
	# We stub _ready/_process/_physics_process because they access scene nodes
	# ($AnimatedSprite2D, $Audio*) that don't exist in the test environment.
	pacman = partial_double(_PacManScript).new()
	stub(pacman, "_ready").to_do_nothing()
	stub(pacman, "_process").to_do_nothing()
	stub(pacman, "_physics_process").to_do_nothing()
	add_child_autoqfree(pacman)


# -----------------------------------------------------------------------------
# TEST 1: Exact intermission time for each level tier
# -----------------------------------------------------------------------------
# Why:  get_intermission_times() returns how long ghosts stay scared.
#       Each level tier has a specific duration. If someone changes level 3
#       from 8.0 to 6.0 by accident, this test catches it.
#
# How:  Dictionary of [level -> expected total time]. We check every tier
#       boundary (1, 2, 3, 4, 5, 8, 9, 16, 17) plus level 99 as extreme.
# -----------------------------------------------------------------------------
func test_get_intermission_times_exact_values() -> void:
	var test_cases = {
		1: 10.0,
		2: 9.0,
		3: 8.0,
		4: 7.0,
		5: 6.0,  8: 6.0,    # Tier 5-8
		9: 5.0,  16: 5.0,   # Tier 9-16
		17: 4.0, 99: 4.0    # Level 17+ is capped at minimum
	}

	for lvl in test_cases.keys():
		var result = pacman.get_intermission_times(lvl)
		assert_eq(result["total"], test_cases[lvl],
			"Total time for level %d should be %s" % [lvl, test_cases[lvl]])


# -----------------------------------------------------------------------------
# TEST 2: Blink time is always exactly half of total time
# -----------------------------------------------------------------------------
# Why:  Ghosts start blinking when half the scared time has passed.
#       blink = total / 2 is a design rule. If someone sets blink = 3.0
#       for a level with total = 8.0, this breaks the 50% rule.
#
# How:  Loop through levels 1-20, check blink == total / 2 for each.
# -----------------------------------------------------------------------------
func test_blink_time_is_half_of_total() -> void:
	for lvl in range(1, 21):
		var times = pacman.get_intermission_times(lvl)
		assert_eq(times["blink"], times["total"] / 2.0,
			"Level %d: blink must be half of total" % lvl)


# -----------------------------------------------------------------------------
# TEST 3: Scared time never increases with higher levels
# -----------------------------------------------------------------------------
# Why:  The game must get harder as levels go up. If someone accidentally
#       gives level 5 more time than level 4, the difficulty drops.
#       This is an "invariant" — a rule that must ALWAYS be true.
#
# How:  Loop through levels 1-20, check that each total <= previous total.
# -----------------------------------------------------------------------------
func test_time_never_increases_with_level() -> void:
	var previous_total = 999.0

	for lvl in range(1, 21):
		var total = pacman.get_intermission_times(lvl)["total"]
		assert_lte(total, previous_total,
			"Level %d: time should not increase vs previous level" % lvl)
		previous_total = total
