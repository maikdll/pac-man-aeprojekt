extends GutTest

# =============================================================================
# test_pacman.gd
# Tests the pure logic functions of PacMan.
# Physics, inputs, and Area2D collisions are omitted as they require 
# integration testing with the scene tree.
# =============================================================================

var _PacManScript = load("res://scripts/PacMan.gd")
var pacman

func before_each() -> void:
	# Arrange: Create a stubbed PacMan instance to avoid engine physics errors
	pacman = partial_double(_PacManScript).new()
	stub(pacman, "_ready").to_do_nothing()
	stub(pacman, "_process").to_do_nothing()
	stub(pacman, "_physics_process").to_do_nothing()
	add_child_autoqfree(pacman)

# ---------------------------------------------------------
# TEST 1: Intermission Times mapped by Level (Data-Driven)
# ---------------------------------------------------------
func test_get_intermission_times_exact_values() -> void:
	# Arrange: A dictionary mapping [Level -> Expected Total Time]
	var test_cases = {
		1: 10.0,
		2: 9.0,
		3: 8.0,
		4: 7.0,
		5: 6.0,  8: 6.0,    # Tier 5-8
		9: 5.0,  16: 5.0,   # Tier 9-16
		17: 4.0, 99: 4.0    # Capped at level 17+
	}
	
	# Act & Assert: Loop through all critical levels
	for lvl in test_cases.keys():
		var expected_time = test_cases[lvl]
		var result = pacman.get_intermission_times(lvl)
		
		assert_eq(result["total"], expected_time, "Total time for level %d should be %s" % [lvl, expected_time])

# ---------------------------------------------------------
# TEST 2: Mathematical Rules (Invariants)
# ---------------------------------------------------------
func test_intermission_time_mathematical_rules() -> void:
	var previous_total = 999.0 # Arbitrary high starting number
	
	# Act & Assert: Check a continuous range of levels from 1 to 20
	for lvl in range(1, 20):
		var times = pacman.get_intermission_times(lvl)
		var total = times["total"]
		var blink = times["blink"]
		
		# Rule 1: Blink time must ALWAYS be exactly half of the total time
		assert_eq(blink, total / 2.0, "Level %d: Blink time must be half of total time" % lvl)
		
		# Rule 2: Game must only get harder (time must decrease or stay equal)
		assert_lte(total, previous_total, "Level %d: Time should not increase compared to previous level" % lvl)
		
		previous_total = total
