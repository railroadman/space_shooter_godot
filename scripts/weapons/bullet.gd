class_name Bullet
extends Area2D
## One pooled projectile. `fire()` arms it; it flies straight (or homes in), expires after its lifespan and hits
## enemies (player bullets) or the player (enemy bullets).

@onready var _sprite: Sprite2D = $Sprite # atlas bullets
@onready var _anim: AnimatedSprite2D = $Anim # default animated enemy bullet
@onready var _visuals: Array[Node2D] = [_sprite, _anim]
@onready var _shape: RectangleShape2D = $Shape.shape

var pool: Pool
## Ship that fired the bullet (the boss clears its own bullets on a phase change).
var source: Node
var velocity := Vector2.ZERO

var _life := 0.0 # seconds left
var _age := 0.0 # ms since fired, delays homing
var _friendly := false
var _damage := 1.0
var _pierce := false
var _hit_effect := ""
var _chain: Dictionary = {}
var _homing: Dictionary = {}
var _explosion: Dictionary = {}
var _target: Node2D
var _hit_enemies: Array[Node2D] = [] # targets a piercing bullet already damaged


func _ready() -> void:
	_shape = _shape.duplicate() # every bullet resizes its own shape
	$Shape.shape = _shape
	area_entered.connect(_on_area_entered)


## `angle_deg` is the flight direction in degrees clockwise from straight up (world space); `config.speed` is its magnitude.
func fire(config: Dictionary, pos: Vector2, angle_deg: float, muzzle: Dictionary, friendly: bool, shooter: Node) -> void:
	source = shooter
	var angle := deg_to_rad(angle_deg)
	var speed: float = config.speed
	var scale_factor: float = muzzle.get("scale", config.get("scale", Config.BULLET_DEFAULT_SCALE))
	var flip: bool = config.get("flip_y", false)
	global_position = pos
	velocity = Vector2.UP.rotated(angle) * absf(speed)
	_life = config.lifespan
	_age = 0.0
	_friendly = friendly
	_damage = muzzle.get("damage", config.get("damage", 1))
	_pierce = config.get("pierce", false)
	_hit_effect = config.get("hit_effect", "")
	_chain = config.get("chain", {})
	_homing = config.get("homing", {})
	_explosion = config.get("explosion", {})
	_target = null
	_hit_enemies.clear()
	var frame: String = config.get("frame", "")
	_sprite.visible = frame != ""
	_anim.visible = frame == ""
	if frame != "":
		_sprite.texture = Config.weapon_texture(frame)
	else:
		_anim.play()
	_sprite.flip_v = flip
	_anim.flip_v = flip
	for visual in _visuals:
		visual.scale = Vector2.ONE * scale_factor
		visual.rotation = angle + PI if flip else angle # flipped sprites face down
	_shape.size = config.get("body", Vector2(14, 18)) * scale_factor
	collision_layer = Config.LAYER_PLAYER_BULLET if friendly else Config.LAYER_ENEMY_BULLET
	collision_mask = Config.LAYER_ENEMY if friendly else Config.LAYER_PLAYER


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		pool.release(self)
		return
	if not _homing.is_empty():
		_steer(delta)
	position += velocity * delta


func _on_area_entered(area: Area2D) -> void:
	if _friendly:
		_hit_enemy(area)
	else:
		_hit_player(area)


## A player bullet hits an enemy: the enemy takes the damage, the bullet is used up unless it pierces.
func _hit_enemy(enemy: Area2D) -> void:
	if not enemy.is_alive() or enemy in _hit_enemies:
		return
	if _pierce:
		_hit_enemies.append(enemy)
	else:
		pool.release(self)
	enemy.collider.collide_with_projectile(_damage)
	Events.bullet_hit.emit({"x": global_position.x, "y": global_position.y, "effect": _hit_effect,
		"enemy": enemy, "chain": _chain, "explosion": _explosion})


func _hit_player(player: Area2D) -> void:
	if not player.visible:
		return
	Events.bullet_hit.emit({"x": global_position.x, "y": global_position.y, "effect": _hit_effect})
	pool.release(self)
	player.collider.collide_with_projectile(_damage)


## Homing: after a short straight flight, turn toward the nearest enemy ahead and speed up.
func _steer(delta: float) -> void:
	_age += delta * 1000.0
	if _age < _homing.delay:
		return
	if not _can_be_hit(_target):
		_target = _nearest_enemy_ahead()
	var angle := velocity.angle()
	var speed := minf(_homing.max_speed, velocity.length() + _homing.acceleration * delta)
	if _target != null:
		var wanted := (_target.global_position - global_position).angle()
		var max_turn := deg_to_rad(_homing.turn_rate) * delta
		angle += clampf(angle_difference(angle, wanted), -max_turn, max_turn)
	velocity = Vector2.from_angle(angle) * speed
	for visual in _visuals:
		visual.rotation = angle + PI / 2.0


func _nearest_enemy_ahead() -> Node2D:
	var nearest: Node2D
	var nearest_distance: float = _homing.range
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if not _can_be_hit(enemy) or velocity.dot(enemy.global_position - global_position) < 0.0:
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance <= nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest


func _can_be_hit(enemy: Node2D) -> bool:
	return enemy != null and enemy.is_alive() and Config.view_rect().has_point(enemy.global_position)
