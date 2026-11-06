class_name AudioManager
extends Node
## Plays the music and the sound effects that belong to events of the bus. The players are child nodes with their
## streams set in the scene; volumes come from Config.

@onready var _music: AudioStreamPlayer = $Music
@onready var _explosion: AudioStreamPlayer = $Explosion
@onready var _boss_explosion: AudioStreamPlayer = $BossExplosion
@onready var _hit: AudioStreamPlayer = $Hit
@onready var _shot: AudioStreamPlayer = $Shot
@onready var _pickup: AudioStreamPlayer = $Pickup


func _ready() -> void:
	_music.volume_db = linear_to_db(Config.AUDIO_MUSIC)
	_music.finished.connect(_music.play) # loop
	_music.play()
	_explosion.volume_db = linear_to_db(Config.AUDIO_EXPLOSION)
	_boss_explosion.volume_db = linear_to_db(Config.AUDIO_BOSS_EXPLOSION)
	_hit.volume_db = linear_to_db(Config.AUDIO_HIT)
	_shot.volume_db = linear_to_db(Config.AUDIO_SHOT)
	_pickup.volume_db = linear_to_db(Config.AUDIO_PICKUP)
	Events.enemy_destroyed.connect(func(_enemy: Node2D) -> void: _explosion.play())
	Events.player_destroyed.connect(_explosion.play)
	Events.boss_explosion.connect(_boss_explosion.play)
	Events.ship_hit.connect(_hit.play)
	Events.ship_shoot.connect(_shot.play)
	Events.pickup_collected.connect(func(_kind: String, _type: String) -> void: _pickup.play())

