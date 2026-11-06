class_name Loadout
extends Node
## Which weapon the player's two slots use and at which level. The same type again gains a level, another main type
## replaces the weapon and returns at its remembered level. All weapons are lost when the player is destroyed.

@export var main_weapon: Weapon
@export var secondary_weapon: Weapon

var has_secondary := false

var _type: String = Config.WEAPON_START.type
var _levels: Dictionary = {}


func _ready() -> void:
	_reset_levels()
	Events.player_destroyed.connect(_on_player_destroyed)
	_apply_main.call_deferred() # after the HUD connected its listeners
	_apply_secondary.call_deferred()


func level_of(type: String) -> int:
	return _levels[type]


func collect(type: String) -> void:
	if Config.SECONDARY_TYPES.has(type):
		if has_secondary:
			_levels[type] = mini(_levels[type] + 1, Config.WEAPON_MAX_LEVEL)
		has_secondary = true
		_apply_secondary()
	elif Config.WEAPON_TYPES.has(type):
		if type == _type:
			_levels[type] = mini(_levels[type] + 1, Config.WEAPON_MAX_LEVEL)
		_type = type
		_apply_main()


func _reset_levels() -> void:
	for type: String in Config.WEAPON_TYPES:
		_levels[type] = 1
	for type: String in Config.SECONDARY_TYPES:
		_levels[type] = 1
	_type = Config.WEAPON_START.type
	_levels[_type] = Config.WEAPON_START.level


func _on_player_destroyed() -> void:
	_reset_levels()
	_apply_main()
	if has_secondary:
		has_secondary = false
		_apply_secondary()


func _apply_main() -> void:
	main_weapon.set_config(Config.bullet_config(_type, _levels[_type]))
	Events.weapon_changed.emit("main", _type, _levels[_type])


func _apply_secondary() -> void:
	var type: String = Config.SECONDARY_TYPES.keys()[0]
	secondary_weapon.set_config(Config.bullet_config(type, _levels[type]))
	if has_secondary:
		Events.weapon_changed.emit("secondary", type, _levels[type])
	else:
		Events.weapon_changed.emit("secondary", "", 0)
