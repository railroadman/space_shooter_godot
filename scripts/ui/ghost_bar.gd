class_name GhostBar
extends Control
## Health bar: a white "ghost" trails a loss, a short flash marks a hit or a heal. Used for the player and the boss.

@export var back_color := Color("04101c")
@export var ghost_color := Color.WHITE
@export var border := 2.0
@export var ghost_delay := 400.0 # ms before the ghost starts to follow
@export var ghost_speed := 0.6 # fractions per second
@export var heal_speed := 1.0 # fractions per second
@export var hit_flash_color := Color.WHITE
@export var hit_flash_time := 80.0
@export var heal_flash_color := Color("c8ffd8")
@export var heal_flash_time := 300.0
## Player style: green / yellow / red by the remaining health. Otherwise `fill_color` is used.
@export var color_by_health := false

var fill_color := Color.WHITE

var _target := 1.0
var _fraction := 1.0
var _ghost := 1.0
var _ghost_timer := 0.0
var _flash_time := 0.0
var _flash_color := Color.WHITE


## Sets the health share (0..1): a loss shows at once, a heal fills the bar over time.
func set_target(value: float) -> void:
	value = clampf(value, 0.0, 1.0)
	if value < _fraction:
		_fraction = value
		_ghost_timer = ghost_delay
		_flash(hit_flash_color, hit_flash_time)
	elif value > _target:
		_flash(heal_flash_color, heal_flash_time)
	_target = value


func reset(value: float = 1.0) -> void:
	_target = value
	_fraction = value
	_ghost = value
	_flash_time = 0.0


func _process(delta: float) -> void:
	var dt := delta * 1000.0
	if _fraction < _target:
		_fraction = minf(_target, _fraction + heal_speed * delta)
	_flash_time = maxf(0.0, _flash_time - dt)
	_ghost_timer -= dt
	if _ghost < _fraction:
		_ghost = _fraction
	elif _ghost_timer <= 0.0:
		_ghost = maxf(_fraction, _ghost - ghost_speed * delta)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2(-border, -border), size + Vector2.ONE * border * 2.0), Color(back_color, 0.85))
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * _ghost, size.y)), Color(ghost_color, 0.7))
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * _fraction, size.y)), _flash_color if _flash_time > 0.0 else _fill())


func _fill() -> Color:
	if not color_by_health:
		return fill_color
	if _fraction < 0.25:
		return Color("ff4f6a")
	return Color("ffd24f") if _fraction < 0.5 else Color("4fff8a")


func _flash(color: Color, time: float) -> void:
	_flash_color = color
	_flash_time = time
