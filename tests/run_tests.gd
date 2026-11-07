extends Node
## Headless tests. Run from the project folder:
##   Godot_console.exe --headless --path . res://tests/run_tests.tscn
## Exit code 0 = all passed, 1 = some failed.

const DT := 1.0 / 60.0
const SIM_SECONDS := 20.0

var _failed := 0


func _ready() -> void:
	_test_inertia()
	await _test_enemy_spawning()
	print("\n%s" % ("ALL TESTS PASSED" if _failed == 0 else "%d CHECK(S) FAILED" % _failed))
	get_tree().quit(0 if _failed == 0 else 1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed += 1
	print("%s %s" % ["PASS" if condition else "FAIL", message])


# --- player inertia (pure math, no scene)

func _test_inertia() -> void:
	print("== inertia")
	var up := Vector2.UP
	var v := Vector2.ZERO
	for i in 120: # 2 s of holding the key
		v = Player.step_velocity(v, up, DT)
	_check(is_equal_approx(v.length(), Config.PLAYER_SPEED), "holding a key reaches top speed (%.1f)" % v.length())
	_check(v.normalized().is_equal_approx(up), "velocity points along the held direction")

	var released := v
	var after_one_second := released
	for i in 60: # 1 s of coasting
		after_one_second = Player.step_velocity(after_one_second, Vector2.ZERO, DT)
	_check(after_one_second.length() < released.length(), "coasting loses speed (%.1f -> %.1f)" % [released.length(), after_one_second.length()])
	_check(after_one_second.length() > released.length() * 0.7, "coasting does not brake hard (kept %.0f%% after 1 s)" % (100.0 * after_one_second.length() / released.length()))
	_check(after_one_second.normalized().is_equal_approx(released.normalized()), "coasting keeps the movement direction")

	var one_frame := Player.step_velocity(released, Vector2.ZERO, DT)
	_check(one_frame.length() > released.length() * 0.99, "no instant stop on key release")

	var coast := released
	var seconds := 0.0
	while coast != Vector2.ZERO and seconds < 60.0:
		coast = Player.step_velocity(coast, Vector2.ZERO, DT)
		seconds += DT
	_check(coast == Vector2.ZERO and seconds > 3.0, "ship eventually stops after a long drift (%.1f s)" % seconds)

	var turned := Player.step_velocity(released, Vector2.RIGHT, DT)
	_check(turned.x > 0.0 and turned.y < 0.0, "a side key bends the course instead of snapping it")


# --- enemy spawning in the real game scene

func _test_enemy_spawning() -> void:
	print("== enemy spawning (simulating %.0f s of game.tscn)" % SIM_SECONDS)
	var game: Node = load("res://scenes/game.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var player: Node2D = get_tree().get_first_node_in_group("player")
	_check(player != null and player.visible, "player is spawned and visible")
	_check(player.position == Vector2.ZERO, "player starts in the centre of the map")

	var seen := {} # enemy -> {first_distance, first_inside, start_gap}
	var quadrants := {}
	var max_alive := 0
	var closest := INF
	for frame in int(SIM_SECONDS / DT):
		await get_tree().physics_frame
		var enemies := get_tree().get_nodes_in_group("enemies")
		max_alive = maxi(max_alive, enemies.size())
		for enemy: Node2D in enemies:
			var gap := enemy.position.distance_to(player.position)
			closest = minf(closest, gap)
			if not seen.has(enemy):
				var view := Config.view_rect()
				seen[enemy] = {"first_gap": gap, "first_inside": view.has_point(enemy.global_position), "last_gap": gap,
					"quadrant": int((enemy.position - player.position).angle() / (PI / 2.0)) + 2}
				quadrants[seen[enemy].quadrant] = true
			seen[enemy].last_gap = gap
	var spawned := seen.size()
	print("   spawned=%d max_alive=%d closest=%.0f" % [spawned, max_alive, closest])
	_check(spawned > 0, "enemies spawn at all (%d seen)" % spawned)
	var any_inside := false
	var approached := 0
	for enemy: Node2D in seen:
		any_inside = any_inside or seen[enemy].first_inside
		if seen[enemy].last_gap < seen[enemy].first_gap:
			approached += 1
	_check(not any_inside, "every enemy first appears outside the visible area")
	_check(spawned < 6 or quadrants.size() >= 2, "enemies come from several sides (%d quadrants)" % quadrants.size())
	_check(approached > 0, "enemies fly toward the player (%d of %d got closer)" % [approached, spawned])
	_check(closest < Config.spawn_radius(), "enemies actually reach the screen (closest %.0f px)" % closest)

	game.queue_free()
	await get_tree().physics_frame
