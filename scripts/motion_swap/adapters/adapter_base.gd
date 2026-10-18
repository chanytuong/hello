extends RefCounted
class_name NLBMotionAdapter
## Base class for every "kind of motion" the swap system understands.
##
## An adapter is the ONLY place that knows how to read and write one object
## type's motion. The controller never asks what a target IS — so adding a new
## swappable object costs one adapter file, never a new branch inside a manager.
##
## Contract:
##   read_motion()  -> the current exchangeable quantity
##   apply_motion() -> write that quantity back, physics-safe, no teleport

var host: Node = null
## How long a received motion owns the host when the host is self-moving
## (characters). Machines ignore this: their setting persists until the next
## valid change or an explicit lab reset.
var override_time: float = 0.65

func _init(host_node: Node = null) -> void:
	host = host_node

func channel() -> int:
	return NLBMotionChannels.Channel.LINEAR

## Short type name for the overlay ("CHARACTER", "CRATE", "PROJECTILE", ...).
func kind() -> String:
	return "OBJECT"

func read_motion() -> Vector2:
	return Vector2.ZERO

func apply_motion(_motion: Vector2) -> void:
	pass

## Modifier adjustment must not restart an AI/player override timer.
func adjust_motion(change: Vector2) -> void:
	apply_motion(read_motion() + change)

## One line for the debug overlay: the value AND its meaning.
func describe() -> String:
	return kind()

## False when the host is gone/dead/disabled and must not be selectable.
func available() -> bool:
	return is_instance_valid(host)

## Seconds left of a received-motion override, or -1 when not applicable.
func override_remaining() -> float:
	return -1.0
