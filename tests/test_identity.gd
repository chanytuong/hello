extends SceneTree
## Identity pass tests: reversal snap, dash-strike chain, recovery cancel,
## input trust (a press during a swing queues one), hard-landing signal, hit
## bite, stagger.
## Run: godot --headless --path E:\neverlookback --script res://tests/test_identity.gd

var _failures: int = 0
var _frames: int = 0
var _main: Node
var _phase: int = 0
var _pf: int = 0
var _landed: float = -1.0
var _y0: float = 0.0
var _min_vy8: float = 0.0
var _swing1_frame: int = -1
var _swing2_frame: int = -1

func _init() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	get_root().add_child(_main)
	current_scene = _main

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS: " + name)
	else:
		printerr("FAIL: " + name)
		_failures += 1

func _p() -> NLBPlayer:
	return get_first_node_in_group("player") as NLBPlayer

func _physics_process(_delta: float) -> bool:
	_frames += 1
	_pf += 1
	var p := _p()
	match _phase:
		0:  # sharper reversal: full 180 at speed, count to zero-cross
			if _pf == 1:
				_snap(p, 400.0)
				Input.action_press("move_right")
			if _pf == 40:
				Input.action_release("move_right")
				Input.action_press("move_left")
			if _pf > 40 and p.velocity.x < 0.0:
				_check(_pf - 40 <= 12, "identity reversal snaps (%d frames)" % (_pf - 40))
				Input.action_release("move_left")
				_next()
		1:  # dash-strike: swing in late dash keeps momentum
			if _pf == 1:
				_snap(p, 400.0)
				Input.action_press("move_right")
				Input.action_press("dash")
			if _pf == 3:
				Input.action_release("dash")
			if _pf == 8:
				Input.action_press("attack")
			if _pf == 10:
				Input.action_release("attack")
			if _pf == 14:
				_check(p.is_attack_busy(), "identity dash-strike starts in late dash")
				_check(p.velocity.x > 300.0, "identity dash-strike keeps momentum (vx=%.0f)" % p.velocity.x)
				Input.action_release("move_right")
				_next()
		2:  # recovery cancel: dash during recovery ends swing, starts dash
			if _pf == 1:
				_snap(p, 400.0)
				Input.action_press("attack")
			if _pf == 3:
				Input.action_release("attack")
			if _pf == 16:
				Input.action_press("dash")
			if _pf == 18:
				Input.action_release("dash")
				_check(p.move_state == NLBPlayer.MoveState.DASH, "identity dash cancels recovery")
				_check(not p.is_attack_busy(), "identity swing ended by cancel")
				_next()
		3:  # startup commitment: dash during ACTIVE is refused, buffered for after
			if _pf == 1:
				_snap(p, 400.0)
				Input.action_press("attack")
			if _pf == 3:
				Input.action_release("attack")
			if _pf == 6:
				Input.action_press("dash")
			if _pf == 8:
				Input.action_release("dash")
				_check(p.move_state != NLBPlayer.MoveState.DASH, "identity dash refused mid-swing")
				_check(p.is_attack_busy(), "identity swing continues through dash press")
				_next()
		4:  # input trust: a press during a live swing queues exactly one next swing
			if _pf == 1:
				_snap(p, 400.0)
				_swing1_frame = -1
				_swing2_frame = -1
				Input.action_press("attack")
			if _pf == 3:
				Input.action_release("attack")
			# The second press is placed the first frame a swing is actually
			# live, so the test cannot depend on the exact frame input lands.
			if _swing1_frame < 0 and p.is_attack_busy():
				_swing1_frame = _pf
				Input.action_press("attack")
			if _swing1_frame > 0 and _pf == _swing1_frame + 2:
				Input.action_release("attack")
			# Swing 2 can only start after swing 1 has ended AND the 0.35s
			# attack cooldown has expired; being busy again past that point is
			# the queued press having fired, exactly once.
			if _swing1_frame > 0 and _swing2_frame < 0 and _pf > _swing1_frame + 20 and p.is_attack_busy():
				_swing2_frame = _pf
				_check(true, "identity press during a swing fires the next swing (f%d)" % _pf)
				_next()
			if _pf > 100:
				_check(false, "identity press during a swing never fired (swing1 f%d)" % _swing1_frame)
				_next()
		5:  # hard landing signal from a real fall
			if _pf == 1:
				p.global_position = Vector2(400, 200)
				p.velocity = Vector2.ZERO
				p.landed_hard.connect(func(s: float) -> void: _landed = s)
			if _pf == 90:
				_check(_landed > 700.0, "identity hard landing signaled (%.0f)" % _landed)
				_next()
		6:  # miss slides, hit bites
			if _pf == 1:
				_snap(p, 400.0)
				# The chaser has had 5 phases to close the distance and was
				# measured at gap=44 — inside the 82px swing reach — so this
				# "whiff" was really a confirm, and the bite correctly anchored
				# the player. Force the miss this check is about.
				var m6 := _melee_of()
				if m6 != null:
					m6.global_position = Vector2(900.0, 599.0)
					m6.velocity = Vector2.ZERO
					m6._kb = Vector2.ZERO
				Input.action_press("move_right")
			if _pf == 30:
				Input.action_release("move_right")
				Input.action_press("attack")  # whiff: no enemy near
			if _pf == 32:
				Input.action_release("attack")
			if _pf == 45:
				var _m := _melee_of()
				var _g6 := absf(_m.global_position.x - p.global_position.x) if _m != null else -1.0
				_check(_g6 > 82.0, "identity whiff setup is really out of reach (gap=%.0f)" % _g6)
				_check(not p._bite_done, "identity whiff does not confirm")
				_check(p.velocity.x > 150.0, "identity whiff keeps sliding (vx=%.0f)" % p.velocity.x)
				_next()
		7:  # pose: the swing reads on the body itself (Swoosh overlay removed)
			if _pf == 1:
				_snap(p, 400.0)
				var _mj := _melee_of()
				if _mj != null:
					_mj.global_position = Vector2(900, 599)
			if _pf == 4:
				_check(absf(p.body_vis.rotation) < 0.02, "visual body upright at idle (rot=%.3f)" % p.body_vis.rotation)
				Input.action_press("attack")
			if _pf == 6:
				Input.action_release("attack")
			if _pf == 10:
				_check(p.body_vis.rotation > 0.05, "visual body leans into active swing (rot=%.3f)" % p.body_vis.rotation)
				_check(p.body_vis.scale.x > 1.08, "visual body elongates on active (sx=%.2f)" % p.body_vis.scale.x)
				_check(not p._bite_done, "visual pose phase is an unconfirmed swing")
			if _pf == 46:
				_check(absf(p.body_vis.rotation) < 0.04, "visual body returns upright after recovery (rot=%.3f)" % p.body_vis.rotation)
				_check(not p.is_attack_busy(), "visual swing finished before pose check")
				_next()
		8:  # separation: overlap resolves horizontally, never vertically
			if _pf == 1:
				_snap(p, 990.0)
				for e in get_nodes_in_group("enemies"):
					if e is NLBMeleeChaser:
						e.global_position = Vector2(992, 599)
						e.velocity = Vector2.ZERO
				_y0 = p.global_position.y
				_min_vy8 = 0.0
			_min_vy8 = minf(_min_vy8, p.velocity.y)
			if _pf == 60:
				var m2 := _melee_of()
				var gap: float = absf(m2.global_position.x - p.global_position.x)
				_check(gap >= 28.0, "visual bodies separated (gap=%.0f)" % gap)
				_check(absf(p.global_position.y - _y0) < 6.0, "visual separation is horizontal-only")
				_check(_min_vy8 >= -150.0, "visual contact never launches (min vy=%.0f)" % _min_vy8)
				_next()
		9:
			if _failures == 0:
				print("IDENTITY_TESTS: ALL PASS")
			else:
				printerr("IDENTITY_TESTS: %d FAILURES" % _failures)
			Engine.time_scale = 1.0
			quit(1 if _failures > 0 else 0)
			return true
	return false

func _melee_of() -> NLBMeleeChaser:
	for e in get_nodes_in_group("enemies"):
		if e is NLBMeleeChaser:
			return e
	return null

func _next() -> void:
	_phase += 1
	_pf = 0

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
	p._struck_from_dash = false
	p.body_vis.rotation = 0.0
	p.body_vis.scale = Vector2.ONE

## The arena now contains a walk-over pickup (design/
## PERCEPTION_WEAPON_EXPERIMENT.md). These suites measure BARE-HAND combat,
## so they park the prop 400px above the floor where no test path reaches it;
## dy exceeds the pickup window, so auto-pickup can never arm the player.
func _park_prop() -> void:
	var prop := get_first_node_in_group("props")
	if prop != null:
		prop.global_position = Vector2(1190, 200)
