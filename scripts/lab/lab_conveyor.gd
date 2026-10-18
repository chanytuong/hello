extends StaticBody2D
class_name LabConveyor
## Lab conveyor belt — the SURFACE machine.
##
## What Motion Swap exchanges is `surface_speed`: the belt's persistent
## operating speed as a signed scalar along its own axis (positive = drives
## riders to the right). It is NOT the belt body's velocity — a belt never
## moves, so exchanging that would do nothing while looking like a bug.
##
## The belt body is placid: it never moves. Riders are moved by an explicit
## carrier step (`carry_motion`, consumed by the player through the same
## collision pass as its own movement) and crates are driven with a bounded
## acceleration toward the belt speed. The swapped speed PERSISTS: it is not
## tied to any character's override clock and only a new valid swap or an
## explicit lab reset changes it.
##
## Node origin = the belt's TOP-LEFT corner, so a builder can drop the surface
## exactly on a floor line. All geometry is built from the exports.

@export var surface_speed: float = 120.0
@export var belt_length: float = 300.0
@export var thickness: float = 20.0
## How hard the belt drags a crate along. Tuned to be readable, not instant.
@export var carry_accel: float = 900.0
@export var chevron_spacing: float = 28.0

var authored_speed: float = 0.0

var swap_target: NLBMotionSwapTarget = null
var belt_zone: Area2D = null
var _phase: float = 0.0

func _ready() -> void:
	authored_speed = surface_speed
	add_to_group("lab_machines")
	add_to_group("lab_resettable")
	collision_layer = 512
	collision_mask = 2 | 4 | 256
	_build_nodes()

func _build_nodes() -> void:
	var shape := CollisionShape2D.new()
	shape.name = "BeltShape"
	var box := RectangleShape2D.new()
	box.size = Vector2(belt_length, thickness)
	shape.shape = box
	shape.position = Vector2(belt_length * 0.5, thickness * 0.5)
	add_child(shape)
	belt_zone = Area2D.new()
	belt_zone.name = "BeltZone"
	belt_zone.collision_layer = 0
	belt_zone.collision_mask = 2 | 4 | 256
	belt_zone.monitoring = true
	var zshape := CollisionShape2D.new()
	var zbox := RectangleShape2D.new()
	zbox.size = Vector2(belt_length, 34.0)
	zshape.shape = zbox
	# Sits just above the belt's surface and reaches far enough down to catch a
	# riding crate's lower half and a standing body's feet for certain.
	zshape.position = Vector2(belt_length * 0.5, -8.0)
	belt_zone.add_child(zshape)
	add_child(belt_zone)
	swap_target = NLBMotionSwapTarget.new()
	swap_target.name = "SwapTarget"
	swap_target.anchor_offset = Vector2(belt_length * 0.5, -30.0)
	add_child(swap_target)
	swap_target.adapter = NLBMotionConveyorAdapter.new(self)
	swap_target.display_name = "BELT"

## The exchange write path. No clamping, no massaging: the received value is
## what the belt runs at.
func set_surface_speed(value: float) -> void:
	surface_speed = value
	queue_redraw()

func drive_symbol() -> String:
	if surface_speed > 1.0:
		return "->"
	if surface_speed < -1.0:
		return "<-"
	return "=="

func debug_line() -> String:
	return "BELT#%d %s %+.0f px/s" % [get_instance_id() % 1000, drive_symbol(), surface_speed]

func _physics_process(delta: float) -> void:
	_phase = fmod(_phase + surface_speed * delta, chevron_spacing)
	queue_redraw()
	if belt_zone == null:
		return
	for body in belt_zone.get_overlapping_bodies():
		if body is RigidBody2D:
			var rb := body as RigidBody2D
			rb.linear_velocity.x = move_toward(rb.linear_velocity.x, surface_speed, carry_accel * delta)
		elif body is CharacterBody2D:
			var cb := body as CharacterBody2D
			# Only a grounded rider is carried: jumping off a belt must not be
			# dragged back down onto it by a phantom carrier step. The property
			# is opt-in (`carry_motion`), so unrelated bodies are left alone.
			if cb.is_on_floor() and "carry_motion" in cb:
				cb.set("carry_motion", (cb.get("carry_motion") as Vector2) + Vector2(surface_speed * delta, 0.0))

func reset_state() -> void:
	surface_speed = authored_speed
	queue_redraw()

func reset_motion() -> void:
	reset_state()

func _draw() -> void:
	# Belt body.
	draw_rect(Rect2(0, 0, belt_length, thickness), Color("2b3440"), true)
	# Running surface.
	var running := absf(surface_speed) > 1.0
	var surface_col := Color("7ad7e0") if running else Color("8a939c")
	draw_line(Vector2(0, 1), Vector2(belt_length, 1), surface_col, 2.0)
	# Direction chevrons: they scroll at the belt's own speed, so a stopped
	# belt reads as stopped even with nothing riding it.
	var col := Color(0.48, 0.84, 0.88, 0.55) if running else Color(0.6, 0.63, 0.66, 0.3)
	var dir := signf(surface_speed)
	var x := _phase - chevron_spacing
	while x < belt_length + chevron_spacing:
		if x > -chevron_spacing * 0.5 and x < belt_length + chevron_spacing * 0.5:
			if dir > 0.0:
				draw_line(Vector2(x - 6.0, 4.0), Vector2(x, 12.0), col, 2.0)
				draw_line(Vector2(x, 12.0), Vector2(x + 6.0, 4.0), col, 2.0)
			else:
				draw_line(Vector2(x + 6.0, 4.0), Vector2(x, 12.0), col, 2.0)
				draw_line(Vector2(x, 12.0), Vector2(x - 6.0, 4.0), col, 2.0)
		x += chevron_spacing
	# End caps.
	draw_line(Vector2(0.5, 0), Vector2(0.5, thickness), Color("151b22"), 1.0)
	draw_line(Vector2(belt_length - 0.5, 0), Vector2(belt_length - 0.5, thickness), Color("151b22"), 1.0)
