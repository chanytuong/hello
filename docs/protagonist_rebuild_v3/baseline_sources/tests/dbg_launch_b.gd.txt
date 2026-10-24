extends SceneTree
## BUG 1 Phase B: full chaos (move + swing + jump + dash). Every real jump
## fire is timestamped via the `jumped` signal. Flags upward spikes that are
## NOT within 5 frames of a jump fire and exceed landslide margins.

var _frames: int = 0
var _events: int = 0
var _prev_vy: float = 0.0
var _last_jump_fire: int = -1000
var _jumps: int = 0

func _init() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	get_root().add_child(main)

func _p() -> NLBPlayer:
	return get_first_node_in_group("player") as NLBPlayer

func _m() -> NLBMeleeChaser:
	for e in get_nodes_in_group("enemies"):
		if e is NLBMeleeChaser:
			return e
	return null

func _on_jump() -> void:
	_last_jump_fire = _frames
	_jumps += 1

func _physics_process(_delta: float) -> bool:
	_frames += 1
	var p := _p()
	var m := _m()
	if _frames == 1:
		p.jumped.connect(_on_jump)
	if m != null:
		if p.global_position.x < m.global_position.x - 10.0:
			Input.action_press("move_right")
			Input.action_release("move_left")
		else:
			Input.action_press("move_left")
			Input.action_release("move_right")
	if _frames % 17 == 0:
		Input.action_press("attack")
	if _frames % 17 == 4:
		Input.action_release("attack")
	if _frames % 31 == 0:
		Input.action_press("jump")
	if _frames % 31 == 6:
		Input.action_release("jump")
	if _frames % 43 == 0:
		Input.action_press("dash")
	if _frames % 43 == 3:
		Input.action_release("dash")
	var vy: float = p.velocity.y
	var dv: float = vy - _prev_vy
	var near_jump: bool = (_frames - _last_jump_fire) <= 5
	# Anomaly: strong upward injection unrelated to a jump fire, ending airborne.
	if dv < -250.0 and not near_jump and vy < -100.0 and _events < 8:
		_events += 1
		print("ANOMALY #%d f=%d vy=%.0f dvy=%.0f grounded=%s dash=%d atk=%s lastjump=%d frames_ago melee=%s mdx=%.0f p_hp=%d" % [
			_events, _frames, vy, dv, str(p.is_on_floor()), p.move_state,
			("busy" if p.is_attack_busy() else "idle"), _frames - _last_jump_fire,
			(m.ai_state if m != null else -1),
			(m.global_position.x - p.global_position.x) if m != null else 0.0, p.health.hp])
	_prev_vy = vy
	if p.health.hp <= 0 or _frames >= 2500:
		print("PHASE-B: done frames=%d jumps=%d anomalies=%d p_hp=%d melee_alive=%s" % [
			_frames, _jumps, _events, p.health.hp, str(m != null)])
		Engine.time_scale = 1.0
		quit(0)
		return true
	return false
