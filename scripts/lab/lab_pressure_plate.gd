extends Area2D
class_name LabPressurePlate
## Lab pressure plate. ANY physics body presses it: the player, a crate, or an
## enemy. It is not a weight-faking puzzle object — the lab rule is simple and
## legible so the exchange remains the interesting part.
##
## `latch = true` (zone E): the first press is remembered forever. That is the
## no-softlock guarantee — the gate can never close behind the player, and the
## return path home is never lost. `latch = false` is available for
## experiments that want a hold-to-keep-open pad.

signal state_changed(pressed_now: bool, latched: bool)

const DOWN_T := 0.08

@export var latch: bool = true
@export var label_text: String = "PLATE"

var latched: bool = false

var _pressed_now: bool = false
var _sink: float = 0.0
var _settle_t: float = 0.0
var _font: Font = null

@onready var visual: ColorRect = $Visual

func _ready() -> void:
	add_to_group("lab_plates")
	collision_layer = 0
	collision_mask = 2 | 4 | 256
	monitoring = true
	_font = ThemeDB.fallback_font
	if visual != null:
		visual.pivot_offset = Vector2(visual.size.x * 0.5, 0.0)

func is_pressed_now() -> bool:
	return _pressed_now

func is_latched() -> bool:
	return latched

func reset_state() -> void:
	latched = false
	_pressed_now = false
	_sink = 0.0
	# A teleport (reset tool, checkpoint respawn) leaves the body that just left
	# inside the physics broadphase for one more step. Without this window the
	# plate re-latches on that ghost and a reset would leave the gate open — the
	# puzzle would look solved when nothing is on the pad. Measured settle: one
	# step; the window is 0.06 s so it cannot be raced by a real press.
	_settle_t = 0.06
	state_changed.emit(false, false)

func debug_line() -> String:
	return "PLATE %s %s" % ["DOWN" if _pressed_now else "up", "LATCHED" if latched else "clear"]

func _physics_process(delta: float) -> void:
	if _settle_t > 0.0:
		# Fresh after a reset: ignore ghost overlaps left by a teleport.
		_settle_t = maxf(0.0, _settle_t - delta)
		_sink = move_toward(_sink, 0.0, delta / DOWN_T)
		if visual != null:
			visual.position.y = 6.0 * _sink
			visual.color = Color(0.55, 0.6, 0.68, 0.9)
		queue_redraw()
		return
	var on := false
	for body in get_overlapping_bodies():
		if body is PhysicsBody2D:
			on = true
			break
	if on and not _pressed_now:
		_pressed_now = true
		if latch:
			latched = true
		state_changed.emit(true, latched)
	elif not on and _pressed_now:
		# Releasing does not un-latch; it only stops "pressed now".
		_pressed_now = false
		state_changed.emit(false, latched)
	var target := 1.0 if on else 0.0
	_sink = move_toward(_sink, target, delta / DOWN_T)
	if visual != null:
		visual.position.y = 6.0 * _sink
		if latched:
			visual.color = Color(0.35, 0.95, 0.55, 0.95)
		elif on:
			visual.color = Color(0.95, 0.85, 0.35, 0.95)
		else:
			visual.color = Color(0.55, 0.6, 0.68, 0.9)
	queue_redraw()

func _draw() -> void:
	if _font == null:
		return
	draw_string(_font, Vector2(-40, 34), "%s %s" % [label_text, "OPEN" if latched else ("DOWN" if _pressed_now else "")],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.75, 0.85, 0.95, 0.85))
