extends Node
## Combat balance simulation: a bot plays game.tscn and reports how it fares. Run:
##   Godot_console.exe --headless --path . res://tests/sim_combat.tscn
## Strategies: "idle" (only shoots), "chase" (flies at the nearest enemy, shooting all the time),
## "survive" (dodges enemy bullets and ships, shoots all the time).
## Override with user args: ... res://tests/sim_combat.tscn -- survive 600 1   (strategy, seconds, runs)

const DT := 1.0 / 60.0
const DODGE_RADIUS := 260.0
const SHIP_RADIUS := 200.0
const KEEP_RANGE := 280.0

var _seconds := 90.0
var _runs := 3
var _strategies := ["idle", "chase"]
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
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_strategies = [args[0]]
	if args.size() > 1:
		_seconds = float(args[1])
	if args.size() > 2:
		_runs = int(args[2])
	for strategy: String in _strategies:
		for run in _runs:
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
	for frame in int(_seconds / DT):
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
	if strategy == "survive":
		_drive_survive(player)
		return
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


func _drive_survive(player: Node2D) -> void:
	if not player.visible:
		return
	var steer := Vector2.ZERO
	var target: Node2D
	var best := INF
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if not enemy.is_alive():
			continue
		var away := player.position - enemy.position
		var distance := away.length()
		if distance < best:
			best = distance
			target = enemy
		if distance < SHIP_RADIUS:
			steer += away.normalized() * (SHIP_RADIUS - distance) / SHIP_RADIUS * 2.0
	var pool: Node = get_tree().get_first_node_in_group("bullets")
	for bullet: Bullet in pool.get_children():
		if not bullet.visible or bullet.collision_layer != Config.LAYER_ENEMY_BULLET:
			continue
		var rel := player.position - bullet.position
		var distance := rel.length()
		if distance > DODGE_RADIUS or bullet.velocity.length() < 1.0:
			continue
		var along := rel.dot(bullet.velocity.normalized())
		if along < 0.0:
			continue # already past
		var lateral := rel - bullet.velocity.normalized() * along
		if lateral.length() < 60.0:
			var side := lateral.normalized() if lateral.length() > 1.0 else bullet.velocity.orthogonal().normalized()
			steer += side * (1.0 - distance / DODGE_RADIUS) * 3.0
	if steer.length() < 0.15 and target != null: # safe: hold a firing distance
		var to_target := target.position - player.position
		steer = to_target.normalized() * (1.0 if best > KEEP_RANGE else -0.5)
	if steer.x < -0.3:
		Input.action_press("move_left")
	elif steer.x > 0.3:
		Input.action_press("move_right")
	if steer.y < -0.3:
		Input.action_press("move_up")
	elif steer.y > 0.3:
		Input.action_press("move_down")


func _release_keys() -> void:
	for key: String in KEYS:
		Input.action_release(key)
