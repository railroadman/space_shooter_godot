class_name PopupText
extends Label
## A pooled floating text ("+100", "+SHIELD") that rises and fades.

var pool: Pool


## `at` is the middle of the text; it is kept inside the screen.
func show_text(message: String, at: Vector2) -> void:
	text = message
	reset_size()
	var margin := Config.UI_POPUP_EDGE_MARGIN
	position = Vector2(clampf(at.x, margin, Config.WORLD.x - margin), at.y) - size / 2.0
	modulate.a = 1.0
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - Config.UI_POPUP_RISE, Config.UI_POPUP_TIME).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, Config.UI_POPUP_TIME).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(pool.release.bind(self))
