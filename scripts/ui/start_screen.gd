class_name StartScreen
extends Control
## Title screen: animated space backdrop, title, blinking prompt. Enter or Space starts the game.

const GAME_SCENE := "res://scenes/game.tscn"

@onready var _prompt: Label = %Prompt
@onready var _blink: AnimationPlayer = $Blink


func _ready() -> void:
	_blink.play(&"blink")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm") or event.is_action_pressed("shoot"):
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file(GAME_SCENE)
