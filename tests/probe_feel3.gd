extends SceneTree
## PHASE 11 observation probe (read-only): prints the numbers BEHIND the
## body-driven swing so the comparisons can be made from measurements
## instead of guessed at.
##   Q1 standing swing: body anticipation -> strike -> contact -> recovery
##   Q2 dash -> strike: same swing, launched from the dash posture
##   Q3 whiff vs hit:  the body/weapon divergence AND the enemy's reaction
##   Q4 pickup:        the body reaching, recoiling and settling
## Run: godot --headless --path E:\neverlookback --script res://tests/probe_feel3.gd

var _f: int = 0
var _phase: int = 0
var _pf: int = 0

var _log: Array = []

func _init() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	get_root().add_child(main)
	current_scene = main

func _p() -> NLBPlayer:
	return get_first_node_in_group("player") as NLBPlayer

func _melee() -> NLBMeleeChaser:
	for e in get_nodes_in_group("enemies"):
		if e is NLBMeleeChaser:
			return e
	return null

func _prop() -> NLBProp:
	return get_first_node_in_group("props") as NLBProp

func _game() -> NLBGame:
	return current_scene as NLBGame

func _park_prop() -> void:
	var pr := _prop()
	if pr != null:
		pr.global_position = Vector2(1190, 200)

func _snap(p: NLBPlayer, x: float) -> void:
	_park_prop()
	p.global_position = Vector2(x, 599)
	p.velocity = Vector2.ZERO
	p.move_state = NLBPlayer.MoveState.NORMAL
	p._atk_t = -1.0
	p._atk_cd = 0.0
	p._atk_buf = 0.0
	p._dash_t = 0.0
	p._dash_cd = 0.0
	p._struck_from_dash = false
	p._bite_done = false
	p.perception_pose = -1
	p.body_vis.rotation = 0.0
	p.body_vis.scale = Vector2.ONE

func _sample(p: NLBPlayer) -> Dictionary:
	var arc := 0.0
	var pr := _prop()
	if pr != null and pr.armed():
		arc = pr.hero.rotation
	return {
		"f": _pf,
		"atk": snappedf(p._atk_t, 0.001),
		"dash": p._struck_from_dash,
		"vx": snappedf(p.velocity.x, 1.0),
		"rot": snappedf(p.body_vis.rotation, 0.001),
		"sx": snappedf(p.body_vis.scale.x, 0.01),
		"sy": snappedf(p.body_vis.scale.y, 0.01),
		"arc": snappedf(arc, 0.01),
	}

func _enemy_sample(m: NLBMeleeChaser) -> Dictionary:
	return {
		"f": _pf,
		"hp": m.health.hp,
		"x": snappedf(m.global_position.x, 1.0),
		"rot": snappedf(m.body_vis.rotation, 0.001),
		"sx": snappedf(m.body_vis.scale.x, 0.01),
		"sy": snappedf(m.body_vis.scale.y, 0.01),
		"stag": snappedf(m._stagger_t, 0.001),
		"rec": snappedf(m._recoil_t, 0.001),
	}

## Condense a pose log into the four numbers that actually matter:
## min rotation (how far it coils AWAY), max rotation (how far it commits),
## the scale range, and the swing's total arc span.
func _summarise(log: Array) -> String:
	if log.is_empty():
		return "(empty)"
	var rmin := 99.0
	var rmax := -99.0
	var sxmin := 99.0
	var sxmax := -99.0
	var amin := 99.0
	var amax := -99.0
	var f_at_rmin := -1
	var f_at_rmax := -1
	for s: Dictionary in log:
		var r: float = s["rot"]
		var sx: float = s["sx"]
		var a: float = s["arc"]
		if r < rmin:
			rmin = r
			f_at_rmin = int(s["f"])
		if r > rmax:
			rmax = r
			f_at_rmax = int(s["f"])
		sxmin = minf(sxmin, sx)
		sxmax = maxf(sxmax, sx)
		if a != 0.0:
			amin = minf(amin, a)
			amax = maxf(amax, a)
	var arc_txt := "arc n/a"
	if amin < 90.0:
		arc_txt = "arc %.2f..%.2f" % [amin, amax]
	return "rot %.3f(f%d) -> %.3f(f%d)  span=%.3frad | sx %.2f..%.2f | %s" % [
		rmin, f_at_rmin, rmax, f_at_rmax, rmax - rmin, sxmin, sxmax, arc_txt]

func _print_pose(tag: String) -> void:
	print("%s  %s" % [tag, _summarise(_log)])
	# frame-by-frame for the two phases where the phase structure matters.
	var rows := PackedStringArray()
	for s: Dictionary in _log:
		if int(s["f"]) > 30:
			break
		rows.append("f%d a%+.3f r%+.3f s%.2f/%.2f a%+.2f" % [
			int(s["f"]), float(s["atk"]), float(s["rot"]),
			float(s["sx"]), float(s["sy"]), float(s["arc"])])
	print("%s_TIMELINE %s" % [tag, " ".join(rows)])
	_log = []

func _next() -> void:
	_phase += 1
	_pf = 0

func _physics_process(_delta: float) -> bool:
	_f += 1
	_pf += 1
	var p := _p()
	match _phase:
		# ------------------------------------ Q1: standing swing (bare hands)
		0:
			if _pf == 1:
				_snap(p, 300.0)
			if _pf == 5:
				Input.action_press("attack")
			if _pf == 7:
				Input.action_release("attack")
			if _pf >= 5 and _pf <= 40:
				_log.append(_sample(p))
			if _pf == 40:
				_print_pose("Q1_STANDING_WHIFF")
				_next()
		# ------------------------------------ Q2: dash -> strike (bare hands)
		1:
			if _pf == 1:
				_snap(p, 260.0)
				Input.action_press("move_right")
				Input.action_press("dash")
			if _pf == 3:
				Input.action_release("dash")
			if _pf == 6:
				Input.action_press("attack")
			if _pf == 8:
				Input.action_release("attack")
			if _pf >= 1 and _pf <= 40:
				_log.append(_sample(p))
			if _pf == 40:
				Input.action_release("move_right")
				_print_pose("Q2_DASH_STRIKE")
				_next()
		# ------------------------- Q3: weapon hit -> body bite + enemy recoil
		2:
			if _pf == 1:
				_snap(p, 300.0)
				var pr := _prop()
				if pr != null:
					pr.global_position = Vector2(330, 594)
				var m := _melee()
				# Park the foe well clear while the pickup happens: a clean
				# walk-over, then the target is dropped into reach on frame.
				m.global_position = Vector2(900, 599)
				m.velocity = Vector2.ZERO
				m._kb = Vector2.ZERO
				m._cd = 99.0
				m.ai_state = NLBMeleeChaser.AIState.CHASE
				m.body_vis.rotation = 0.0
				m.body_vis.scale = Vector2.ONE
			if _pf >= 1 and _pf <= 14:
				# walk onto the pipe so this is an ARMED hit
				Input.action_press("move_right")
			if _pf == 14:
				Input.action_release("move_right")
			if _pf == 16:
				var m1 := _melee()
				if m1 != null:
					m1.global_position = Vector2(p.global_position.x + 60.0, 599)
					m1.velocity = Vector2.ZERO
					m1._kb = Vector2.ZERO
					m1.body_vis.rotation = 0.0
					m1.body_vis.scale = Vector2.ONE
			if _pf == 17:
				Input.action_press("attack")
			if _pf == 19:
				Input.action_release("attack")
			if _pf >= 17 and _pf <= 70:
				_log.append(_sample(p))
				var m2 := _melee()
				if m2 != null:
					_log.append({"enemy": true, "row": _enemy_sample(m2)})
			if _pf == 70:
				var body_rows := PackedStringArray()
				var foe_rows := PackedStringArray()
				for s: Dictionary in _log:
					if s.has("enemy"):
						var e: Dictionary = s["row"]
						foe_rows.append("f%d hp%d x%.0f r%+.3f s%.2f/%.2f rec%.3f" % [
							int(e["f"]), int(e["hp"]), float(e["x"]), float(e["rot"]),
							float(e["sx"]), float(e["sy"]), float(e["rec"])])
					else:
						body_rows.append("f%d a%+.3f r%+.3f s%.2f/%.2f a%+.2f" % [
							int(s["f"]), float(s["atk"]), float(s["rot"]),
							float(s["sx"]), float(s["sy"]), float(s["arc"])])
				print("Q3_ARMED_HIT_BODY %s" % " ".join(body_rows))
				print("Q3_ARMED_HIT_ENEMY %s" % " ".join(foe_rows))
				_log = []
				_next()
		# ------------------------------------ Q4: the pickup / perception pose
		3:
			if _pf == 1:
				_snap(p, 400.0)
				var pr2 := _prop()
				if pr2 != null:
					pr2.global_position = Vector2(420, 594)
			if _pf >= 1 and _pf <= 45:
				_log.append(_sample(p))
			if _pf == 45:
				_print_pose("Q4_PICKUP_POSE")
				_next()
		4:
			print("PROBE3_DONE")
			quit(0)
			return true
	return false
