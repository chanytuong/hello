extends NLBMotionAdapter
class_name NLBMotionConveyorAdapter
## SURFACE adapter for a conveyor belt.
##
## What is exchanged is the belt's PERSISTENT OPERATING SPEED — the signed
## scalar it drives its surface at, along its own axis. It is deliberately NOT
## the belt body's world velocity: a belt never moves, so its body velocity is
## always zero and exchanging that would do nothing while looking like a bug.
##
## The received speed stays in effect until another valid swap or an explicit
## lab reset. It is never tied to a character's override clock.

func kind() -> String:
	return "CONVEYOR"

func channel() -> int:
	return NLBMotionChannels.Channel.SURFACE

func read_motion() -> Vector2:
	if not available():
		return Vector2.ZERO
	return Vector2(host.surface_speed, 0.0)

func apply_motion(motion: Vector2) -> void:
	if not available():
		return
	host.set_surface_speed(motion.x)

func describe() -> String:
	if not available():
		return "CONVEYOR (gone)"
	return "CONVEYOR %+.0f px/s %s" % [host.surface_speed, host.drive_symbol()]
