extends CanvasLayer
class_name NLBHUD
## Debug HUD only: HP, message, hint. (The Blink state line and cooldown bar
## belonged to the removed mechanic; Motion Swap reports through its own lab
## overlay and the lab message line.)

var _hp: Label
var _msg: Label

func _ready() -> void:
	layer = 10
	add_to_group("hud")
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_hp = _label(root, Vector2(16, 12), 20)
	_msg = _label(root, Vector2(16, 44), 18)
	var hint := _label(root, Vector2(16, 660), 15)
	hint.text = "A/D move | Space jump | Shift/L roll | J/Z/LMB attack | R restart"

func _label(parent: Control, pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l

func set_hp(cur: int, maximum: int) -> void:
	_hp.text = "HP: %d/%d" % [cur, maximum]

func set_message(t: String) -> void:
	_msg.text = t
