class_name Fx
extends Node
## Visual effects from pooled one-shot sprites: ship explosions and bullet impacts. Reacts to the event bus.

@export var player_destroy_frames: SpriteFrames

var _hit_frames: Dictionary = {} # effect name -> SpriteFrames

@onready var _explosions: Pool = $Explosions
@onready var _hits: Pool = $Hits


func _ready() -> void:
	Events.enemy_destroyed.connect(func(enemy: Node2D) -> void: explode(enemy.destroy_frames, enemy.position))
	Events.player_destroyed.connect(_on_player_destroyed)
	Events.bullet_hit.connect(_on_bullet_hit)


## Plays a ship explosion animation once at `at`.
func explode(frames: SpriteFrames, at: Vector2, scale_factor: float = 1.0) -> void:
	var sprite: FxSprite = _explosions.acquire()
	sprite.play_once(frames, at, scale_factor)


func _on_player_destroyed() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player")
	explode(player_destroy_frames, player.position)


func _on_bullet_hit(hit: Dictionary) -> void:
	var effect: String = hit.get("effect", "")
	if effect.is_empty():
		return
	if not _hit_frames.has(effect):
		_hit_frames[effect] = load("res://resources/frames/%s_hit.tres" % effect)
	var sprite: FxSprite = _hits.acquire()
	sprite.play_once(_hit_frames[effect], Vector2(hit.x, hit.y), hit.get("scale", Config.HIT_EFFECT_SCALE))
