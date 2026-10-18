extends SceneTree
## Feel sims with synthetic input across real physics frames:
## reversal snap, short vs full hop, platform reach, swing confirm
## (damage + knockback + hitstop restore), miss = no-op, ranged lock-freeze.
## Run: godot --headless --path E:\neverlookback --script res://tests/test_feel.gd

var _failures: int = 0
var _frames: int = 0
var _main: Node
var _phase: int = 0
var _phase_frame: int = 0
var _reversal_frames: int = -1
var _min_y_full: float = 9999.0
var _min_y_tap: float = 9999.0
var _melee_hp0: int = 3
var _kb_max: float = 0.0
var _shot_dir: Vector2 = Vector2.ZERO
var _shot_from: Vector2 = Vector2.ZERO

func _init() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	get_root().add_child(_main)

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS: " + name)
	else:
		printerr("FAIL: " + name)
		_failures += 1

func _player() -> NLBPlayer:
	return get_first_node_in_group("player") as NLBPlayer

func _physics_process(_delta: float) -> bool:
	_frames += 1
	_phase_frame += 1
	var p := _player()
	match _phase:
		0:  # run right to speed
			Input.action_press("move_right")
			if _phase_frame > 40:
				_next()
		1:  # 180° reversal timing
			if _phase_frame == 1:
				Input.action_release("move_right")
				Input.action_press("move_left")
			if p.velocity.x < 0.0 and _reversal_frames < 0:
				_reversal_frames = _phase_frame
			if _phase_frame > 40:
				_check(_reversal_frames > 0 and _reversal_frames <= 14, "feel reversal crosses zero fast (%d frames)" % _reversal_frames)
				Input.action_release("move_left")
				_next()
		2:  # full-hop apex
			if _phase_frame == 1:
				_snap(p, 400.0)
				Input.action_press("jump")
			_min_y_full = minf(_min_y_full, p.global_position.y)
			if _phase_frame > 70:
				Input.action_release("jump")
				_next()
		3:  # tap-hop apex
			if _phase_frame == 1:
				_snap(p, 400.0)
				Input.action_press("jump")
			if _phase_frame == 4:
				Input.action_release("jump")
			_min_y_tap = minf(_min_y_tap, p.global_position.y)
			if _phase_frame > 70:
				_check(_min_y_full < 600.0 - 100.0, "feel full hop high (apex y=%.0f)" % _min_y_full)
				_check(_min_y_tap > _min_y_full + 40.0, "feel tap hop short (y=%.0f vs %.0f)" % [_min_y_tap, _min_y_full])
				_next()
		4:  # platform reach: jump from the SIDE (x=760), drift right onto top
			if _phase_frame == 1:
				_snap(p, 760.0)
				_min_y_full = 9999.0
				Input.action_press("move_right")
				Input.action_press("jump")
			if _phase_frame == 30:
				Input.action_release("jump")
			if _phase_frame == 45:
				Input.action_release("move_right")
			_min_y_full = minf(_min_y_full, p.global_position.y)
			if _phase_frame > 110:
				_check(_min_y_full <= 482.0, "feel platform reachable (min y=%.0f, top=480)" % _min_y_full)
				_check(p.is_on_floor() and p.global_position.y < 550.0, "feel lands ON platform (y=%.0f)" % p.global_position.y)
				_next()
		5:  # swing confirm vs melee: pin melee in range, then swing
			if _phase_frame == 1:
				_snap(p, 990.0)
				p.facing = 1
				var m0 := _melee()
				m0.global_position = Vector2(1005, 599)
				m0.velocity = Vector2.ZERO
				m0.ai_state = NLBMeleeChaser.AIState.CHASE
				_melee_hp0 = m0.health.hp
				_kb_max = 0.0
				Input.action_press("attack")
			if _phase_frame == 3:
				Input.action_release("attack")
			_kb_max = maxf(_kb_max, _melee().global_position.x)
			if _phase_frame == 40:
				var m := _melee()
				_check(m.health.hp < _melee_hp0, "feel swing connects (melee hp %d->%d)" % [_melee_hp0, m.health.hp])
				_check(_kb_max > 1015.0, "feel knockback shoves (peak x=%.0f)" % _kb_max)
				_check(Engine.time_scale == 1.0, "feel hitstop restored (scale=%.2f)" % Engine.time_scale)
				_next()
		6:  # ranged lock-freeze: aim, then dodge late; shot must keep old line
			if _phase_frame == 1:
				var r := _ranged()
				_snap(p, 700.0)
				r.global_position = Vector2(950, 599)
				r.velocity = Vector2.ZERO
				r.ai_state = NLBRangedEnemy.AIState.AIM
				r._state_t = r.aim_time
			if _phase_frame == 12:
				_snap(p, 200.0)  # dodge inside the 0.15s lock window
			if _phase_frame == 45:
				var shots := get_nodes_in_group("projectiles")
				_check(shots.size() >= 1, "feel ranged fired (%d shots)" % shots.size())
				if shots.size() >= 1:
					var s := shots[0] as NLBProjectile
					var to_now: Vector2 = (p.global_position - s.global_position).normalized()
					var ang: float = absf(s.velocity.normalized().angle_to(to_now))
					_check(ang > 0.15, "feel locked shot does not track dodge (%.2f rad)" % ang)
					s.queue_free()
				_next()
		7:
			if _failures == 0:
				print("FEEL_TESTS: ALL PASS")
			else:
				printerr("FEEL_TESTS: %d FAILURES" % _failures)
			Engine.time_scale = 1.0
			quit(1 if _failures > 0 else 0)
			return true
	return false

func _next() -> void:
	_phase += 1
	_phase_frame = 0

func _snap(p: NLBPlayer, x: float) -> void:
	_park_prop()
	p.global_position = Vector2(x, 599)
	p.velocity = Vector2.ZERO

## Arena now has a walk-over pickup; these suites measure bare hands, so park
## it 400px up where dy puts it outside the pickup window.
func _park_prop() -> void:
	var prop := get_first_node_in_group("props")
	if prop != null:
		prop.global_position = Vector2(1190, 200)

func _melee() -> NLBMeleeChaser:
	return _find_melee()

func _find_melee() -> NLBMeleeChaser:
	for e in get_nodes_in_group("enemies"):
		if e is NLBMeleeChaser:
			return e
	return null

func _ranged() -> NLBRangedEnemy:
	for e in get_nodes_in_group("enemies"):
		if e is NLBRangedEnemy:
			return e
	return null
