extends LabEnemy
class_name LabPatrolEnemy
## PATROL — walks a configured stretch, pauses at the ends, turns on walls.
##
## It exists to be the lab's cleanest "something is moving" source: a steady
## horizontal velocity with no tricks, so a swap visibly transfers a walk into
## whatever is picked second (a crate usually) and stops the walker dead.
##
## After an override the walk continues FROM WHEREVER THE BODY IS: the nearest
## authorable bound wraps it back inside its stretch instead of teleporting it.

@export var speed: float = 90.0
@export var wait_at_ends: float = 0.45
@export var turn_accel: float = 1400.0

var patrol_left: float = 0.0
var patrol_right: float = 0.0
var dir: float = 1.0

var _wait: float = 0.0

func type_label() -> String:
	return "PATROL"

func ai_state_name() -> String:
	if _wait > 0.0:
		return "TURN"
	return "WALK R" if dir > 0.0 else "WALK L"

## World-space stretch this patrol owns. Set by the zone builder.
func configure_patrol(left_x: float, right_x: float) -> void:
	patrol_left = minf(left_x, right_x)
	patrol_right = maxf(left_x, right_x)
	dir = 1.0
	_wait = 0.0

func _ai_step(delta: float) -> void:
	_apply_gravity(delta)
	if _wait > 0.0:
		_wait = maxf(_wait - delta, 0.0)
		velocity.x = move_toward(velocity.x, 0.0, turn_accel * delta)
		return
	# is_on_wall() is last frame's solve: a wall interrupts the walk the same
	# way an authored bound does.
	if is_on_wall() or (dir > 0.0 and global_position.x >= patrol_right) \
			or (dir < 0.0 and global_position.x <= patrol_left):
		dir = -dir
		_wait = wait_at_ends
		velocity.x = move_toward(velocity.x, 0.0, turn_accel * delta)
		return
	velocity.x = dir * speed

func _reset_ai() -> void:
	dir = 1.0
	_wait = 0.0

func _on_swap_override_end() -> void:
	# AI resumes here, from the position the body actually reached. No restore.
	if global_position.x <= patrol_left:
		dir = 1.0
	elif global_position.x >= patrol_right:
		dir = -1.0
	_wait = 0.0
