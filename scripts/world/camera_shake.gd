class_name CameraShake
extends Camera2D
## Shakes the view on `Events.camera_shake` (duration in seconds, intensity as a share of the screen).

var _time_left := 0.0
var _intensity := 0.0


func _ready() -> void:
	Events.camera_shake.connect(_on_shake)


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left -= delta
	offset = Vector2.ZERO if _time_left <= 0.0 else Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _intensity * Config.WORLD


func _on_shake(duration: float, intensity: float) -> void:
	_time_left = duration
	_intensity = intensity
