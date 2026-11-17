class_name DisplaySettings
extends RefCounted
## Window mode and size, saved between runs in user://settings.cfg. `load_and_apply()` runs when the start screen opens.

const PATH := "user://settings.cfg"
const SECTION := "display"
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440),
]

static var fullscreen := false
static var resolution_index := 0


## Resolutions that fit on the current screen (the first one is always offered).
static func available() -> Array[Vector2i]:
	var screen := DisplayServer.screen_get_size()
	var result: Array[Vector2i] = []
	for size in RESOLUTIONS:
		if result.is_empty() or (size.x <= screen.x and size.y <= screen.y):
			result.append(size)
	return result


static func resolution() -> Vector2i:
	return available()[clampi(resolution_index, 0, available().size() - 1)]


static func load_and_apply() -> void:
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		fullscreen = file.get_value(SECTION, "fullscreen", false)
		var saved: Vector2i = file.get_value(SECTION, "resolution", RESOLUTIONS[0])
		resolution_index = maxi(0, available().find(saved))
	apply()


static func apply() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var size := resolution()
	DisplayServer.window_set_size(size)
	var screen := DisplayServer.screen_get_usable_rect()
	DisplayServer.window_set_position(screen.position + (screen.size - size) / 2)


static func save() -> void:
	var file := ConfigFile.new()
	file.load(PATH) # keep other sections (crosshair) of the same file
	file.set_value(SECTION, "fullscreen", fullscreen)
	file.set_value(SECTION, "resolution", resolution())
	file.save(PATH)


static func toggle_fullscreen() -> void:
	fullscreen = not fullscreen
	apply()
	save()


## Steps through the resolutions (wraps around) and applies the new one in windowed mode.
static func step_resolution(step: int) -> void:
	var count := available().size()
	resolution_index = posmod(resolution_index + step, count)
	apply()
	save()
