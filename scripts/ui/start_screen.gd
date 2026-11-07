class_name StartScreen
extends Control
## Title screen: animated space backdrop, title, blinking prompt and a display settings menu. Enter or Space starts the
## game; Up/Down pick a setting, Left/Right change it (fullscreen or windowed, window resolution).

const GAME_SCENE := "res://scenes/game.tscn"
const ROWS := 2 # 0 = mode, 1 = resolution

var _row := 0

@onready var _prompt: Label = %Prompt
@onready var _blink: AnimationPlayer = $Blink
@onready var _settings: Label = %Settings


func _ready() -> void:
	DisplaySettings.load_and_apply()
	_blink.play(&"blink")
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	var viewport := get_viewport() # taken first: changing the scene takes this node out of the tree
	if event.is_action_pressed("confirm") or event.is_action_pressed("shoot"):
		viewport.set_input_as_handled()
		get_tree().change_scene_to_file(GAME_SCENE)
		return
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		_row = posmod(_row + (1 if event.is_action_pressed("ui_down") else -1), ROWS)
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		_change(1 if event.is_action_pressed("ui_right") else -1)
	else:
		return
	viewport.set_input_as_handled()
	_refresh()


func _change(step: int) -> void:
	if _row == 0:
		DisplaySettings.toggle_fullscreen()
	elif not DisplaySettings.fullscreen:
		DisplaySettings.step_resolution(step)


func _refresh() -> void:
	var size := DisplayServer.screen_get_size() if DisplaySettings.fullscreen else DisplaySettings.resolution()
	var mode := "FULLSCREEN" if DisplaySettings.fullscreen else "WINDOWED"
	var resolution := "%d x %d" % [size.x, size.y]
	_settings.text = "%s MODE:  < %s >\n%s RESOLUTION:  < %s >" % [
		">" if _row == 0 else " ", mode, ">" if _row == 1 else " ", resolution]
