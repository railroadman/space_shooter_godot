class_name CrosshairSettings
extends RefCounted
## Mouse cursor shown as the crosshair: one of the sprites in assets/images/crosshairs, saved between runs in
## user://settings.cfg. `load_and_apply()` runs when the start screen opens; the OS cursor keeps the shape in the game.

const SECTION := "crosshair"
const DIR := "res://assets/images/crosshairs/"
const COUNT := 72
const CURSOR_SIZE := 48
const CURSOR_ALPHA := 0.7

static var index := 0


static func texture(i: int) -> Texture2D:
	return load("%scrosshair_%02d.png" % [DIR, posmod(i, COUNT) + 1])


static func load_and_apply() -> void:
	var file := ConfigFile.new()
	if file.load(DisplaySettings.PATH) == OK:
		index = posmod(file.get_value(SECTION, "index", 0), COUNT)
	apply()


static func apply() -> void:
	var image := texture(index).get_image()
	image.resize(CURSOR_SIZE, CURSOR_SIZE, Image.INTERPOLATE_LANCZOS)
	for y in CURSOR_SIZE:
		for x in CURSOR_SIZE:
			var pixel := image.get_pixel(x, y)
			pixel.a *= CURSOR_ALPHA
			image.set_pixel(x, y, pixel)
	Input.set_custom_mouse_cursor(ImageTexture.create_from_image(image), Input.CURSOR_ARROW,
		Vector2(CURSOR_SIZE, CURSOR_SIZE) / 2.0)


## Makes crosshair `i` the cursor and saves the choice.
static func select(i: int) -> void:
	index = posmod(i, COUNT)
	apply()
	var file := ConfigFile.new()
	file.load(DisplaySettings.PATH) # keep the display settings stored in the same file
	file.set_value(SECTION, "index", index)
	file.save(DisplaySettings.PATH)
