class_name ScrollingLayer
extends Parallax2D
## A background layer that scrolls down forever. Its Sprite2D child is repeated vertically to cover the screen.

## Scroll speed in px/s at normal flight.
@export var base_speed := 8.0
## Scale the picture to the width of the world (nebula photos) instead of using the sprite scale as it is.
@export var fit_width := false

@onready var _sprite: Sprite2D = $Sprite

var speed_multiplier := 1.0:
	set(value):
		speed_multiplier = value
		autoscroll = Vector2(0.0, base_speed * value)


func _ready() -> void:
	set_texture(_sprite.texture)


func set_texture(texture: Texture2D) -> void:
	_sprite.texture = texture
	if fit_width:
		_sprite.scale = Vector2.ONE * Config.WORLD.x / texture.get_width()
	var tile_height := texture.get_height() * _sprite.scale.y
	repeat_size = Vector2(0.0, tile_height)
	repeat_times = ceili(Config.WORLD.y / tile_height) + 2
	autoscroll = Vector2(0.0, base_speed * speed_multiplier)
