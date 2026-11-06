class_name Game
extends Node2D
## One run of the game: owns the lives, respawns the player, and opens the pause, game over and level end screens.

@export var game_over_screen: OverlayScreen
@export var level_end_screen: OverlayScreen
@export var pause_screen: OverlayScreen

var _lives := Config.PLAYER_LIVES


func _ready() -> void:
	Events.player_destroyed.connect(_on_player_destroyed)
	Events.extra_life.connect(_on_extra_life)
	Events.boss_defeated.connect(_on_boss_defeated)
	Events.player_spawn.emit.call_deferred() # after everything is ready


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_screen.open()
		get_viewport().set_input_as_handled()


func _on_player_destroyed() -> void:
	_lives -= 1
	Events.lives_changed.emit(_lives)
	Events.camera_shake.emit(Config.PLAYER_DEATH_SHAKE.x, Config.PLAYER_DEATH_SHAKE.y)
	if _lives > 0:
		get_tree().create_timer(Config.PLAYER_RESPAWN_DELAY).timeout.connect(Events.player_spawn.emit)
		return
	Events.game_over.emit()
	game_over_screen.open()


func _on_extra_life() -> void:
	_lives += 1
	Events.lives_changed.emit(_lives)


func _on_boss_defeated() -> void:
	await get_tree().create_timer(Config.BOSS.victory_delay).timeout
	if not game_over_screen.visible:
		level_end_screen.open()
