extends Area2D
class_name NLBHurtBox
## Monitorable side of combat. Convention: sibling node named "Health" (NLBHealth).
## HitBoxes call take_hit(); this keeps damage routing in one place.

func _ready() -> void:
	monitorable = true
	monitoring = false

func health_node() -> NLBHealth:
	return get_parent().get_node_or_null("Health") as NLBHealth

func take_hit(amount: int, kb: Vector2 = Vector2.ZERO) -> bool:
	var h := health_node()
	if h == null:
		return false
	if not h.damage(amount):
		return false
	var owner := get_parent()
	# Clean rule: damage drops pending jump intent. A buffer pressed before
	# the hit must not fire off the next landing and read as a "launcher".
	if owner != null and owner.has_method("clear_jump_intent"):
		owner.clear_jump_intent()
	if owner != null and owner.has_method("apply_knockback"):
		owner.apply_knockback(kb)
	return true
