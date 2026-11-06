class_name Enemy
extends Area2D
## A pooled enemy ship (scout or fighter, chosen by `kind`). The spawner calls `spawn()`; the ship follows its
## movement pattern, shoots all the time and gives its score when destroyed.

@export_enum("scout", "fighter") var kind := "scout"
## Played by the effects node where the ship dies.
@export var destroy_frames: SpriteFrames

var pool: Pool
var health: Health
var collider: ShipCollider
var score_value := 0
var drop_chance := 0.0

var _def: Dictionary
var _patterns: Dictionary = {}
var _pattern: MovementPatterns.Pattern
var _out := {"axis_x": 0.0, "speed_scale": 1.0}
var _player: Node2D
var _difficulty: Difficulty

@onready var _weapon: Weapon = $Weapon


func _ready() -> void:
	_def = Config.ENEMIES[kind]
	score_value = _def.score
	drop_chance = _def.drop_chance
	health = Health.new(_def.health)
	collider = ShipCollider.new(health)
	_player = get_tree().get_first_node_in_group("player")
	_difficulty = get_tree().get_first_node_in_group("difficulty")
	_patterns = _create_patterns()
	_weapon.firing = true
	area_entered.connect(_on_area_entered)


func is_alive() -> bool:
	return not health.is_dead


## Puts a fresh ship at `at`, scaled to the current difficulty.
func spawn(at: Vector2) -> void:
	position = at
	health.set_max_life(_difficulty.enemy_health(_def.health))
	health.reset()
	_weapon.set_config(_weapon_config())
	_pattern = _patterns[_def.patterns.pick_random()]
	_pattern.reset()
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if health.is_dead:
		Events.enemy_destroyed.emit(self)
		_leave()
		return
	_pattern.update(delta * 1000.0, self, _player, _out)
	var velocity := Vector2(_out.axis_x * _def.h_speed, _out.speed_scale * _def.v_speed)
	position += velocity.limit_length(Config.ENEMY_MAX_SPEED) * delta
	if kind == "scout":
		var half := Config.ENEMY_BODY_SIZE / 2.0
		position.x = clampf(position.x, half, Config.WORLD.x - half)
	if position.y > Config.WORLD.y + Config.DESPAWN_MARGIN_Y:
		_leave()


func _on_area_entered(area: Area2D) -> void:
	if not area.visible:
		return
	area.collider.collide_with_ship()
	collider.collide_with_ship()


func _leave() -> void:
	remove_from_group("enemies")
	pool.release(self)


func _create_patterns() -> Dictionary:
	if kind == "scout":
		return {
			"wave": MovementPatterns.Wave.new(_def.wave_period),
			"zigzag": MovementPatterns.Zigzag.new(_def.zigzag_interval, _def.zigzag_smoothing),
		}
	var chase := MovementPatterns.Chase.new(_def.chase_range, _def.chase_smoothing)
	return {"dash": MovementPatterns.Dash.new(chase, _def.dash)}


func _weapon_config() -> Dictionary:
	var base: Dictionary = _def.bullet.duplicate()
	base.merge({
		"damage": Config.ENEMY_BULLET_DAMAGE,
		"hit_effect": Config.ENEMY_BULLET_HIT_EFFECT,
		"y_offset": Config.ENEMY_BULLET_Y_OFFSET,
		"flip_y": true,
	})
	if kind == "scout":
		base.merge({"aim_target": _player, "max_aim_angle": _def.aim_max_angle, "burst": _def.burst})
	else:
		base.angles = _def.spread
	return _difficulty.enemy_weapon(kind, base, _player)
