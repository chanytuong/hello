extends LabEnemy
class_name LabChargerEnemy
## CHARGER — IDLE -> WINDUP (telegraph, direction is committed HERE and shown)
## -> CHARGE (one straight committed run, never re-aimed) -> STUN if it hits a
## wall (the payoff of the zone) -> RECOVER -> IDLE.
##
## The committed-run rule is the same one Motion Swap obeys: a telegraph is a
## promise. The charge cannot track, and a swap can never give it a target it
## was not already committed to.

enum State { IDLE, WINDUP, CHARGE, STUN, RECOVER }

@export var charge_speed: float = 520.0
@export var windup_time: float = 0.5
@export var charge_time: float = 1.5
@export var stun_time: float = 0.9
@export var recover_time: float = 0.55
@export var trigger_range: float = 560.0
@export var vertical_tolerance: float = 96.0
@export var brake_accel: float = 1600.0

var state: int = State.IDLE
var _state_t: float = 0.0
var _locked_dir: float = 1.0
var _out_of_trigger: float = 0.0

@onready var telegraph: Line2D = $Telegraph

func type_label() -> String:
	return "CHARGER"

func ai_state_name() -> String:
	match state:
		State.IDLE:
			return "IDLE"
		State.WINDUP:
			return "WINDUP"
		State.CHARGE:
			return "CHARGE"
		State.STUN:
			return "STUN"
	return "RECOVER"

## Direction the committed run will use (also drawn during WINDUP).
func committed_direction() -> float:
	return _locked_dir

func _ai_step(delta: float) -> void:
	_apply_gravity(delta)
	_state_t -= delta
	var p := player_node()
	match state:
		State.IDLE:
			body_color = Color(0.95, 0.45, 0.2)
			telegraph.visible = false
			velocity.x = move_toward(velocity.x, 0.0, brake_accel * delta)
			if p != null and _in_trigger(p):
				# Direction is locked at the START of the windup and shown, so
				# the telegraph is honest and the run can never re-aim.
				_locked_dir = signf(p.global_position.x - global_position.x)
				if _locked_dir == 0.0:
					_locked_dir = 1.0
				state = State.WINDUP
				_state_t = windup_time
		State.WINDUP:
			var blink := int(Time.get_ticks_msec() / 90) % 2 == 0
			body_color = Color(1.0, 0.25, 0.25) if blink else Color(0.95, 0.45, 0.2)
			velocity.x = 0.0
			_draw_telegraph()
			if _state_t <= 0.0:
				state = State.CHARGE
				_state_t = charge_time
				telegraph.visible = false
		State.CHARGE:
			body_color = Color(1.0, 0.75, 0.25)
			telegraph.visible = false
			velocity.x = _locked_dir * charge_speed
			if is_on_wall():
				impact.emit(absf(charge_speed))
				state = State.STUN
				_state_t = stun_time
			elif _state_t <= 0.0:
				state = State.RECOVER
				_state_t = recover_time
		State.STUN:
			body_color = Color(0.8, 0.8, 0.9)
			velocity.x = move_toward(velocity.x, 0.0, brake_accel * 1.5 * delta)
			if _state_t <= 0.0:
				state = State.RECOVER
				_state_t = recover_time
		State.RECOVER:
			body_color = Color(0.6, 0.5, 0.45)
			telegraph.visible = false
			velocity.x = move_toward(velocity.x, 0.0, brake_accel * delta)
			if _state_t <= 0.0:
				state = State.IDLE
				_state_t = 0.0

func _in_trigger(p: Node2D) -> bool:
	var dx := absf(p.global_position.x - global_position.x)
	return dx <= trigger_range and dx > 8.0 \
		and absf(p.global_position.y - global_position.y) <= vertical_tolerance

func _draw_telegraph() -> void:
	telegraph.visible = true
	var y := -20.0
	telegraph.clear_points()
	telegraph.add_point(Vector2(0, y))
	telegraph.add_point(Vector2(_locked_dir * 150.0, y))
	telegraph.add_point(Vector2(_locked_dir * 128.0, y - 9.0))
	telegraph.add_point(Vector2(_locked_dir * 150.0, y))
	telegraph.add_point(Vector2(_locked_dir * 128.0, y + 9.0))

func _on_swap_override_end() -> void:
	# A charge that was interrupted is OVER: the body resumes from where the
	# override left it, in RECOVER, not by resuming the committed run.
	if state == State.CHARGE or state == State.WINDUP:
		state = State.RECOVER
		_state_t = recover_time

func _reset_ai() -> void:
	state = State.IDLE
	_state_t = 0.0
	_locked_dir = 1.0
	if telegraph != null:
		telegraph.visible = false
