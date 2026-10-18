extends NLBMotionAdapter
class_name NLBMotionCharacterAdapter
## LINEAR adapter for a self-moving body (enemy CharacterBody2D).
##
## The host owns the override semantics; this adapter only forwards, so every
## character type shares one implementation:
##   motion_swap_read()                     -> Vector2 (its OWN current velocity)
##   motion_swap_apply(motion, duration)    -> hold that motion, gravity keeps
##                                             acting, AI paused, no teleport

func kind() -> String:
	return "CHARACTER"

func read_motion() -> Vector2:
	if not available():
		return Vector2.ZERO
	return host.motion_swap_read()

func apply_motion(motion: Vector2) -> void:
	if not available():
		return
	host.motion_swap_apply(motion, override_time)

func describe() -> String:
	var m := read_motion()
	return "CHARACTER v=(%.0f, %.0f)" % [m.x, m.y]

func available() -> bool:
	if not is_instance_valid(host):
		return false
	if host.has_method("is_swap_selectable"):
		return host.is_swap_selectable()
	return true

func override_remaining() -> float:
	if not available():
		return -1.0
	return host.swap_override_t
