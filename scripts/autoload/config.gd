extends Node
## All tunable game constants (ported from the Phaser config.js). Autoload `Config`.
## Speeds are px/s, intervals/durations ms unless a name says otherwise; bullet `lifespan` is in seconds.

# --- collision layers (bit values)
const LAYER_PLAYER := 1
const LAYER_ENEMY := 2
const LAYER_PLAYER_BULLET := 4
const LAYER_ENEMY_BULLET := 8
const LAYER_PICKUP := 16

# --- world
const UI_SAFE_MARGIN := 15.0
const SPAWN_RING_MARGIN := 60.0 # px outside the view where enemies appear
const DESPAWN_RING_FACTOR := 1.8 # enemies farther than spawn radius * factor from the player are released
const ACTIVE_VIEW_MARGIN := 40.0 # ships this far outside the view still count as on screen

# --- player
const PLAYER_LIVES := 3
const PLAYER_HEALTH := 200.0
const PLAYER_EXTRA_LIFE_SCORE := 5000
const PLAYER_SPEED := 200.0 # top speed
const PLAYER_ACCELERATION := 900.0 # px/s^2 while a move key is held
const PLAYER_DRIFT_DRAG := 250.0 # px/s^2 lost while coasting: from top speed it takes ~0.8 s to stop
const PLAYER_TURN_RATE := 540.0 # deg/s the ship turns toward its movement direction
const PLAYER_BODY_SIZE := 24.0
const PLAYER_BULLET_Y_OFFSET := -20.0
const PLAYER_INVULNERABLE_TIME := 3000.0
const PLAYER_BLINK_INTERVAL := 100.0
const PLAYER_BLINK_ALPHA := 0.25
const PLAYER_RESPAWN_DELAY := 1.5
const PLAYER_DEATH_SHAKE := Vector2(0.5, 0.01) # seconds, intensity (share of the screen)
const PLAYER_HIT_FLASH_TIME := 120.0
const PLAYER_HIT_FLASH_COLOR := Color("ff3b3b")

# --- shared bullet defaults
const BULLET_DEFAULT_SCALE := 0.8
const HIT_EFFECT_SCALE := 0.5

# --- chain lightning arcs
const CHAIN_RADIUS := 150.0
const CHAIN_ARC_TIME := 150.0
const CHAIN_JAGS := 6
const CHAIN_JAG_SIZE := 9.0
const CHAIN_GLOW := {"color": Color("b455ff"), "width": 6.0, "alpha": 0.55}
const CHAIN_CORE := {"color": Color("ffffff"), "width": 2.0, "alpha": 1.0}

# --- player weapons. Each type has `base` bullet settings and one entry per level in `levels` (a level overrides base).
# muzzles: {x, y} px from the ship, one bullet per muzzle and angle (a muzzle may override scale and damage).
# angles: degrees of the fan. Frames are `<type>_shot` of the weapons atlas (resources/weapons/).
const WEAPON_MAX_LEVEL := 3
const WEAPON_START := {"type": "plasma", "level": 1}
const LASER_MUZZLE_Y := -34.0
const WEAPON_TYPES := {
	"plasma": {
		"color": Color("29b6ff"),
		"base": {"speed": 300.0, "interval": 300.0, "lifespan": 3.0, "frame": "plasma_shot", "hit_effect": "plasma",
			"scale": 0.6, "body": Vector2(14, 40), "damage": 1},
		"levels": [
			{"muzzles": [{"x": 0, "y": -20}]},
			{"muzzles": [{"x": -8, "y": -20}, {"x": 8, "y": -20}]},
			{"muzzles": [{"x": -13, "y": -17}, {"x": 0, "y": -22, "scale": 0.85, "damage": 2}, {"x": 13, "y": -17}]},
		],
	},
	"shotgun": {
		"color": Color("ffc233"),
		"base": {"speed": 280.0, "interval": 450.0, "lifespan": 0.9, "frame": "shotgun_shot", "hit_effect": "shotgun",
			"scale": 0.55, "body": Vector2(14, 30), "damage": 1, "muzzles": [{"x": 0, "y": -20}]},
		"levels": [
			{"angles": [-12, 0, 12]},
			{"angles": [-24, -12, 0, 12, 24]},
			{"angles": [-36, -24, -12, 0, 12, 24, 36]},
		],
	},
	# fast piercing beams: every beam hits each enemy once and flies on
	"laser": {
		"color": Color("ff3b3b"),
		"base": {"speed": 600.0, "interval": 320.0, "lifespan": 1.6, "frame": "laser_shot", "hit_effect": "laser",
			"pierce": true, "scale": 1.0, "body": Vector2(8, 48), "damage": 1},
		"levels": [
			{"muzzles": [{"x": 0, "y": -34}]},
			{"interval": 320.0, "scale": 1.15, "body": Vector2(10, 48), "muzzles": [{"x": -6, "y": -34}, {"x": 6, "y": -34}]},
			{"interval": 440.0, "scale": 1.5, "body": Vector2(12, 48), "damage": 2, "muzzles": [{"x": -8, "y": -34}, {"x": 8, "y": -34}]},
		],
	},
	# chain lightning: on a hit the bolt jumps to the nearest other enemies (`chain.targets` in total)
	"lightning": {
		"color": Color("b455ff"),
		"base": {"speed": 450.0, "interval": 420.0, "lifespan": 1.4, "frame": "lightning_shot", "hit_effect": "lightning",
			"scale": 0.8, "body": Vector2(12, 40), "damage": 1, "muzzles": [{"x": 0, "y": -20}]},
		"levels": [
			{"chain": {"targets": 2}},
			{"scale": 0.95, "chain": {"targets": 3}},
			{"scale": 1.1, "chain": {"targets": 5}},
		],
	},
}
# secondary slot: shoots together with the main weapon, silent. Homing rockets with an area blast.
const SECONDARY_TYPES := {
	"rocket": {
		"color": Color("ff7a1a"),
		"base": {"speed": 220.0, "interval": 1200.0, "lifespan": 3.0, "silent": true, "frame": "rocket_shot",
			"scale": 0.7, "body": Vector2(10, 26), "damage": 2,
			"homing": {"delay": 250.0, "turn_rate": 220.0, "range": 450.0, "acceleration": 500.0, "max_speed": 420.0},
			"explosion": {"radius": 50.0, "damage": 1, "effect": "rocket", "effect_scale": 1.1}},
		"levels": [
			{"muzzles": [{"x": 0, "y": -8}]},
			{"muzzles": [{"x": -12, "y": -6}, {"x": 12, "y": -6}]},
			{"muzzles": [{"x": -16, "y": -4}, {"x": 0, "y": -10}, {"x": 16, "y": -4}]},
		],
	},
}

# --- pickups dropped by destroyed enemies
const DROP_COOLDOWN := 10000.0
const DROP_WEIGHTS := {"health": 35, "shield": 30, "main": 25, "secondary": 10}
const DROP_MAIN := ["plasma", "shotgun", "laser", "lightning"]
const DROP_SECONDARY := ["rocket"]
const PICKUP := {
	"scale": 0.5, "body": 56.0, "spin_speed": 40.0, "pulse_amount": 0.08, "pulse_period": 700.0,
	"lifetime": 9000.0, "blink_time": 2500.0, "blink_interval": 120.0,
}
const HEALTH_PICKUP_HEAL := 0.3
const SHIELD := {"charges": 3, "hit_grace": 400.0, "radius": 30.0, "color": Color("4fc3ff"), "ripple_time": 0.35}

# --- enemies (bullet `speed` < 0 means the bullet flies down)
const ENEMY_BODY_SIZE := 24.0
const ENEMY_BULLET_Y_OFFSET := 10.0
const ENEMY_BULLET_DAMAGE := 8
const ENEMY_RAM_DAMAGE := 15.0 # a ship that rams the player is destroyed and hurts the player
const ENEMY_BULLET_HIT_EFFECT := "plasma"
const ENEMY_ZIGZAG_SCALE := Vector2(0.7, 1.3)
const ENEMY_MAX_SPEED := 320.0
const ENEMY_TURN_RATE := 120.0 # deg/s an enemy turns toward the player
const SCOUT := {
	"score": 100, "health": 2, "v_speed": 90.0, "h_speed": 80.0, "drop_chance": 0.065,
	"bullet": {"speed": -250.0, "interval": 7000.0, "lifespan": 3.0},
	"spawn_interval": 10000.0, "spawn_start": 1000.0,
	"patterns": ["wave", "zigzag"], "wave_period": 2600.0, "zigzag_interval": 900.0, "zigzag_smoothing": 5.0,
	"burst": {"count": 2, "delay": 250.0}, "aim_max_angle": 30.0,
	"formations": [{"type": "single", "count": 1}, {"type": "single", "count": 1}, {"type": "single", "count": 1}, {"type": "line", "count": 3}],
}
const FIGHTER := {
	"score": 200, "health": 3, "v_speed": 110.0, "h_speed": 45.0, "drop_chance": 0.22,
	"bullet": {"speed": -280.0, "interval": 6000.0, "lifespan": 3.0},
	"spawn_interval": 14000.0, "spawn_start": 3000.0,
	"patterns": ["dash"], "spread": [-18, 0, 18],
	"dash": {"cooldown_min": 3500, "cooldown_max": 6500, "windup": 350.0, "windup_axis_factor": 0.2, "windup_speed_scale": 0.4,
		"duration": 450.0, "axis_boost": 2.0, "speed_boost": 2.5},
	"formations": [{"type": "single", "count": 1}, {"type": "v", "count": 3}],
}
const ENEMIES := {"scout": SCOUT, "fighter": FIGHTER}
const FORMATION_SPACING_X := 50.0
const FORMATION_STAGGER_DELAY := 0.7 # seconds between ships of a 'v' formation

# bullet looks and damage of special enemy weapons
const BULLET_ACID := {"frame": "acid_shot", "scale": 0.5, "body": Vector2(16, 16), "damage": 20, "hit_effect": "acid"}
const BULLET_RAILGUN := {"frame": "railgun_shot", "scale": 0.6, "body": Vector2(10, 30), "damage": 34, "hit_effect": "railgun"}
# enemy weapon presets: overrides on the base bullet settings of the enemy
const ENEMY_WEAPONS := {
	"single": {},
	"triple": {"burst": {"count": 3, "delay": 200.0}},
	"acid": {"bullet": BULLET_ACID, "speed": -210.0, "burst": {"count": 2, "delay": 220.0}},
	"spread3": {},
	"spread5": {"angles": [-24, 0, 24]},
	"acid5": {"bullet": BULLET_ACID, "speed": -220.0, "angles": [-18, 0, 18]},
	"railgun": {"bullet": BULLET_RAILGUN, "speed": -380.0, "angles": [0], "aim": true, "max_aim_angle": 30.0,
		"burst": {"count": 2, "delay": 250.0}},
}
# difficulty grows with game time (ms): the last stage with `from` <= time applies
const DIFFICULTY_STAGES := [
	{"from": 0, "health_bonus": 0, "spawn_scale": 1.0, "fire_scale": 1.0, "scout": "single", "fighter": "spread3"},
	{"from": 60000, "health_bonus": 2, "spawn_scale": 0.85, "fire_scale": 1.1, "scout": "triple", "fighter": "spread5"},
	{"from": 150000, "health_bonus": 3, "spawn_scale": 0.65, "fire_scale": 1.2, "scout": "acid", "fighter": "acid5"},
	{"from": 240000, "health_bonus": 4, "spawn_scale": 0.55, "fire_scale": 1.2, "scout": "acid", "fighter": "railgun"},
]

# --- boss (spawn.time_* in ms of game time)
const BOSS := {
	"spawn": {"time_min": 300000, "time_max": 360000, "warning": 3.0, "resume_delay": 4.0},
	"health": 300, "score": 5000, "victory_delay": 1.5,
	"sprite": {"scale": 0.56, "body": Vector2(120, 110)},
	"entry": {"hold_distance": 300.0, "min_speed": 60.0, "gain": 1.5}, # px from the player where the boss circles
	"max_speed": 400.0,
	"turn_rate": 60.0, # deg/s the boss swings its nose toward the player
	"transition": {"duration": 1200.0, "flash": 200.0},
	"hit_flash": 50.0,
	"weapons": {
		"main": {"muzzles": [{"x": -31, "y": 62}, {"x": 31, "y": 62}], "speed": -230.0, "lifespan": 4.0,
			"angles": [-14, 0, 14], "aim": true, "max_aim_angle": 25.0},
		"wing_l": {"muzzles": [{"x": -59, "y": 20}], "speed": -260.0, "lifespan": 4.0, "angles": [0],
			"burst": {"count": 3, "delay": 180.0}, "aim": true, "max_aim_angle": 30.0},
		"wing_r": {"muzzles": [{"x": 59, "y": 20}], "speed": -260.0, "lifespan": 4.0, "angles": [0],
			"burst": {"count": 3, "delay": 180.0}, "aim": true, "max_aim_angle": 30.0},
		"snipe": {"muzzles": [{"x": 0, "y": 66}], "speed": -400.0, "lifespan": 3.0, "angles": [0],
			"burst": {"count": 2, "delay": 280.0}, "aim": true, "max_aim_angle": 35.0, "bullet": BULLET_RAILGUN},
		"fan": {"muzzles": [{"x": 0, "y": 66}], "speed": -200.0, "lifespan": 4.0, "angles": [-60, -40, -20, 0, 20, 40, 60],
			"burst": {"count": 2, "delay": 300.0}, "bullet": BULLET_ACID},
		"ring": {"muzzles": [{"x": 0, "y": 20}], "speed": -170.0, "lifespan": 4.0,
			"angles": [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330], "bullet": BULLET_ACID},
	},
	# a phase ends when the health fraction drops to hp_to; attacks fire `weapon` every `interval` ms
	"phases": [
		{"hp_to": 0.65, "move": {"type": "sway", "period": 4200.0, "speed": 90.0, "return_gain": 2.0},
			"attacks": [{"weapon": "main", "interval": 2200.0, "first_delay": 1200.0}],
			"tint": Color.WHITE, "bar_color": Color("4fd8ff"), "clear_bullets": false},
		{"hp_to": 0.3, "move": {"type": "sway", "period": 3000.0, "speed": 130.0, "return_gain": 2.0},
			"attacks": [
				{"weapon": "main", "interval": 2000.0, "first_delay": 800.0},
				{"weapon": "wing_l", "interval": 3200.0, "first_delay": 1500.0},
				{"weapon": "wing_r", "interval": 3200.0, "first_delay": 3100.0},
				{"weapon": "snipe", "interval": 5200.0, "first_delay": 2400.0}],
			"tint": Color.WHITE, "bar_color": Color("ffd24f"), "clear_bullets": true},
		{"hp_to": 0.0,
			"move": {"type": "dash", "period": 3600.0, "speed": 130.0, "return_gain": 2.0, "dive_speed": 220.0,
				"dash": {"cooldown_min": 4000, "cooldown_max": 6000, "windup": 600.0, "windup_axis_factor": 0.1,
					"windup_speed_scale": 0.6, "duration": 500.0, "axis_boost": 1.6, "speed_boost": 2.2}},
			"attacks": [
				{"weapon": "main", "interval": 1700.0, "first_delay": 800.0},
				{"weapon": "snipe", "interval": 3600.0, "first_delay": 1200.0},
				{"weapon": "fan", "interval": 4200.0, "first_delay": 1500.0},
				{"weapon": "ring", "interval": 5200.0, "first_delay": 3000.0}],
			"tint": Color("ff9a9a"), "bar_color": Color("ff4f6a"), "clear_bullets": true},
	],
	"death": {"duration": 2.2, "explosion_interval": 0.14, "spread": Vector2(90, 70), "scale_min": 1.2, "scale_max": 2.4,
		"shake": Vector2(0.6, 0.012)},
	"warning_text": "WARNING", "warning_y": 0.3, "warning_blink": 0.35,
}

# --- audio (linear volumes)
const AUDIO_MUSIC := 0.05
const AUDIO_EXPLOSION := 0.6
const AUDIO_BOSS_EXPLOSION := 0.35
const AUDIO_HIT := 0.6
const AUDIO_SHOT := 0.05
const AUDIO_PICKUP := 0.15

# --- background
const BACKGROUND_IMAGE_SWITCH := 60.0 # seconds of play before the nebula photo changes
const BACKGROUND_IMAGE_FADE := 8.0 # out and in together
const BACKGROUND_IMAGE_SPEED := 4.0
const BACKGROUND_IMAGE_ALPHA := 0.8
const BACKGROUND_BOOST := 2.2
const BACKGROUND_BOOST_SMOOTHING := 4.0
const PLANET_NAMES := ["alien", "amethyst", "copper", "crystal", "desert", "frozen_ringed", "ice", "jungle", "lava",
	"magma_blue", "moon", "obsidian", "ocean", "ocean_dark", "red_giant", "ringed", "rose_ringed", "salt", "storm", "toxic"]
const PROP_FIRST_SPAWN := 1500.0
const PROP_SPAWN_INTERVAL := 24000.0
const PROP_RETRY_DELAY := 1500.0
const PROP_PLANET_GAP := 40.0
const PROP_SPEED := Vector2(12, 30)
const PROP_FADE_DISTANCE := 120.0
const STREAK_COUNT := 6
const STREAK_SPEED := Vector2(450, 800)

# --- ui
const UI_SCORE_DIGITS := 6
const UI_POPUP_RISE := 40.0
const UI_POPUP_TIME := 0.7
const UI_POPUP_EDGE_MARGIN := 30.0
const UI_EXTRA_LIFE_TEXT := "+1"

var _weapon_textures: Dictionary = {}


## Size of the visible area in world px (the window shape decides it, the camera never zooms).
func view_size() -> Vector2:
	return get_viewport().get_visible_rect().size


## Centre of the visible area: the camera, or the origin before a camera exists.
func view_center() -> Vector2:
	var camera := get_viewport().get_camera_2d()
	return camera.get_screen_center_position() if camera != null else Vector2.ZERO


## The visible area in world coordinates, grown by `margin` px on every side.
func view_rect(margin := 0.0) -> Rect2:
	var size := view_size()
	return Rect2(view_center() - size / 2.0, size).grow(margin)


## Radius of the ring where enemies appear: just beyond the screen corners.
func spawn_radius() -> float:
	return view_size().length() / 2.0 + SPAWN_RING_MARGIN


## Texture of a weapons atlas frame (`plasma_shot`, `box_health`, ...), loaded once.
func weapon_texture(frame: String) -> Texture2D:
	if not _weapon_textures.has(frame):
		_weapon_textures[frame] = load("res://resources/weapons/%s.tres" % frame)
	return _weapon_textures[frame]


## Bullet settings of a weapon type at a level (1-based): base overridden by the level entry.
func bullet_config(type: String, level: int) -> Dictionary:
	var weapon: Dictionary = WEAPON_TYPES[type] if WEAPON_TYPES.has(type) else SECONDARY_TYPES[type]
	var config: Dictionary = weapon["base"].duplicate()
	config.merge(weapon["levels"][level - 1], true)
	config["y_offset"] = PLAYER_BULLET_Y_OFFSET
	return config


func weapon_color(type: String) -> Color:
	return (WEAPON_TYPES[type] if WEAPON_TYPES.has(type) else SECONDARY_TYPES[type])["color"]
