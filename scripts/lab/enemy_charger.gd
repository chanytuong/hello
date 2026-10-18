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

@export var charge_speed: float = 600.0
@export var windup_time: float = 0.5
@export var charge_time: float = 1.5
@export var stun_time: float = 0.9
@export var recover_time: float = 0.55
@export var trigger_range: float = 560.0
@export var vertical_tolerance: float = 96.0
@export var brake_accel: float = 1600.0
@export var charge_attack_knockback: float = 180.0

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
			var pulse := _state_t > windup_time * 0.5
			body_color = Color(1.0, 0.25, 0.25) if pulse else Color(0.95, 0.45, 0.2)
			velocity.x = 0.0
			_draw_telegraph()
			if _state_t <= 0.0:
				state = State.CHARGE
				_state_t = charge_time
				_touch_box.begin()
				telegraph.visible = false
		State.CHARGE:
			body_color = Color(1.0, 0.75, 0.25)
			telegraph.visible = false
			velocity.x = _locked_dir * charge_speed
			if is_on_wall():
				impact.emit(absf(charge_speed))
				state = State.STUN
				_state_t = stun_time
				_touch_box.end()
			elif _state_t <= 0.0:
				state = State.RECOVER
				_state_t = recover_time
				_touch_box.end()
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
	if _touch_box != null:
		_touch_box.end()
	# A charge that was interrupted is OVER: the body resumes from where the
	# override left it, in RECOVER, not by resuming the committed run.
	if state == State.CHARGE or state == State.WINDUP:
		state = State.RECOVER
		_state_t = recover_time

func _reset_ai() -> void:
	state = State.IDLE
	_state_t = 0.0
	_locked_dir = 1.0
	if _touch_box != null:
		_touch_box.manual_contact_only = true
		_touch_box.continuous = false
		_touch_box.damage_kind = &"enemy_attack"
		_touch_box.end()
	if telegraph != null:
		telegraph.visible = false

func _on_swapped(_motion: Vector2) -> void:
	if _touch_box != null:
		_touch_box.end() # an interrupted charge cannot keep dealing attack damage

func _on_damaged(current: int, maximum: int) -> void:
	super._on_damaged(current, maximum)
	if state == State.CHARGE or state == State.WINDUP:
		state = State.RECOVER
		_state_t = recover_time
		if _touch_box != null:
			_touch_box.end()

func receive_motion_impact(speed: float, normal: Vector2, other: Object, incoming: Vector2, context: Dictionary = {}) -> void:
	var charge_wall := state == State.CHARGE and other is StaticBody2D and absf(normal.x) > 0.5
	super.receive_motion_impact(speed, normal, other, incoming, context)
	# Generic impact damage/override cleanup happens during the contact solve,
	# before next tick's is_on_wall(). Keep the promised charge-crash stun.
	if charge_wall and _alive:
		state = State.STUN
		_state_t = stun_time
		_touch_box.end()

func try_contact_attack(victim: Object, point: Vector2, normal: Vector2, incoming: Vector2, victim_velocity: Vector2) -> bool:
	if not victim is NLBPlayer or not _alive or state != State.CHARGE or swap_override_t > 0.0 or _stagger_t > 0.0:
		return false
	var p := victim as NLBPlayer
	if p.living_projectile or not _touch_box.monitoring:
		return false
	if normal.x * _locked_dir > -0.5 or (incoming.x - victim_velocity.x) * _locked_dir < 200.0:
		return false # only the committed forward face can strike
	_touch_box.strike_contact(p, {"kind": "enemy_attack", "source": str(get_path()) + "/Charge",
		"velocity": incoming, "source_velocity": incoming, "other_velocity": victim_velocity, "contact": point, "normal": normal,
		"closing_speed": maxf(0.0, -(incoming - victim_velocity).dot(normal)),
		"knockback": -normal * charge_attack_knockback})
	return true # even a gated/repeated attack contact must not also count as impact
