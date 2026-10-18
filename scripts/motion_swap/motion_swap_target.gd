extends Node2D
class_name NLBMotionSwapTarget
## Component: "this object's motion can be exchanged".
##
## Attach one per swappable object and point it at an adapter. The component
## carries identity (name, anchor for markers, enabled flag) and forwards
## everything else. It registers itself in the "swap_targets" group so the
## controller can find targets without knowing the scene layout, and it
## unregisters on exit — a freed target can therefore never be selected.

@export var display_name: String = "TARGET"
## Marker/hover anchor in host-local space (roughly the object's centre).
@export var anchor_offset: Vector2 = Vector2(0, -30)
## Cleared by the owner when the object must stop being swappable (death).
var enabled: bool = true
var adapter: NLBMotionAdapter = null
var host: Node2D = null
var received_velocity: Vector2 = Vector2.ZERO
var overdrive_velocity: Vector2 = Vector2.ZERO
var overdrive_left: float = 0.0
var _boost_extra: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("swap_targets")
	host = get_parent() as Node2D

func _exit_tree() -> void:
	remove_from_group("swap_targets")

func setup(host_node: Node2D, new_adapter: NLBMotionAdapter, title: String) -> void:
	host = host_node
	adapter = new_adapter
	display_name = title

func channel() -> int:
	if adapter == null:
		return NLBMotionChannels.Channel.LINEAR
	return adapter.channel()

func channel_label() -> String:
	return NLBMotionChannels.label(channel())

func read_motion() -> Vector2:
	if adapter == null:
		return Vector2.ZERO
	return adapter.read_motion()

func apply_motion(motion: Vector2) -> void:
	if adapter == null:
		return
	clear_overdrive()
	received_velocity = motion
	overdrive_velocity = motion
	adapter.apply_motion(motion)

func clear_overdrive() -> void:
	overdrive_left = 0.0
	_boost_extra = Vector2.ZERO

func overdrive_snapshot() -> Dictionary:
	if overdrive_left <= 0.0 or _boost_extra == Vector2.ZERO:
		return {}
	return {"extra": _remaining_extra(), "time": overdrive_left}

func apply_overdrive(active: bool, multiplier: float, threshold: float, duration: float, inherited: Dictionary = {}) -> void:
	if channel() != NLBMotionChannels.Channel.LINEAR:
		return # machine settings persist, and are never physical launch modifiers
	if not inherited.is_empty():
		_boost_extra = inherited.extra
		overdrive_left = inherited.time
		return # already amplified at its source; transfer its expiry, never multiply it
	if not active or duration <= 0.0 or multiplier <= 1.0 or received_velocity.length() < threshold:
		return
	_boost_extra = received_velocity * (multiplier - 1.0)
	overdrive_left = duration
	adapter.adjust_motion(_boost_extra)
	overdrive_velocity = read_motion()

func _remaining_extra() -> Vector2:
	if _boost_extra == Vector2.ZERO:
		return Vector2.ZERO
	var direction := _boost_extra.normalized()
	# A collision may have removed the boosted component. Never resurrect it or reverse a body.
	return direction * minf(_boost_extra.length(), maxf(read_motion().dot(direction), 0.0))

func _physics_process(delta: float) -> void:
	if overdrive_left <= 0.0 or adapter == null:
		return
	overdrive_left = maxf(overdrive_left - delta, 0.0)
	if overdrive_left <= 0.0:
		adapter.adjust_motion(-_remaining_extra())
		_boost_extra = Vector2.ZERO

func describe() -> String:
	if adapter == null:
		return display_name + " (no adapter)"
	return adapter.describe()

func kind() -> String:
	if adapter == null:
		return "NONE"
	return adapter.kind()

## Valid = alive, enabled, and its adapter still has a host worth swapping.
func is_valid() -> bool:
	if not enabled or adapter == null:
		return false
	if not is_instance_valid(self) or not is_inside_tree():
		return false
	return adapter.available()

func override_remaining() -> float:
	if adapter == null:
		return -1.0
	return adapter.override_remaining()

## World-space point markers and hover checks use.
func anchor_world() -> Vector2:
	if host != null and is_instance_valid(host):
		return host.global_position + anchor_offset
	return global_position
