class_name Enemy
extends Area2D
## A pooled enemy ship (scout or fighter, chosen by `kind`). The spawner calls `spawn()`; the ship turns toward the
## player, follows its movement pattern, shoots all the time and gives its score when destroyed.

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
var _out := {"lateral": 0.0, "speed_scale": 1.0}
var _heading := Vector2.DOWN
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
	_heading = _to_player()
	_face_heading()
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if health.is_dead:
		Events.enemy_destroyed.emit(self)
		_leave()
		return
	_steer(delta)
	_pattern.update(delta * 1000.0, self, _player, _out)
	var velocity: Vector2 = _heading *(_out.speed_scale * _def.v_speed) + _heading.orthogonal() * (_out.lateral * _def.h_speed)
	position += velocity.limit_length(Config.ENEMY_MAX_SPEED) * delta
	_face_heading()
	if position.distance_to(_player.position) > Config.spawn_radius() * Config.DESPAWN_RING_FACTOR:
		_leave()


func _on_area_entered(area: Area2D) -> void:
	if not area.visible:
		return
	area.collider.collide_with_projectile(Config.ENEMY_RAM_DAMAGE) # a ram hurts, it no longer kills outright
	collider.collide_with_ship()


func _leave() -> void:
	remove_from_group("enemies")
	pool.release(self)


## Direction to the player (keeps the current heading while the player is gone).
func _to_player() -> Vector2:
	if _player == null or not _player.visible:
		return _heading
	return (_player.position - position).normalized()


## Turns the heading toward the player at a limited rate, so the ship swings around instead of snapping.
func _steer(delta: float) -> void:
	var wanted := _to_player()
	var max_turn := deg_to_rad(Config.ENEMY_TURN_RATE) * delta
	_heading = _heading.rotated(clampf(_heading.angle_to(wanted), -max_turn, max_turn))


## Enemy sprites face down at rotation 0.
func _face_heading() -> void:
	rotation = _heading.angle() - PI / 2.0


func _create_patterns() -> Dictionary:
	if kind == "scout":
		return {
			"wave": MovementPatterns.Wave.new(_def.wave_period),
			"zigzag": MovementPatterns.Zigzag.new(_def.zigzag_interval, _def.zigzag_smoothing),
		}
	return {"dash": MovementPatterns.Dash.new(MovementPatterns.Steady.new(), _def.dash)}


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
