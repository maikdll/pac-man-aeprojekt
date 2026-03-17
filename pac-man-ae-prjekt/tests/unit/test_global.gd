extends GutTest

# =============================================================================
# test_global.gd
# Tests leaderboard logic: insertion, sorting, and trimming to top 5.
# File I/O (save/load) is intentionally NOT tested here to avoid disk errors.
# =============================================================================

var _original_leaderboard: Array = []
var _original_score: int = 0

func before_each() -> void:
	# Arrange: Save original state to restore it later
	_original_leaderboard = Global.leaderboard.duplicate(true)
	_original_score = Global.score

	# Start with a clean empty leaderboard for each test
	Global.leaderboard = []
	Global.score = 0

func after_each() -> void:
	# Clean up: Restore everything to avoid contaminating other tests
	Global.leaderboard = _original_leaderboard
	Global.score = _original_score

# -----------------------------------------------------------------------------
# TEST 1: Insertion and Sorting
# -----------------------------------------------------------------------------
func test_leaderboard_insertion_and_sorting() -> void:
	# Act: Add three entries in unsorted order
	Global.score = 100
	Global.update_leaderboard("Low")

	Global.score = 500
	Global.update_leaderboard("High")

	Global.score = 300
	Global.update_leaderboard("Mid")

	# Assert: Check size and descending order
	assert_eq(Global.leaderboard.size(), 3, "Should contain exactly 3 entries")
	assert_eq(Global.leaderboard[0]["name"], "High", "Highest score must be at index 0")
	assert_eq(Global.leaderboard[0]["score"], 500, "Highest score value must be 500")
	assert_eq(Global.leaderboard[1]["score"], 300, "Middle score must be at index 1")
	assert_eq(Global.leaderboard[2]["score"], 100, "Lowest score must be at index 2")

# -----------------------------------------------------------------------------
# TEST 2: Trimming (Keeping only Top 5)
# -----------------------------------------------------------------------------
func test_leaderboard_trims_to_top_5() -> void:
	# Arrange & Act: Add 6 entries
	var scores: Array = [100, 200, 300, 400, 500, 600]
	for i in range(scores.size()):
		Global.score = scores[i]
		Global.update_leaderboard("Player_" + str(scores[i]))

	# Assert: Check that leaderboard is capped at 5
	assert_eq(Global.leaderboard.size(), 5, "Leaderboard must not exceed 5 entries")
	
	# Assert: Check top and bottom scores of the remaining 5
	assert_eq(Global.leaderboard[0]["score"], 600, "1st place should be 600")
	assert_eq(Global.leaderboard[4]["score"], 200, "5th place should be 200")
	
	# Assert: Verify the lowest score (100) was successfully removed
	for entry in Global.leaderboard:
		assert_ne(entry["score"], 100, "Score 100 should have been dropped")
