extends GutTest

# =============================================================================
# test_global.gd — Unit tests for Global.gd logic
# =============================================================================

var _GlobalScript = load("res://scripts/Global.gd") 
var test_global
var _original_score: int = 0

func before_each() -> void:
	# Create a partial double (mock) of the Global script
	test_global = partial_double(_GlobalScript).new()
	
	# Disable side effects: WebSocket (_ready), file I/O (save_leaderboard)
	stub(test_global, "_ready").to_do_nothing()
	stub(test_global, "save_leaderboard").to_do_nothing()
	
	add_child_autoqfree(test_global)
	
	# Start with a clean slate
	test_global.leaderboard = []
	
	# IMPORTANT: update_leaderboard() reads Global.score (the singleton),
	# not test_global.score. So we must set the singleton's score.
	_original_score = Global.score
	Global.score = 0

func after_each() -> void:
	# Restore the real Global.score so tests don't affect the game
	Global.score = _original_score

# -----------------------------------------------------------------------------
# TEST 1: The table cannot contain more than 5 entries
# -----------------------------------------------------------------------------
# Reason: update_leaderboard() must trim the array using .slice(0, 5).
# If this fails, the leaderboard will grow infinitely and lag the game.
# -----------------------------------------------------------------------------
func test_leaderboard_keeps_only_top_5() -> void:
	var scores = [100, 300, 200, 600, 400, 500]
	for s in scores:
		Global.score = s  # update_leaderboard() reads Global.score (singleton)
		test_global.update_leaderboard("P" + str(s))

	assert_eq(test_global.leaderboard.size(), 5, "The table must contain exactly 5 entries")


# -----------------------------------------------------------------------------
# TEST 2: Results are sorted descending (Best score first)
# -----------------------------------------------------------------------------
# Reason: sort_custom must use a["score"] > b["score"].
# If the logic is flipped (< instead of >), the worst player becomes #1.
# -----------------------------------------------------------------------------
func test_leaderboard_sorted_descending() -> void:
	var scores = [100, 300, 200, 600, 400, 500]
	for s in scores:
		Global.score = s
		test_global.update_leaderboard("P" + str(s))

	assert_eq(test_global.leaderboard[0]["score"], 600, "1st place must be the highest score")
	assert_eq(test_global.leaderboard[4]["score"], 200, "5th place must be the lowest of the Top 5")


# -----------------------------------------------------------------------------
# TEST 3: The weakest score is dropped
# -----------------------------------------------------------------------------
# Reason: When 6 entries are added, the absolute lowest must be removed.
# This ensures only the elite players stay on the board.
# -----------------------------------------------------------------------------
func test_lowest_score_is_dropped() -> void:
	var scores = [100, 300, 200, 600, 400, 500]
	for s in scores:
		Global.score = s
		test_global.update_leaderboard("P" + str(s))

	# Verify that the minimum score (100) is nowhere in the top 5
	for entry in test_global.leaderboard:
		assert_ne(entry["score"], 100, "Score 100 should have been dropped from the Top 5")


# -----------------------------------------------------------------------------
# TEST 4: Player name is saved correctly
# -----------------------------------------------------------------------------
# Reason: update_leaderboard() must map the name argument to the dictionary.
# If lost, the board will show empty strings or "Null" instead of names.
# -----------------------------------------------------------------------------
func test_player_name_is_saved() -> void:
	Global.score = 500
	test_global.update_leaderboard("TestPlayer")

	assert_eq(test_global.leaderboard[0]["name"], "TestPlayer", "The player name must be correctly saved")
