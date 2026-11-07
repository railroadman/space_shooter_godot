class_name OverlayScreen
extends CanvasLayer
## A full-screen message over the paused game (pause, game over, level complete). While open the tree is paused;
## the screen itself keeps running. `restart` screens start a new run on Enter, the pause screen resumes on Esc.

@export var title := "PAUSED"
@export var hint := ""
@export var title_style: LabelSettings
@export var restart := true
@export_range(0.0, 1.0) var dim_alpha := 0.75

@onready var _title: Label = %Title
@onready var _hint: Label = %Hint
@onready var _dim: ColorRect = $Dim


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_title.text = title
	_title.label_settings = title_style
	_hint.text = hint
	_dim.color.a = dim_alpha
	hide()


func open() -> void:
	show()
	get_tree().paused = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var viewport := get_viewport() # taken first: reloading the scene takes this node out of the tree
	if restart and event.is_action_pressed("confirm"):
		get_tree().paused = false
		get_tree().reload_current_scene()
	elif not restart and event.is_action_pressed("pause"):
		hide()
		get_tree().paused = false
	else:
		return
	viewport.set_input_as_handled()
