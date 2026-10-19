extends "res://tests/test_foundation_repair.gd"
## Real controller / source sprites, with an evidence-only 4x inspection camera.
## The shipped camera, physics and source art are never changed by this replay.
var stage: String
var case_name: String
var rows: Array[Dictionary] = []
var events: Array[Dictionary] = []
var caption: Label
var details: Label
var capture: bool
var saved_frames := 0

func _run() -> void:
	root.unfocusable = true
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	stage = "before" if "--before" in OS.get_cmdline_user_args() else "after"
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute(out_dir() + "frames")
	await prepare()
	lab.get_node("HUD").hide()
	var cam := player.get_node("LabCamera") as Camera2D
	cam.zoom = Vector2(4, 4)
	cam.offset = Vector2(0, -30)
	cam.position_smoothing_enabled = false
	var layer := CanvasLayer.new()
	layer.layer = 30
	lab.add_child(layer)
	caption = Label.new()
	caption.position = Vector2(24, 20)
	caption.add_theme_font_size_override("font_size", 25)
	layer.add_child(caption)
	details = Label.new()
	details.position = Vector2(24, 635)
	details.add_theme_font_size_override("font_size", 19)
	layer.add_child(details)
	await begin_case("RUN > ROLL > RUN")
	Input.action_press("move_right")
	await observe(12)
	await roll()
	mark("roll_entry")
	await observe(18)
	mark("natural_exit")
	await observe(10)
	await begin_case("RUN > ROLL > STOP")
	Input.action_press("move_right")
	await observe(12)
	await roll()
	await observe(6)
	Input.action_release("move_right")
	await observe(1)
	mark("cancel")
	await observe(10)
	await begin_case("ROLL > REVERSE")
	Input.action_press("move_right")
	await observe(10)
	await roll()
	await observe(8)
	Input.action_release("move_right")
	Input.action_press("move_left")
	await observe(1)
	mark("cancel")
	await observe(10)
	await begin_case("ROLL > JUMP from tuck")
	await roll()
	await observe(9)
	Input.action_press("jump")
	await observe(1)
	mark("cancel")
	await observe(5)
	Input.action_release("jump")
	await observe(14)
	await begin_case("JUMP > AIR ROLL > MOVE")
	Input.action_press("jump")
	await observe(8)
	await roll()
	mark("air_entry")
	await observe(8)
	Input.action_press("move_left")
	await observe(1)
	mark("cancel")
	Input.action_release("jump")
	await observe(14)
	await begin_case("REPEATED ROLL / no pose rewinds")
	await roll()
	await observe(5)
	await roll()
	mark("repeat")
	await observe(5)
	await roll()
	mark("repeat")
	await observe(23)
	for age in [2, 7, 11, 16]:
		await begin_case("CANCEL at tick %d" % age)
		await roll()
		await observe(age - 1)
		Input.action_press("move_right")
		await observe(1)
		mark("cancel")
		await observe(9)
	await begin_case("ROLL into solid wall", Vector2(3430, 599))
	await roll()
	await observe(28)
	await begin_case("LEFT RUN > ROLL > RUN")
	player.facing = -1
	Input.action_press("move_left")
	await observe(12)
	await roll()
	mark("roll_entry")
	await observe(18)
	mark("natural_exit")
	await observe(10)
	if stage == "after":
		verify_results()
	FileAccess.open(out_dir() + "results.json", FileAccess.WRITE).store_string(JSON.stringify({"stage": stage,
		"checks": checks, "failures": failures, "assertions": receipts, "events": events, "samples": rows,
		"capture_frames": saved_frames, "inspection_camera_zoom": 4}, "\t"))
	print("ROLL_VISUAL_TESTS: %s / %d checks / %d failures / %d samples" % [stage, checks, failures, rows.size()])
	lab.queue_free()
	await process_frame
	quit(1 if failures else 0)

func out_dir() -> String:
	return "res://artifacts/roll_visual_transition/" + stage + "/"

func begin_case(value: String, at: Vector2 = Vector2(2700, 599)) -> void:
	for action in ["move_left", "move_right", "jump", "dash"]:
		Input.action_release(action)
	player.reset_movement(at)
	player.facing = 1
	case_name = value
	caption.text = stage.to_upper() + " / " + value + "  (4x inspection view)"
	await observe(5)

func roll() -> void:
	Input.action_press("dash")
	await observe(1)
	Input.action_release("dash")

func observe(count: int) -> void:
	for i in count:
		await step(1)
		var vis := player.movement_visual
		var row := {"index": rows.size(), "case": case_name, "physics_frame": Engine.get_physics_frames(),
			"position": [player.global_position.x, player.global_position.y], "velocity": [player.velocity.x, player.velocity.y],
			"roll": player.roll_remaining, "floor": player.is_on_floor(), "facing": player.facing,
			"state": vis.state, "clip": str(vis.body.animation), "drawing": vis.body.frame,
			"neck_local": [vis.neck_local.x, vis.neck_local.y], "flame_angle": vis.flame.rotation,
			"visual_offset": [vis.position.x, vis.position.y], "hp": player.health.hp,
			"anchor_error": vis.flame.position.distance_to(vis.neck_local),
			"ground_clearance": player.global_position.y - vis.flame.global_position.y - vis.flame.ground_extent}
		rows.append(row)
		details.text = "Physics: %s  vx %.2f  |  visual: %s / %d\nNo physics tuning override / normal 60 Hz playback / root and collider unchanged" % [vis.state, player.velocity.x, str(vis.body.animation), vis.body.frame]
		if capture:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out_dir() + "frames/%04d.png" % saved_frames)
			saved_frames += 1

func mark(kind: String) -> void:
	events.append({"kind": kind, "index": rows.size() - 1, "case": case_name})

func verify_results() -> void:
	check(is_equal_approx(player.roll_duration, 0.29) and is_equal_approx(player.roll_speed, 333.3333333), "approved controller tuning unchanged")
	check(rows.all(func(r): return r.anchor_error <= 0.708), "flame root stays on the actual displayed drawing's neck")
	check(rows.all(func(r): return absf(r.visual_offset[0]) <= 0.501 and absf(r.visual_offset[1]) <= 0.501), "no root recentering or presentation displacement beyond pixel snapping")
	check(rows.all(func(r): return r.clip.ends_with("right" if r.facing > 0 else "left")), "new facing reaches every displayed pose immediately")
	check(rows.all(func(r): return not r.floor or r.ground_clearance >= 0.99), "grounded flame remains above support plane")
	for event in events:
		var row: Dictionary = rows[event.index]
		if event.kind in ["roll_entry", "air_entry"]:
			check(row.roll > 0.0 and absf(row.velocity[0]) > 333.0 and row.clip.begins_with("ROLL_IN_"), event.case + ": movement starts immediately with an existing entry pose")
		elif event.kind == "cancel":
			check(row.roll == 0.0 and row.state != "DODGE_ROLL", event.case + ": gameplay and logical visual state cancel immediately")
			var settled: Dictionary = rows[event.index + 3]
			check(str(settled.clip).begins_with(row.state + "_"), event.case + ": target drawing reached within three visual updates")
		elif event.kind == "repeat":
			var previous: Dictionary = rows[event.index - 1]
			check(row.roll < previous.roll and row.clip == "DODGE_ROLL_right" and row.drawing > previous.drawing,
				event.case + ": unavailable roll input does not extend or rewind the tumble")
		elif event.kind == "natural_exit":
			check(row.state == "RUN" and row.velocity[0] * row.facing == player.run_speed, event.case + ": no gameplay recovery")
			check(rows[event.index + 3].clip.begins_with("RUN_") and rows[event.index + 3].drawing >= 13,
				event.case + ": return uses the matching existing run stride")
