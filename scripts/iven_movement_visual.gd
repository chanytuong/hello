extends Node2D
## Five visual states; source clips and per-frame anchors are immutable data.
const FRAMES = preload("res://art/iven/movement/body_frames.tres")
const PIVOT := Vector2(40.499926203, 75.579576591)
var state: String = "IDLE"
var state_time: float = 0.0
var state_changes: int = 0
var body := AnimatedSprite2D.new()
var flame: Node2D
var anchors: Dictionary
var _skid_left: float = 0.0
var _last_direction: int = 1
var neck_local := Vector2.ZERO

func _ready() -> void:
	anchors = JSON.parse_string(FileAccess.get_file_as_string("res://art/iven/movement/anchors.json"))
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.name = "BodySprite"
	body.sprite_frames = FRAMES
	body.centered = false
	body.offset = -PIVOT
	# Physics owns the animation clock, including roll end. No repeated play().
	body.speed_scale = 0.0
	add_child(body)
	flame = preload("res://scripts/iven_flame.gd").new()
	flame.name = "FlameHead"
	add_child(flame)
	_apply_frame(0)

func reset_state() -> void:
	state = "IDLE"
	state_time = 0.0
	_skid_left = 0.0
	_apply_frame(0)

func advance(dt: float, input_dir: float, release_skid: bool, old_velocity: Vector2) -> void:
	var player := get_parent() as NLBPlayer
	_skid_left = maxf(0.0, _skid_left - dt)
	if release_skid and player.is_on_floor() and player.roll_remaining <= 0.0:
		_skid_left = 13.0 / 30.0
	# New intent cancels the decorative recovery immediately.
	if input_dir != 0.0 or not player.is_on_floor() or player.roll_remaining > 0.0:
		_skid_left = 0.0
	var next := "IDLE"
	if not player.is_on_floor():
		next = "JUMP"
	elif player.roll_remaining > 0.0:
		next = "DODGE_ROLL"
	elif _skid_left > 0.0:
		next = "SKID_STOP"
	elif absf(player.get_real_velocity().x) > 20.0:
		next = "RUN"
	if next != state:
		state = next
		state_time = 0.0
		state_changes += 1
	else:
		state_time += dt
	var frame_index := int(state_time * 30.0 + 0.00001)
	if state == "DODGE_ROLL":
		frame_index = int((player.roll_duration - player.roll_remaining) * 21.0 / player.roll_duration + 0.00001)
	_apply_frame(frame_index)
	# Keep visual pixels on the pixel grid; never snap the physics body.
	position = player.global_position.round() - player.global_position
	flame.step(player.get_real_velocity(), (player.velocity - old_velocity) / dt, dt)
	if player.is_on_floor():
		flame.limit_at_ground(player.global_position.y - flame.global_position.y)

func _apply_frame(index: int) -> void:
	var player := get_parent() as NLBPlayer
	var direction := "right" if player.facing > 0 else "left"
	var clip := StringName(state + "_" + direction)
	var count := FRAMES.get_frame_count(clip)
	index = index % count if state == "RUN" else mini(index, count - 1)
	if body.animation != clip:
		body.play(clip)
		body.speed_scale = 0.0
	body.set_frame_and_progress(index, 0.0)
	var data: Dictionary = anchors[String(clip)][index]
	neck_local = Vector2(data.neck[0], data.neck[1]) - PIVOT
	flame.position = neck_local.round()
	flame.rotation = float(data.angle) # nonzero only for measured roll neck basis
	_last_direction = player.facing
