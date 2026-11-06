class_name ShipCollider
extends RefCounted
## Reacts to collisions of a ship: damage, invulnerability and the shield charges of the player.

var is_invulnerable := false
var shield := 0
var _health: Health
var _shield_grace := 0.0
var _shield_cooldown := 0.0


func _init(health: Health) -> void:
	_health = health


func add_shield(charges: int, hit_grace: float) -> void:
	shield = charges
	_shield_grace = hit_grace
	_shield_cooldown = 0.0
	Events.shield_changed.emit(charges, false)


func clear_shield() -> void:
	if shield == 0:
		return
	shield = 0
	_shield_cooldown = 0.0
	Events.shield_changed.emit(0, false)


## Call every frame with the frame time in ms.
func update(dt: float) -> void:
	_shield_cooldown = maxf(0.0, _shield_cooldown - dt)


func collide_with_ship() -> void:
	if is_invulnerable or _health.is_dead or _absorb_with_shield():
		return
	_health.die()


func collide_with_projectile(damage: float = 1.0) -> void:
	if is_invulnerable or _health.is_dead or _absorb_with_shield():
		return
	_health.hit(damage)
	Events.ship_hit.emit()


func _absorb_with_shield() -> bool:
	if shield == 0:
		return false
	if _shield_cooldown > 0.0:
		return true
	shield -= 1
	_shield_cooldown = _shield_grace
	Events.shield_changed.emit(shield, true)
	return true
