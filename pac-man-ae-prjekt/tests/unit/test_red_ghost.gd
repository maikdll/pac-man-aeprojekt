extends GutTest

# =============================================================================
# test_red_ghost.gd
# =============================================================================
# WHAT we test:
#   ✅ get_speed_multiplier() - returns Global.speedGhostRed.
#      Each ghost subclass has its own speed variable in Global.
#      This verifies Red uses the correct one.
#   ✅ _on_wave_timeout() - mode switching logic (SCATTER <-> CHASE).
#      Key rule: if remainingPoints < 50, Blinky switches to permanent CHASE.
#      We stub pick_new_scatter_target() and update_path() since they need main_node.
#
# WHAT we do NOT test and why:
#   ❌ get_custom_target() in CHASE mode - requires pacman.global_position
#      and pacman is null when _ready() is stubbed (handled in orange ghost tests)
#   ❌ Permanent chase audio ($AudioStreamPlayer2D) - needs AudioStreamPlayer node
# =============================================================================

var _Script = load("res://scripts/Ghosts/RedGhost.gd")
var ghost


func before_each() -> void:
	ghost = partial_double(_Script).new()
	stub(ghost, "_ready").to_do_nothing()
	stub(ghost, "_process").to_do_nothing()
	stub(ghost, "update_path").to_do_nothing()
	stub(ghost, "pick_new_scatter_target").to_do_nothing()

	# _on_wave_timeout() accesses $AudioStreamPlayer2D when remainingPoints < 50.
	# We add a real node with the correct name so the path resolves without crashing.
	var audio := AudioStreamPlayer2D.new()
	audio.name = "AudioStreamPlayer2D"
	ghost.add_child(audio)

	add_child_autoqfree(ghost)

	ghost.isReady = false  # wave_timer is not initialized, keep it safe
	ghost.current_mode = ghost.Mode.SCATTER


# -----------------------------------------------------------------------------
# get_speed_multiplier()
# Red ghost (Blinky) uses Global.speedGhostRed, not the base 1.0.
# -----------------------------------------------------------------------------

func test_speed_multiplier_matches_global_red() -> void:
	Global.speedGhostRed = 1.0
	assert_eq(ghost.get_speed_multiplier(), 1.0)

func test_speed_multiplier_reflects_global_change() -> void:
	# If the global speed changes, the multiplier must update immediately.
	Global.speedGhostRed = 1.8
	assert_eq(ghost.get_speed_multiplier(), 1.8)
	Global.speedGhostRed = 1.0  # restore


# -----------------------------------------------------------------------------
# _on_wave_timeout() - mode switching
#
# Rules:
#   SCATTER -> CHASE (normal, remainingPoints >= 50): 20 second chase
#   SCATTER -> CHASE (many eaten, remainingPoints < 50): 200 second permanent chase
#   CHASE   -> SCATTER (normal, remainingPoints >= 50): 10 second scatter
#   CHASE   -> CHASE  (many eaten, remainingPoints < 50): stay in chase
# -----------------------------------------------------------------------------

func test_scatter_to_chase_when_points_remaining() -> void:
	ghost.current_mode = ghost.Mode.SCATTER
	Global.remainingPoints = 100  # enough points left
	ghost._on_wave_timeout()
	assert_eq(ghost.current_mode, ghost.Mode.CHASE)

func test_chase_to_scatter_when_points_remaining() -> void:
	ghost.current_mode = ghost.Mode.CHASE
	Global.remainingPoints = 100
	ghost._on_wave_timeout()
	assert_eq(ghost.current_mode, ghost.Mode.SCATTER)

func test_scatter_stays_chase_when_few_points_left() -> void:
	# When fewer than 50 points remain, Blinky enters permanent chase.
	ghost.current_mode = ghost.Mode.SCATTER
	Global.remainingPoints = 30  # < 50
	ghost._on_wave_timeout()
	assert_eq(ghost.current_mode, ghost.Mode.CHASE)

func test_chase_stays_chase_when_few_points_left() -> void:
	# Already chasing + few points = stays in chase (permanent mode).
	ghost.current_mode = ghost.Mode.CHASE
	Global.remainingPoints = 10  # < 50
	ghost._on_wave_timeout()
	assert_eq(ghost.current_mode, ghost.Mode.CHASE)

func test_boundary_49_points_triggers_permanent_chase() -> void:
	# Exactly 49 points remaining -> permanent chase threshold
	ghost.current_mode = ghost.Mode.CHASE
	Global.remainingPoints = 49
	ghost._on_wave_timeout()
	assert_eq(ghost.current_mode, ghost.Mode.CHASE)

func test_boundary_50_points_allows_scatter() -> void:
	# Exactly 50 points -> normal scatter allowed
	ghost.current_mode = ghost.Mode.CHASE
	Global.remainingPoints = 50
	ghost._on_wave_timeout()
	assert_eq(ghost.current_mode, ghost.Mode.SCATTER)
