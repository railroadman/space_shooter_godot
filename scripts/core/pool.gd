class_name Pool
extends Node
## Fixed-prewarm object pool. Pooled nodes stay in the tree but are switched off (hidden, no processing, no collisions).
## A pooled node may declare `var pool: Pool`, which is set here so it can release itself.

@export var scene: PackedScene
@export var prewarm := 8

var _free: Array[Node] = []


func _ready() -> void:
	for i in prewarm:
		_free.append(_create())


## Returns a switched-on node of the pooled scene (a new one when the pool ran dry).
func acquire() -> Node:
	var node: Node = _free.pop_back() if not _free.is_empty() else _create()
	set_active(node, true)
	return node


func release(node: Node) -> void:
	if node in _free:
		return
	set_active(node, false)
	_free.append(node)


## Active nodes are visible, processed and (for areas) take part in collisions. Physics state changes are deferred,
## because a node is often released from inside a collision callback; deferred calls keep their order.
static func set_active(node: Node, active: bool) -> void:
	node.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED)
	if node is CanvasItem:
		node.visible = active
	if node is Area2D:
		node.set_deferred("monitoring", active)
		node.set_deferred("monitorable", active)


func _create() -> Node:
	var node: Node = scene.instantiate()
	if "pool" in node:
		node.pool = self
	add_child(node)
	node.process_mode = Node.PROCESS_MODE_DISABLED # at once: a new node must not run before its first acquire
	set_active(node, false)
	return node
