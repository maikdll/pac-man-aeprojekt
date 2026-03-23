extends GutTest

# =============================================================================
# test_start_menu.gd — Unit tests for start_menu.gd
#
# TESTED:     start_game() — must reset all Global state for a new game
# NOT TESTED: _ready, _process, _build_ui, animations (scene nodes)
# =============================================================================

var _MenuScript = load("res://scripts/UI/start_menu.gd")
var menu

func before_each() -> void:
	menu = partial_double(_MenuScript).new()
	stub(menu, "_ready").to_do_nothing()
	add_child_autoqfree(menu)


# -----------------------------------------------------------------------------
# start_game() must reset ALL game state to defaults
# -----------------------------------------------------------------------------
# Why:  If any variable is not reset, the new game starts with old data
#       (e.g. score from previous run, 0 lives, wrong level).
#
# How:  Set Global to a "dirty" mid-game state, call start_game(), verify reset.
# -----------------------------------------------------------------------------
func test_start_game_resets_globals() -> void:
	# Simulate a finished game: level 5, no lives, high score
	Global.level = 5
	Global.score = 1000
	Global.health = 0
	Global.isIntermissionMode = true

	menu.start_game()

	assert_eq(Global.level, 1, "Level must reset to 1")
	assert_eq(Global.score, 0, "Score must reset to 0")
	assert_eq(Global.health, 3, "Must start with 3 lives")
	assert_false(Global.isIntermissionMode, "Intermission must be off")
