class_name Streaks
extends Node2D
## Fast thin light streaks that rush past the ship against its flight direction while it thrusts. The Sprite2D
## children are the streaks.

var _speeds: Array[float] = []
var _heading := Vector2.UP


func _ready() -> void:
	for streak: Sprite2D in get_children():
		_speeds.append(0.0)
		_reset(streak, streak.get_index(), true)


## `heading` is the flight direction; `intensity` (0..1) fades the streaks in while the ship thrusts.
func advance(delta: float, heading: Vector2, intensity: float) -> void:
	_heading = heading
	var radius := Config.view_size().length() / 2.0
	var center := Config.view_center()
	for i in _speeds.size():
		var streak: Sprite2D = get_child(i)
		streak.rotation = heading.angle() + PI / 2.0
		streak.modulate.a = 0.3 * intensity
		streak.position -= heading * _speeds[i] * delta
		if (streak.position - center).dot(heading) < -radius:
			_reset(streak, i, false)


## Places a streak on a line across the view; a fresh one starts ahead of the ship, an initial one anywhere.
func _reset(streak: Sprite2D, index: int, anywhere: bool) -> void:
	_speeds[index] = randf_range(Config.STREAK_SPEED.x, Config.STREAK_SPEED.y)
	var radius := Config.view_size().length() / 2.0
	var ahead := randf_range(-radius, radius) if anywhere else radius
	streak.position = Config.view_center() + _heading * ahead + _heading.orthogonal() * randf_range(-radius, radius)
