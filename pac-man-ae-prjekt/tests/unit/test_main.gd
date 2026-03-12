extends GutTest

# =============================================================================
# test_main.gd
# =============================================================================
# WHAT we test:
#   ✅ get_fruit_score(level) — a perfect pure function.
#      Takes a level, returns the score for the fruit. No nodes, no 
#      side effects. The best example for a unit test in this project.
#
# WHAT we DO NOT test and why:
#   ❌ setDifficulty()       — changes Global.speed*, requires isolation between tests
#   ❌ spawn_points()        — requires TileMap + AStarGrid2D
#   ❌ checkAllPointsEaten() — uses await + call_group + change_scene
#   ❌ spawn_fruit()         — uses await + $Fruit node
#
# HOW IT WORKS:
#   We create main via autofree() without add_child — _ready() is not called.
#   This means @onready variables = null. But get_fruit_score() doesn't use them.
# =============================================================================

var _MainScript = load("res://scripts/main.gd")
var main_node


func before_each() -> void:
	# Create an instance without adding it to the scene tree.
	# _ready() will not be called → @onready vars = null → we don't care,
	# because get_fruit_score() is a pure function (if/elif chain).
	main_node = autofree(_MainScript.new())


# ─────────────────────────────────────────────────────────────────────────────
# get_fruit_score(level) — fruit score for each level
# ─────────────────────────────────────────────────────────────────────────────

func test_fruit_score_level_1_is_cherry() -> void:
	# Level 1 — cherry, 200 points
	assert_eq(main_node.get_fruit_score(1), 200)

func test_fruit_score_level_2_is_strawberry() -> void:
	# Level 2 — strawberry, 600 points
	assert_eq(main_node.get_fruit_score(2), 600)

func test_fruit_score_level_3_and_4_are_orange() -> void:
	# Levels 3-4 — orange, 1000 points
	assert_eq(main_node.get_fruit_score(3), 1000)
	assert_eq(main_node.get_fruit_score(4), 1000)

func test_fruit_score_level_5_and_6_are_apple() -> void:
	# Levels 5-6 — apple, 1400 points
	assert_eq(main_node.get_fruit_score(5), 1400)
	assert_eq(main_node.get_fruit_score(6), 1400)

func test_fruit_score_level_7_and_8_are_melon() -> void:
	# Levels 7-8 — melon, 2000 points
	assert_eq(main_node.get_fruit_score(7), 2000)
	assert_eq(main_node.get_fruit_score(8), 2000)

func test_fruit_score_level_9_and_10() -> void:
	# Levels 9-10 — 4000 points
	assert_eq(main_node.get_fruit_score(9), 4000)
	assert_eq(main_node.get_fruit_score(10), 4000)

func test_fruit_score_level_11_and_12() -> void:
	# Levels 11-12 — 6000 points
	assert_eq(main_node.get_fruit_score(11), 6000)
	assert_eq(main_node.get_fruit_score(12), 6000)

func test_fruit_score_high_levels_max_out() -> void:
	# Level 13 and above — 10000 points (max, does not increase)
	assert_eq(main_node.get_fruit_score(13), 10000)
	assert_eq(main_node.get_fruit_score(99), 10000)

func test_fruit_score_increases_with_level() -> void:
	# The score should increase with the level (or remain the same, but not decrease)
	var prev: int = main_node.get_fruit_score(1)
	for lvl in [2, 3, 5, 7, 9, 11, 13]:
		var curr: int = main_node.get_fruit_score(lvl)
		assert_gte(curr, prev, "Level %d score should be >= level before" % lvl)
		prev = curr
