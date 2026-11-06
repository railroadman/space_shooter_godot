class_name PickupSpawner
extends Node
## Rolls a drop when an enemy is destroyed. Regular enemies cannot drop again for a while after a drop;
## an enemy with a drop chance of 1 (the boss) always drops. Stops dropping after the game is over.

@onready var _pool: Pool = $Pool

var _cooldown := 0.0 # ms
var _is_game_over := false


func _ready() -> void:
	Events.enemy_destroyed.connect(_on_enemy_destroyed)
	Events.game_over.connect(func() -> void: _is_game_over = true)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta * 1000.0)


func _on_enemy_destroyed(enemy: Node2D) -> void:
	if _is_game_over:
		return
	var chance: float = enemy.drop_chance
	if (chance < 1.0 and _cooldown > 0.0) or randf() >= chance:
		return
	var drop := _roll_drop()
	if drop.is_empty():
		return
	var pickup: Pickup = _pool.acquire()
	pickup.setup(enemy.position, drop.kind, drop.get("type", ""))
	_cooldown = Config.DROP_COOLDOWN


## Picks a kind by weight; weapon kinds also pick one of the droppable weapons.
func _roll_drop() -> Dictionary:
	var weights: Dictionary = Config.DROP_WEIGHTS
	var roll: float = randf() * weights.values().reduce(func(sum: float, weight: float) -> float: return sum + weight, 0.0)
	var kind: String = weights.keys().back()
	for key: String in weights:
		roll -= weights[key]
		if roll < 0.0:
			kind = key
			break
	if kind == "health" or kind == "shield":
		return {"kind": kind}
	var types: Array = Config.DROP_SECONDARY if kind == "secondary" else Config.DROP_MAIN
	return {} if types.is_empty() else {"kind": "weapon", "type": types.pick_random()}
