extends "res://tests/test_foundation_repair.gd"
## Identical real-scene input sequence on the saved foundation and final tuning.
## --before labels the pre-edit recording; default is after. No tuning overrides.
var stage: String
var phase: String
var caption: Label
var rows: Array[Dictionary] = []
var metrics: Dictionary = {}

func _run() -> void:
	root.unfocusable = true
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	stage = "before" if "--before" in OS.get_cmdline_user_args() else "after"
	DirAccess.make_dir_recursive_absolute(output_dir())
	await prepare()
	var layer := CanvasLayer.new()
	layer.layer = 30
	lab.add_child(layer)
	caption = Label.new()
	caption.position = Vector2(20, 148)
	caption.add_theme_font_size_override("font_size", 22)
	layer.add_child(caption)
	set_phase("GROUND ROLL / no held movement")
	await observe(8)
	var start_x := player.global_position.x
	var start_tick := Engine.get_physics_frames()
	Input.action_press("dash")
	await observe(1)
	Input.action_release("dash")
	metrics.same_update_active = player.roll_remaining > 0.0 and player.global_position.x > start_x
	metrics.first_update_vx = player.velocity.x
	var active_ticks := 1
	var frames: Array[int] = [player.movement_visual.body.frame]
	while player.roll_remaining > 0.0:
		await observe(1)
		if player.roll_remaining > 0.0:
			active_ticks += 1
			frames.append(player.movement_visual.body.frame)
	metrics.configured_duration = player.roll_duration
	metrics.configured_speed = player.roll_speed
	metrics.ground_distance_px = player.global_position.x - start_x
	metrics.active_physics_ticks = active_ticks
	metrics.movement_seconds = float(active_ticks) / 60.0
	metrics.seconds_including_exit_update = float(Engine.get_physics_frames() - start_tick) / 60.0
	metrics.roll_frames = frames
	metrics.natural_exit_state = player.movement_visual.state
	metrics.natural_exit_vx = player.velocity.x
	await observe(10)
	await reset_case()
	set_phase("RUN > ROLL > RUN / held direction")
	Input.action_press("move_right")
	await observe(10)
	Input.action_press("dash")
	await observe(1)
	Input.action_release("dash")
	while player.roll_remaining > 0.0:
		await observe(1)
	metrics.held_run_exit_vx = player.velocity.x
	metrics.held_run_exit_state = player.movement_visual.state
	await observe(8)
	await reset_case()
	set_phase("ROLL > REVERSE / fresh left input")
	Input.action_press("dash")
	await observe(3)
	Input.action_release("dash")
	Input.action_press("move_left")
	await observe(1)
	metrics.reverse = sample()
	await observe(10)
	await reset_case()
	set_phase("ROLL > RELEASE / immediate idle pose")
	Input.action_press("move_right")
	await observe(8)
	Input.action_press("dash")
	await observe(3)
	Input.action_release("dash")
	Input.action_release("move_right")
	await observe(1)
	metrics.release = sample()
	await snapshot("release_cancel")
	await observe(10)
	await reset_case()
	set_phase("ROLL > JUMP / valid grounded jump")
	Input.action_press("dash")
	await observe(3)
	Input.action_release("dash")
	Input.action_press("jump")
	await observe(1)
	metrics.jump_cancel = sample()
	# A jump-cancelled roll now has a real cooldown. Keep ordinary jump physics
	# running until readiness before testing the separate valid air-roll case.
	while not player.can_movement_roll():
		await observe(1)
	set_phase("JUMP > AIR ROLL > AIR CONTROL")
	var vy := player.velocity.y
	var budget := player._air_dashes
	Input.action_press("dash")
	await observe(1)
	Input.action_release("dash")
	metrics.air_roll = sample()
	metrics.air_vy_before = vy
	metrics.air_budget_before = budget
	metrics.air_budget_after = player._air_dashes
	Input.action_press("move_left")
	await observe(1)
	metrics.air_cancel = sample()
	Input.action_release("jump")
	await observe(18)
	await reset_case()
	set_phase("RAPID ROLLS / bounded speed")
	var starts := [0]
	player.dashed.connect(func() -> void: starts[0] += 1)
	var peak := 0.0
	for i in 5:
		Input.action_press("dash")
		await observe(1)
		Input.action_release("dash")
		peak = maxf(peak, absf(player.velocity.x))
		await observe(2)
	metrics.repeat_starts = starts[0]
	metrics.repeat_peak_vx = peak
	await observe(18)
	if stage == "after":
		check(metrics.same_update_active, "same-update activation")
		check(is_equal_approx(player.roll_duration, 0.29) and metrics.ground_distance_px >= 95.0 and metrics.ground_distance_px <= 105.0, "final roll duration and travel budget", metrics)
		check(metrics.natural_exit_state == "IDLE" and metrics.natural_exit_vx == 0.0, "no recovery or idle-origin drift")
		check(metrics.held_run_exit_state == "RUN" and is_equal_approx(metrics.held_run_exit_vx, player.run_speed), "held RUN resumes at intended speed on exit")
		check(metrics.reverse.roll == 0.0 and metrics.reverse.vx == -player.run_speed and metrics.reverse.state == "RUN", "reverse input immediately controls motion and pose")
		check(metrics.release.roll == 0.0 and metrics.release.vx == 0.0 and metrics.release.state == "IDLE", "release cancellation has no decorative skid")
		check(metrics.jump_cancel.roll == 0.0 and metrics.jump_cancel.vy < -600.0 and metrics.jump_cancel.state == "JUMP", "valid jump immediately cancels roll")
		check(metrics.air_roll.roll > 0.0 and metrics.air_roll.state == "DODGE_ROLL" and metrics.air_roll.vy >= metrics.air_vy_before and metrics.air_budget_before == metrics.air_budget_after, "air roll preserves gravity and jump budget")
		check(metrics.air_cancel.roll == 0.0 and metrics.air_cancel.vx == -player.run_speed and metrics.air_cancel.state == "JUMP", "air control and pose resume immediately")
		check(starts[0] == 1 and peak <= player.roll_speed + 0.01, "five rapid presses cannot extend roll or stack velocity")
		check(frames[-1] == 17, "roll reaches final V2 drawing before immediate exit")
	FileAccess.open(output_dir() + "results.json", FileAccess.WRITE).store_string(JSON.stringify({"stage": stage, "metrics": metrics, "checks": checks, "failures": failures, "assertions": receipts, "samples": rows}, "\t"))
	print("FINAL_ROLL_REPLAY: " + JSON.stringify({"stage": stage, "metrics": metrics, "checks": checks, "failures": failures}))
	lab.queue_free()
	await process_frame
	quit(1 if failures else 0)

func output_dir() -> String:
	return "res://artifacts/final_roll_feel/" + stage + "/"

func set_phase(value: String) -> void:
	phase = value
	caption.text = stage.to_upper() + " / " + value

func sample() -> Dictionary:
	return {"tick": Engine.get_physics_frames(), "phase": phase, "x": player.global_position.x,
		"y": player.global_position.y, "vx": player.velocity.x, "vy": player.velocity.y,
		"roll": player.roll_remaining, "state": player.movement_visual.state, "frame": player.movement_visual.body.frame}

func observe(frames: int) -> void:
	for i in frames:
		await step(1)
		rows.append(sample())

func reset_case() -> void:
	for action in ["move_left", "move_right", "jump", "dash"]:
		Input.action_release(action)
	player.reset_movement(Vector2(2700, 599))
	await observe(3)

func snapshot(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output_dir() + label + ".png")
