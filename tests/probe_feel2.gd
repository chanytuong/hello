extends SceneTree
## Probe 2: quantitative feel audit.
## P0 WHIFF (running) vs P1 HIT (running) — same input, different outcome.
##   measures: player velocity curve, travelled distance, gap trajectory,
##   hits per swing, minimum body gap (bodies touch at 30.0).
## P2 dash straight into an enemy — measures interpenetration depth/duration.

var _phase: int = 0
var _pf: int = 0
var _main: Node

# P0/P1
var _hit_log: Array = []
var _hp0: int = -1
var _hits: int = 0
var _min_gap: float = 9999.0
var _min_vy: float = 0.0
var _x_start: float = 0.0
var _x_end: float = 0.0

# P2
var _ov: Array = []
var _ov_worst: float = 9999.0
var _ov_frames: int = 0

func _init() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	get_root().add_child(_main)
	current_scene = _main

func _p() -> NLBPlayer:
	return get_first_node_in_group("player") as NLBPlayer

func _melee() -> NLBMeleeChaser:
	for e in get_nodes_in_group("enemies"):
		if e is NLBMeleeChaser:
			return e
	return null

func _snap(p: NLBPlayer, x: float) -> void:
	_park_prop()
	p.global_position = Vector2(x, 599)
	p.velocity = Vector2.ZERO
	p.move_state = NLBPlayer.MoveState.NORMAL
	p._atk_t = -1.0
	p._dash_cd = 0.0
	p._dash_buf = 0.0
	p._dash_t = 0.0
	p._atk_cd = 0.0
	p._atk_buf = 0.0
	p._hurt_t = 0.0
	p._struck_from_dash = false
	p.body_vis.rotation = 0.0
	p.body_vis.scale = Vector2.ONE

## Arena now has a walk-over pickup; this probe measures bare hands, so park
## it 400px up where dy puts it outside the pickup window.
func _park_prop() -> void:
	var prop := get_first_node_in_group("props")
	if prop != null:
		prop.global_position = Vector2(1190, 200)

func _place(m: NLBMeleeChaser, x: float) -> void:
	m.global_position = Vector2(x, 599)
	m.velocity = Vector2.ZERO
	m._kb = Vector2.ZERO
	m._cd = 99.0
	m._stagger_t = 0.0
	m.ai_state = NLBMeleeChaser.AIState.CHASE

func _physics_process(_delta: float) -> bool:
	_pf += 1
	var p := _p()
	var m := _melee()
	match _phase:
		0:  # WHIFF while running: baseline momentum
			if _pf == 1:
				_snap(p, 300.0)
				m.global_position = Vector2(900, 599)  # far away: clean miss
				_place(m, 900.0)
				_x_start = p.global_position.x
				Input.action_press("move_right")
				Input.action_press("attack")
			if _pf == 3:
				Input.action_release("attack")
			if _pf >= 1 and _pf <= 45:
				_hit_log.append(_row("W", _pf, p, m))
			if _pf == 45:
				Input.action_release("move_right")
				_x_end = p.global_position.x
				print("P0_WHIFF travel=%.0f minGap=%.0f" % [_x_end - _x_start, _min_gap])
				print("P0_TRACE %s" % _trace())
				_reset()
				_next()
		1:  # HIT while running: identical input, enemy in range
			if _pf == 1:
				_snap(p, 300.0)
				_place(m, 352.0)
				_hp0 = m.health.hp
				m.health.changed.connect(func(c: int, _mx: int) -> void:
					_hits += 1
					print("HITCALL #%d frame %d -> hp %d" % [_hits, _pf, c]))
				_x_start = p.global_position.x
				Input.action_press("move_right")
				Input.action_press("attack")
			if _pf == 3:
				Input.action_release("attack")
			if _pf >= 1 and _pf <= 45:
				_hit_log.append(_row("H", _pf, p, m))
				if m != null:
					_min_vy = minf(_min_vy, m.velocity.y)
					_min_gap = minf(_min_gap, m.global_position.x - p.global_position.x)
			if _pf == 45:
				Input.action_release("move_right")
				_x_end = p.global_position.x
				print("P1_HIT travel=%.0f minGap=%.1f hitsPerSwing=%d startGapEnd=%.0f" % [
					_x_end - _x_start, _min_gap, _hits, m.global_position.x - p.global_position.x])
				print("P1_ENEMY_MIN_VY %.1f (0.0 = no launch)" % _min_vy)
				print("P1_TRACE %s" % _trace())
				_reset()
				_next()
		2:  # dash straight through an enemy
			if _pf == 1:
				_snap(p, 260.0)
				_place(m, 420.0)
				Input.action_press("move_right")
				Input.action_press("dash")
			if _pf == 3:
				Input.action_release("dash")
			if _pf >= 1 and _pf <= 40 and m != null:
				var gap: float = m.global_position.x - p.global_position.x
				_ov_worst = minf(_ov_worst, gap)
				if absf(gap) < 30.0:
					_ov_frames += 1
				_ov.append("%d:g%d" % [_pf, gap])
			if _pf == 40:
				Input.action_release("move_right")
				print("P2_DASH worst_gap=%.0f overlapping_frames=%d (%.0fms) of 40" % [
					_ov_worst, _ov_frames, _ov_frames * 1000.0 / 60.0])
				print("P2_TRACE %s" % " ".join(_ov))
				_next()
		3:
			print("PROBE2_DONE")
			quit(0)
			return true
	return false

func _row(tag: String, f: int, p: NLBPlayer, m: NLBMeleeChaser) -> Dictionary:
	var d := {"t": tag, "f": f, "vx": snappedf(p.velocity.x, 1.0),
		"atk": snappedf(p._atk_t, 0.001), "px": snappedf(p.global_position.x, 1.0)}
	if m != null:
		d["gap"] = snappedf(m.global_position.x - p.global_position.x, 1.0)
		d["vy"] = snappedf(m.velocity.y, 1.0)
	return d

func _trace() -> String:
	var out := ""
	for r in _hit_log:
		out += "%d:v%+d a%.2f p%.0f" % [r["f"], r["vx"], r["atk"], r["px"]]
		if r.has("gap"):
			out += " g%.0f" % r["gap"]
		out += " | "
	return out

func _reset() -> void:
	_hit_log = []
	_min_gap = 9999.0
	_min_vy = 0.0
	_hits = 0

func _next() -> void:
	_phase += 1
	_pf = 0
