class_name ShieldEffect
extends Node2D
## The shield bubble around the ship; a ripple runs over it each time a hit is absorbed,
## and a burst plays when the last charge is gone.

const SHEET: Texture2D = preload("res://assets/images/misc/sheet_frames.png")
const COLUMNS := 4
const ROWS := 2
const FPS := 12.0
const DRAW_SCALE := 2.4  # frame size relative to the shield radius, so the bubble edge matches it

const END_SHEET: Texture2D = preload("res://assets/images/misc/shield_ended.png")
const END_COLUMNS := 5
const END_ROWS := 2
const END_FRAMES := 9  # the last row of the sheet is only partly filled
const END_FPS := 14.0
const END_SCALE := 0.2  # screen pixels per sheet pixel, so the burst bubble matches the live one

var _charges := 0
var _ripple_scale := 1.0
var _ripple_alpha := 0.0
var _frame := 0
var _ending := false
var _end_time := 0.0
var _tween: Tween


func _ready() -> void:
	hide()
	Events.shield_changed.connect(_on_shield_changed)


func _process(delta: float) -> void:
	if _ending:
		_end_time += delta
		if int(_end_time * END_FPS) >= END_FRAMES:
			_ending = false
			hide()
		queue_redraw()
		return
	var frame := int(Time.get_ticks_msec() * 0.001 * FPS) % (COLUMNS * ROWS)
	if frame != _frame:
		_frame = frame
		queue_redraw()


func _draw() -> void:
	if _ending:
		_draw_frame(END_SHEET, END_COLUMNS, END_ROWS, int(_end_time * END_FPS), END_SCALE)
		return
	var radius: float = Config.SHIELD.radius
	var color: Color = Config.SHIELD.color
	var cell := SHEET.get_size() / Vector2(COLUMNS, ROWS)
	var size := Vector2.ONE * radius * DRAW_SCALE
	_draw_frame(SHEET, COLUMNS, ROWS, _frame, size.x / cell.x)
	if _ripple_alpha > 0.0:
		draw_arc(Vector2.ZERO, radius * _ripple_scale, 0.0, TAU, 48, Color(color, _ripple_alpha), 3.0)


func _draw_frame(sheet: Texture2D, columns: int, rows: int, frame: int, pixel_scale: float) -> void:
	var cell := sheet.get_size() / Vector2(columns, rows)
	var src := Rect2(Vector2(frame % columns, frame / columns) * cell, cell)
	var size := cell * pixel_scale
	draw_texture_rect_region(sheet, Rect2(-size * 0.5, size), src)


func _on_shield_changed(charges: int, absorbed: bool) -> void:
	_charges = charges
	if charges == 0 and absorbed:
		_start_ending()
		return
	_ending = false
	visible = charges > 0
	modulate.a = 0.4 + 0.6 * charges / Config.SHIELD.charges
	if absorbed:
		_play_ripple()


func _start_ending() -> void:
	_ending = true
	_end_time = 0.0
	modulate.a = 1.0
	show()


func _play_ripple() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_method(_set_ripple, 0.0, 1.0, Config.SHIELD.ripple_time).set_ease(Tween.EASE_OUT)


func _set_ripple(progress: float) -> void:
	_ripple_scale = lerpf(1.0, 1.6, progress)
	_ripple_alpha = 1.0 - progress
	queue_redraw()
