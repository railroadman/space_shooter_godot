class_name FxSprite
extends AnimatedSprite2D
## A pooled one-shot animation: plays its frames once, then returns to the pool.

var pool: Pool


func _ready() -> void:
	animation_finished.connect(func() -> void: pool.release(self))


func play_once(frames: SpriteFrames, at: Vector2, scale_factor: float) -> void:
	sprite_frames = frames
	position = at
	scale = Vector2.ONE * scale_factor
	play(&"default")
