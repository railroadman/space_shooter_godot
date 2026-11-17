class_name OptionsScreen
extends Control
## Options: window mode and resolution, the crosshair that replaces the mouse cursor, and the key bindings.
## Click a crosshair to choose it; Esc or Back returns.

const START_SCENE := "res://scenes/start_screen.tscn"
const COLUMNS := 12
const BUTTON_SIZE := 56

@onready var _grid: GridContainer = %Grid
@onready var _mode: Button = %Mode
@onready var _resolution: Button = %Resolution


func _ready() -> void:
	_grid.columns = COLUMNS
	var group := ButtonGroup.new()
	for i in CrosshairSettings.COUNT:
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.icon = CrosshairSettings.texture(i)
		button.expand_icon = true
		button.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
		button.button_pressed = i == CrosshairSettings.index
		button.pressed.connect(CrosshairSettings.select.bind(i))
		_grid.add_child(button)
	_mode.pressed.connect(_toggle_mode)
	_resolution.pressed.connect(_next_resolution)
	%Back.pressed.connect(_back)
	_mode.grab_focus()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back()


func _toggle_mode() -> void:
	DisplaySettings.toggle_fullscreen()
	_refresh()


func _next_resolution() -> void:
	DisplaySettings.step_resolution(1)
	_refresh()


func _refresh() -> void:
	var size := DisplayServer.screen_get_size() if DisplaySettings.fullscreen else DisplaySettings.resolution()
	_mode.text = "MODE:  %s" % ("FULLSCREEN" if DisplaySettings.fullscreen else "WINDOWED")
	_resolution.text = "RESOLUTION:  %d x %d" % [size.x, size.y]
	_resolution.disabled = DisplaySettings.fullscreen


func _back() -> void:
	get_tree().change_scene_to_file(START_SCENE)
