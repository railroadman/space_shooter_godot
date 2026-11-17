class_name StartScreen
extends Control
## Title screen: animated space backdrop, title and blinking prompt. Enter or Space starts the game, O opens the options.

const GAME_SCENE := "res://scenes/game.tscn"
const OPTIONS_SCENE := "res://scenes/options_screen.tscn"

@onready var _blink: AnimationPlayer = $Blink


func _ready() -> void:
	DisplaySettings.load_and_apply()
	CrosshairSettings.load_and_apply()
	_blink.play(&"blink")


func _unhandled_input(event: InputEvent) -> void:
	var viewport := get_viewport() # taken first: changing the scene takes this node out of the tree
	if event.is_action_pressed("confirm") or event.is_action_pressed("shoot"):
		viewport.set_input_as_handled()
		get_tree().change_scene_to_file(GAME_SCENE)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_O:
		viewport.set_input_as_handled()
		get_tree().change_scene_to_file(OPTIONS_SCENE)
