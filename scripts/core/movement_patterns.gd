class_name MovementPatterns
extends RefCounted
## Trajectory strategies of bots. The bot always steers toward its target (heading); each
## `update(dt_ms, me, target, out)` writes `out.lateral` (-1..1, share of the sideways speed, perpendicular to the
## heading) and `out.speed_scale` (multiplier of the forward speed).


class Pattern extends RefCounted:
	func reset() -> void:
		pass

	func update(_dt: float, _me: Node2D, _target: Node2D, _out: Dictionary) -> void:
		pass


## Straight at the target.
class Steady extends Pattern:
	func update(_dt: float, _me: Node2D, _target: Node2D, out: Dictionary) -> void:
		out.lateral = 0.0
		out.speed_scale = 1.0


## Sine wave left and right of the heading.
class Wave extends Pattern:
	var _period: float
	var _elapsed := 0.0

	func _init(period: float) -> void:
		_period = period

	func reset() -> void:
		_elapsed = randf_range(0.0, _period)

	func update(dt: float, _me: Node2D, _target: Node2D, out: Dictionary) -> void:
		_elapsed += dt
		out.lateral = sin(TAU * _elapsed / _period)
		out.speed_scale = 1.0


## Changes sideways direction at random intervals.
class Zigzag extends Pattern:
	var _interval: float
	var _smoothing: float
	var _direction := 1.0
	var _axis := 0.0
	var _timer := 0.0

	func _init(interval: float, smoothing: float) -> void:
		_interval = interval
		_smoothing = smoothing

	func reset() -> void:
		_direction = 1.0 if randf() < 0.5 else -1.0
		_axis = 0.0
		_timer = _next_interval()

	func update(dt: float, _me: Node2D, _target: Node2D, out: Dictionary) -> void:
		_timer -= dt
		if _timer <= 0.0:
			_direction = -_direction
			_timer = _next_interval()
		_axis += (_direction - _axis) * minf(1.0, _smoothing * dt / 1000.0)
		out.lateral = _axis
		out.speed_scale = 1.0

	func _next_interval() -> float:
		return _interval * randf_range(Config.ENEMY_ZIGZAG_SCALE.x, Config.ENEMY_ZIGZAG_SCALE.y)


## Decorator: the base pattern plus telegraphed dashes (wind-up, then a fast dive).
class Dash extends Pattern:
	enum State { IDLE, WINDUP, DASH }

	var _base: Pattern
	var _options: Dictionary
	var _state := State.IDLE
	var _timer := 0.0

	func _init(base: Pattern, options: Dictionary) -> void:
		_base = base
		_options = options

	func reset() -> void:
		_base.reset()
		_state = State.IDLE
		_timer = _next_cooldown()

	func update(dt: float, me: Node2D, target: Node2D, out: Dictionary) -> void:
		_base.update(dt, me, target, out)
		if target == null or not target.visible:
			return
		_timer -= dt
		match _state:
			State.IDLE:
				if _timer <= 0.0:
					_state = State.WINDUP
					_timer = _options.windup
			State.WINDUP:
				out.lateral *= _options.windup_axis_factor
				out.speed_scale = _options.windup_speed_scale
				if _timer <= 0.0:
					_state = State.DASH
					_timer = _options.duration
			State.DASH:
				out.lateral *= _options.axis_boost
				out.speed_scale = _options.speed_boost
				if _timer <= 0.0:
					_state = State.IDLE
					_timer = _next_cooldown()

	func _next_cooldown() -> float:
		return float(randi_range(_options.cooldown_min, _options.cooldown_max))
