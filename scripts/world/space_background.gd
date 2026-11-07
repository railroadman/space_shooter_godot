class_name SpaceBackground
extends Node2D
## The backdrop: plain star layers that follow the camera at different parallax, plus fast streaks that show while the
## player thrusts. The nebula photo and the drifting props are switched off (they were distracting).

var _thrust := 0.0 # eased 0..1, 1 while the ship flies
var _target_thrust := 0.0
var _heading := Vector2.UP # flight direction of the player

@onready var _photo: ScrollingLayer = $Photo
@onready var _props: SpaceProps = $Props
@onready var _streaks: Streaks = $Streaks


func _ready() -> void:
	_photo.hide()
	_props.hide()
	Events.player_moved.connect(func(_at: Vector2, angle: float) -> void: _heading = Vector2.UP.rotated(angle))
	Events.player_thrust.connect(func(is_thrusting: bool) -> void: _target_thrust = 1.0 if is_thrusting else 0.0)


func _process(delta: float) -> void:
	_thrust = lerpf(_thrust, _target_thrust, minf(1.0, Config.BACKGROUND_BOOST_SMOOTHING * delta))
	_streaks.advance(delta, _heading, _thrust)
