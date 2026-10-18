extends RefCounted
class_name NLBImpactResponse
## Contact-only resolver. A speed in empty space never causes damage.
## Normals point from the obstacle towards the moving body. Pair marks suppress
## duplicate slide/manifold callbacks, using physics frames (independent of slow time).

static var _pair_frames: Dictionary = {}
static var _last_prune: int = 0

static func velocity_of(body: Object) -> Vector2:
	if body is CharacterBody2D:
		return (body as CharacterBody2D).velocity
	if body is RigidBody2D:
		return (body as RigidBody2D).linear_velocity
	if body is StaticBody2D:
		return (body as StaticBody2D).constant_linear_velocity
	return Vector2.ZERO

static func resolve(mover: Node2D, other: Object, point: Vector2, normal: Vector2,
		incoming: Vector2, other_velocity: Vector2) -> float:
	if not is_instance_valid(mover) or not is_instance_valid(other) or not normal.is_finite():
		return 0.0
	var closing := maxf(0.0, -(incoming - other_velocity).dot(normal.normalized()))
	if closing < 180.0:
		return 0.0
	var frame := Engine.get_physics_frames()
	if frame - _last_prune > 120:
		_pair_frames.clear()
		_last_prune = frame
	var key := "%d:%d" % [mini(mover.get_instance_id(), other.get_instance_id()), maxi(mover.get_instance_id(), other.get_instance_id())]
	if frame - int(_pair_frames.get(key, -100)) < 10:
		return 0.0
	# One contact has one damage authority. A committed Charger attack owns
	# ordinary Iven contact; a self-launched Iven instead resolves as impact.
	if mover.has_method("try_contact_attack") and mover.try_contact_attack(other, point, normal, incoming, other_velocity):
		_pair_frames[key] = frame
		return closing
	if other.has_method("try_contact_attack") and other.try_contact_attack(mover, point, -normal, other_velocity, incoming):
		_pair_frames[key] = frame
		return closing
	# Ordinary run / roll contact is solid separation, not a kinetic attack.
	# Attack windows above use their own closing-speed rule, including a charge
	# catching a player who is running away at ordinary movement speed.
	if mover is CharacterBody2D and other is CharacterBody2D and closing < 480.0:
		return 0.0
	_pair_frames[key] = frame
	var mover_context := {"contact": point, "normal": normal, "velocity": incoming, "other_velocity": other_velocity}
	var other_context := {"contact": point, "normal": -normal, "velocity": other_velocity, "other_velocity": incoming}
	# Resolve a human projectile's victim before the player's recovery clears that state.
	if mover.is_in_group("player"):
		if other.has_method("receive_motion_impact"):
			other.receive_motion_impact(closing, -normal, mover, other_velocity, other_context)
		if mover.has_method("receive_motion_impact"):
			mover.receive_motion_impact(closing, normal, other, incoming, mover_context)
	else:
		if mover.has_method("receive_motion_impact"):
			mover.receive_motion_impact(closing, normal, other, incoming, mover_context)
		if other.has_method("receive_motion_impact"):
			other.receive_motion_impact(closing, -normal, mover, other_velocity, other_context)
	# Transfer only contact-normal momentum, never aim at a third object.
	if other is RigidBody2D and not mover is RigidBody2D:
		var rigid := other as RigidBody2D
		rigid.sleeping = false
		rigid.apply_central_impulse(-normal * closing * minf(rigid.mass, 2.0) * 0.70)
	elif other is CharacterBody2D and other.has_method("receive_contact_motion"):
		other.receive_contact_motion(-normal * closing * 0.55)
	var scene := mover.get_tree().current_scene
	if scene != null and scene.has_method("show_motion_impact"):
		scene.show_motion_impact(point, normal, closing)
	return closing

static func solve_slides(body: CharacterBody2D, incoming: Vector2) -> void:
	for i in body.get_slide_collision_count():
		var contact := body.get_slide_collision(i)
		resolve(body, contact.get_collider(), contact.get_position(), contact.get_normal(),
			incoming, contact.get_collider_velocity())
