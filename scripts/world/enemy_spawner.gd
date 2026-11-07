class_name EnemySpawner
extends Node
## Spawns formations (single, line, V) of one enemy kind on a ring just outside the screen, from a random side, at
## intervals scaled by the difficulty stage. Stops while the boss is around and after the game is over.

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


## The ships line up along the tangent of the ring at a random angle; a V staggers its wings in time.
func _spawn_formation(formation: Dictionary) -> void:
	var outward := Vector2.from_angle(randf() * TAU)
	var tangent := outward.orthogonal()
	var center := Config.view_center() + outward * Config.spawn_radius()
	var half: float = (formation.count - 1) / 2.0
	for i in formation.count:
		var offset: float = i - half
		var at := center + tangent * offset * Config.FORMATION_SPACING_X
		var delay := absf(offset) * Config.FORMATION_STAGGER_DELAY if formation.type == "v" else 0.0
		if delay == 0.0:
			_spawn_one(at)
		else:
			get_tree().create_timer(delay).timeout.connect(_spawn_one.bind(at))


func _spawn_one(at: Vector2) -> void:
	if _is_disabled or _is_boss_active:
		return
	var enemy: Enemy = _pool.acquire()
	enemy.spawn(at)
