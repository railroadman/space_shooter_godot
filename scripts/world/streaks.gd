class_name Streaks
extends Node2D
## Fast thin light streaks that fall through the background. The Sprite2D children are the streaks.

var _speeds: Array[float] = []


func _ready() -> void:
	for streak: Sprite2D in get_children():
		_speeds.append(0.0)
		_reset(streak, streak.get_index(), true)


func advance(delta: float, speed_multiplier: float) -> void:
	for i in _speeds.size():
		var streak: Sprite2D = get_child(i)
		streak.position.y += _speeds[i] * speed_multiplier * delta
		if streak.position.y - streak.texture.get_height() > Config.WORLD.y:
			_reset(streak, i, false)


func _reset(streak: Sprite2D, index: int, anywhere: bool) -> void:
	_speeds[index] = randf_range(Config.STREAK_SPEED.x, Config.STREAK_SPEED.y)
	streak.position = Vector2(
		randf() * Config.WORLD.x,
		randf() * Config.WORLD.y * (1.0 if anywhere else -1.0))
