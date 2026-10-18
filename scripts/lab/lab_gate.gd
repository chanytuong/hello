extends AnimatableBody2D
class_name LabGate
## Lab gate. Slides up into its ceiling recess when told to open; latching is
## the plate's business, not the gate's. While moving it is a real body
## (sync_to_physics), so it can never teleport someone standing in the doorway;
## once fully open its shape is disabled so the doorway has no snag.
##
## Node origin = the gate's TOP-LEFT corner; the closed gate fills from the
## origin down to the floor.

@export var gate_size: Vector2 = Vector2(20.0, 120.0)
@export var open_offset: Vector2 = Vector2(0.0, -160.0)
@export var move_speed: float = 260.0
@export var start_open: bool = false

signal opened

var open: bool = false

var _closed_pos: Vector2 = Vector2.ZERO
var _target: Vector2 = Vector2.ZERO
var _shape: CollisionShape2D = null

func _ready() -> void:
	add_to_group("lab_gates")
	add_to_group("lab_resettable")
	collision_layer = 512
	collision_mask = 2 | 4 | 256
	sync_to_physics = true
	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var box := RectangleShape2D.new()
	box.size = gate_size
	shape.shape = box
	shape.position = gate_size * 0.5
	add_child(shape)
	_shape = shape
	_closed_pos = position
	open = start_open
	_target = _closed_pos + open_offset if open else _closed_pos
	position = _target
	if open:
		_shape.disabled = true

func is_open() -> bool:
	return open

func set_open(value: bool) -> void:
	if open == value:
		return
	open = value
	_target = _closed_pos + open_offset if open else _closed_pos
	if open:
		opened.emit()

func debug_line() -> String:
	return "GATE %s" % ("OPEN" if open else "CLOSED")

func _physics_process(delta: float) -> void:
	if _shape == null:
		return
	if not open:
		_shape.disabled = false
	position = position.move_toward(_target, move_speed * delta)
	if open and position.distance_to(_target) < 0.5:
		_shape.disabled = true

func reset_state() -> void:
	open = start_open
	_target = _closed_pos + open_offset if open else _closed_pos
	position = _target
	if _shape != null:
		_shape.disabled = open

func _draw() -> void:
	var col := Color(0.75, 0.35, 0.3) if not open else Color(0.35, 0.8, 0.5)
	draw_rect(Rect2(Vector2.ZERO, gate_size), col.darkened(0.35), true)
	# Hazard stripes: it reads as machinery, not as background.
	var y := 6.0
	while y < gate_size.y - 6.0:
		draw_line(Vector2(2.0, y + 4.0), Vector2(gate_size.x - 2.0, y), col, 2.0)
		y += 14.0
	draw_rect(Rect2(Vector2.ZERO, gate_size), col, false, 1.0)
