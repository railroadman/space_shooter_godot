class_name Pickup
extends Area2D
## A pooled pickup box that falls, spins, pulses and blinks before it vanishes. The ship picks it up by touching it.

var pool: Pool

var _kind := ""
var _type := ""
var _age := 0.0 # ms

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	area_entered.connect(_on_area_entered)


## `kind` is health, shield or weapon; `type` names the weapon of a weapon pickup.
func setup(at: Vector2, kind: String, type: String) -> void:
	position = at
	_kind = kind
	_type = type
	_age = 0.0
	_sprite.texture = Config.weapon_texture("box_%s" % (type if kind == "weapon" else kind))
	_sprite.rotation = 0.0
	_sprite.modulate.a = 1.0


func _physics_process(delta: float) -> void:
	var config := Config.PICKUP
	_age += delta * 1000.0
	if _age >= config.lifetime or position.y > Config.WORLD.y + Config.DESPAWN_MARGIN_Y:
		pool.release(self)
		return
	position.y += config.fall_speed * delta
	_sprite.rotation += deg_to_rad(config.spin_speed) * delta
	_sprite.scale = Vector2.ONE * config.scale * (1.0 + config.pulse_amount * sin(_age / config.pulse_period * TAU))
	var is_blink_hidden: bool = _age > config.lifetime - config.blink_time and int(_age / config.blink_interval) % 2 == 1
	_sprite.modulate.a = 0.3 if is_blink_hidden else 1.0


func _on_area_entered(area: Area2D) -> void:
	if not area.visible:
		return
	Events.pickup_collected.emit(_kind, _type)
	pool.release(self)
