extends Node
## Global event bus: components talk through these signals instead of direct references. Autoload `Events`.

signal enemy_destroyed(enemy: Node2D)
signal player_spawn
signal player_destroyed
signal game_over
signal ship_hit
signal ship_shoot
signal player_thrust(is_thrusting: bool)
signal extra_life
signal lives_changed(count: int)
signal score_changed(score: int)
signal weapon_changed(slot: String, type: String, level: int) # type "" = slot emptied
signal bullet_hit(hit: Dictionary) # x, y, effect, scale?, enemy?, chain?, explosion?
signal pickup_collected(kind: String, type: String)
signal shield_changed(charges: int, absorbed: bool)
signal boss_warning
signal boss_spawn(boss: Node2D)
signal boss_defeated
signal boss_explosion
signal camera_shake(duration: float, intensity: float) # seconds, share of the screen
