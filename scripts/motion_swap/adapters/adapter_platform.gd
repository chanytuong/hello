extends NLBMotionAdapter
class_name NLBMotionPlatformAdapter
## PLATFORM adapter for a moving platform.
##
## What is exchanged is the platform's PERSISTENT TRAVEL COMMAND — a signed
## scalar along its own path axis. The platform still obeys its authored travel
## bounds: a swapped speed changes how fast it travels and in which direction,
## never whether it may leave its designed range. A speed of 0 parks it, and it
## stays parked until another valid swap or an explicit lab reset.

func kind() -> String:
	return "PLATFORM"

func channel() -> int:
	return NLBMotionChannels.Channel.PLATFORM

func read_motion() -> Vector2:
	if not available():
		return Vector2.ZERO
	return Vector2(host.travel_speed, 0.0)

func apply_motion(motion: Vector2) -> void:
	if not available():
		return
	host.set_travel_speed(motion.x)

func describe() -> String:
	if not available():
		return "PLATFORM (gone)"
	return "PLATFORM %+.0f px/s %s" % [host.travel_speed, host.drive_symbol()]
