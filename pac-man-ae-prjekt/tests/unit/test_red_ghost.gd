extends GutTest

# =============================================================================
# test_red_ghost.gd — Unit tests for RedGhost.gd (Blinky)
#
# Focused on: get_speed_multiplier() and the conditional logic in _on_wave_timeout()
# =============================================================================

var _Script = load("res://scripts/Ghosts/RedGhost.gd")
var ghost
var _orig_remaining: int

func before_each() -> void:
	# Using partial_double to keep original logic while allowing stubs on specific methods
	ghost = partial_double(_Script).new()
	
	# Stubbing internal engine/base methods to prevent side effects during unit tests
	stub(ghost, "_ready").to_do_nothing()
	stub(ghost, "_process").to_do_nothing()
	stub(ghost, "update_path").to_do_nothing()
	stub(ghost, "pick_new_scatter_target").to_do_nothing()
	stub(ghost, "start_wave").to_do_nothing() # We want to check arguments passed here

	# Setup required child node for audio logic in _on_wave_timeout
	var audio := AudioStreamPlayer2D.new()
	audio.name = "AudioStreamPlayer2D"
	ghost.add_child(audio)

	add_child_autoqfree(ghost)
	ghost.isReady = false
	
	# Save Global state to restore after test
	_orig_remaining = Global.remainingPoints

func after_each() -> void:
	Global.remainingPoints = _orig_remaining


# -----------------------------------------------------------------------------
# Speed Logic
# -----------------------------------------------------------------------------
func test_speed_multiplier_reflects_global_variable() -> void:
	Global.speedGhostRed = 1.8
	assert_eq(ghost.get_speed_multiplier(), 1.8, "Should return current Global speed")


# -----------------------------------------------------------------------------
# Wave Logic: Normal Behavior (>= 50 points)
# -----------------------------------------------------------------------------
func test_on_wave_timeout_switches_to_chase_normally() -> void:
	ghost.current_mode = ghost.Mode.SCATTER
	Global.remainingPoints = 100
	
	ghost._on_wave_timeout()
	
	# Verify it switched to CHASE with standard duration (20.0)
	assert_called(ghost, "start_wave", [ghost.Mode.CHASE, 20.0])

func test_on_wave_timeout_switches_to_scatter_normally() -> void:
	ghost.current_mode = ghost.Mode.CHASE
	Global.remainingPoints = 100
	
	ghost._on_wave_timeout()
	
	# Verify it switched to SCATTER with standard duration (10.0)
	assert_called(ghost, "start_wave", [ghost.Mode.SCATTER, 10.0])


# -----------------------------------------------------------------------------
# Wave Logic: "Cruise Elroy" / Permanent Chase (< 50 points)
# -----------------------------------------------------------------------------
func test_boundary_49_triggers_permanent_chase() -> void:
	# Even if currently in CHASE, it should restart with a long duration (200.0)
	ghost.current_mode = ghost.Mode.CHASE
	Global.remainingPoints = 49
	
	ghost._on_wave_timeout()
	
	# Logic check: < 50 points triggers "Dauerangriff"
	assert_called(ghost, "start_wave", [ghost.Mode.CHASE, 200.0])

func test_boundary_50_still_allows_normal_scatter() -> void:
	# At exactly 50, the ghost should still follow normal patterns
	ghost.current_mode = ghost.Mode.CHASE
	Global.remainingPoints = 50
	
	ghost._on_wave_timeout()
	
	# Should NOT trigger 200.0 duration; should go to SCATTER
	assert_called(ghost, "start_wave", [ghost.Mode.SCATTER, 10.0])
