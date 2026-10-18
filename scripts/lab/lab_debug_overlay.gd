extends CanvasLayer
class_name LabDebugOverlay
## Compact Motion Swap debug read-out. Shows the STATE OF THE EXCHANGE, not a
## wall of numbers: who is A, who is hovered, whether the pair is compatible,
## what each target's exchangeable quantity currently is, how long an override
## has left, what the machines are running at, and what the lab just said.
##
## F1 expands details; the compact instructions/timer remain visible by default.
## The HUD uses real time so slow motion never delays selection or stun feedback.

const REFRESH := 0.1
const MSG_TIME := 3.0

var lab: Node = null
var controller: NLBMotionSwapController = null
var player: Node2D = null

var message: String = ""
var debug_expanded: bool = false
var _veil: ColorRect
var _bar: ColorRect

var _panel: ColorRect
var _label: Label
var _refresh: float = 0.0
var _msg_t: float = 0.0
var _last_real_tick: int = 0

func _ready() -> void:
	layer = 20
	_veil = ColorRect.new()
	_veil.color = Color(0.10, 0.30, 0.40, 0.06)
	_veil.size = Vector2(1280, 720)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_veil)
	_panel = ColorRect.new()
	_panel.name = "Panel"
	_panel.color = Color(0.02, 0.04, 0.06, 0.72)
	_panel.position = Vector2(10, 10)
	_panel.size = Vector2(780, 112)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_label = Label.new()
	_label.name = "Readout"
	_label.position = Vector2(20, 16)
	_label.size = Vector2(740, 300)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_constant_override("line_spacing", 0)
	_label.add_theme_color_override("font_color", Color(0.78, 0.92, 0.98))
	add_child(_label)
	_bar = ColorRect.new()
	_bar.position = Vector2(10, 122)
	_bar.color = Color(0.35, 0.85, 1.0, 0.8)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar)
	_last_real_tick = Time.get_ticks_usec()

func set_message(text: String) -> void:
	message = text
	_msg_t = MSG_TIME

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var real_delta := float(now - _last_real_tick) / 1000000.0
	_last_real_tick = now
	if controller != null:
		_veil.visible = controller.is_selecting()
		_bar.visible = controller.is_selecting()
		_bar.size = Vector2(780.0 * controller._timeout_left / maxf(controller.selection_timeout, 0.01), 2.0)
	_msg_t = maxf(_msg_t - real_delta, 0.0)
	if _msg_t <= 0.0:
		message = ""
	_panel.size.y = 300.0 if debug_expanded else 112.0
	_bar.position.y = _panel.position.y + _panel.size.y
	_label.add_theme_font_size_override("font_size", 13 if debug_expanded else 14)
	if not debug_expanded:
		_label.text = _compact() # selection/stun feedback updates on the next visible frame
	_refresh -= real_delta
	if _refresh > 0.0 or not debug_expanded:
		return
	_refresh = REFRESH
	if not visible:
		return
	_label.text = _compose()

func _compact() -> String:
	if controller == null:
		return ""
	var status := "STUN %.2fs" % player.motion_stun_t if player != null and player.motion_stun_t > 0.0 else controller.phase_label()
	return "%s  ·  %s\n%s  ·  OD %s  ·  HP %d/%d\nE slow / cancel  ·  LMB A → B  ·  Q / RMB Iven  ·  Esc cancel\n1 retry  ·  2 clear motion  ·  3 enemies  ·  F2–F7 zones  ·  F1 details  ·  F8 OD  ·  R restart\n%s" % [
		lab.current_zone().get_meta("title", "LAB") if lab != null and lab.current_zone() != null else "LAB",
		status, "LAUNCHED" if player != null and player.swap_override_t > 0.0 else "",
		"ON" if controller.overdrive_enabled else "OFF", _player_hp(), _player_max_hp(),
		message.left(108) if not message.is_empty() else controller.last_feedback.left(108)]

func _compose() -> String:
	var lines: Array[String] = []
	if lab != null and lab.has_method("lab_status_line"):
		lines.append(lab.lab_status_line())
	if controller != null:
		lines.append("swap  %-14s  cooldown %.2fs   targets %d live / %d disabled" % [
			controller.phase_label(), controller.cooldown_left,
			_live_targets(), _disabled_targets()])
		lines.append("A     %s" % _target_line(controller.target_a))
		lines.append("hover %s   pair: %s" % [
			_target_line(controller.hover_target), _compat_line()])
	lines.append("player %s   hp %d/%d   floor %s" % [
		_vec(player.global_position if player != null else Vector2.ZERO),
		_player_hp(), _player_max_hp(),
		"yes" if (player is CharacterBody2D and (player as CharacterBody2D).is_on_floor()) else "no"])
	lines.append("player v %s" % _vec(_player_velocity()))
	if player != null and player.swap_target != null:
		lines.append("Iven received %s → Overdrive %s   launch %.2f   stun %.2f" % [
			_vec(player.swap_target.received_velocity), _vec(player.swap_target.overdrive_velocity), player.swap_override_t, player.motion_stun_t])
	if controller != null and not controller.last_exchange.is_empty():
		var last := controller.last_exchange
		lines.append("exchange A received %s → final %s | B received %s → final %s" % [_vec(last.a_received), _vec(last.a_final), _vec(last.b_received), _vec(last.b_final)])
	lines.append("machines  %s" % _machine_lines())
	lines.append("enemies   %s" % _enemy_lines())
	lines.append("shots     %s" % _shot_lines())
	lines.append("last      %s" % (controller.last_feedback if controller != null else "-"))
	if not message.is_empty():
		lines.append("lab       %s" % message)
	lines.append("E slow/cancel · LMB A/B · Q/RMB Iven · Esc cancel · 1 retry · F2–F7 zones · F8 OD · F1 details")
	return "\n".join(lines)

func _live_targets() -> int:
	var n := 0
	for t in get_tree().get_nodes_in_group("swap_targets"):
		var tgt := t as NLBMotionSwapTarget
		if tgt != null and tgt.is_inside_tree() and tgt.is_valid():
			n += 1
	return n

func _disabled_targets() -> int:
	var n := 0
	for t in get_tree().get_nodes_in_group("swap_targets"):
		var tgt := t as NLBMotionSwapTarget
		if tgt != null and tgt.is_inside_tree() and not tgt.is_valid():
			n += 1
	return n

func _target_line(t: NLBMotionSwapTarget) -> String:
	if t == null or not is_instance_valid(t):
		return "—"
	var name := t.display_name
	if t.host != null and is_instance_valid(t.host):
		name += "#%d" % (t.host.get_instance_id() % 1000)
	var s := "%s [%s] %s" % [name, t.channel_label(), t.describe()]
	var rem := t.override_remaining()
	if rem >= 0.0:
		s += "  override %.1fs" % rem
	return s

func _compat_line() -> String:
	if controller == null or controller.target_a == null:
		return "pick target A"
	var h := controller.hover_target
	if h == null or not is_instance_valid(h) or h == controller.target_a:
		return "pick target B"
	if not h.is_valid():
		return "B is not swappable right now"
	if NLBMotionChannels.compatible(controller.target_a.channel(), h.channel()):
		return "compatible"
	return "REFUSED (%s)" % NLBMotionChannels.label(h.channel())

func _machine_lines() -> String:
	var parts: Array[String] = []
	for n in get_tree().get_nodes_in_group("lab_machines"):
		if player != null and n is Node2D and absf(n.global_position.x - player.global_position.x) > 700.0:
			continue
		if n.has_method("debug_line"):
			parts.append(n.debug_line())
	if parts.is_empty():
		return "—"
	return "  |  ".join(parts)

func _enemy_lines() -> String:
	var parts: Array[String] = []
	for n in get_tree().get_nodes_in_group("lab_enemies"):
		if player != null and absf(n.global_position.x - player.global_position.x) > 700.0:
			continue
		if n.has_method("debug_line") and n.has_method("ai_state_name"):
			parts.append("%s %s" % [n.debug_line(), n.ai_state_name()])
	if parts.is_empty():
		return "—"
	return "  |  ".join(parts)

func _shot_lines() -> String:
	var live := 0
	var parked := 0
	for n in get_tree().get_nodes_in_group("lab_projectiles"):
		live += 1
		var p := n as LabProjectile
		if p != null and p.velocity.length() < LabProjectile.PARKED_SPEED:
			parked += 1
	return "%d live, %d parked/expiring" % [live, parked]

func _player_hp() -> int:
	if player == null:
		return 0
	var h := player.get_node_or_null("Health") as NLBHealth
	return h.hp if h != null else 0

func _player_max_hp() -> int:
	if player == null:
		return 0
	var h := player.get_node_or_null("Health") as NLBHealth
	return h.max_hp if h != null else 0

func _player_velocity() -> Vector2:
	if player is CharacterBody2D:
		return (player as CharacterBody2D).velocity
	return Vector2.ZERO

func _vec(v: Vector2) -> String:
	return "(%.0f, %.0f)" % [v.x, v.y]
