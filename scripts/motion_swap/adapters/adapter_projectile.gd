extends NLBMotionAdapter
class_name NLBMotionProjectileAdapter
## LINEAR adapter for a projectile (Area2D flying a straight line).
##
## A projectile exposes its ACTUAL current directional velocity. After a swap
## it flies the other target's velocity, so it can stop, reverse or fall —
## its lifetime keeps running (a stopped shot expires instead of accumulating),
## collision and damage rules do not change, and nothing ever homes.

func kind() -> String:
	return "PROJECTILE"

func read_motion() -> Vector2:
	if not available():
		return Vector2.ZERO
	return host.velocity

func apply_motion(motion: Vector2) -> void:
	if not available():
		return
	host.velocity = motion

func describe() -> String:
	var m := read_motion()
	return "PROJECTILE v=(%.0f, %.0f) life=%.1fs" % [m.x, m.y, host.life]

func available() -> bool:
	if not is_instance_valid(host):
		return false
	return host.life > 0.0
