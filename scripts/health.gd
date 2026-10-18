extends Node
class_name NLBHealth
## Reusable hit-point container with invulnerability windows.
## Owned by a fighter; damaged only through NLBHurtBox.

signal changed(current: int, maximum: int)
signal died
signal damage_recorded(event: Dictionary)

## Opt-in forensic logging. Normal gameplay performs no console logging.
static var trace_damage: bool = false
static var damage_records: Array[Dictionary] = []

@export var max_hp: int = 3
@export var iframes: float = 0.5

var hp: int = -1  # -1 = unprimed; primed lazily (see _ensure)
var _primed: bool = false

func _ready() -> void:
	if "--damage-trace" in OS.get_cmdline_user_args():
		trace_damage = true
	_ensure()

func _ensure() -> void:
	if _primed:
		return
	_primed = true
	hp = max_hp

func _process(delta: float) -> void:
	_invuln = maxf(_invuln - delta, 0.0)

var _invuln: float = 0.0

## Returns true if damage was applied.
func damage(amount: int, context: Dictionary = {}) -> bool:
	_ensure()
	var before := hp
	if amount <= 0 or _invuln > 0.0 or hp <= 0:
		_record_damage(before, before, amount, false, context)
		return false
	hp = maxi(hp - amount, 0)
	_record_damage(before, hp, amount, true, context) # before synchronous death/respawn handlers
	if hp <= 0:
		died.emit()
	else:
		_invuln = iframes
		changed.emit(hp, max_hp)
	return true

func _record_damage(before: int, after: int, amount: int, accepted: bool, context: Dictionary) -> void:
	var event := context.duplicate()
	event.merge({"kind": context.get("kind", "unspecified"), "amount": amount,
		"hp_before": before, "hp_after": after, "accepted": accepted,
		"victim": str(get_parent().get_path()) if is_inside_tree() else str(name),
		"physics_frame": Engine.get_physics_frames()}, true)
	if get_parent() is CharacterBody2D:
		event["victim_velocity"] = (get_parent() as CharacterBody2D).velocity
	damage_recorded.emit(event)
	if trace_damage:
		damage_records.append(event)
		if damage_records.size() > 512:
			damage_records.pop_front()
		print("DAMAGE_TRACE " + JSON.stringify(event))

func grant_iframes(t: float) -> void:
	_invuln = maxf(_invuln, t)

func reset() -> void:
	_primed = true
	hp = max_hp
	_invuln = 0.0
	changed.emit(hp, max_hp)
