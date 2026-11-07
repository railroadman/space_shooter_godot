class_name ChainLightning
extends Node2D
## Chain lightning: when a lightning bolt hits, it jumps on to the nearest unvisited enemies and draws jagged arcs.

var _arcs: Array[Dictionary] = [] # from, to, life (ms)


func _ready() -> void:
	Events.bullet_hit.connect(_on_bullet_hit)


func _process(delta: float) -> void:
	if _arcs.is_empty():
		return
	for arc in _arcs:
		arc.life -= delta * 1000.0
	_arcs = _arcs.filter(func(arc: Dictionary) -> bool: return arc.life > 0.0)
	queue_redraw()


func _draw() -> void:
	for arc in _arcs:
		var fade: float = arc.life / Config.CHAIN_ARC_TIME
		var points := _jagged_line(arc.from, arc.to)
		_stroke(points, Config.CHAIN_GLOW, fade)
		_stroke(points, Config.CHAIN_CORE, fade)


func _stroke(points: PackedVector2Array, style: Dictionary, fade: float) -> void:
	var color: Color = style.color
	color.a = style.alpha * fade
	draw_polyline(points, color, style.width)


func _on_bullet_hit(hit: Dictionary) -> void:
	var chain: Dictionary = hit.get("chain", {})
	if chain.is_empty() or hit.get("enemy") == null:
		return
	var radius: float = chain.get("radius", Config.CHAIN_RADIUS)
	var visited: Array[Node2D] = [hit.enemy]
	var current: Node2D = hit.enemy
	for jump in range(1, chain.targets):
		var next := _nearest_unvisited(current, visited, radius)
		if next == null:
			break
		visited.append(next)
		next.collider.collide_with_projectile(chain.get("damage", 1))
		_arcs.append({"from": current.global_position, "to": next.global_position, "life": Config.CHAIN_ARC_TIME})
		Events.bullet_hit.emit({"x": next.global_position.x, "y": next.global_position.y, "effect": "lightning"})
		current = next
	queue_redraw()


func _nearest_unvisited(from: Node2D, visited: Array[Node2D], radius: float) -> Node2D:
	var nearest: Node2D
	var nearest_distance := radius
	var screen := Config.view_rect()
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if enemy in visited or not enemy.is_alive() or not screen.has_point(enemy.global_position):
			continue
		var distance := from.global_position.distance_to(enemy.global_position)
		if distance <= nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest


func _jagged_line(from: Vector2, to: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array([from])
	var normal := (to - from).orthogonal().normalized()
	for i in range(1, Config.CHAIN_JAGS):
		var stray := randf_range(-Config.CHAIN_JAG_SIZE, Config.CHAIN_JAG_SIZE)
		points.append(from.lerp(to, float(i) / Config.CHAIN_JAGS) + normal * stray)
	points.append(to)
	return points
