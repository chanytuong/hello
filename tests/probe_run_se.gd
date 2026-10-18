extends SceneTree
## RUN_SE integration probe: loads the REAL main scene, drives the REAL input
## actions and records which player frame/texture/pivot/facing the renderer
## is actually given every physics tick. Run graphically (no --headless) to
## also save screenshots to docs/run_se_integration/capture/.
## Exit 0 only if every check passes.

const SHOT_DIR := "res://docs/run_se_integration/capture/"
const MAX_F := 3000

var _f := 0
var _t := 0
var _phase := "boot"
var _main: Node = null
var _p: Node = null
var _fail := 0
var _pass := 0
var _graphical := false
var _seq: Array = []            # run frame indices observed in the current phase
var _changes := 0
var _bad_steps := 0
var _last := ""
var _flags := {}
var _bad_run_ticks := 0
var _inv := {}            # invariant violations, never reset
var _shots := {}

func _init() -> void:
	_graphical = DisplayServer.get_name() != "headless"
	if _graphical:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_main = load("res://scenes/main.tscn").instantiate()
	get_root().add_child(_main)
	current_scene = _main

func _player() -> Node:
	if _p == null:
		_p = _main.get_node("Player")
	return _p

func _check(ok: bool, msg: String) -> void:
	if ok:
		_pass += 1
		print("PASS: " + msg)
	else:
		_fail += 1
		print("FAIL: " + msg)

func _release_all() -> void:
	for a in ["move_left", "move_right", "jump", "dash", "attack"]:
		Input.action_release(a)

func _shot(tag: String) -> void:
	if not _graphical or _shots.has(tag):
		return
	_shots[tag] = true
	get_root().get_texture().get_image().save_png(ProjectSettings.globalize_path(SHOT_DIR + tag + ".png"))
	var sp: Vector2 = _player().get_global_transform_with_canvas().origin
	print("SHOT %s screen=%.0f,%.0f frame=%s sx=%.0f" % [tag, sp.x, sp.y, _player()._frame_shown, _player().sprite.scale.x])

func _next(phase: String) -> void:
	# harness only: keep run segments clear of the arena edge (wall = idle by design)
	if phase in ["prejump", "dash", "attack", "damage"] and _p != null:
		_p.global_position.x = 750.0   # clear of the hazard strip (500-650)
	_phase = phase
	_t = 0
	_seq = []
	_changes = 0
	_bad_steps = 0
	_flags = {}

func _run_idx(name: String) -> int:
	if name.begins_with("run_se_"):
		return int(name.substr(7, 2))
	return -1

## Per-tick observation + invariants that must hold in EVERY state.
func _observe() -> void:
	var p := _player()
	var shown: String = p._frame_shown
	var tex: Texture2D = p.sprite.texture
	var tex_file := str(tex.resource_path).get_file() if tex != null else "none"
	var is_run := shown.begins_with("run_se_")
	# texture / pivot / facing contract
	if is_run:
		if tex_file != shown or tex.get_width() != 88 or tex.get_height() != 88 or p.sprite.offset != Vector2(-44, -71):
			_inv["run_contract_broken"] = "%s tex=%s off=%s" % [shown, tex_file, str(p.sprite.offset)]
	else:
		if tex != null and (tex.get_width() != 64 or p.sprite.offset != Vector2(-32, -62)):
			_inv["legacy_contract_broken"] = "%s tex=%s off=%s" % [shown, tex_file, str(p.sprite.offset)]
	if p.sprite.position != Vector2.ZERO:
		_inv["sprite_drift"] = str(p.sprite.position)
	if signf(p.sprite.scale.x) != float(p.facing):
		_inv["facing_mismatch"] = "sx=%.0f facing=%d" % [p.sprite.scale.x, p.facing]
	if p.sprite.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		_inv["filter"] = str(p.sprite.texture_filter)
	# run may only show when actually running on the ground
	if is_run and not (p.is_on_floor() and absf(p.get_real_velocity().x) > p.RUN_MIN_SPEED):
		_bad_run_ticks += 1
		if _bad_run_ticks >= 2:
			_inv["run_while_not_grounded_running"] = "%s phase=%s floor=%s real_vx=%.1f" % [shown, _phase, str(p.is_on_floor()), p.get_real_velocity().x]
	else:
		_bad_run_ticks = 0
	if shown != _last:
		print("  t=%4d %-10s %-16s -> %-16s tex=%-16s off=%s sx=%.0f floor=%s vx=%7.1f move=%d atk=%.3f" % [
			_f, _phase, _last, shown, tex_file, str(p.sprite.offset), p.sprite.scale.x,
			str(p.is_on_floor()), p.velocity.x, p.move_state, p._atk_t])
		var a := _run_idx(_last)
		var b := _run_idx(shown)
		if b >= 0:
			_seq.append(b)
			if a >= 0:
				_changes += 1
				if b != (a + 1) % 8:
					_bad_steps += 1
		_last = shown

func _physics_process(_delta: float) -> bool:
	_f += 1
	if _f >= MAX_F:
		print("PROBE_TIMEOUT phase=%s" % _phase)
		quit(1)
		return true
	if _f < 30:
		return false
	_t += 1
	var p := _player()
	_observe()
	match _phase:
		"boot":
			# Animation probe only: park the enemies so the scripted input
			# sequence is deterministic (damage is exercised via health below).
			for en in ["Melee", "Ranged"]:
				var n := _main.get_node_or_null(en)
				if n != null:
					n.process_mode = Node.PROCESS_MODE_DISABLED
					n.visible = false
			# harness: stray hazard contact must not trigger the death->reload path
			p.health.max_hp = 999
			p.health.reset()
			_check(p._run_cache.size() == 8, "8 approved run frames loaded (%d)" % p._run_cache.size())
			for i in 8:
				var tex: Texture2D = p._run_cache.get("run_se_%02d.png" % i)
				_check(tex != null and tex.resource_path == "res://art/character/player/run_southeast/run_se_%02d.png" % i, "run_se_%02d bound from production folder" % i)
			_next("idle")
		"idle":
			if _t == 20:
				_check(p._frame_shown == "neutral.png", "idle shows neutral (%s)" % p._frame_shown)
				_shot("01_idle")
				Input.action_press("move_right")
				_next("run_right")
		"run_right":
			var idx := _run_idx(p._frame_shown)
			if idx >= 0:
				_shot("02_run_right_f%d" % idx)
			if _t == 150:
				_check(_seq.size() > 0 and _seq[0] >= 0, "idle -> run switches to run_se on the ground")
				var distinct := {}
				for s in _seq:
					distinct[s] = true
				_check(distinct.size() == 8, "sustained right run shows all 8 frames (%d distinct)" % distinct.size())
				_check(_bad_steps == 0, "run frames advance strictly 0..7 in order, no restart (%d bad steps over %d changes)" % [_bad_steps, _changes])
				_check(_changes >= 16, "cycle loops cleanly past frame 7 -> 0 (%d changes)" % _changes)
				_check(p.sprite.scale.x == 1.0, "right run is unflipped South-East")
				var ticks_per_frame := 120.0 / maxf(1.0, float(_changes))
				print("  RUN cadence ~%.2f ticks/frame at vx=%.1f -> %.1f drawings/s" % [ticks_per_frame, p.velocity.x, 60.0 / ticks_per_frame])
				Input.action_release("move_right")
				_next("stop")
		"stop":
			if _t == 40:
				_check(p._frame_shown == "neutral.png", "run -> idle returns to neutral (%s)" % p._frame_shown)
				_check(p.sprite.offset == Vector2(-32, -62), "idle pivot restored (%s)" % str(p.sprite.offset))
				_shot("03_stop_idle")
				Input.action_press("move_left")
				_next("run_left")
		"run_left":
			var idx2 := _run_idx(p._frame_shown)
			if idx2 >= 0:
				_shot("04_run_left_f%d" % idx2)
			if _t == 90:
				_check(p.sprite.scale.x == -1.0, "left run is the mirrored South-East (sx=-1)")
				_check(_seq.size() >= 8 and _bad_steps == 0, "left run cycles in order (%d frames, %d bad)" % [_seq.size(), _bad_steps])
				_next("reverse")
		"reverse":
			# rapid reversals every 6 ticks
			var right := (_t / 6) % 2 == 0
			Input.action_release("move_left" if right else "move_right")
			Input.action_press("move_right" if right else "move_left")
			if _t == 72:
				_check(not _inv.has("facing_mismatch"), "rapid reversal keeps sprite facing == input facing")
				Input.action_release("move_left")
				Input.action_press("move_right")
				_next("prejump")
		"prejump":
			if _t == 1:
				p.global_position.x = 750.0   # harness: clear of the arena edge
			if _t == 40:
				_check(_run_idx(p._frame_shown) >= 0, "running again before jump (%s)" % p._frame_shown)
				Input.action_press("jump")
				_next("jump")
		"jump":
			if not p.is_on_floor():
				_flags["air"] = true
				if _run_idx(p._frame_shown) >= 0:
					_flags["run_in_air"] = true
				_shot("05_jump_air")
			if _t == 4:
				Input.action_release("jump")
			if _flags.has("air") and p.is_on_floor() and not _flags.has("landed"):
				_flags["landed"] = _t
			if _flags.has("landed") and _t == int(_flags["landed"]) + 12:
				_check(not _flags.has("run_in_air"), "run -> jump: no run frame while airborne")
				_check(_run_idx(p._frame_shown) >= 0, "jump -> run: run resumes after landing while held (%s)" % p._frame_shown)
				_shot("06_land_run")
				Input.action_press("dash")
				_next("dash")
			elif _t > 120:
				_check(false, "jump phase landed in time")
				_next("dash")
		"dash":
			if p.move_state == 1:
				_flags["dashed"] = true
				_shot("07_dash")
			if _t == 3:
				Input.action_release("dash")
			if _t == 45:
				_check(_flags.has("dashed"), "run -> dash: dash frames shown")
				_check(_run_idx(p._frame_shown) >= 0, "dash -> run: run resumes (%s)" % p._frame_shown)
				Input.action_press("attack")
				_next("attack")
		"attack":
			if p._atk_t >= 0.0:
				_flags["attacked"] = true
				if p._frame_shown.begins_with("attack_"):
					_flags["atk_frame"] = true
				_shot("08_attack")
			if _t == 3:
				Input.action_release("attack")
			if _t == 60:
				_check(_flags.has("attacked") and _flags.has("atk_frame"), "run -> attack: attack frames shown")
				_check(_run_idx(p._frame_shown) >= 0, "attack -> run: run resumes (%s)" % p._frame_shown)
				_next("damage")
		"damage":
			if _t == 2:
				p.health._invuln = 0.0
				_check(p.health.damage(1), "damage applied through the real Health path")
			if _t == 4:
				_check(p._frame_shown == "neutral.png", "take damage: hurt frame shown, run paused (%s)" % p._frame_shown)
				_shot("10_damage")
			if _t == 40:
				_check(_run_idx(p._frame_shown) >= 0, "run resumes after hurt (%s)" % p._frame_shown)
				_next("wall")
		"wall":
			# Run LEFT into the arena's left wall (WallL) and keep pushing.
			Input.action_release("move_right")
			Input.action_press("move_left")
			if _t == 240:
				_check(p.is_on_wall() or absf(p.get_real_velocity().x) < 1.0, "player is pressed against a static blocker (x=%.0f)" % p.global_position.x)
				_check(p._frame_shown == "neutral.png", "pushing into a wall shows idle, not a treadmill run (%s)" % p._frame_shown)
				_shot("11_wall_push")
				_release_all()
				_next("done")
		"done":
			if _t == 30:
				for k in ["run_contract_broken", "legacy_contract_broken", "sprite_drift", "facing_mismatch", "filter", "run_while_not_grounded_running"]:
					_check(not _inv.has(k), "invariant held all run: %s %s" % [k, str(_inv.get(k, ""))])
				print("RUN_SE_PROBE: %s (%d pass, %d fail)" % ["ALL PASS" if _fail == 0 else "FAILURES", _pass, _fail])
				quit(1 if _fail > 0 else 0)
				return true
	return false
