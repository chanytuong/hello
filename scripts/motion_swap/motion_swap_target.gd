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
	adapter.apply_motion(motion)

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
