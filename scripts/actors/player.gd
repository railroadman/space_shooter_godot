class_name Player
extends Area2D
## The player's ship: moves with the keyboard, fires its two weapon slots and reacts to pickups and damage.
## It stays switched off until `Events.player_spawn` and after being destroyed.

const FLASH_SHADER_AMOUNT := "shader_parameter/amount"

var health := Health.new(Config.PLAYER_HEALTH)
var collider := ShipCollider.new(health)
var loadout: Loadout

var _invulnerable_time := 0.0
var _flash_time := 0.0
var _last_life := Config.PLAYER_HEALTH
var velocity := Vector2.ZERO

var _is_thrusting := false

@onready var _ship: Sprite2D = $Ship
@onready var _main_weapon: Weapon = $MainWeapon
@onready var _secondary_weapon: Weapon = $SecondaryWeapon


func _ready() -> void:
	loadout = $Loadout
	Events.player_spawn.connect(_spawn)
	Events.pickup_collected.connect(_on_pickup_collected)
	Events.extra_life.connect(_show_popup.bind(Config.UI_EXTRA_LIFE_TEXT))
	Pool.set_active(self, false)


func _physics_process(delta: float) -> void:
	if health.is_dead:
		_die()
		return
	var dt := delta * 1000.0
	_ship.frame = mini(3, int((1.0 - health.life / Config.PLAYER_HEALTH) * 4.0)) # one damage frame per quarter
	_update_hit_flash(dt)
	collider.update(dt)
	_update_invulnerability(dt)
	_move(delta)
	var shooting := Input.is_action_pressed("shoot")
	_main_weapon.firing = shooting
	_secondary_weapon.firing = shooting and loadout.has_secondary


func _move(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO: # the nose turns toward the flight direction (sprite faces up at rotation 0)
		rotation = rotate_toward(rotation, direction.angle() + PI / 2.0, deg_to_rad(Config.PLAYER_TURN_RATE) * delta)
	velocity = step_velocity(velocity, direction, delta)
	position += velocity * delta
	Events.player_moved.emit(position, rotation)
	var thrusting := direction != Vector2.ZERO
	if thrusting != _is_thrusting:
		_is_thrusting = thrusting
		Events.player_thrust.emit(thrusting)


## Inertia: input accelerates the ship (up to the top speed); without input it keeps drifting the same way and only
## slowly loses speed (a gentle constant drag, not a brake).
static func step_velocity(current: Vector2, direction: Vector2, delta: float) -> Vector2:
	if direction == Vector2.ZERO:
		return current.move_toward(Vector2.ZERO, Config.PLAYER_DRIFT_DRAG * delta)
	return (current + direction * Config.PLAYER_ACCELERATION * delta).limit_length(Config.PLAYER_SPEED)


func _spawn() -> void:
	Pool.set_active(self, true)
	health.reset()
	collider.clear_shield()
	collider.is_invulnerable = true
	_invulnerable_time = Config.PLAYER_INVULNERABLE_TIME
	modulate.a = 1.0
	_last_life = health.life
	_flash_time = 0.0
	_set_flash(0.0)
	rotation = 0.0
	position = Vector2.ZERO # centre of the map; the camera follows
	velocity = Vector2.ZERO
	_is_thrusting = false
	Events.player_moved.emit(position, rotation)


func _die() -> void:
	Pool.set_active(self, false)
	_main_weapon.firing = false
	Events.player_destroyed.emit()


func _update_hit_flash(dt: float) -> void:
	if health.life < _last_life:
		_flash_time = Config.PLAYER_HIT_FLASH_TIME
		_set_flash(1.0)
	_last_life = health.life
	if _flash_time <= 0.0:
		return
	_flash_time -= dt
	if _flash_time <= 0.0:
		_set_flash(0.0)


func _set_flash(amount: float) -> void:
	_ship.material.set(FLASH_SHADER_AMOUNT, amount)


## Counts down the post-spawn invulnerability and blinks the ship while it lasts.
func _update_invulnerability(dt: float) -> void:
	if _invulnerable_time <= 0.0:
		return
	_invulnerable_time -= dt
	if _invulnerable_time <= 0.0:
		collider.is_invulnerable = false
		modulate.a = 1.0
		return
	var phase := int(_invulnerable_time / Config.PLAYER_BLINK_INTERVAL) % 2
	modulate.a = Config.PLAYER_BLINK_ALPHA if phase == 0 else 1.0


func _on_pickup_collected(kind: String, type: String) -> void:
	if not visible:
		return
	match kind:
		"health":
			health.heal(Config.PLAYER_HEALTH * Config.HEALTH_PICKUP_HEAL)
			_show_popup("+%d%%" % roundi(Config.HEALTH_PICKUP_HEAL * 100.0))
		"shield":
			collider.add_shield(Config.SHIELD.charges, Config.SHIELD.hit_grace)
			_show_popup("+SHIELD")
		_:
			loadout.collect(type)
			_show_popup("%s LV%d" % [type.to_upper(), loadout.level_of(type)])


## Floats a short text up from the ship.
func _show_popup(message: String) -> void:
	var popup: PopupText = get_tree().get_first_node_in_group("popups").acquire()
	popup.show_text(message, position + Vector2(0.0, -Config.UI_POPUP_EDGE_MARGIN))
