extends AnimatableBody2D
class_name LabMovingPlatform
## Lab moving platform — the PLATFORM machine.
##
## What Motion Swap exchanges is `travel_speed`: the platform's persistent
## travel command as a signed scalar along its own path axis. The platform
## ALWAYS obeys its authored path bounds: a swapped speed changes how fast it
## travels and in which direction, never whether it may leave its path. Speed
## 0 parks it — and it stays parked until another valid swap or a lab reset.
##
## Carrying: the platform is an AnimatableBody2D with `sync_to_physics` on, so
## its own transform delta is reported to the physics server and grounded
## CharacterBody2D riders are carried by their own `move_and_slide` platform
## handling. `manual_carry` is the explicit carrier-step fallback (`carry_motion`)
## kept for the case the platform-speed path is unavailable; it is OFF by
## default so a rider is never carried twice.
##
## Node origin = the platform's TOP-LEFT corner at the START of its path.

@export var axis: Vector2 = Vector2.RIGHT
@export var path_length: float = 160.0
@export var travel_speed: float = 70.0
@export var platform_size: Vector2 = Vector2(120.0, 16.0)
@export var manual_carry: bool = false
## How hard the platform drags a resting crate along its own axis.
@export var rider_drive_accel: float = 900.0
## Optional visual tag so two platforms are told apart at a glance.
@export var label_text: String = ""

var authored_speed: float = 0.0

var swap_target: NLBMotionSwapTarget = null
var rider_zone: Area2D = null

var _origin: Vector2 = Vector2.ZERO
var _t: float = 0.0
var _axis: Vector2 = Vector2.RIGHT
var _font: Font = null

func _ready() -> void:
	authored_speed = travel_speed
	add_to_group("lab_machines")
	add_to_group("lab_resettable")
	collision_layer = 512
	collision_mask = 2 | 4 | 256
	sync_to_physics = true
	_axis = axis.normalized() if axis.length() > 0.001 else Vector2.RIGHT
	_origin = global_position
	_t = 0.0
	_build_nodes()

func _build_nodes() -> void:
	var shape := CollisionShape2D.new()
	shape.name = "PlatformShape"
	var box := RectangleShape2D.new()
	box.size = platform_size
	shape.shape = box
	shape.position = platform_size * 0.5
	add_child(shape)
	rider_zone = Area2D.new()
	rider_zone.name = "RiderZone"
	rider_zone.collision_layer = 0
	rider_zone.collision_mask = 2 | 4 | 256
	rider_zone.monitoring = true
	var zshape := CollisionShape2D.new()
	var zbox := RectangleShape2D.new()
	zbox.size = Vector2(platform_size.x, 34.0)
	zshape.shape = zbox
	# Same reasoning as the belt zone: deep enough to reliably overlap a resting
	# crate or a standing rider, not just graze their lowest pixel.
	zshape.position = Vector2(platform_size.x * 0.5, -8.0)
	rider_zone.add_child(zshape)
	add_child(rider_zone)
	swap_target = NLBMotionSwapTarget.new()
	swap_target.name = "SwapTarget"
	swap_target.anchor_offset = Vector2(platform_size.x * 0.5, -34.0)
	add_child(swap_target)
	swap_target.adapter = NLBMotionPlatformAdapter.new(self)
	swap_target.display_name = "LIFT" if label_text.is_empty() else "LIFT " + label_text
	_font = ThemeDB.fallback_font

## The exchange write path. No clamping: 0 parks it, a sign flips its direction,
## a bigger number makes it faster — within its authored bounds, always.
func set_travel_speed(value: float) -> void:
	travel_speed = value

func drive_symbol() -> String:
	var d := signf(travel_speed)
	if d == 0.0:
		return "=="
	var v := _axis * d
	if absf(v.x) >= absf(v.y):
		return "->" if v.x > 0.0 else "<-"
	return "vv" if v.y > 0.0 else "^^"

func debug_line() -> String:
	return "%s#%d %s %+.0f px/s [%.0f/%.0f]" % [
		swap_target.display_name if swap_target != null else "LIFT",
		get_instance_id() % 1000, drive_symbol(), travel_speed, _t, path_length]

func progress() -> float:
	return _t

func _physics_process(delta: float) -> void:
	# Progress is the authoritative state: the platform is always inside its
	# authored path, whatever speed it was handed.
	_t = clampf(_t + travel_speed * delta, 0.0, path_length)
	var next := _origin + _axis * _t
	if sync_to_physics:
		global_position = next  # the physics server sweeps and carries riders
	else:
		var before := global_position
		move_and_collide(next - global_position)
		if manual_carry:
			_carry_riders(global_position - before)
	_drive_riders(delta)

## A machine drives what rests on it. Crates are pulled along the platform's
## own axis toward its travel speed (the same bounded acceleration the belts
## use), so a crate can actually ride. This only runs while the platform is
## itself commanded to move: a PARKED platform never brakes a rider, so a
## swapped motion on a crate is never silently deleted by standing on it.
func _drive_riders(delta: float) -> void:
	if absf(travel_speed) < 1.0 or rider_zone == null:
		return
	for body in rider_zone.get_overlapping_bodies():
		var rb := body as RigidBody2D
		if rb == null:
			continue
		var along := rb.linear_velocity.dot(_axis)
		var driven := move_toward(along, travel_speed, rider_drive_accel * delta)
		rb.linear_velocity += _axis * (driven - along)

func _carry_riders(step: Vector2) -> void:
	if step == Vector2.ZERO or rider_zone == null:
		return
	for body in rider_zone.get_overlapping_bodies():
		if body is CharacterBody2D:
			var cb := body as CharacterBody2D
			if cb.is_on_floor() and "carry_motion" in cb:
				cb.set("carry_motion", (cb.get("carry_motion") as Vector2) + step)

func reset_state() -> void:
	travel_speed = authored_speed
	_t = 0.0
	global_position = _origin

func reset_motion() -> void:
	reset_state()

func _draw() -> void:
	var col := Color("39485c")
	draw_rect(Rect2(Vector2.ZERO, platform_size), col, true)
	draw_line(Vector2(0, 1), Vector2(platform_size.x, 1), Color("c9d6e2"), 2.0)
	# Path guide: faint dashes along the authored travel, so the bound is
	# visible even when the platform is parked at one end.
	var dashes := int(path_length / 22.0)
	for i in dashes + 1:
		var p := _axis * (i * 22.0)
		var perp := _axis.orthogonal() * 2.0
		draw_line(p + Vector2(platform_size.x * 0.5, 0) + perp * 3.0 - _axis.orthogonal() * 4.0,
			p + Vector2(platform_size.x * 0.5, 0) + perp * 3.0 + _axis.orthogonal() * 4.0,
			Color(0.6, 0.75, 0.9, 0.22), 2.0)
	if not label_text.is_empty() and _font != null:
		draw_string(_font, Vector2(platform_size.x * 0.5 - 22.0, platform_size.y * 0.5 + 5.0),
			label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.85, 0.92, 1.0, 0.9))
