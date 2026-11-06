class_name BossSpawner
extends Node
## Brings the boss in once, after a random moment of game time: first a warning, then the boss flies in.

enum State { WAITING, WARNING, ACTIVE, DONE }

@export var boss_scene: PackedScene

var _state := State.WAITING
var _timer: float # ms


func _ready() -> void:
	var spawn: Dictionary = Config.BOSS.spawn
	_timer = randf_range(spawn.time_min, spawn.time_max)
	Events.game_over.connect(func() -> void: _state = State.DONE)
	Events.boss_defeated.connect(func() -> void: _state = State.DONE)


func _physics_process(delta: float) -> void:
	match _state:
		State.WAITING:
			_timer -= delta * 1000.0
			if _timer <= 0.0:
				_state = State.WARNING
				_timer = Config.BOSS.spawn.warning * 1000.0
				Events.boss_warning.emit()
		State.WARNING:
			_timer -= delta * 1000.0
			if _timer <= 0.0:
				_state = State.ACTIVE
				_spawn_boss()


func _spawn_boss() -> void:
	var boss: Boss = boss_scene.instantiate()
	boss.position = Vector2(Config.WORLD.x / 2.0, Config.BOSS.sprite.spawn_y)
	get_parent().add_child(boss)
	Events.boss_spawn.emit(boss)
