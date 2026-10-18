extends NLBMotionAdapter
class_name NLBMotionRigidBodyAdapter
## LINEAR adapter for a physics crate (RigidBody2D).
##
## Reads the crate's ACTUAL linear velocity (the physics server's number, after
## gravity, contacts and pushes) and writes the received motion back through the
## same property. No impulse fiction, no stored momentum: what the crate was
## doing is what leaves, what it receives is what arrives.

func kind() -> String:
	return "CRATE"

func read_motion() -> Vector2:
	if not available():
		return Vector2.ZERO
	return host.linear_velocity

func apply_motion(motion: Vector2) -> void:
	if not available():
		return
	# Physics-safe: assigning linear_velocity is the supported way to set a
	# rigid body's motion, and it is called from input/idle, never from inside
	# a physics callback. sleeping must be cleared or a stopped crate would
	# swallow the received motion.
	host.sleeping = false
	host.linear_velocity = motion

func describe() -> String:
	var m := read_motion()
	return "CRATE v=(%.0f, %.0f)" % [m.x, m.y]
