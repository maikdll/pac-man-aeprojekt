extends GutTest

# =============================================================================
# test_global.gd
# =============================================================================
# WHAT we test:
#   ✅ update_leaderboard() appends a new entry with the current score
#   ✅ Entries are sorted in descending order by score
#   ✅ After 6 entries only the top 5 are kept (slice to 5)
#   ✅ The lowest-scoring entry is removed when the leaderboard overflows
#   ✅ Entry names are stored correctly alongside scores
#
# WHAT we do NOT test and why:
#   ❌ save_leaderboard() / load_leaderboard() - file I/O, writes to user://
#      These are tested implicitly (save is called inside update_leaderboard),
#      but we do not assert file contents here.
#   ❌ Global._ready() / socket / WebSocket - network, not unit testable
#
# NOTE: Global is an autoload singleton. We must restore leaderboard and score
# in after_each() to avoid affecting other test files.
# =============================================================================

var _original_leaderboard: Array = []
var _original_score: int = 0


func before_each() -> void:
	# Save original state so we can restore it after each test.
	_original_leaderboard = Global.leaderboard.duplicate(true)
	_original_score = Global.score

	# Start with a clean empty leaderboard for each test.
	Global.leaderboard = []
	Global.score = 0


func after_each() -> void:
	# Restore everything to avoid contaminating other tests.
	Global.leaderboard = _original_leaderboard
	Global.score = _original_score


# -----------------------------------------------------------------------------
# Basic insertion
# -----------------------------------------------------------------------------

func test_entry_is_added_to_leaderboard() -> void:
	Global.score = 100
	Global.update_leaderboard("Alice")
	assert_eq(Global.leaderboard.size(), 1)

func test_entry_has_correct_name() -> void:
	Global.score = 50
	Global.update_leaderboard("Bob")
	assert_eq(Global.leaderboard[0]["name"], "Bob")

func test_entry_has_correct_score() -> void:
	Global.score = 250
	Global.update_leaderboard("Carol")
	assert_eq(Global.leaderboard[0]["score"], 250)


# -----------------------------------------------------------------------------
# Sorting (descending by score)
# -----------------------------------------------------------------------------

func test_entries_sorted_descending() -> void:
	# Add three entries in unsorted order.
	Global.score = 100
	Global.update_leaderboard("Low")

	Global.score = 500
	Global.update_leaderboard("High")

	Global.score = 300
	Global.update_leaderboard("Mid")

	# After each call, leaderboard is re-sorted.
	assert_eq(Global.leaderboard[0]["score"], 500)
	assert_eq(Global.leaderboard[1]["score"], 300)
	assert_eq(Global.leaderboard[2]["score"], 100)

func test_first_entry_is_highest_score() -> void:
	Global.score = 10
	Global.update_leaderboard("Worst")
	Global.score = 9999
	Global.update_leaderboard("Best")
	assert_eq(Global.leaderboard[0]["name"], "Best")


# -----------------------------------------------------------------------------
# Trimming to top 5
# -----------------------------------------------------------------------------

func test_leaderboard_keeps_max_5_entries() -> void:
	# Add 6 entries with distinct scores.
	var scores: Array = [100, 200, 300, 400, 500, 600]
	for i in range(scores.size()):
		Global.score = scores[i]
		Global.update_leaderboard("Player" + str(i))
	assert_eq(Global.leaderboard.size(), 5)

func test_lowest_score_is_removed_on_overflow() -> void:
	# Add 6 entries; the one with score=100 is the lowest.
	var scores: Array = [100, 200, 300, 400, 500, 600]
	for i in range(scores.size()):
		Global.score = scores[i]
		Global.update_leaderboard("P" + str(i))

	# Top 5 should be 600, 500, 400, 300, 200. Score 100 is dropped.
	for entry in Global.leaderboard:
		assert_true(entry["score"] >= 200, "score 100 should have been removed")

func test_top_5_have_correct_scores_after_overflow() -> void:
	var scores: Array = [50, 150, 250, 350, 450, 550]
	for i in range(scores.size()):
		Global.score = scores[i]
		Global.update_leaderboard("X")

	assert_eq(Global.leaderboard[0]["score"], 550)
	assert_eq(Global.leaderboard[1]["score"], 450)
	assert_eq(Global.leaderboard[2]["score"], 350)
	assert_eq(Global.leaderboard[3]["score"], 250)
	assert_eq(Global.leaderboard[4]["score"], 150)

func test_exactly_5_entries_are_all_kept() -> void:
	# Exactly 5 entries - no trimming should occur.
	for i in range(5):
		Global.score = (i + 1) * 10
		Global.update_leaderboard("Player" + str(i))
	assert_eq(Global.leaderboard.size(), 5)
