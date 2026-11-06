class_name Hud
extends CanvasLayer
## Heads-up display: score, game time, lives with the health bar, weapon slots and the boss warning.
## The layout (anchors, containers) lives in the scene; this script only feeds it values.

@export var life_icon: Texture2D

var _elapsed := 0.0 # seconds of play
var _shown_seconds := -1
var _player: Player

@onready var _score: Label = %Score
@onready var _timer: Label = %Timer
@onready var _lives: HBoxContainer = %Lives
@onready var _health_bar: GhostBar = %HealthBar
@onready var _warning: Label = %Warning


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_score.pivot_offset = Vector2(_score.size.x, _score.size.y / 2.0)
	_set_lives(Config.PLAYER_LIVES)
	_warning.hide()
	Events.score_changed.connect(_on_score_changed)
	Events.lives_changed.connect(_set_lives)
	Events.boss_warning.connect(_show_warning)
	Events.boss_spawn.connect(func(_boss: Node2D) -> void: _warning.hide())


func _process(delta: float) -> void:
	_elapsed += delta
	var seconds := int(_elapsed)
	if seconds != _shown_seconds:
		_shown_seconds = seconds
		_timer.text = "%d:%02d" % [seconds / 60, seconds % 60]
	_health_bar.set_target(_player.health.life / Config.PLAYER_HEALTH)


func _on_score_changed(score: int) -> void:
	_score.text = str(score).pad_zeros(Config.UI_SCORE_DIGITS)
	var tween := create_tween()
	tween.tween_property(_score, "scale", Vector2.ONE * 1.25, 0.12).set_ease(Tween.EASE_OUT)
	tween.tween_property(_score, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_IN)


## Shows `count` life icons; a new one pops in.
func _set_lives(count: int) -> void:
	while _lives.get_child_count() > count:
		var last := _lives.get_child(_lives.get_child_count() - 1)
		_lives.remove_child(last)
		last.queue_free()
	while _lives.get_child_count() < count:
		var icon := TextureRect.new()
		icon.texture = life_icon
		icon.custom_minimum_size = Vector2.ONE * 29.0
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_lives.add_child(icon)
		icon.pivot_offset = icon.custom_minimum_size / 2.0
		icon.scale = Vector2.ZERO
		create_tween().tween_property(icon, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_warning() -> void:
	_warning.text = Config.BOSS.warning_text
	_warning.show()
	var blink := create_tween().set_loops()
	blink.tween_property(_warning, "modulate:a", 0.15, Config.BOSS.warning_blink)
	blink.tween_property(_warning, "modulate:a", 1.0, Config.BOSS.warning_blink)
	Events.boss_spawn.connect(func(_boss: Node2D) -> void: blink.kill(), CONNECT_ONE_SHOT)
