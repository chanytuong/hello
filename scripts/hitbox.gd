extends Area2D
class_name NLBHitBox
## Monitoring side of combat. Enabled only during explicit windows (attack
## active frames, slam strikes, hazard ticks). One hit per activation epoch
## per Health, so multi-frame overlap never multi-hits.

signal landed  # emitted when a swing actually connects (hitstop/shake hook)

@export var damage: int = 1
@export var knockback: Vector2 = Vector2.ZERO
## When true, hits every overlapping HurtBox on the configured tick (hazards,
## touch damage). When false, hits once per begin() epoch (swings, slams).
@export var continuous: bool = false
@export var tick: float = 0.25

var _epoch: int = 0
var _marks: Dictionary = {}
var _tick_t: float = 0.0
var _latched: Array[Area2D] = []

func _ready() -> void:
	monitoring = false
	monitorable = false
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func begin() -> void:
	_epoch += 1
	_marks.clear()
	_tick_t = 0.0
	monitoring = true
	_latched = get_overlapping_areas()
	if not continuous:
		_strike_latched()

func end() -> void:
	monitoring = false
	_latched.clear()

func _process(delta: float) -> void:
	if not monitoring or not continuous:
		return
	_tick_t -= delta
	if _tick_t <= 0.0:
		_tick_t = tick
		_marks.clear()  # continuous boxes re-arm every tick; one-shot boxes keep epoch marks
		for a in get_overlapping_areas():
			_try_hit(a)

func _on_area_entered(a: Area2D) -> void:
	if not monitoring:
		return
	if continuous:
		return  # tick loop handles it; avoids physics-callback damage
	_try_hit(a)

func _on_area_exited(a: Area2D) -> void:
	_latched.erase(a)

func _strike_latched() -> void:
	for a in _latched.duplicate():
		_try_hit(a)

func _try_hit(a: Area2D) -> void:
	var hb := a as NLBHurtBox
	if hb == null:
		return
	var h := hb.health_node()
	if h == null:
		return
	var key := h.get_instance_id()
	if _marks.get(key, -1) == _epoch:
		return
	_marks[key] = _epoch
	if hb.take_hit(damage, knockback):
		landed.emit()
