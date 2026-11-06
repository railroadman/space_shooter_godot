class_name Health
extends RefCounted
## Hit points of a ship.

var life: float
var is_dead := false
var _max_life: float


func _init(max_life: float) -> void:
	_max_life = max_life
	life = max_life


func set_max_life(max_life: float) -> void:
	_max_life = max_life


func reset() -> void:
	life = _max_life
	is_dead = false


func hit(damage: float = 1.0) -> void:
	if is_dead:
		return
	life -= damage
	is_dead = life <= 0.0


func heal(amount: float) -> void:
	if not is_dead:
		life = minf(_max_life, life + amount)


func die() -> void:
	life = 0.0
	is_dead = true
