extends Node
## Combat balance simulation: a bot plays game.tscn and reports how it fares. Run:
##   Godot_console.exe --headless --path . res://tests/sim_combat.tscn
## Strategies: "idle" (only shoots), "chase" (flies at the nearest enemy, shooting all the time).

const DT := 1.0 / 60.0
const SECONDS := 90.0
const RUNS := 3
const STRATEGIES := ["idle", "chase"]
const KEYS := ["move_left", "move_right", "move_up", "move_down"]

var _kills := 0
var _lives_lost := 0
var _first_loss := -1.0
var _time := 0.0
var _is_over := false
var _bullet_hits := 0
var _shots_fired := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Events.game_over.connect(func() -> void: _is_over = true)
	Events.bullet_hit.connect(func(hit: Dictionary) -> void: _bullet_hits += 0 if hit.has("enemy") else 1)
	Events.ship_shoot.connect(func() -> void: _shots_fired += 1)
	Events.enemy_destroyed.connect(func(_enemy: Node2D) -> void: _kills += 1)
	Events.player_destroyed.connect(_on_player_destroyed)
	for strategy: String in STRATEGIES:
		for run in RUNS:
			await _simulate(strategy, run)
	get_tree().quit()


func _on_player_destroyed() -> void:
	_lives_lost += 1
	if _first_loss < 0.0:
		_first_loss = _time


func _simulate(strategy: String, run: int) -> void:
	_kills = 0
	_lives_lost = 0
	_first_loss = -1.0
	_time = 0.0
	_is_over = false
	_bullet_hits = 0
	_shots_fired = 0
	get_tree().paused = false # a finished run leaves the tree paused by the game over screen
	var game: Node = load("res://scenes/game.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var player: Node2D = get_tree().get_first_node_in_group("player")
	var min_health := 100.0
	for frame in int(SECONDS / DT):
		await get_tree().physics_frame
		_time += DT
		_drive(strategy, player)
		if player.visible:
			min_health = minf(min_health, player.health.life)
		if _is_over:
			break
	_release_keys()
	print("%-5s run %d: %s after %.0fs | kills=%d lives_lost=%d first_loss=%s enemy_bullet_hits=%d shots=%d" % [
		strategy, run, "GAME OVER" if _is_over else "alive", _time, _kills, _lives_lost,
		"%.0fs" % _first_loss if _first_loss >= 0.0 else "never", _bullet_hits, _shots_fired])
	game.queue_free()
	await get_tree().physics_frame


func _drive(strategy: String, player: Node2D) -> void:
	Input.action_press("shoot")
	_release_keys()
	if strategy != "chase" or not player.visible:
		return
	var target: Node2D
	var best := INF
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		var distance := enemy.position.distance_to(player.position)
		if distance < best and enemy.is_alive():
			best = distance
			target = enemy
	if target == null:
		return
	var to_target := (target.position - player.position).normalized()
	if to_target.x < -0.38:
		Input.action_press("move_left")
	elif to_target.x > 0.38:
		Input.action_press("move_right")
	if to_target.y < -0.38:
		Input.action_press("move_up")
	elif to_target.y > 0.38:
		Input.action_press("move_down")


func _release_keys() -> void:
	for key: String in KEYS:
		Input.action_release(key)
