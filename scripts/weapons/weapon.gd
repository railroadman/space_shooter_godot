class_name Weapon
extends Node
## Fires bullets from its parent node along the parent's nose. The owner sets `firing` (held trigger) or calls
## `trigger()` (one shot request). `config` holds the bullet settings (see Config.WEAPON_TYPES); bullets come from
## the shared pool in group "bullets". Muzzle offsets are in the ship's local space (player: nose is up, enemies with
## `flip_y` have their nose down at rotation 0).

const STRAIGHT: Array = [0]

## Bullets of a player weapon hit enemies, others hit the player.
@export var friendly := false

var config: Dictionary = {}
var firing := false

var _shooter: Node2D
var _bullets: Pool
var _requested := false
var _cooldown := 0.0 # ms until the next volley
var _burst_left := 0
var _burst_timer := 0.0


func _ready() -> void:
	_shooter = _find_shooter()
	_bullets = get_tree().get_first_node_in_group("bullets")


## The nearest Node2D above this node (a weapon may sit in a container node).
func _find_shooter() -> Node2D:
	var node := get_parent()
	while not node is Node2D:
		node = node.get_parent()
	return node


func set_config(new_config: Dictionary) -> void:
	config = new_config
	_burst_left = 0


func trigger() -> void:
	_requested = true


func _physics_process(delta: float) -> void:
	var wants_fire := firing or _requested
	_requested = false
	if config.is_empty() or not Config.view_rect(Config.ACTIVE_VIEW_MARGIN).has_point(_shooter.global_position):
		return
	var dt := delta * 1000.0
	_update_burst(dt)
	_cooldown -= dt
	if _cooldown > 0.0 or not wants_fire or not _fire_volley():
		return
	_cooldown = config.interval
	var burst: Dictionary = config.get("burst", {})
	_burst_left = burst.get("count", 1) - 1
	_burst_timer = burst.get("delay", 0.0)
	if not config.get("silent", false):
		Events.ship_shoot.emit()


func _update_burst(dt: float) -> void:
	if _burst_left <= 0:
		return
	_burst_timer -= dt
	if _burst_timer > 0.0:
		return
	_fire_volley()
	_burst_left -= 1
	_burst_timer = config.burst.delay


## One bullet per muzzle and angle; returns false when nothing was fired.
func _fire_volley() -> bool:
	var angles: Array = config.get("angles", STRAIGHT)
	var muzzles: Array = config.get("muzzles", [])
	if muzzles.is_empty():
		muzzles = [{"x": 0.0, "y": config.get("y_offset", 0.0)}]
	var base := _nose_angle()
	for muzzle: Dictionary in muzzles:
		var origin := _shooter.global_position + Vector2(muzzle.x, muzzle.y).rotated(_shooter.global_rotation)
		var aim := _aim_angle(origin, base)
		for angle: float in angles:
			var bullet: Bullet = _bullets.acquire()
			bullet.fire(config, origin, base + aim + angle, muzzle, friendly, _shooter)
	return true


## Degrees from straight up to the ship's nose.
func _nose_angle() -> float:
	var angle := rad_to_deg(_shooter.global_rotation)
	return angle + 180.0 if config.get("flip_y", false) else angle


## Degrees from the nose to the aim target as seen from the muzzle (0 without a usable target). Targets behind the
## muzzle are ignored and the angle is limited, so shots stay dodgeable.
func _aim_angle(origin: Vector2, base: float) -> float:
	var target: Node2D = config.get("aim_target")
	if target == null or not target.visible:
		return 0.0
	var to_target := target.global_position - origin
	var offset := wrapf(rad_to_deg(atan2(to_target.x, -to_target.y)) - base, -180.0, 180.0)
	if absf(offset) >= 90.0:
		return 0.0
	var limit: float = config.get("max_aim_angle", 35.0)
	return clampf(offset, -limit, limit)
