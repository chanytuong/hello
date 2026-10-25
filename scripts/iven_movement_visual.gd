extends Node2D
## Movement visual for the live gameplay path.
## Source clips and per-frame anchors are immutable data. The physics body owns
## the action clock; this node only chooses the authored drawing for that clock.
const FRAMES = preload("res://art/iven/movement/body_frames.tres")
const JUMP_SHEET_RIGHT = preload("res://art/iven/movement/jump_v02/IVEN_JUMP_V02_SHEET.png")
const JUMP_SHEET_LEFT = preload("res://art/iven/movement/jump_v02/IVEN_JUMP_V02_SHEET_LEFT.png")
const ROLL_SHEET_RIGHT = preload("res://art/iven/movement/roll_v03/IVEN_ROLL_SHEET_V03.png")
const ROLL_SHEET_LEFT = preload("res://art/iven/movement/roll_v03/IVEN_ROLL_SHEET_LEFT.png")
const AIR_ROLL_SHEET_RIGHT = preload("res://art/iven/movement/roll_v03/IVEN_AIR_ROLL_SHEET_V03.png")
const AIR_ROLL_SHEET_LEFT = preload("res://art/iven/movement/roll_v03/IVEN_AIR_ROLL_SHEET_LEFT.png")
const PIVOT := Vector2(40.499926203, 75.579576591)
const CELL := 82
const FOOT_JUMP := 77.0
const ART_FPS := 30.0
const JUMP_FRAMES := 30
const LAND_FRAMES := 5
const LAND_START := 25
const ROLL_FRAMES := 15
const AIR_ROLL_FRAMES := 7
const ROLL_MODULATE := Color(0.84, 0.765, 0.739, 1.0)

var state: String = "IDLE"
var roll_duration: float = 0.50
var roll_cooldown: float = 0.35
var state_time: float = 0.0
var state_changes: int = 0
var body := AnimatedSprite2D.new()
var flame: Node2D
var neck_local: Vector2 = Vector2.ZERO
var anchors: Dictionary
var _skid_left: float = 0.0
var _roll_clock: float = 0.0
var _roll_family: String = "DODGE_ROLL"
## Kept as a compatibility field: m1_combo._start clears decorative handoffs.
var _exit_poses: Array[Dictionary] = []

func _ready() -> void:
	var body_anchors: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/iven/movement/anchors.json"))
	var jump_anchors: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/iven/movement/jump_v02/jump_anchors.json"))
	var roll_anchors: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/iven/movement/roll_v03/anchors.json"))
	anchors = {}
	anchors.merge(body_anchors, true)
	anchors["JUMP_right"] = jump_anchors["right"]
	anchors["JUMP_left"] = jump_anchors["left"]
	anchors["LAND_right"] = (jump_anchors["right"] as Array).slice(LAND_START, LAND_START + LAND_FRAMES)
	anchors["LAND_left"] = (jump_anchors["left"] as Array).slice(LAND_START, LAND_START + LAND_FRAMES)
	anchors.merge(roll_anchors, true)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.name = "BodySprite"
	body.sprite_frames = FRAMES.duplicate(true) # never mutate the shared source resource
	_add_sheet("JUMP_right", JUMP_SHEET_RIGHT, JUMP_FRAMES)
	_add_sheet("JUMP_left", JUMP_SHEET_LEFT, JUMP_FRAMES)
	_add_sheet("LAND_right", JUMP_SHEET_RIGHT, LAND_FRAMES, LAND_START)
	_add_sheet("LAND_left", JUMP_SHEET_LEFT, LAND_FRAMES, LAND_START)
	_add_sheet("DODGE_ROLL_right", ROLL_SHEET_RIGHT, ROLL_FRAMES)
	_add_sheet("DODGE_ROLL_left", ROLL_SHEET_LEFT, ROLL_FRAMES)
	_add_sheet("AIR_ROLL_right", AIR_ROLL_SHEET_RIGHT, AIR_ROLL_FRAMES)
	_add_sheet("AIR_ROLL_left", AIR_ROLL_SHEET_LEFT, AIR_ROLL_FRAMES)
	body.centered = false
	body.offset = -PIVOT
	# Physics owns the animation clock, including roll end. No repeated play().
	body.speed_scale = 0.0
	add_child(body)
	flame = preload("res://scripts/iven_flame.gd").new()
	flame.name = "FlameHead"
	add_child(flame)
	_apply_frame(0)

func _add_sheet(clip: String, sheet: Texture2D, count: int, start: int = 0) -> void:
	var frames := body.sprite_frames
	if frames.has_animation(clip):
		frames.remove_animation(clip)
	frames.add_animation(clip)
	frames.set_animation_speed(clip, ART_FPS)
	frames.set_animation_loop(clip, false)
	for i in count:
		var cell := AtlasTexture.new()
		cell.atlas = sheet
		cell.region = Rect2((start + i) * CELL, 0, CELL, CELL)
		frames.add_frame(clip, cell)

func reset_state() -> void:
	state = "IDLE"
	state_time = 0.0
	_skid_left = 0.0
	_roll_clock = 0.0
	_roll_family = "DODGE_ROLL"
	_exit_poses.clear()
	_apply_frame(0)

func advance(dt: float, input_dir: float, release_skid: bool, old_velocity: Vector2) -> void:
	var player := get_parent() as NLBPlayer
	_skid_left = maxf(0.0, _skid_left - dt)
	if release_skid and player.is_on_floor() and player.roll_remaining <= 0.0:
		_skid_left = 13.0 / 30.0
	# New intent cancels the decorative recovery immediately.
	if input_dir != 0.0 or not player.is_on_floor() or player.roll_remaining > 0.0:
		_skid_left = 0.0
	var previous := state
	var next := "IDLE"
	if player.roll_remaining > 0.0:
		# The clip family is chosen once, at roll start. Landing mid-air-roll
		# never pops the drawing family or rewinds the tumble.
		if previous != "DODGE_ROLL" and previous != "AIR_ROLL":
			_roll_family = "DODGE_ROLL" if player.is_on_floor() else "AIR_ROLL"
			_roll_clock = 0.0
		next = _roll_family
	elif not player.is_on_floor():
		next = "JUMP"
	elif player._jump_land_t > 0.0:
		next = "LAND"
		# A held run leaves the landing pose after its first touchdown drawing;
		# an idle landing shows the full 25..29 recovery.
		if previous == "LAND" and input_dir != 0.0:
			next = "RUN" if absf(player.get_real_velocity().x) > 20.0 else "IDLE"
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
	if state == "DODGE_ROLL" or state == "AIR_ROLL":
		# One tumble per accepted action. Rejected presses never rewind it.
		if previous == state:
			_roll_clock += dt
		_apply_frame(_roll_frame_index())
	elif state == "JUMP":
		var jump_index := clampi(3 + int(player._air_time * ART_FPS + 0.00001), 3, 24)
		_apply_frame(jump_index)
	elif state == "LAND":
		var land_elapsed := maxf(0.0, LAND_FRAMES / ART_FPS - player._jump_land_t)
		var land_index := clampi(int(land_elapsed * ART_FPS + 0.00001), 0, LAND_FRAMES - 1)
		_apply_frame(land_index)
	else:
		_apply_frame(int(state_time * ART_FPS + 0.00001))
	# Keep visual pixels on the pixel grid; never snap the physics body.
	position = player.global_position.round() - player.global_position
	flame.step(player.get_real_velocity(), (player.velocity - old_velocity) / dt, dt)
	if player.is_on_floor():
		flame.limit_at_ground(player.global_position.y - flame.global_position.y)

func _roll_frame_index() -> int:
	var count := AIR_ROLL_FRAMES if _roll_family == "AIR_ROLL" else ROLL_FRAMES
	return mini(int(_roll_clock * ART_FPS + 0.00001), count - 1)

func _apply_frame(index: int) -> void:
	var player := get_parent() as NLBPlayer
	var direction := "right" if player.facing > 0 else "left"
	var clip := StringName(state + "_" + direction)
	var count := body.sprite_frames.get_frame_count(clip)
	if count <= 0:
		return
	index = index % count if state == "RUN" else mini(index, count - 1)
	if body.animation != clip:
		body.play(clip)
		body.speed_scale = 0.0
	body.set_frame_and_progress(index, 0.0)
	body.modulate = ROLL_MODULATE if state == "DODGE_ROLL" or state == "AIR_ROLL" else Color.WHITE
	var airborne_frame := state == "JUMP" or state == "LAND"
	body.offset = Vector2(-PIVOT.x, -FOOT_JUMP) if airborne_frame else -PIVOT
	var data: Dictionary = anchors[String(clip)][index]
	var origin_y := FOOT_JUMP if airborne_frame else PIVOT.y
	neck_local = Vector2(data.neck[0] - PIVOT.x, data.neck[1] - origin_y)
	flame.position = neck_local.round()
	flame.rotation = float(data.angle)
