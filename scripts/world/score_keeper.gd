class_name ScoreKeeper
extends Node
## Adds the score of destroyed enemies, grants extra lives and floats the "+N" popups.

var score := 0

@onready var _popups: Pool = $Popups


func _ready() -> void:
	Events.enemy_destroyed.connect(_on_enemy_destroyed)


func _on_enemy_destroyed(enemy: Node2D) -> void:
	var points: int = enemy.score_value
	var extra_lives := (score + points) / Config.PLAYER_EXTRA_LIFE_SCORE - score / Config.PLAYER_EXTRA_LIFE_SCORE
	score += points
	for i in extra_lives:
		Events.extra_life.emit()
	Events.score_changed.emit(score)
	var popup: PopupText = _popups.acquire()
	popup.show_text("+%d" % points, enemy.position)
