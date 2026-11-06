class_name SpaceBackground
extends Node2D
## The whole backdrop: a nebula photo (fades out and in as another one now and then), three star layers, drifting props
## and fast streaks. All of it speeds up while the player thrusts forward.

## Nebula photos to choose from; one is picked at random per run.
@export var photos: Array[Texture2D] = []

var _speed_multiplier := 1.0
var _target_multiplier := 1.0
var _switch_in := Config.BACKGROUND_IMAGE_SWITCH # seconds
var _photo_index := 0
var _layers: Array[ScrollingLayer] = []

@onready var _photo: ScrollingLayer = $Photo
@onready var _props: SpaceProps = $Props
@onready var _streaks: Streaks = $Streaks


func _ready() -> void:
	for child in get_children():
		if child is ScrollingLayer:
			_layers.append(child)
	_photo_index = randi() % photos.size()
	_photo.set_texture(photos[_photo_index])
	_photo.modulate.a = Config.BACKGROUND_IMAGE_ALPHA
	Events.player_thrust.connect(func(is_thrusting: bool) -> void: _target_multiplier = Config.BACKGROUND_BOOST if is_thrusting else 1.0)


func _process(delta: float) -> void:
	_speed_multiplier = lerpf(_speed_multiplier, _target_multiplier, minf(1.0, Config.BACKGROUND_BOOST_SMOOTHING * delta))
	_switch_in -= delta
	if _switch_in <= 0.0:
		_switch_in = Config.BACKGROUND_IMAGE_SWITCH
		_switch_photo()
	for layer in _layers:
		layer.speed_multiplier = _speed_multiplier
	_props.advance(delta, _speed_multiplier)
	_streaks.advance(delta, _speed_multiplier)


## Fades the photo out, swaps it while it is invisible and fades the new one in. The two photos never overlap.
func _switch_photo() -> void:
	if photos.size() < 2:
		return
	_photo_index = (_photo_index + randi_range(1, photos.size() - 1)) % photos.size()
	var half := Config.BACKGROUND_IMAGE_FADE / 2.0
	var tween := create_tween()
	tween.tween_property(_photo, "modulate:a", 0.0, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void: _photo.set_texture(photos[_photo_index]))
	tween.tween_property(_photo, "modulate:a", Config.BACKGROUND_IMAGE_ALPHA, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
