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
@export var damage_kind: StringName = &"attack"
## Charger attack is armed by its state, confirmed by real body contact.
@export var manual_contact_only: bool = false

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
	if not continuous and not manual_contact_only:
		_strike_latched()

func end() -> void:
	monitoring = false
	_latched.clear()

func _process(delta: float) -> void:
	if not monitoring or not continuous or manual_contact_only:
		return
	_tick_t -= delta
	if _tick_t <= 0.0:
		_tick_t = tick
		_marks.clear()  # continuous boxes re-arm every tick; one-shot boxes keep epoch marks
		for a in get_overlapping_areas():
			_try_hit(a)

func _on_area_entered(a: Area2D) -> void:
	if not monitoring or manual_contact_only:
		return
	if continuous:
		# A fast body may cross a hazard between two tick samples. Defer the
		# first contact hit out of the physics flush; epoch marks + iframes still
		# prevent a second hit from the periodic overlap loop.
		_try_hit.call_deferred(a)
		return
	_try_hit(a)

func _on_area_exited(a: Area2D) -> void:
	_latched.erase(a)

func _strike_latched() -> void:
	for a in _latched.duplicate():
		_try_hit(a)

func strike_contact(body: Node2D, context: Dictionary) -> void:
	if not monitoring or not manual_contact_only:
		return
	var hurt := body.get_node_or_null("HurtBox") as NLBHurtBox
	if hurt != null:
		_try_hit(hurt, context)

func _try_hit(a: Area2D, context: Dictionary = {}) -> void:
	if not monitoring or not is_instance_valid(a):
		return
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
	var info := {"kind": str(damage_kind), "source": str(get_path()) if is_inside_tree() else str(name),
		"source_position": global_position, "source_velocity": NLBImpactResponse.velocity_of(get_parent()),
		"contact": hb.global_position, "attack_epoch": _epoch}
	info.merge(context, true)
	var hit_knockback: Vector2 = info.get("knockback", knockback)
	if hb.take_hit(damage, hit_knockback, info):
		landed.emit()
