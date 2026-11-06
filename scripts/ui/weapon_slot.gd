class_name WeaponSlot
extends Control
## HUD slot of one weapon: the weapon's box icon and level pips in the weapon's colour. Hidden while empty.

const ICON_SCALE := 0.28
const PIP_RADIUS := 2.0
const PIP_SPACING := 6.0
const PIP_OFFSET_X := 6.0
const PIP_DIM_ALPHA := 0.25

@export_enum("main", "secondary") var slot := "main"

var _color := Color.WHITE
var _level := 0

@onready var _icon: TextureRect = $Icon


func _ready() -> void:
	hide()
	Events.weapon_changed.connect(_on_weapon_changed)


func _on_weapon_changed(changed_slot: String, type: String, level: int) -> void:
	if changed_slot != slot:
		return
	visible = type != ""
	if type == "":
		return
	_icon.texture = Config.weapon_texture("box_%s" % type)
	_icon.custom_minimum_size = _icon.texture.get_size() * ICON_SCALE
	_icon.size = _icon.custom_minimum_size
	custom_minimum_size = _icon.size + Vector2(PIP_OFFSET_X * 2.0, 0.0)
	_color = Config.weapon_color(type)
	_level = level
	queue_redraw()


func _draw() -> void:
	for i in Config.WEAPON_MAX_LEVEL:
		var offset := PIP_SPACING * (i - (Config.WEAPON_MAX_LEVEL - 1) / 2.0)
		var center := Vector2(_icon.size.x + PIP_OFFSET_X, _icon.size.y / 2.0 - offset)
		draw_circle(center, PIP_RADIUS, Color(_color, 1.0 if i < _level else PIP_DIM_ALPHA))
