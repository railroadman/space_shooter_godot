class_name SpaceProps
extends Node2D
## Nebula clouds and planets that drift down the screen and fade in and out. The Sprite2D children are the pool;
## a planet is never picked twice in a row and never overlaps another planet.

## Cloud textures; planets are loaded from Config.PLANET_NAMES.
@export var nebulae: Array[Texture2D] = []

const NEBULA_WEIGHT := 1.0
const PLANET_WEIGHT := 0.3
const NEBULA_SCALE := Vector2(1.6, 2.8)
const PLANET_SCALE := Vector2(0.35, 0.8)
const NEBULA_ALPHA := 0.45
const PLANET_ALPHA := 0.95

var _spawn_in := Config.PROP_FIRST_SPAWN # ms
var _last_texture: Texture2D
var _planets: Array[Texture2D] = []
var _speeds: Dictionary = {} # Sprite2D -> px/s
var _alphas: Dictionary = {} # Sprite2D -> opacity at full visibility
var _is_planet: Dictionary = {} # Sprite2D -> bool


func _ready() -> void:
	for planet: String in Config.PLANET_NAMES:
		_planets.append(load("res://assets/images/planets/planet_%s.png" % planet))
	for prop: Sprite2D in get_children():
		prop.visible = false


func advance(delta: float, speed_multiplier: float) -> void:
	_spawn_in -= delta * 1000.0
	if _spawn_in <= 0.0:
		_spawn_in = Config.PROP_SPAWN_INTERVAL * randf_range(0.7, 1.3) if _spawn() else Config.PROP_RETRY_DELAY
	var fade := Config.PROP_FADE_DISTANCE
	for prop: Sprite2D in get_children():
		if not prop.visible:
			continue
		prop.position.y += _speeds[prop] * speed_multiplier * delta
		var half := _half_height(prop)
		if prop.position.y - half > Config.WORLD.y:
			prop.visible = false
			continue
		var fade_in := clampf((prop.position.y + half) / fade, 0.0, 1.0)
		var fade_out := clampf((Config.WORLD.y - (prop.position.y - half)) / fade, 0.0, 1.0)
		prop.modulate.a = _alphas[prop] * minf(fade_in, fade_out)


## Starts one prop; false when there is no free sprite or a planet found no free place.
func _spawn() -> bool:
	var prop := _free_prop()
	if prop == null:
		return false
	var texture := _pick_texture()
	var is_planet := _planets.has(texture)
	var scale_range := PLANET_SCALE if is_planet else NEBULA_SCALE
	var speed := randf_range(Config.PROP_SPEED.x, Config.PROP_SPEED.y)
	prop.texture = texture
	prop.scale = Vector2.ONE * randf_range(scale_range.x, scale_range.y)
	prop.rotation_degrees = randf() * 360.0
	var x := randf_range(-Config.WORLD.x * 0.1, Config.WORLD.x * 1.1)
	if is_planet:
		var place := _find_planet_place(prop, speed)
		if place.is_empty():
			return false
		x = place.x
		speed = place.speed
	_last_texture = texture
	_speeds[prop] = speed
	_alphas[prop] = PLANET_ALPHA if is_planet else NEBULA_ALPHA
	_is_planet[prop] = is_planet
	prop.position = Vector2(x, -_half_height(prop))
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


## A planet needs a spot clear of the other planets. If it starts above one in the same column it drifts no faster
## than that one, so they never touch. Returns {x, speed} or an empty dictionary.
func _find_planet_place(planet: Sprite2D, speed: float) -> Dictionary:
	var gap := Config.PROP_PLANET_GAP
	var radius := _half_height(planet)
	for attempt in 8:
		var x := randf_range(-Config.WORLD.x * 0.1, Config.WORLD.x * 1.1)
		var limit := speed
		var fits := true
		for other: Sprite2D in get_children():
			if other == planet or not other.visible or not _is_planet[other]:
				continue
			if absf(other.position.x - x) >= radius + _half_height(other) + gap:
				continue
			if other.position.y - _half_height(other) < radius + gap:
				fits = false
				break
			limit = minf(limit, _speeds[other])
		if fits:
			return {"x": x, "speed": limit}
	return {}


func _half_height(prop: Sprite2D) -> float:
	return prop.texture.get_height() * prop.scale.y / 2.0
