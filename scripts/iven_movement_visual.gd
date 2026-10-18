extends Node2D
## Five visual states; source clips and per-frame anchors are immutable data.
const FRAMES = preload("res://art/iven/movement/body_frames.tres")
const BRIDGES = preload("res://art/iven/movement/roll_transitions/frames.tres")
const PIVOT := Vector2(40.499926203, 75.579576591)
const BRIDGE_TIME := 2.0 / 60.0
const RUN_RETURN_FRAME := 13 # existing source preview's matched RUN_14
var state: String = "IDLE"
var state_time: float = 0.0
var state_changes: int = 0
var body := AnimatedSprite2D.new()
var flame: Node2D
var anchors: Dictionary
var _skid_left: float = 0.0
var _last_direction: int = 1
var neck_local := Vector2.ZERO
var _roll_clock: float = 0.0
var _entry_family: String = "IDLE"
var _exit_poses: Array[Dictionary] = []
var _exit_clock: float = 0.0
var _exit_angle: float = 0.0
var _last_roll_frame: int = 0

func _ready() -> void:
	anchors = JSON.parse_string(FileAccess.get_file_as_string("res://art/iven/movement/anchors.json"))
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.name = "BodySprite"
	body.sprite_frames = FRAMES.duplicate() # never mutate the shared source resource
	for clip in BRIDGES.get_animation_names():
		body.sprite_frames.add_animation(clip)
		body.sprite_frames.set_animation_loop(clip, false)
		for i in BRIDGES.get_frame_count(clip):
			body.sprite_frames.add_frame(clip, BRIDGES.get_frame_texture(clip, i))
	anchors.merge(JSON.parse_string(FileAccess.get_file_as_string("res://art/iven/movement/roll_transitions/anchors.json")))
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
	_roll_clock = 0.0
	_exit_poses.clear()
	_exit_clock = 0.0
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
	if player.roll_remaining > 0.0:
		next = "DODGE_ROLL"
	elif not player.is_on_floor():
		next = "JUMP"
	elif _skid_left > 0.0:
		next = "SKID_STOP"
	elif absf(player.get_real_velocity().x) > 20.0:
		next = "RUN"
	var previous := state
	if next != state:
		if next == "DODGE_ROLL":
			_entry_family = "RUN" if previous == "RUN" else "IDLE"
			_roll_clock = 0.0
			_exit_poses.clear()
		elif previous == "DODGE_ROLL" or not _exit_poses.is_empty():
			_begin_roll_exit(next)
		state = next
		state_time = 0.0
		state_changes += 1
	else:
		state_time += dt
	if state == "DODGE_ROLL":
		# Repeated presses extend gameplay, but never rewind an ongoing tumble.
		if previous == state:
			_roll_clock = fmod(_roll_clock + dt, player.roll_duration)
		if _roll_clock < BRIDGE_TIME - 0.00001:
			var entry_index := mini(int(_roll_clock * 60.0 + 0.00001), 1)
			_apply_frame(entry_index, "ROLL_IN_" + _entry_family, _bridge_angle(entry_index))
		else:
			_last_roll_frame = mini(int((_roll_clock - BRIDGE_TIME) * 21.0 / (player.roll_duration - BRIDGE_TIME) + 0.00001), 20)
			_apply_frame(_last_roll_frame)
	elif not _exit_poses.is_empty():
		var exit_index := int(_exit_clock * 60.0 + 0.00001)
		if exit_index < 2:
			var pose: Dictionary = _exit_poses[exit_index]
			_apply_frame(pose.frame, pose.pose, _exit_angle * float(2 - exit_index) / 3.0)
			_exit_clock += dt
		else:
			_exit_poses.clear()
			if state == "RUN":
				state_time = float(RUN_RETURN_FRAME) / 30.0
			_apply_frame(int(state_time * 30.0 + 0.00001))
	else:
		_apply_frame(int(state_time * 30.0 + 0.00001))
	# Keep visual pixels on the pixel grid; never snap the physics body.
	position = player.global_position.round() - player.global_position
	flame.step(player.get_real_velocity(), (player.velocity - old_velocity) / dt, dt)
	if player.is_on_floor():
		flame.limit_at_ground(player.global_position.y - flame.global_position.y)

func _bridge_angle(index: int) -> float:
	var player := get_parent() as NLBPlayer
	var direction := "right" if player.facing > 0 else "left"
	var data: Dictionary = anchors["ROLL_IN_" + _entry_family + "_" + direction][index]
	return float(data.angle) * float(index + 1) / 3.0

func _begin_roll_exit(target: String) -> void:
	var player := get_parent() as NLBPlayer
	var direction := "right" if player.facing > 0 else "left"
	var family := "RUN" if target == "RUN" else "IDLE"
	_exit_poses.clear()
	_exit_clock = 0.0
	_exit_angle = wrapf(flame.rotation, -PI, PI)
	if player.facing != _last_direction:
		_exit_angle = -_exit_angle
	# Natural completion is already upright: use the authored return samples.
	if str(body.animation).begins_with("DODGE_ROLL") and body.frame >= 18:
		_exit_poses.assign([{"pose": "ROLL_OUT_" + family, "frame": 0}, {"pose": "ROLL_OUT_" + family, "frame": 1}])
		return
	# Cancels never finish the whole action. Select at most two existing poses
	# toward the requested silhouette, using neck position as a pose landmark.
	var start := neck_local + PIVOT
	if player.facing != _last_direction:
		start.x = 81.0 - start.x
	var target_clip := target + "_" + direction
	var target_frame := RUN_RETURN_FRAME if target == "RUN" else 0
	var endpoint_data: Dictionary = anchors[target_clip][target_frame]
	var endpoint := Vector2(endpoint_data.neck[0], endpoint_data.neck[1])
	var candidates: Array[Dictionary] = []
	if str(body.animation).begins_with("DODGE_ROLL") and body.frame <= 8:
		for i in range(body.frame - 1, -1, -1):
			candidates.append({"pose": "DODGE_ROLL", "frame": i})
		candidates.append({"pose": "ROLL_IN_" + family, "frame": 1})
		candidates.append({"pose": "ROLL_IN_" + family, "frame": 0})
	else:
		for i in range(13, 21):
			candidates.append({"pose": "DODGE_ROLL", "frame": i})
		candidates.append({"pose": "ROLL_OUT_" + family, "frame": 0})
		candidates.append({"pose": "ROLL_OUT_" + family, "frame": 1})
	for step_index in 2:
		var wanted := start.lerp(endpoint, float(step_index + 1) / 3.0)
		var best := 0
		var cost := INF
		for i in candidates.size():
			var pose: Dictionary = candidates[i]
			var data: Dictionary = anchors[pose.pose + "_" + direction][pose.frame]
			var point := Vector2(data.neck[0], data.neck[1])
			# Vertical continuity dominates during an unfold. The neck travels
			# sideways around the tumble; treating X equally can skip the crouch.
			var delta := point - wanted
			var distance := delta.y * delta.y + delta.x * delta.x * 0.15
			if distance < cost:
				cost = distance
				best = i
		_exit_poses.append(candidates[best])
		candidates = candidates.slice(mini(best + 1, candidates.size() - 1))

func _apply_frame(index: int, pose: String = "", angle: float = INF) -> void:
	var player := get_parent() as NLBPlayer
	var direction := "right" if player.facing > 0 else "left"
	var pose_name := state if pose.is_empty() else pose
	var clip := StringName(pose_name + "_" + direction)
	var count := body.sprite_frames.get_frame_count(clip)
	index = index % count if pose_name == "RUN" else mini(index, count - 1)
	if body.animation != clip:
		body.play(clip)
		body.speed_scale = 0.0
	body.set_frame_and_progress(index, 0.0)
	var data: Dictionary = anchors[String(clip)][index]
	neck_local = Vector2(data.neck[0], data.neck[1]) - PIVOT
	flame.position = neck_local.round()
	flame.rotation = angle if is_finite(angle) else float(data.angle)
	_last_direction = player.facing
