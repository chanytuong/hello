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

enum Phase { IDLE, ARMED, COOLDOWN, SELECTING }

@export_group("Targeting")
## Maximum distance from Iven to a selectable target, in pixels.
@export var max_range: float = 520.0
## Cursor slop: an object counts as hovered within this radius of the anchor.
@export var grab_radius: float = 40.0
## A lone first pick expires instead of staying armed forever.
@export var selection_timeout: float = 1.5
@export_range(0.01, 1.0) var slow_motion_scale: float = 0.12
@export var projectile_grab_radius: float = 48.0
@export_group("Exchange")
## Cooldown between two exchanges.
@export var cooldown: float = 0.5
## How long a CHARACTER keeps a received motion before its own AI resumes.
## Machines ignore this: their setting persists until changed or reset.
@export var character_override_time: float = 0.65
@export_group("Overdrive (after the faithful exchange)")
@export var overdrive_enabled: bool = true
@export var overdrive_multiplier: float = 1.25
@export var overdrive_min_speed: float = 250.0
@export var overdrive_duration: float = 0.12
@export_group("Readability")
@export var draw_indicators: bool = true
var debug_values: bool = false

var phase: int = Phase.IDLE
var target_a: NLBMotionSwapTarget = null
var hover_target: NLBMotionSwapTarget = null
var cooldown_left: float = 0.0
var last_feedback: String = ""
var last_feedback_ok: bool = true

var _timeout_left: float = 0.0
var _selection_deadline: int = 0
var _cooldown_deadline: int = 0
var _owns_slow_motion: bool = false
var last_exchange: Dictionary = {}
var _player: Node2D = null
var _fx: Array = []          # {pos: Vector2, t: float, ok: bool}
const FX_TIME := 0.35

func _ready() -> void:
	z_index = 5  # indicators must read over bodies, under the HUD
	process_mode = Node.PROCESS_MODE_ALWAYS

func is_selecting() -> bool:
	return phase == Phase.SELECTING or phase == Phase.ARMED

func begin_selection() -> bool:
	if is_selecting():
		cancel_selection()
		return false
	_refresh_clock()
	if cooldown_left > 0.0 or not _player_available():
		return false
	target_a = null
	_selection_deadline = Time.get_ticks_usec() + int(selection_timeout * 1000000.0)
	_timeout_left = selection_timeout
	_owns_slow_motion = true
	Engine.time_scale = slow_motion_scale
	_set_phase(Phase.SELECTING)
	_say("CHOOSE TWO  ·  LMB targets  ·  Q / RMB Iven", true)
	return true

func _player_available() -> bool:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(_player):
		return false
	return not _player.has_method("is_swap_selectable") or _player.is_swap_selectable()

func _refresh_clock() -> void:
	var now := Time.get_ticks_usec()
	cooldown_left = maxf(float(_cooldown_deadline - now) / 1000000.0, 0.0)
	if phase == Phase.COOLDOWN and cooldown_left <= 0.0:
		_set_phase(Phase.IDLE)
	if is_selecting():
		_timeout_left = maxf(float(_selection_deadline - now) / 1000000.0, 0.0)
		if _timeout_left <= 0.0:
			_say("SELECTION EXPIRED", false)
			_clear_selection()

func _restore_time() -> void:
	if _owns_slow_motion:
		Engine.time_scale = 1.0
		_owns_slow_motion = false

func _exit_tree() -> void:
	_restore_time()

func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	# A freed or disabled target must never survive as a selection.
	if is_selecting() and not _player_available():
		_clear_selection()
	if phase == Phase.ARMED and (not is_instance_valid(target_a) or not target_a.is_valid() or _out_of_range(target_a)):
		_say("TARGET LOST — SELECTION CLEARED", false)
		_clear_selection()
	_refresh_clock()
	_update_hover()
	for fx in _fx:
		fx.t -= delta
	for i in range(_fx.size() - 1, -1, -1):
		if _fx[i].t <= 0.0:
			_fx.remove_at(i)
	if draw_indicators:
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("swap_activate"):
		begin_selection()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("swap_cancel"):
		cancel_selection()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("swap_self") and is_selecting():
		select_self()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("swap_select") and is_selecting():
		var cursor := get_global_mouse_position()
		if event is InputEventMouseButton:
			cursor = get_canvas_transform().affine_inverse() * (event as InputEventMouseButton).position
		select_at(cursor)
		get_viewport().set_input_as_handled()

func select_self() -> bool:
	if not _player_available():
		_clear_selection()
		return false
	return select_target(_player.get_node_or_null("SwapTarget") as NLBMotionSwapTarget)

# ------------------------------------------------------------------ targeting

## Pick (or complete) a selection at a world position. Returns true when the
## click changed anything; every refusal explains itself through `feedback`.
func select_at(world_pos: Vector2) -> bool:
	return select_target(target_near(world_pos))

func select_target(found: NLBMotionSwapTarget) -> bool:
	_refresh_clock()
	if not is_selecting():
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
	if not is_instance_valid(target_a):
		_select_a(found)
		return true
	if found == target_a:
		_say("SAME TARGET — SELECTION CANCELLED", false)
		_clear_selection()
		return true
	if not NLBMotionChannels.compatible(target_a.channel(), found.channel()):
		_say(NLBMotionChannels.refusal(target_a.channel(), found.channel()), false)
		_clear_selection()
		return false
	return exchange(target_a, found)

func _select_a(t: NLBMotionSwapTarget) -> void:
	target_a = t
	_set_phase(Phase.ARMED)
	_say("A: %s  ·  choose B" % _name_of(t), true)

## The exchange. Read both, THEN write both — the two reads happen before
## either target can change, so no target can consume its own motion back.
func exchange(a: NLBMotionSwapTarget, b: NLBMotionSwapTarget) -> bool:
	_refresh_clock()
	if not is_instance_valid(a) or not is_instance_valid(b) or a == b or cooldown_left > 0.0:
		_clear_selection()
		return false
	if not (a.is_valid() and b.is_valid()):
		_say("EXCHANGE REFUSED — A TARGET BECAME UNAVAILABLE", false)
		_clear_selection()
		return false
	if not NLBMotionChannels.compatible(a.channel(), b.channel()) or _out_of_range(a) or _out_of_range(b):
		_say("INCOMPATIBLE CHANNEL OR OUT OF RANGE", false)
		_clear_selection()
		return false
	var motion_a: Vector2 = a.read_motion()
	var motion_b: Vector2 = b.read_motion()
	if not motion_a.is_finite() or not motion_b.is_finite():
		_clear_selection()
		return false
	# Capture modifier provenance too. A transferred active boost is never multiplied again.
	var boost_a := a.overdrive_snapshot()
	var boost_b := b.overdrive_snapshot()
	if a.kind() == "CHARACTER" and not a.host.is_in_group("player"):
		a.adapter.override_time = character_override_time
	if b.kind() == "CHARACTER" and not b.host.is_in_group("player"):
		b.adapter.override_time = character_override_time
	a.apply_motion(motion_b)
	b.apply_motion(motion_a)
	# The exchange above is exact; this explicit, optional stage is the exaggeration.
	a.apply_overdrive(overdrive_enabled, overdrive_multiplier, overdrive_min_speed, overdrive_duration, boost_b)
	b.apply_overdrive(overdrive_enabled, overdrive_multiplier, overdrive_min_speed, overdrive_duration, boost_a)
	last_exchange = {"a_received": motion_b, "b_received": motion_a,
		"a_final": a.read_motion(), "b_final": b.read_motion()}
	_fx.append({"pos": a.anchor_world(), "t": FX_TIME, "ok": true})
	_fx.append({"pos": b.anchor_world(), "t": FX_TIME, "ok": true})
	_say("MOTION EXCHANGED  ·  %s ↔ %s" % [_name_of(a), _name_of(b)], true)
	swap_executed.emit(a, b)
	cooldown_left = cooldown
	_cooldown_deadline = Time.get_ticks_usec() + int(cooldown * 1000000.0)
	target_a = null
	_restore_time()
	_set_phase(Phase.COOLDOWN)
	return true

func cancel_selection() -> void:
	if is_selecting():
		_say("SELECTION CANCELLED", true)
	_clear_selection()

func _clear_selection() -> void:
	target_a = null
	_timeout_left = 0.0
	_restore_time()
	if is_selecting():
		_set_phase(Phase.IDLE)

func reset_state() -> void:
	_clear_selection()
	_cooldown_deadline = 0
	cooldown_left = 0.0
	_set_phase(Phase.IDLE)

func _set_phase(p: int) -> void:
	phase = p
	phase_changed.emit(p)

# --------------------------------------------------------------------- lookup

## Nearest valid-or-invalid target within grab_radius of the cursor.
func target_near(world_pos: Vector2) -> NLBMotionSwapTarget:
	var best: NLBMotionSwapTarget = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group("swap_targets"):
		var t := node as NLBMotionSwapTarget
		if t == null or not is_instance_valid(t) or not t.is_valid() or _out_of_range(t):
			continue
		if t.host != null and not is_instance_valid(t.host):
			continue
		var d: float = t.anchor_world().distance_to(world_pos)
		var radius := projectile_grab_radius if t.kind() == "PROJECTILE" else grab_radius
		var score := d / radius
		if d <= radius and score < best_d:
			best_d = score
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
			return "E  ·  MOTION SWAP"
		Phase.SELECTING:
			return "CHOOSE A  %.2fs" % _timeout_left
		Phase.ARMED:
			return "CHOOSE B  %.2fs" % _timeout_left
		Phase.COOLDOWN:
			return "COOLDOWN %.1fs" % cooldown_left
	return "?"

func _name_of(t: NLBMotionSwapTarget) -> String:
	if t == null:
		return "?"
	if t.host != null and is_instance_valid(t.host):
		return t.display_name
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
	if is_selecting():
		draw_arc(player_pos, max_range, 0.0, TAU, 96, Color(0.45, 0.8, 0.9, 0.18), 2.0)
		for n in get_tree().get_nodes_in_group("swap_targets"):
			var t := n as NLBMotionSwapTarget
			if t == null or not t.is_valid() or _out_of_range(t):
				continue
			var point := to_local(t.anchor_world())
			var tint := Color(0.45, 0.85, 1.0, 0.65)
			draw_rect(Rect2(point - Vector2(19, 19), Vector2(38, 38)), tint, false, 1.0)
			var v := t.read_motion()
			if t.channel() == NLBMotionChannels.Channel.LINEAR and v.length() > 8.0:
				var tip := point + v.normalized() * clampf(v.length() * 0.07, 18.0, 90.0)
				draw_line(point, tip, tint, 2.0)
				draw_line(tip, tip - v.normalized().rotated(0.5) * 9.0, tint, 2.0)
				draw_line(tip, tip - v.normalized().rotated(-0.5) * 9.0, tint, 2.0)
	# Hover read-out.
	if hover_target != null and is_instance_valid(hover_target):
		var p := to_local(hover_target.anchor_world())
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
		if debug_values:
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
