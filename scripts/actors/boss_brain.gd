class_name BossBrain
extends RefCounted
## Decides what the boss does: flies in toward the player, then plays its phases in order (a phase ends when the boss
## health drops to its `hp_to`). A phase has a movement pattern (strafing around the player, with dives) and attacks
## that pull the trigger of a boss weapon at intervals.

var _boss: Boss
var _player: Node2D
var _weapons: Dictionary # id -> Weapon
var _on_phase_change: Callable # (index, phase, is_first)
var _is_entering := true
var _phase := -1
var _pattern: MovementPatterns.Pattern
var _timers: Array[float] = [] # ms until each attack of the phase fires
var _transition := 0.0 # ms of invulnerability and silence after a phase change
var _out := {"lateral": 0.0, "speed_scale": 1.0}


func _init(boss: Boss, player: Node2D, weapons: Dictionary, on_phase_change: Callable) -> void:
	_boss = boss
	_player = player
	_weapons = weapons
	_on_phase_change = on_phase_change


func is_invulnerable() -> bool:
	return _is_entering or _transition > 0.0


func update(dt: float) -> void:
	if _is_entering:
		_fly_in()
		return
	_check_phase()
	_move(dt)
	if _transition > 0.0:
		_transition -= dt
		return
	_update_attacks(dt)


func _fly_in() -> void:
	var entry: Dictionary = Config.BOSS.entry
	var to_player := _player.position - _boss.position
	var distance := to_player.length() - float(entry.hold_distance)
	if distance <= 1.0:
		_boss.velocity = Vector2.ZERO
		_is_entering = false
		_start_phase(0, true)
		return
	_boss.velocity = to_player.normalized() * maxf(entry.min_speed, distance * entry.gain)


func _check_phase() -> void:
	var phases: Array = Config.BOSS.phases
	var index := _phase
	while index < phases.size() - 1 and _boss.health_fraction() <= phases[index].hp_to:
		index += 1
	if index != _phase:
		_start_phase(index, false)


func _start_phase(index: int, is_first: bool) -> void:
	var phase: Dictionary = Config.BOSS.phases[index]
	_phase = index
	_pattern = _create_pattern(phase.move)
	_pattern.reset()
	_timers.clear()
	for attack: Dictionary in phase.attacks:
		_timers.append(attack.first_delay)
	_transition = 0.0 if is_first else Config.BOSS.transition.duration
	_on_phase_change.call(index, phase, is_first)


func _create_pattern(move: Dictionary) -> MovementPatterns.Pattern:
	var strafe := MovementPatterns.Wave.new(move.period)
	if move.type == "dash":
		return MovementPatterns.Dash.new(strafe, move.dash)
	return strafe


## Strafes sideways around the player (the pattern's lateral share), holds its distance and dives at the player.
func _move(dt: float) -> void:
	var move: Dictionary = Config.BOSS.phases[_phase].move
	_pattern.update(dt, _boss, _player, _out)
	var to_player := _player.position - _boss.position
	var distance := to_player.length()
	var toward := to_player / distance if distance > 0.0 else Vector2.DOWN
	var hold: float = Config.BOSS.entry.hold_distance
	var strafe: Vector2 = toward.orthogonal() * (_out.lateral * move.speed)
	var radial: Vector2 = toward * ((distance - hold) * move.return_gain + (_out.speed_scale - 1.0) * move.get("dive_speed", 0.0))
	_boss.velocity = (strafe + radial).limit_length(Config.BOSS.max_speed)


func _update_attacks(dt: float) -> void:
	var attacks: Array = Config.BOSS.phases[_phase].attacks
	for i in attacks.size():
		_timers[i] -= dt
		if _timers[i] > 0.0:
			continue
		_weapons[attacks[i].weapon].trigger()
		_timers[i] = attacks[i].interval
