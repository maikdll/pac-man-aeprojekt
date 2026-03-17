extends GutTest

# =============================================================================
# test_main.gd
# Tests pure logic and state-modifying functions of the Main scene.
# Node dependencies (TileMap, AStar) are intentionally excluded.
# =============================================================================

var _MainScript = load("res://scripts/main.gd")
var main_node

# Backup variables for Global state isolation
var _orig_level: int
var _orig_speed_p: float
var _orig_speed_g: float

func before_each() -> void:
	# Arrange: Create script instance without adding to tree (avoids @onready crashes)
	main_node = autofree(_MainScript.new())
	
	# Arrange: Backup Global state
	_orig_level = Global.level
	_orig_speed_p = float(Global.speedPlayer)
	_orig_speed_g = float(Global.speedGhost)

func after_each() -> void:
	# Clean up: Restore Global state
	Global.level = _orig_level
	Global.speedPlayer = _orig_speed_p
	Global.speedGhost = _orig_speed_g

# ---------------------------------------------------------
# TEST 1: Fruit Scores mapped by Level (Data-Driven)
# ---------------------------------------------------------
func test_get_fruit_score_logic() -> void:
	# Arrange: Dictionary mapping [Level -> Expected Score]
	var test_cases = {
		1: 200,   2: 600,   3: 1000,  4: 1000,
		5: 1400,  6: 1400,  7: 2000,  8: 2000,
		9: 4000,  10: 4000, 11: 6000, 12: 6000,
		13: 10000, 99: 10000 # Maxes out at 10000
	}
	
	var previous_score = 0
	
	# Act & Assert
	for lvl in test_cases.keys():
		var expected = test_cases[lvl]
		var result = main_node.get_fruit_score(lvl)
		
		# Rule 1: Exact score match
		assert_eq(result, expected, "Level %d fruit should give %d points" % [lvl, expected])
		
		# Rule 2: Score should never decrease as level goes up
		assert_gte(result, previous_score, "Score at level %d should not be lower than previous" % lvl)
		previous_score = result

# ---------------------------------------------------------
# TEST 2: Difficulty Scaling (Data-Driven)
# ---------------------------------------------------------
func test_set_difficulty_scaling() -> void:
	# Arrange: Define expected speeds for specific levels
	# Dictionary format: Level -> {"p": PlayerSpeed, "g": GhostSpeed}
	var test_cases = {
		1: {"p": 1.0, "g": 0.6},
		3: {"p": 1.4, "g": 0.8},
		8: {"p": 2.0, "g": 1.6},
		10: {"p": 2.0, "g": 2.0},
		15: {"p": 1.8, "g": 2.5} # Formula: 2 + (15 - 10) / 10.0 = 2.5
	}
	
	# Act & Assert
	for lvl in test_cases.keys():
		Global.level = lvl
		main_node.setDifficulty() # Modifies Global state
		
		var expected_p = test_cases[lvl]["p"]
		var expected_g = test_cases[lvl]["g"]
		
		# FIX: Use float() to avoid INT vs FLOAT comparison warnings
		assert_eq(float(Global.speedPlayer), float(expected_p), "Player speed at level %d is incorrect" % lvl)
		assert_eq(float(Global.speedGhost), float(expected_g), "Ghost speed at level %d is incorrect" % lvl)
