extends SceneTree
## PHASE 8 probe: ATTACK INPUT TRUST.
## Question: if a player deliberately presses attack AGAIN during/after the
## swing they already committed to, does that press survive?
## Read-only: stages positions, changes no game code.
##
## For each offset (seconds after swing start) we press attack and record
##   - when the press actually registered (2-frame Input lag measured, not assumed)
##   - the buffer/cooldown state at that moment
##   - whether a SECOND swing actually happened
## then print a trust verdict per offset.

const OFFSETS: Array = [0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.55]
const SETTLE_FRAMES: int = 6      # idle time demanded between cases
const WATCH_FRAMES: int = 50      # how long we wait for the queued swing

var _f: int = 0
var _main: Node

# case state
var _case: int = -1
var _stage: int = 0   # 0 settle, 1 wait swing start, 2 press at offset, 3 watch
var _stage_f: int = 0
var _swing_start: int = -1
var _press_f: int = -1
var _reg_f: int = -1
var _buf_at_reg: float = -1.0
var _cd_at_reg: float = -1.0
var _second: bool = false
var _second_f: int = -1
var _first_done: bool = false

func _init() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	get_root().add_child(_main)
	current_scene = _main

func _p() -> NLBPlayer:
	return get_first_node_in_group("player") as NLBPlayer

func _park() -> void:
	var prop := get_first_node_in_group("props")
	if prop != null:
		prop.global_position = Vector2(1190, 200)
	for e in get_nodes_in_group("enemies"):
		e.global_position = Vector2(1230, 599)
		if e is NLBMeleeChaser:
			e.velocity = Vector2.ZERO
			e._kb = Vector2.ZERO
			e._cd = 99.0
			e.ai_state = NLBMeleeChaser.AIState.CHASE

func _reset(p: NLBPlayer) -> void:
	p.global_position = Vector2(300, 599)
	p.velocity = Vector2.ZERO
	p.move_state = NLBPlayer.MoveState.NORMAL
	p._atk_t = -1.0
	p._atk_cd = 0.0
	p._atk_buf = 0.0
	p._dash_t = 0.0
	p._dash_cd = 0.0
	p._struck_from_dash = false
	p.facing = 1

func _physics_process(_delta: float) -> bool:
	_f += 1
	var p := _p()
	if p == null:
		return false
	if _f == 1:
		_park()
		_reset(p)
		_case = 0
		_stage = 0
		_stage_f = 0
		return false

	# ---- detect the queued swing (second one) ----
	# The first swing must be OBSERVED TO END before a new _atk_t >= 0 means
	# anything; otherwise a still-running first swing fakes a "trusted" press.
	if _stage >= 2 and _swing_start >= 0 and not _first_done and p._atk_t < 0.0:
		_first_done = true
	if _stage >= 2 and _swing_start >= 0 and _first_done and p._atk_t >= 0.0 and not _second:
		_second = true
		_second_f = _f

	# ---- detect press registration (2-frame Input lag, measured) ----
	if _stage == 2 and _reg_f < 0 and p._atk_buf > 0.0:
		_reg_f = _f
		_buf_at_reg = p._atk_buf
		_cd_at_reg = p._atk_cd

	match _stage:
		0:  # settle between cases
			_stage_f += 1
			if _stage_f >= SETTLE_FRAMES and p._atk_t < 0.0 and p._atk_cd <= 0.0 and p._atk_buf <= 0.0:
				_reset(p)
				Input.action_press("attack")
				_stage = 1
				_stage_f = 0
				_press_f = _f
				_swing_start = -1
				_reg_f = -1
				_second = false
				_first_done = false
				_second_f = -1
				_buf_at_reg = -1.0
				_cd_at_reg = -1.0
		1:  # first swing start
			_stage_f += 1
			if _stage_f >= 3:
				Input.action_release("attack")
			if _swing_start < 0 and p._atk_t >= 0.0:
				_swing_start = _f
			if _swing_start >= 0:
				var want := _swing_start + int(round(OFFSETS[_case] * 60.0))
				if _f >= want:
					Input.action_press("attack")
					_stage = 2
					_stage_f = 0
		2:  # second press in flight (hold 2 frames)
			_stage_f += 1
			if _stage_f >= 3:
				Input.action_release("attack")
			if _stage_f >= 8:
				_stage = 3
				_stage_f = 0
		3:  # watch for the queued swing
			_stage_f += 1
			if _stage_f >= WATCH_FRAMES or (_second and _stage_f >= 4):
				_report(p)
				_stage = 0
				_stage_f = 0
				_case += 1
				if _case >= OFFSETS.size():
					print("INPUT_TRUST_DONE cases=%d" % OFFSETS.size())
					Engine.time_scale = 1.0
					quit(0)
					return true
	return false

func _report(p: NLBPlayer) -> void:
	var off: float = OFFSETS[_case]
	var t_reg := -1.0
	if _reg_f >= 0 and _swing_start >= 0:
		t_reg = float(_reg_f - _swing_start) / 60.0
	var cd_left := p._atk_cd
	var t_fire := -1.0
	if _second and _swing_start >= 0 and _second_f >= 0:
		t_fire = float(_second_f - _swing_start) / 60.0
	var verdict := "DROPPED"
	if _second:
		verdict = "TRUSTED"
	print("TRUST off=%.2f reg_at=%.2f buf=%.2f cd_left=%.2f -> %s fire_at=%.2f" % [
		off, t_reg, _buf_at_reg, _cd_at_reg, verdict, t_fire])
	# silence unused
	var _x: NLBPlayer = p
