class_name Difficulty
extends Node
## Counts game time (paused with the tree) and tells which difficulty stage applies. Enemies read it on every spawn.

var _elapsed := 0.0 # ms


func _physics_process(delta: float) -> void:
	_elapsed += delta * 1000.0


## Game time in ms.
func elapsed() -> float:
	return _elapsed


func stage() -> Dictionary:
	var current: Dictionary = Config.DIFFICULTY_STAGES[0]
	for candidate: Dictionary in Config.DIFFICULTY_STAGES:
		if candidate.from <= _elapsed:
			current = candidate
	return current


func enemy_health(base_health: float) -> float:
	return base_health + stage().health_bonus


## The enemy's base bullet settings overridden by the weapon preset of the current stage.
func enemy_weapon(kind: String, base: Dictionary, player: Node2D) -> Dictionary:
	var current := stage()
	var preset: Dictionary = Config.ENEMY_WEAPONS[current[kind]]
	var config := base.duplicate()
	config.merge(preset.get("bullet", {}), true)
	for key: String in preset:
		if key != "bullet" and key != "aim":
			config[key] = preset[key]
	if preset.get("aim", false):
		config.aim_target = player
	config.interval = base.interval * current.fire_scale
	return config
