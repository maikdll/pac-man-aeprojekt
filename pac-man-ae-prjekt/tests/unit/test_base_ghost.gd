extends GutTest

# =============================================================================
# test_base_ghost.gd
# =============================================================================
# WHAT we test:
#   ✅ Initial state — is_eaten, is_immune, is_in_house, current_mode
#      Important: the ghost starts in SCATTER mode inside the house.
#   ✅ start_wave(mode, duration) — switches current_mode.
#      When isReady=false (before leaving the house), wave_timer is NOT called,
#      so the function is safe to test without a scene.
#   ✅ get_speed_multiplier() — base ghost is always 1.0.
#      Each inheriting class overrides this (Red/Cyan/Pink/Orange).
#
# WHAT we DO NOT test and why:
#   ❌ leave_house()             — creates Timers, requires a scene
#   ❌ update_path()             — requires main_node (TileMap + AStar)
#   ❌ get_direction()           — accesses $AnimatedSprite2D
#   ❌ get_eaten()               — uses await + $AnimatedSprite2D
#   ❌ pick_new_scatter_target() — requires main_node.tile_map1
# =============================================================================

var _Script = load("res://scripts/Ghosts/BaseGhost.gd")
var ghost


func before_each() -> void:
	ghost = partial_double(_Script).new()
	# Stub everything that accesses the scene or nodes
	stub(ghost, "_ready").to_do_nothing()
	stub(ghost, "_process").to_do_nothing()
	stub(ghost, "update_path").to_do_nothing()
	stub(ghost, "pick_new_scatter_target").to_do_nothing()
	add_child_autoqfree(ghost)


# ─────────────────────────────────────────────────────────────────────────────
# Initial state
# ─────────────────────────────────────────────────────────────────────────────

func test_ghost_starts_inside_house() -> void:
	# The ghost should start in the house and not move until it leaves
	assert_true(ghost.is_in_house)

func test_ghost_starts_not_eaten() -> void:
	assert_false(ghost.is_eaten)

func test_ghost_starts_not_immune() -> void:
	# Immunity turns on AFTER returning home (get_eaten → revive)
	assert_false(ghost.is_immune)

func test_ghost_starts_not_ready() -> void:
	# isReady=true only after leave_house()
	assert_false(ghost.isReady)

func test_ghost_starts_in_scatter_mode() -> void:
	# All ghosts start in SCATTER (wandering) mode, not in CHASE (hunting)
	assert_eq(ghost.current_mode, ghost.Mode.SCATTER)

func test_ghost_initial_time_in_house_is_zero() -> void:
	assert_eq(ghost.current_time_in_house, 0.0)

func test_ghost_not_panicking_by_default() -> void:
	# was_intermission tracks the previous intermission status
	assert_false(ghost.was_intermission)


# ─────────────────────────────────────────────────────────────────────────────
# start_wave(mode, duration)
# When isReady=false → only changes current_mode, wave_timer is untouched.
# ─────────────────────────────────────────────────────────────────────────────

func test_start_wave_switches_to_chase() -> void:
	# Base case: switch to chase mode
	ghost.start_wave(ghost.Mode.CHASE, 20.0)
	assert_eq(ghost.current_mode, ghost.Mode.CHASE)

func test_start_wave_switches_to_scatter() -> void:
	ghost.current_mode = ghost.Mode.CHASE
	ghost.start_wave(ghost.Mode.SCATTER, 10.0)
	assert_eq(ghost.current_mode, ghost.Mode.SCATTER)

func test_start_wave_does_not_crash_before_ready() -> void:
	# isReady=false → wave_timer.start() is NOT called → no crash
	ghost.isReady = false
	ghost.start_wave(ghost.Mode.CHASE, 5.0)
	assert_eq(ghost.current_mode, ghost.Mode.CHASE)

func test_start_wave_can_be_called_multiple_times() -> void:
	ghost.start_wave(ghost.Mode.CHASE, 20.0)
	ghost.start_wave(ghost.Mode.SCATTER, 10.0)
	ghost.start_wave(ghost.Mode.CHASE, 15.0)
	assert_eq(ghost.current_mode, ghost.Mode.CHASE)


# ─────────────────────────────────────────────────────────────────────────────
# get_speed_multiplier()
# Base ghost = 1.0. Each inheriting class returns its own Global.speedGhostX.
# ─────────────────────────────────────────────────────────────────────────────

func test_base_speed_multiplier_is_one() -> void:
	assert_eq(ghost.get_speed_multiplier(), 1.0)
