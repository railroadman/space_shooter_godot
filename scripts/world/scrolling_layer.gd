class_name ScrollingLayer
extends Parallax2D
## A background layer that follows the camera slower than the world (`parallax`), which makes it look far away. Its
## Sprite2D child is repeated in both directions to cover the screen.

## Share of the camera movement the layer follows (0 = fixed in the world, 1 = moves with the world).
@export var parallax := 0.2
## Scale the picture to cover the view (nebula photos) instead of using the sprite scale as it is.
@export var fit_width := false

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	scroll_scale = Vector2.ONE * parallax
	set_texture(_sprite.texture)


func set_texture(texture: Texture2D) -> void:
	_sprite.texture = texture
	var view := Config.view_size()
	if fit_width:
		_sprite.scale = Vector2.ONE * maxf(view.x / texture.get_width(), view.y / texture.get_height())
	var tile := texture.get_size() * _sprite.scale
	repeat_size = tile
	repeat_times = ceili(maxf(view.x / tile.x, view.y / tile.y)) + 2
