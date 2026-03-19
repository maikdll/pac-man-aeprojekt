extends GutTest

var _Script = load("res://scripts/Ghosts/OrangeGhost.gd")
var ghost
var pacman

func before_each():
	ghost = partial_double(_Script).new()
	# Bulk stubbing to save space
	for m in ["_ready", "update_path", "pick_new_scatter_target", "start_wave"]:
		stub(ghost, m).to_do_nothing()
	
	pacman = add_child_autoqfree(Node2D.new())
	ghost.pacman = pacman
	ghost.current_scatter_target = Vector2(1000, 1000)
	add_child_autoqfree(ghost)

# -----------------------------------------------------------------------------
# Basic Stats & Mode Cycling
# -----------------------------------------------------------------------------
func test_basics():
	Global.speedGhostOrange = 1.4
	assert_eq(ghost.get_speed_multiplier(), 1.4, "Should use Global.speedGhostOrange")
	
	ghost.current_mode = ghost.Mode.SCATTER
	ghost._on_wave_timeout()
	assert_called(ghost, "start_wave", [ghost.Mode.CHASE, 20.0])

# -----------------------------------------------------------------------------
# Panic Logic Flow (Clyde's signature behavior)
# -----------------------------------------------------------------------------
func test_panic_logic_flow():
	ghost.current_mode = ghost.Mode.CHASE
	
	# 1. Trigger Panic: Pacman is close (< 150px)
	pacman.global_position = Vector2(100, 0)
	assert_eq(ghost.get_custom_target(), ghost.current_scatter_target, "Target should be corner when close")
	assert_true(ghost.is_panicking)
	
	# 2. Hysteresis: Stay panicking in 'gray zone' (300px is < 500px)
	pacman.global_position = Vector2(300, 0)
	ghost.get_custom_target()
	assert_true(ghost.is_panicking, "Panic should persist until 500px distance")
	
	# 3. Resume Chase: Pacman is far (> 500px)
	pacman.global_position = Vector2(600, 0)
	assert_eq(ghost.get_custom_target(), pacman.global_position, "Target should be Pacman when far")
	assert_false(ghost.is_panicking)
	
	# 4. Forced Reset: Scatter mode kills panic state
	ghost.is_panicking = true
	ghost.current_mode = ghost.Mode.SCATTER
	ghost.get_custom_target()
	assert_false(ghost.is_panicking, "Scatter mode must override/reset panic")
