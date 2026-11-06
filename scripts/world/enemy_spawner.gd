class_name EnemySpawner
extends Node
## Spawns formations (single, line, V) of one enemy kind at intervals scaled by the difficulty stage.
## Stops while the boss is around and after the game is over.

@export_enum("scout", "fighter") var kind := "scout"

var _def: Dictionary
var _timer: float # ms until the next formation
var _is_disabled := false
var _is_boss_active := false
var _difficulty: Difficulty

@onready var _pool: Pool = $Pool


func _ready() -> void:
	_def = Config.ENEMIES[kind]
	_timer = _def.spawn_start
	_difficulty = get_tree().get_first_node_in_group("difficulty")
	Events.game_over.connect(func() -> void: _is_disabled = true)
	Events.boss_warning.connect(func() -> void: _is_boss_active = true)
	Events.boss_defeated.connect(_on_boss_defeated)


func _physics_process(delta: float) -> void:
	if _is_disabled or _is_boss_active:
		return
	_timer -= delta * 1000.0
	if _timer > 0.0:
		return
	_spawn_formation(_def.formations.pick_random())
	_timer = _def.spawn_interval * _difficulty.stage().spawn_scale


func _on_boss_defeated() -> void:
	_is_boss_active = false
	_timer = Config.BOSS.spawn.resume_delay * 1000.0


func _spawn_formation(formation: Dictionary) -> void:
	var half: float = (formation.count - 1) / 2.0
	var span := half * Config.FORMATION_SPACING_X
	var center := randf_range(Config.SPAWN_MARGIN_X + span, Config.WORLD.x - Config.SPAWN_MARGIN_X - span)
	for i in formation.count:
		var offset: float = i - half
		var x: float = center + offset * Config.FORMATION_SPACING_X
		var delay := absf(offset) * Config.FORMATION_STAGGER_DELAY if formation.type == "v" else 0.0
		if delay == 0.0:
			_spawn_one(x)
		else:
			get_tree().create_timer(delay).timeout.connect(_spawn_one.bind(x))


func _spawn_one(x: float) -> void:
	if _is_disabled or _is_boss_active:
		return
	var enemy: Enemy = _pool.acquire()
	enemy.spawn(Vector2(x, Config.SPAWN_OFFSET_Y))
