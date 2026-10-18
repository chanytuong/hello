extends Node2D
class_name NLBMotionSwapController
## MOTION SWAP — the targeting front end and the exchange itself.
##
## Rule: the player picks two valid targets. First pick is A, second pick is B.
## Both targets' CURRENT motions are read BEFORE either one changes, then the
## two values are written back in the opposite order. It is a true two-way
## exchange: never a teleport, never a position swap, never stored momentum,
## never an auto-aimed knockback, never a change of owner.
##
## The controller knows nothing about object types. It asks each target's
## component for its channel and its motion, and it refuses pairs that the
## channel table cannot express — with a readable reason instead of a silent
## reinterpretation.

signal phase_changed(phase: int)
signal swap_executed(target_a: NLBMotionSwapTarget, target_b: NLBMotionSwapTarget)
signal feedback(text: String, ok: bool)

enum Phase { IDLE, ARMED, COOLDOWN }

@export_group("Targeting")
## Maximum distance from Iven to a selectable target, in pixels.
@export var max_range: float = 520.0
## Cursor slop: an object counts as hovered within this radius of the anchor.
@export var grab_radius: float = 40.0
## A lone first pick expires instead of staying armed forever.
@export var selection_timeout: float = 5.0
@export_group("Exchange")
## Cooldown between two exchanges.
@export var cooldown: float = 1.0
## How long a CHARACTER keeps a received motion before its own AI resumes.
## Machines ignore this: their setting persists until changed or reset.
@export var character_override_time: float = 2.5
@export_group("Readability")
@export var draw_indicators: bool = true

var phase: int = Phase.IDLE
var target_a: NLBMotionSwapTarget = null
var hover_target: NLBMotionSwapTarget = null
var cooldown_left: float = 0.0
var last_feedback: String = ""
var last_feedback_ok: bool = true

var _timeout_left: float = 0.0
var _player: Node2D = null
var _fx: Array = []          # {pos: Vector2, t: float, ok: bool}
const FX_TIME := 0.35

func _ready() -> void:
	z_index = 5  # indicators must read over bodies, under the HUD

func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	# A freed or disabled target must never survive as a selection.
	if target_a != null and not target_a.is_valid():
		_say("TARGET A LOST (%s) — SELECTION CLEARED" % _name_of(target_a), false)
		_clear_selection()
	if cooldown_left > 0.0:
		cooldown_left = maxf(cooldown_left - delta, 0.0)
		if cooldown_left <= 0.0 and phase == Phase.COOLDOWN:
			_set_phase(Phase.IDLE)
	if phase == Phase.ARMED:
		_timeout_left -= delta
		if _timeout_left <= 0.0:
			_say("SELECTION TIMED OUT — PICK TARGET A AGAIN", false)
			_clear_selection()
	_update_hover()
	for fx in _fx:
		fx.t -= delta
	for i in range(_fx.size() - 1, -1, -1):
		if _fx[i].t <= 0.0:
			_fx.remove_at(i)
	if draw_indicators:
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("swap_cancel"):
		if phase == Phase.ARMED:
			_say("SELECTION CANCELLED", true)
			_clear_selection()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("swap_select"):
		select_at(get_global_mouse_position())
		get_viewport().set_input_as_handled()

# ------------------------------------------------------------------ targeting

## Pick (or complete) a selection at a world position. Returns true when the
## click changed anything; every refusal explains itself through `feedback`.
func select_at(world_pos: Vector2) -> bool:
	var found := target_near(world_pos)
	if phase == Phase.COOLDOWN:
		_say("SWAP ON COOLDOWN (%.1fs)" % cooldown_left, false)
		return false
	if found == null:
		if phase == Phase.ARMED:
			_say("NO TARGET THERE — A STAYS SELECTED", false)
		else:
			_say("NO TARGET THERE", false)
		return false
	if not found.is_valid():
		_say("%s IS NOT SWAPPABLE RIGHT NOW" % _name_of(found), false)
		return false
	if _out_of_range(found):
		_say("OUT OF RANGE (%.0f px > %.0f px)" % [_distance_to(found), max_range], false)
		return false
	if phase != Phase.ARMED:
		_select_a(found)
		return true
	if found == target_a:
		_say("SAME TARGET — SELECTION CANCELLED", false)
		_clear_selection()
		return true
	if not NLBMotionChannels.compatible(target_a.channel(), found.channel()):
		_say(NLBMotionChannels.refusal(target_a.channel(), found.channel()), false)
		return false
	exchange(target_a, found)
	return true

func _select_a(t: NLBMotionSwapTarget) -> void:
	target_a = t
	_timeout_left = selection_timeout
	_set_phase(Phase.ARMED)
	_say("TARGET A: %s [%s] %s — pick target B" % [_name_of(t), t.channel_label(), _motion_text(t)], true)

## The exchange. Read both, THEN write both — the two reads happen before
## either target can change, so no target can consume its own motion back.
func exchange(a: NLBMotionSwapTarget, b: NLBMotionSwapTarget) -> void:
	if a == null or b == null or a == b:
		return
	if not (a.is_valid() and b.is_valid()):
		_say("EXCHANGE REFUSED — A TARGET BECAME UNAVAILABLE", false)
		_clear_selection()
		return
	var motion_a: Vector2 = a.read_motion()
	var motion_b: Vector2 = b.read_motion()
	a.apply_motion(motion_b)
	b.apply_motion(motion_a)
	_fx.append({"pos": a.anchor_world(), "t": FX_TIME, "ok": true})
	_fx.append({"pos": b.anchor_world(), "t": FX_TIME, "ok": true})
	_say("SWAPPED %s %s  <->  %s %s" % [
		_name_of(a), _vec_text(motion_a), _name_of(b), _vec_text(motion_b)], true)
	swap_executed.emit(a, b)
	cooldown_left = cooldown
	target_a = null
	_set_phase(Phase.COOLDOWN)

func cancel_selection() -> void:
	if phase == Phase.ARMED:
		_say("SELECTION CANCELLED", true)
	_clear_selection()

func _clear_selection() -> void:
	target_a = null
	_timeout_left = 0.0
	if phase == Phase.ARMED:
		_set_phase(Phase.IDLE)

func _set_phase(p: int) -> void:
	phase = p
	phase_changed.emit(p)

# --------------------------------------------------------------------- lookup

## Nearest valid-or-invalid target within grab_radius of the cursor.
func target_near(world_pos: Vector2) -> NLBMotionSwapTarget:
	var best: NLBMotionSwapTarget = null
	var best_d := grab_radius
	for node in get_tree().get_nodes_in_group("swap_targets"):
		var t := node as NLBMotionSwapTarget
		if t == null or not is_instance_valid(t) or not t.is_inside_tree():
			continue
		if t.host != null and not is_instance_valid(t.host):
			continue
		var d: float = t.anchor_world().distance_to(world_pos)
		if d <= best_d:
			best_d = d
			best = t
	return best

func _out_of_range(t: NLBMotionSwapTarget) -> bool:
	return _distance_to(t) > max_range

func _distance_to(t: NLBMotionSwapTarget) -> float:
	if _player == null or not is_instance_valid(_player):
		return 0.0
	return _player.global_position.distance_to(t.anchor_world())

func _update_hover() -> void:
	if _player == null or not is_instance_valid(_player):
		hover_target = null
		return
	hover_target = target_near(get_global_mouse_position())

# ------------------------------------------------------------------- reporting

func phase_label() -> String:
	match phase:
		Phase.IDLE:
			return "READY"
		Phase.ARMED:
			return "A SELECTED"
		Phase.COOLDOWN:
			return "COOLDOWN %.1fs" % cooldown_left
	return "?"

func _name_of(t: NLBMotionSwapTarget) -> String:
	if t == null:
		return "?"
	if t.host != null and is_instance_valid(t.host):
		return "%s#%d" % [t.display_name, t.host.get_instance_id() % 1000]
	return t.display_name

func _motion_text(t: NLBMotionSwapTarget) -> String:
	return _vec_text(t.read_motion())

func _vec_text(v: Vector2) -> String:
	return "(%.0f, %.0f)" % [v.x, v.y]

func _say(text: String, ok: bool) -> void:
	last_feedback = text
	last_feedback_ok = ok
	feedback.emit(text, ok)

# ------------------------------------------------------------------ indicators

func _draw() -> void:
	if not draw_indicators:
		return
	var font := ThemeDB.fallback_font
	var player_pos: Vector2 = _player.global_position if (_player != null and is_instance_valid(_player)) else Vector2.ZERO
	# Range ring: only while choosing, so it never becomes permanent clutter.
	if phase == Phase.ARMED:
		draw_arc(player_pos, max_range, 0.0, TAU, 96, Color(0.45, 0.8, 0.9, 0.18), 2.0)
	# Hover read-out.
	if hover_target != null and is_instance_valid(hover_target):
		var p := hover_target.anchor_world()
		var in_range := not _out_of_range(hover_target)
		var compatible := true
		if phase == Phase.ARMED and target_a != null:
			compatible = NLBMotionChannels.compatible(target_a.channel(), hover_target.channel())
		var ok := in_range and compatible and hover_target.is_valid()
		var col := Color(0.55, 0.95, 0.65, 0.95) if ok else Color(1.0, 0.35, 0.35, 0.95)
		draw_rect(Rect2(p - Vector2(18, 18), Vector2(36, 36)), col, false, 2.0)
		var tag := "?" if not hover_target.is_valid() else ("B" if phase == Phase.ARMED else ("X" if not ok else "+"))
		if not in_range:
			tag = "RANGE"
		elif not compatible:
			tag = "CHANNEL"
		draw_string(font, p + Vector2(-20, -26), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
		draw_string(font, p + Vector2(-40, 40), hover_target.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
		draw_string(font, p + Vector2(-40, 54), hover_target.describe(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
	# Selected A.
	if target_a != null and is_instance_valid(target_a):
		var pa := target_a.anchor_world()
		draw_rect(Rect2(pa - Vector2(20, 20), Vector2(40, 40)), Color(0.35, 0.85, 1.0, 0.95), false, 2.0)
		draw_string(font, pa + Vector2(-20, -28), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.35, 0.85, 1.0))
		if hover_target != null and is_instance_valid(hover_target) and hover_target != target_a:
			draw_line(pa, hover_target.anchor_world(), Color(0.35, 0.85, 1.0, 0.35), 1.0)
	# Exchange flash: two short expanding rings, purely presentational.
	for fx in _fx:
		var k: float = 1.0 - clampf(fx.t / FX_TIME, 0.0, 1.0)
		var r: float = lerpf(10.0, 46.0, k)
		var a: float = (1.0 - k) * 0.85
		draw_arc(fx.pos, r, 0.0, TAU, 32, Color(0.7, 0.95, 1.0, a), 2.0)
