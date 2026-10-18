extends RigidBody2D
class_name LabCrate
## Lab crate — the LINEAR physics prop.
##
## Its exchangeable quantity is its REAL `linear_velocity` (read and written by
## NLBMotionRigidBodyAdapter): what it was doing when picked is what leaves it.
## Low friction is deliberate: a swapped motion must travel far enough to be
## read as "the crate is running that enemy's walk", which is the whole point
## of zone A and the zone E plate route. Reset is an EXPLICIT lab action (it
## teleports back to spawn), which the swap rules never allow.

@onready var swap_target: NLBMotionSwapTarget = $SwapTarget
@onready var visual: ColorRect = $Visual

var spawn_position: Vector2 = Vector2.ZERO
var spawn_rotation: float = 0.0
var _previous_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	spawn_position = global_position
	spawn_rotation = rotation
	add_to_group("crates")
	add_to_group("lab_resettable")
	contact_monitor = true
	max_contacts_reported = 8
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	if visual != null:
		visual.pivot_offset = visual.size * 0.5
	if swap_target != null:
		swap_target.adapter = NLBMotionRigidBodyAdapter.new(self)
		swap_target.display_name = "CRATE"
		swap_target.anchor_offset = Vector2(0, -30)

func record_contact_motion(motion: Vector2) -> void:
	_previous_velocity = motion

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# The solver has already changed velocity at a contact. Use the previous
	# incoming step, including a just-exchanged motion, to measure the approach.
	for i in state.get_contact_count():
		var other := state.get_contact_collider_object(i)
		var normal := state.transform.basis_xform(state.get_contact_local_normal(i)).normalized()
		var point := state.get_contact_local_position(i) # Godot reports this in world coordinates
		var other_velocity := state.get_contact_collider_velocity_at_position(i)
		_resolve_contact.call_deferred(other, point, normal, _previous_velocity, other_velocity)
	_previous_velocity = state.linear_velocity

func _resolve_contact(other: Object, point: Vector2, normal: Vector2, incoming: Vector2, other_velocity: Vector2) -> void:
	NLBImpactResponse.resolve(self, other, point, normal, incoming, other_velocity)

func receive_motion_impact(_speed: float, _normal: Vector2, _other: Object, _incoming: Vector2, _context: Dictionary = {}) -> void:
	if swap_target != null:
		swap_target.clear_overdrive()

func debug_line() -> String:
	return "CRATE v=(%.0f, %.0f)" % [linear_velocity.x, linear_velocity.y]

## Full lab reset: back to the authored spawn, dead stop.
func reset_state() -> void:
	if not is_instance_valid(self):
		return
	freeze = true
	global_position = spawn_position
	rotation = spawn_rotation
	linear_velocity = Vector2.ZERO
	_previous_velocity = Vector2.ZERO
	if swap_target != null:
		swap_target.clear_overdrive()
	angular_velocity = 0.0
	freeze = false
	sleeping = false

## "Reset targets": motion state cleared IN PLACE. A crate in mid-air simply
## drops from where it is — a lab motion reset is not an object teleport.
func reset_motion() -> void:
	linear_velocity = Vector2.ZERO
	_previous_velocity = Vector2.ZERO
	if swap_target != null:
		swap_target.clear_overdrive()
	angular_velocity = 0.0
	sleeping = false
