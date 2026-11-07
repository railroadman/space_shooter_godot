class_name Boss
extends Area2D
## The level boss. Created by `BossSpawner`; flies in, fights in phases (see `BossBrain`) and ends the level when
## it is destroyed. Its health bar follows it.

const FLASH_AMOUNT := "shader_parameter/amount"

@export var destroy_frames: SpriteFrames
@export var bar_fade_time := 0.5

var velocity := Vector2.ZERO
var health := Health.new(Config.BOSS.health)
var collider := ShipCollider.new(health)
var score_value: int = Config.BOSS.score
var drop_chance := 1.0

var _brain: BossBrain
var _player: Node2D
var _bullet_pool: Pool
var _is_dying := false
var _last_life: float = Config.BOSS.health
var _flash_time := 0.0
var _phase_tint := Color.WHITE
var _bar_shown := false

@onready var _ship: Sprite2D = $Ship
@onready var _bar: GhostBar = $HealthBar


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_bullet_pool = get_tree().get_first_node_in_group("bullets")
	var weapons := _setup_weapons()
	_brain = BossBrain.new(self, _player, weapons, _on_phase_change)
	_bar.top_level = true # the bar must not turn with the ship
	_bar.modulate.a = 0.0
	add_to_group("enemies")


func is_alive() -> bool:
	return not health.is_dead


func health_fraction() -> float:
	return health.life / Config.BOSS.health


func _physics_process(delta: float) -> void:
	_update_bar(delta)
	if _is_dying:
		return
	if health.is_dead:
		_die()
		return
	position += velocity * delta
	_face_player(delta)
	_brain.update(delta * 1000.0)
	collider.is_invulnerable = _brain.is_invulnerable()
	_track_health()
	_update_flash(delta * 1000.0)
	if overlaps_area(_player) and _player.visible: # ramming the boss only hurts the player
		_player.collider.collide_with_ship()


## Gives every boss weapon node its bullet settings from the boss config.
func _setup_weapons() -> Dictionary:
	var weapons := {}
	for id: String in Config.BOSS.weapons:
		var def: Dictionary = Config.BOSS.weapons[id]
		var weapon: Weapon = $Weapons.get_node(NodePath(id))
		var config := {
			"speed": def.speed, "interval": 0.0, "lifespan": def.lifespan, "y_offset": 0.0, "flip_y": true,
			"angles": def.angles, "muzzles": def.muzzles, "damage": Config.ENEMY_BULLET_DAMAGE,
			"hit_effect": Config.ENEMY_BULLET_HIT_EFFECT,
		}
		if def.has("burst"):
			config.burst = def.burst
		if def.get("aim", false):
			config.aim_target = _player
			config.max_aim_angle = def.max_aim_angle
		config.merge(def.get("bullet", {}), true)
		weapon.set_config(config)
		weapons[id] = weapon
	return weapons


## Swings the nose (down at rotation 0) toward the player at a limited rate.
func _face_player(delta: float) -> void:
	var wanted := (_player.position - position).angle() - PI / 2.0
	rotation = rotate_toward(rotation, wanted, deg_to_rad(Config.BOSS.turn_rate) * delta)


func _on_phase_change(_index: int, phase: Dictionary, is_first: bool) -> void:
	_phase_tint = phase.tint
	_ship.modulate = _phase_tint
	_bar.fill_color = phase.bar_color
	_bar_shown = true
	if not is_first:
		_flash_time = Config.BOSS.transition.flash
		_ship.material.set(FLASH_AMOUNT, 1.0)
		if phase.clear_bullets:
			_clear_bullets()


func _track_health() -> void:
	if health.life == _last_life:
		return
	_last_life = health.life
	_flash_time = maxf(_flash_time, Config.BOSS.hit_flash)
	_ship.material.set(FLASH_AMOUNT, 1.0)
	_bar.set_target(health_fraction())


func _update_flash(dt: float) -> void:
	if _flash_time <= 0.0:
		return
	_flash_time -= dt
	if _flash_time <= 0.0:
		_ship.material.set(FLASH_AMOUNT, 0.0)


## The bar hovers above the boss, kept inside the screen, and fades in and out.
func _update_bar(delta: float) -> void:
	var margin := Config.UI_SAFE_MARGIN
	var view := Config.view_rect()
	_bar.global_position.x = clampf(position.x - _bar.size.x / 2.0, view.position.x + margin, view.end.x - margin - _bar.size.x)
	_bar.global_position.y = clampf(position.y - 95.0, view.position.y + margin, view.end.y - margin - _bar.size.y)
	var step := delta / bar_fade_time
	_bar.modulate.a = clampf(_bar.modulate.a + (step if _bar_shown else -step), 0.0, 1.0)


func _clear_bullets() -> void:
	for bullet: Bullet in _bullet_pool.get_children():
		if bullet.visible and bullet.source == self:
			bullet.pool.release(bullet)


## Death sequence: explosions over the hull for a while, then the camera shakes and the level ends.
func _die() -> void:
	var death: Dictionary = Config.BOSS.death
	_is_dying = true
	collider.is_invulnerable = true
	velocity = Vector2.ZERO
	_clear_bullets()
	_flash_time = 0.0
	_ship.material.set(FLASH_AMOUNT, 0.0)
	_ship.modulate = Color.WHITE
	var tween := create_tween().set_loops(int(death.duration / death.explosion_interval))
	tween.tween_callback(_explode)
	tween.tween_interval(death.explosion_interval)
	await get_tree().create_timer(death.duration).timeout
	_finish_death()


func _explode() -> void:
	var death: Dictionary = Config.BOSS.death
	var offset := Vector2(randf_range(-death.spread.x, death.spread.x), randf_range(-death.spread.y, death.spread.y))
	get_tree().get_first_node_in_group("fx").explode(destroy_frames, position + offset, randf_range(death.scale_min, death.scale_max))
	Events.boss_explosion.emit()


func _finish_death() -> void:
	var shake: Vector2 = Config.BOSS.death.shake
	Events.camera_shake.emit(shake.x, shake.y)
	remove_from_group("enemies")
	Pool.set_active(self, false)
	Events.enemy_destroyed.emit(self)
	Events.boss_defeated.emit()
