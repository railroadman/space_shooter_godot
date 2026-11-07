class_name CameraShake
extends Camera2D
## Follows the player (centred on the ship, via `Events.player_moved`) and shakes the view on `Events.camera_shake`
## (duration in seconds, intensity as a share of the screen).

var _time_left := 0.0
var _intensity := 0.0


func _ready() -> void:
	Events.player_moved.connect(func(at: Vector2, _rotation: float) -> void: global_position = at)
	Events.camera_shake.connect(_on_shake)


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left -= delta
	offset = Vector2.ZERO if _time_left <= 0.0 else Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _intensity * Config.view_size()


func _on_shake(duration: float, intensity: float) -> void:
	_time_left = duration
	_intensity = intensity
