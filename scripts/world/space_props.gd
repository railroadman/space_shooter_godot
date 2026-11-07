class_name SpaceProps
extends Node2D
## Nebula clouds and planets that float across the endless space and fade in and out. The Sprite2D children are the
## pool; they appear on a ring around the camera and cross toward it. A planet is never picked twice in a row and
## never overlaps another planet.

## Cloud textures; planets are loaded from Config.PLANET_NAMES.
@export var nebulae: Array[Texture2D] = []

const NEBULA_WEIGHT := 1.0
const PLANET_WEIGHT := 0.3
const NEBULA_SCALE := Vector2(1.6, 2.8)
const PLANET_SCALE := Vector2(0.35, 0.8)
const NEBULA_ALPHA := 0.45
const PLANET_ALPHA := 0.95
const FADE_IN_TIME := 3.0 # seconds
const AIM_SPREAD := 0.5 # rad, how far a prop's course may miss the camera

var _spawn_in := Config.PROP_FIRST_SPAWN # ms
var _last_texture: Texture2D
var _planets: Array[Texture2D] = []
var _velocities: Dictionary = {} # Sprite2D -> px/s
var _ages: Dictionary = {} # Sprite2D -> seconds since it appeared
var _alphas: Dictionary = {} # Sprite2D -> opacity at full visibility
var _is_planet: Dictionary = {} # Sprite2D -> bool


func _ready() -> void:
	for planet: String in Config.PLANET_NAMES:
		_planets.append(load("res://assets/images/planets/planet_%s.png" % planet))
	for prop: Sprite2D in get_children():
		prop.visible = false


func advance(delta: float) -> void:
	_spawn_in -= delta * 1000.0
	if _spawn_in <= 0.0:
		_spawn_in = Config.PROP_SPAWN_INTERVAL * randf_range(0.7, 1.3) if _spawn() else Config.PROP_RETRY_DELAY
	var center := Config.view_center()
	for prop: Sprite2D in get_children():
		if not prop.visible:
			continue
		var far := _ring_radius() + _half_height(prop) * 2.0 # gone when it left the view on the far side
		prop.position += _velocities[prop] * delta
		_ages[prop] += delta
		var distance := prop.position.distance_to(center)
		if distance > far:
			prop.visible = false
			continue
		var fade_in := clampf(_ages[prop] / FADE_IN_TIME, 0.0, 1.0)
		var fade_out := clampf((far - distance) / Config.PROP_FADE_DISTANCE, 0.0, 1.0)
		prop.modulate.a = _alphas[prop] * minf(fade_in, fade_out)


## Starts one prop; false when there is no free sprite or a planet found no free place.
func _spawn() -> bool:
	var prop := _free_prop()
	if prop == null:
		return false
	var texture := _pick_texture()
	var is_planet := _planets.has(texture)
	var scale_range := PLANET_SCALE if is_planet else NEBULA_SCALE
	prop.texture = texture
	prop.scale = Vector2.ONE * randf_range(scale_range.x, scale_range.y)
	prop.rotation_degrees = randf() * 360.0
	var place := _find_place(prop, is_planet)
	if place.is_empty():
		return false
	_last_texture = texture
	_velocities[prop] = place.velocity
	_ages[prop] = 0.0
	_alphas[prop] = PLANET_ALPHA if is_planet else NEBULA_ALPHA
	_is_planet[prop] = is_planet
	prop.position = place.position
	prop.modulate.a = 0.0
	prop.visible = true
	return true


func _free_prop() -> Sprite2D:
	for prop: Sprite2D in get_children():
		if not prop.visible:
			return prop
	return null


## Weighted random texture, never the one picked last.
func _pick_texture() -> Texture2D:
	var choices: Array[Texture2D] = []
	var weights: Array[float] = []
	for texture in nebulae:
		choices.append(texture)
		weights.append(NEBULA_WEIGHT)
	for texture in _planets:
		choices.append(texture)
		weights.append(PLANET_WEIGHT)
	var last := choices.find(_last_texture)
	if last >= 0:
		weights[last] = 0.0
	return choices[_weighted_index(weights)]


func _weighted_index(weights: Array[float]) -> int:
	var roll: float = randf() * weights.reduce(func(sum: float, weight: float) -> float: return sum + weight, 0.0)
	for i in weights.size():
		roll -= weights[i]
		if roll < 0.0:
			return i
	return weights.size() - 1


## A spot on the ring around the camera with a course across the view. A planet needs a spot clear of the other
## planets. Returns {position, velocity} or an empty dictionary.
func _find_place(prop: Sprite2D, is_planet: bool) -> Dictionary:
	var center := Config.view_center()
	var radius := _half_height(prop)
	for attempt in 8:
		var angle := randf() * TAU
		var spot := center + Vector2.from_angle(angle) * (_ring_radius() + radius)
		if is_planet and _touches_planet(prop, spot, radius):
			continue
		var course := (center - spot).normalized().rotated(randf_range(-AIM_SPREAD, AIM_SPREAD))
		return {"position": spot, "velocity": course * randf_range(Config.PROP_SPEED.x, Config.PROP_SPEED.y)}
	return {}


func _touches_planet(planet: Sprite2D, spot: Vector2, radius: float) -> bool:
	for other: Sprite2D in get_children():
		if other == planet or not other.visible or not _is_planet[other]:
			continue
		if other.position.distance_to(spot) < radius + _half_height(other) + Config.PROP_PLANET_GAP:
			return true
	return false


## Radius of the ring props appear on: the screen corners.
func _ring_radius() -> float:
	return Config.view_size().length() / 2.0


func _half_height(prop: Sprite2D) -> float:
	return prop.texture.get_height() * prop.scale.y / 2.0
