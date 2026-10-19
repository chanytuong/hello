extends SceneTree
## Drives the real playable scene. -- --capture saves actual Godot framebuffers.
const OUT := "res://artifacts/movement_integration/"
var scene: Node2D
var player: NLBPlayer
var rows: Array = []
var results: Array = []
var failures: int = 0
var capture: bool = false
var capture_index: int = 0
var case_name: String = ""
var tick: int = 0
var live_keys: Array = []

func _init() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	call_deferred("_run")

func _run() -> void:
	# Synthetic actions remain active in an unfocused window. Do not let typing
	# in another desktop task inject Shift/Space into this deterministic replay.
	root.unfocusable = true
	root.window_input.connect(_record_live_input)
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/movement_test.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "frames"))
	for direction in [1, -1]:
		for scenario in range(13):
			await _case(scenario, direction)
	var result := {"failures": failures, "assertions": results, "samples": rows.size(),
		"live_key_events": live_keys,
		"capture": capture, "framebuffers": capture_index,
		"evidence": "Godot runtime input replay; human feel review pending"}
	FileAccess.open(OUT + ("graphical_results.json" if capture else "runtime_results.json"), FileAccess.WRITE).store_string(JSON.stringify(result, "\t"))
	FileAccess.open(OUT + ("graphical_trace.json" if capture else "runtime_trace.json"), FileAccess.WRITE).store_string(JSON.stringify(rows))
	print("MOVEMENT_INTEGRATION: %d assertions; %d failures; %d samples" % [results.size(), failures, rows.size()])
	quit(1 if failures > 0 else 0)

func _record_live_input(event: InputEvent) -> void:
	if event is InputEventKey:
		live_keys.append({"case": case_name, "tick": tick, "event": event.as_text()})

func _check(ok: bool, label: String) -> void:
	results.append({"case": case_name, "check": label, "pass": ok})
	if not ok:
		failures += 1
		printerr("FAIL: %s / %s" % [case_name, label])

func _release_all() -> void:
	for action in ["move_left", "move_right", "jump", "dash", "attack", "swap_select", "swap_cancel"]:
		Input.action_release(action)

func _step() -> void:
	await physics_frame
	await process_frame
	var vis = player.movement_visual
	var anchor_error: float = vis.flame.position.distance_to(vis.neck_local)
	var row := {"case": case_name, "tick": tick, "x": player.position.x, "y": player.position.y,
		"vx": player.velocity.x, "vy": player.velocity.y, "floor": player.is_on_floor(),
		"wall": player.is_on_wall(), "facing": player.facing, "state": vis.state,
		"frame": vis.body.frame, "roll_remaining": player.roll_remaining,
		"anchor_error": anchor_error, "flame_angle": vis.flame.rotation,
		"flame_cel": vis.flame.cel, "flame_clock": vis.flame.clock,
		"flame_ground_clearance": player.global_position.y - vis.flame.global_position.y - vis.flame.ground_extent,
		"flame_angle_limited": vis.flame.angle_limited,
		"iframes": player.health._invuln}
	if capture and tick % 2 == 0:
		await RenderingServer.frame_post_draw
		var path := "frames/frame_%05d.png" % capture_index
		root.get_texture().get_image().save_png(OUT + path)
		row["capture"] = path
		capture_index += 1
	rows.append(row)
	tick += 1

func _case(scenario: int, direction: int) -> void:
	var names := ["idle_run_skid_idle", "run_jump_run", "standing_jump", "walk_off_ledge", "run_roll_run", "idle_roll_idle", "reversal", "buffered_jump_landing", "roll_wall", "jump_cancels_roll", "simultaneous_jump_roll", "jump_cancels_skid", "jump_after_landing"]
	case_name = names[scenario] + ("_right" if direction > 0 else "_left")
	_release_all()
	var at := Vector2(230 if direction > 0 else 430, 599)
	if scenario == 3:
		at = Vector2(744 if direction > 0 else 867, 599)
	if scenario == 8:
		at = Vector2(1190 if direction > 0 else 40, 599)
	player.reset_movement(at)
	player.facing = direction
	for settle in 4:
		await physics_frame
		await process_frame
	tick = 0
	var first := rows.size()
	var move := "move_right" if direction > 0 else "move_left"
	var reverse := "move_left" if direction > 0 else "move_right"
	var buffered := false
	var buffer_tick := -1
	var count := 90 if scenario in [1, 2, 7, 12] else 78
	if scenario == 3:
		count = 32
	for f in count:
		match scenario:
			0, 11:
				if f == 4: Input.action_press(move)
				if f == 30: Input.action_release(move)
				if scenario == 11 and f == 32: Input.action_press("jump")
				if scenario == 11 and f == 42: Input.action_release("jump")
			1:
				if f == 0: Input.action_press(move)
				if f == 20: Input.action_press("jump")
				if f == 33: Input.action_release("jump")
			2, 7, 12:
				if f == 8: Input.action_press("jump")
				if f == 22: Input.action_release("jump")
				if scenario == 7 and not buffered and player.velocity.y > 100.0 and player.position.y > 580.0 and not player.is_on_floor():
					Input.action_press("jump")
					buffered = true
					buffer_tick = f
				if buffered and f == buffer_tick + 3: Input.action_release("jump")
				if scenario == 12 and f > 22 and not buffered and player.is_on_floor():
					Input.action_press("jump")
					buffered = true
					buffer_tick = f
			3:
				if f == 0: Input.action_press(move)
			4:
				if f == 0: Input.action_press(move)
				if f == 20: Input.action_press("dash")
				if f == 21: Input.action_release("dash")
			5, 8, 9:
				if f == 8: Input.action_press("dash")
				if f == 9: Input.action_release("dash")
				if scenario == 9 and f == 18: Input.action_press("jump")
				if scenario == 9 and f == 30: Input.action_release("jump")
			6:
				if f == 0: Input.action_press(move)
				if f == 24:
					Input.action_release(move)
					Input.action_press(reverse)
			10:
				if f == 8:
					Input.action_press("jump")
					Input.action_press("dash")
				if f == 9: Input.action_release("dash")
				if f == 24: Input.action_release("jump")
		await _step()
	var part := rows.slice(first)
	var states: Array = part.map(func(r): return r.state)
	_check(part.all(func(r): return r.anchor_error <= 0.708), "neck root follows actual frame within pixel rounding")
	_check(part.all(func(r): return r.iframes == 0.0), "no roll immunity")
	_check(part.all(func(r): return not r.floor or r.flame_ground_clearance >= 0.99), "flame pixels remain above grounded support plane")
	_check(part.all(func(r): return r.x >= 13.8 and r.x <= 1216.2), "capsule does not cross boundary walls")
	if scenario == 0:
		_check("RUN" in states and "SKID_STOP" in states and states[-1] == "IDLE", "run release skid then idle")
		_check(part.filter(func(r): return r.state == "RUN").any(func(r): return r.frame > 5), "run advances without per-tick restart")
	if scenario in [1, 2, 7, 9, 10, 11]:
		_check("JUMP" in states, "airborne visual displayed")
	if scenario == 1:
		_check(states[-1] == "RUN", "landing returns to held run")
	if scenario == 2:
		_check(states[-1] == "IDLE", "standing jump returns idle")
		_check(part[8].vy < -600.0, "jump impulse on press tick")
	if scenario == 3:
		_check("JUMP" in states and part.any(func(r): return r.vy > 0.0 and not r.floor), "ledge fall uses airborne visual")
	if scenario in [4, 5, 8]:
		_check("DODGE_ROLL" in states, "processed roll plays")
		# Check the actual transition; a longer replay can later reach a wall,
		# especially when headless catch-up advances several ticks per sample.
		var exit_state := ""
		for k in range(1, part.size()):
			if part[k-1].state == "DODGE_ROLL" and part[k].state != "DODGE_ROLL":
				exit_state = part[k].state
				break
		_check(exit_state == ("RUN" if scenario == 4 else "IDLE"), "roll exits using current input")
		_check(part.filter(func(r): return r.state == "DODGE_ROLL").any(func(r): return r.frame == 17), "roll reaches last V2 drawing")
	if scenario == 5:
		var roll_rows := part.filter(func(r): return r.state == "DODGE_ROLL")
		var travel: float = absf(roll_rows[-1].x - roll_rows[0].x) + player.roll_speed/60.0
		_check(travel >= 95.0 and travel <= 105.0, "single final-roll trajectory stays within 95–105 px")
		for k in range(1, part.size()):
			if part[k-1].state == "DODGE_ROLL" and part[k].state != "DODGE_ROLL":
				_check(part[k].state == "IDLE", "no forced run flash at idle roll exit")
	if scenario == 6:
		_check(part[30].vx * direction < 0.0 and part[30].facing == -direction, "fast reversal retained")
	if scenario == 7:
		_check(buffered, "pre-landing jump buffered")
		var launches := 0
		for k in range(1, part.size()):
			if part[k].vy < -100.0 and part[k-1].vy > -100.0: launches += 1
		_check(launches == 2, "buffer consumed once after landing")
	if scenario == 8:
		_check(part.any(func(r): return r.wall and r.state == "DODGE_ROLL"), "roll blocked by wall")
	if scenario == 9:
		_check(part[18].state == "JUMP" and part[18].roll_remaining == 0.0, "jump immediately interrupts roll")
	if scenario == 10:
		_check(part[8].state == "JUMP" and not "DODGE_ROLL" in states, "simultaneous jump wins without queued roll")
	if scenario == 11:
		_check(part[32].state == "JUMP", "jump immediately interrupts skid")
	if scenario == 12:
		_check(buffered and part[buffer_tick].vy < -600.0, "new jump starts immediately after observed touchdown")
