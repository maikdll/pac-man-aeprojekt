extends GutTest

# =============================================================================
# test_main.gd — Unit tests for main.gd
#
# TESTED:     get_fruit_score(level), setDifficulty()
# NOT TESTED: _ready, spawn_points, spawn_fruit (TileMap, AStar, await)
#             checkAllPointsEaten (await, SceneTransition)
# =============================================================================

var _MainScript = load("res://scripts/main.gd")
var main_node

# Backup Global state so tests don't affect the game
var _orig_level: int
var _orig_speed_p: float
var _orig_speed_g: float

func before_each() -> void:
	# autofree() creates the node but does NOT add it to the scene tree,
	# so _ready() never runs and @onready vars stay null.
	# That's fine — get_fruit_score() and setDifficulty() don't need them.
	main_node = autofree(_MainScript.new())
	
	# Backup Global state (setDifficulty reads/writes Global singleton)
	_orig_level = Global.level
	_orig_speed_p = float(Global.speedPlayer)
	_orig_speed_g = float(Global.speedGhost)

func after_each() -> void:
	Global.level = _orig_level
	Global.speedPlayer = _orig_speed_p
	Global.speedGhost = _orig_speed_g


# -----------------------------------------------------------------------------
# TEST 1: Exact fruit score for each level tier
# -----------------------------------------------------------------------------
# Why:  get_fruit_score() maps level -> points for eating a fruit.
#       If someone changes level 5 from 1400 to 1000, this catches it.
#
# How:  Dictionary of [level -> expected score]. Checks every tier boundary.
# -----------------------------------------------------------------------------
func test_get_fruit_score_exact_values() -> void:
	var test_cases = {
		1: 200,   2: 600,   3: 1000,  4: 1000,
		5: 1400,  6: 1400,  7: 2000,  8: 2000,
		9: 4000,  10: 4000, 11: 6000, 12: 6000,
		13: 10000, 99: 10000  # Level 13+ is capped at maximum
	}

	for lvl in test_cases.keys():
		var result = main_node.get_fruit_score(lvl)
		assert_eq(result, test_cases[lvl],
			"Level %d fruit should give %d points" % [lvl, test_cases[lvl]])


# -----------------------------------------------------------------------------
# TEST 2: Fruit score never decreases with higher levels
# -----------------------------------------------------------------------------
# Why:  Fruits must be worth more (or equal) as the game gets harder.
#       If level 7 accidentally gives less than level 6, this catches it.
#
# How:  Loop levels 1-20, check each score >= previous score.
# -----------------------------------------------------------------------------
func test_fruit_score_never_decreases() -> void:
	var previous_score = 0

	for lvl in range(1, 21):
		var result = main_node.get_fruit_score(lvl)
		assert_gte(result, previous_score,
			"Fruit score at level %d should not be lower than previous" % lvl)
		previous_score = result


# -----------------------------------------------------------------------------
# TEST 3: Difficulty scaling — exact speeds per level
# -----------------------------------------------------------------------------
# Why:  setDifficulty() sets Global.speedPlayer and Global.speedGhost
#       based on Global.level. Wrong values = game too easy or impossible.
#
# How:  Set Global.level, call setDifficulty(), check the resulting speeds.
#       Note: setDifficulty() reads/writes Global singleton directly.
# -----------------------------------------------------------------------------
func test_set_difficulty_scaling() -> void:
	var test_cases = {
		1:  {"p": 1.0, "g": 0.6},
		3:  {"p": 1.4, "g": 0.8},
		8:  {"p": 2.0, "g": 1.6},
		10: {"p": 2.0, "g": 2.0},
		15: {"p": 1.8, "g": 2.5}  # Formula: 2 + (15-10)/10.0 = 2.5
	}

	for lvl in test_cases.keys():
		Global.level = lvl
		main_node.setDifficulty()
		
		# float() avoids INT vs FLOAT comparison warnings in GUT
		assert_eq(float(Global.speedPlayer), float(test_cases[lvl]["p"]),
			"Player speed at level %d" % lvl)
		assert_eq(float(Global.speedGhost), float(test_cases[lvl]["g"]),
			"Ghost speed at level %d" % lvl)
