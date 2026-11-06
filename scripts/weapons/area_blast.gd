class_name AreaBlast
extends Node
## Rocket explosions: every other enemy near the hit takes area damage, and a blast effect is played.


func _ready() -> void:
	Events.bullet_hit.connect(_on_bullet_hit)


func _on_bullet_hit(hit: Dictionary) -> void:
	var blast: Dictionary = hit.get("explosion", {})
	if blast.is_empty():
		return
	var center := Vector2(hit.x, hit.y)
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if enemy != hit.enemy and enemy.is_alive() and center.distance_to(enemy.global_position) <= blast.radius:
			enemy.collider.collide_with_projectile(blast.damage)
	if blast.has("effect"):
		Events.bullet_hit.emit({"x": center.x, "y": center.y, "effect": blast.effect, "scale": blast.effect_scale})
