extends SceneTree
## Rendered, scripted input replay of the shipped lab. Uses real E/Q/LMB events.
## Test setup uses zone jumps / explicit lab resets; impacts still use physics.
const OUT := "res://artifacts/motion_swap_chaos/capture/"
var lab: NLBMotionSwapLab
var player: NLBPlayer
var controller: NLBMotionSwapController
var trace_rows: Array[Dictionary] = []
var sample: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run")

func step(frames: int) -> void:
	for i in frames:
		await physics_frame
		await process_frame
		trace_rows.append({"sample": sample, "real_usec": Time.get_ticks_usec(), "scale": Engine.time_scale,
			"phase": controller.phase_label(), "position": str(player.global_position), "velocity": str(player.velocity),
			"launch": player.swap_override_t, "stun": player.motion_stun_t, "hp": player.health.hp})
		sample += 1

func key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func click_target(target: NLBMotionSwapTarget) -> void:
	var screen := lab.get_global_transform_with_canvas() * target.anchor_world()
	var move := InputEventMouseMotion.new()
	move.position = screen
	move.global_position = screen
	Input.parse_input_event(move)
	Input.flush_buffered_events()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = screen
	click.global_position = screen
	click.pressed = true
	Input.parse_input_event(click)
	Input.flush_buffered_events()
	click = click.duplicate()
	click.pressed = false
	Input.parse_input_event(click)
	Input.flush_buffered_events()

func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")
	print("CAPTURE %s | %s | pos=%s v=%s launch=%.2f stun=%.2f scale=%.2f" % [name, controller.last_feedback, str(player.global_position), str(player.velocity), player.swap_override_t, player.motion_stun_t, Engine.time_scale])

func verify(ok: bool, title: String) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", title])
	if not ok:
		failed += 1

func enemy(zone: String, type: String) -> LabEnemy:
	for e in get_nodes_in_group("lab_enemies"):
		if e.get_parent().name == zone and e.type_label() == type:
			return e as LabEnemy
	return null

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(OUT)
	lab = load("res://labs/motion_swap_lab.tscn").instantiate() as NLBMotionSwapLab
	root.add_child(lab)
	current_scene = lab
	player = lab.player
	controller = lab.controller
	if "--profile" in OS.get_cmdline_user_args():
		await profile_runtime()
		return
	await step(12)
	await snap("01_entry")
	# Human Projectile: actual committed charger AI, selected through LMB then Q.
	key(KEY_F4)
	await step(5)
	var charger := enemy("ZoneC", "CHARGER") as LabChargerEnemy
	var patrol := enemy("ZoneC", "PATROL")
	var guard := 0
	while charger.velocity.x < 590.0 and guard < 90:
		await step(1)
		guard += 1
	key(KEY_E)
	await step(2)
	click_target(charger.swap_target)
	verify(controller.target_a == charger.swap_target, "real LMB picks Charger during E mode")
	await snap("02_slow_select_charger")
	key(KEY_Q)
	verify(player.velocity.x > 700.0 and Engine.time_scale == 1.0, "real Q completes self swap and returns full speed")
	await step(4)
	await snap("03_human_projectile")
	await step(12)
	verify(not is_instance_valid(patrol) or patrol.health.hp <= 0, "rendered human-projectile contact defeats patrol")
	await snap("04_patrol_impact")
	await step(28)
	# Wall: same playable cannon, explicitly fired now to arrange the replay.
	lab.place_player(Vector2(3430, 599))
	controller.reset_state()
	var cannon := lab.get_node("World/ZoneC/LabCannon") as LabCannon
	key(KEY_E)
	key(KEY_Q)
	var p := cannon.fire()
	click_target(p.swap_target)
	await step(4)
	verify(player.motion_stun_t > 0.0 and player.health.hp > 0, "rendered wall contact causes nonlethal stun")
	await snap("05_wall_stun")
	await step(24)
	# Physical chain in the existing B zone.
	key(KEY_F3)
	await step(5)
	charger = enemy("ZoneB", "CHARGER") as LabChargerEnemy
	guard = 0
	while charger.velocity.x < 590.0 and guard < 90:
		await step(1)
		guard += 1
	key(KEY_E)
	click_target(charger.swap_target)
	var crate := lab.get_node("World/ZoneB/Crate") as LabCrate
	click_target(crate.swap_target)
	verify(crate.linear_velocity.x > 700.0, "rendered LMB pair sends charge into crate")
	await step(6)
	await snap("06_charger_crate")
	await step(35)
	await snap("07_crate_chain")
	# Leftward projectile -> Iven, this time Iven is the first selection.
	key(KEY_F5)
	await step(8)
	key(KEY_E)
	key(KEY_Q)
	cannon = lab.get_node("World/ZoneD/LabCannon") as LabCannon
	p = cannon.fire()
	click_target(p.swap_target)
	verify(player.velocity.x < -1400.0, "real LMB gives Iven leftward bullet velocity")
	await step(4)
	await snap("08_projectile_iven_left")
	await step(28)
	# Machinery puzzle: same physical crossing, no special activation shortcut.
	key(KEY_F6)
	lab.place_player(Vector2(5900, 599))
	await step(6)
	var belt := lab.get_node("World/ZoneE/BeltE") as LabConveyor
	var lift := lab.get_node("World/ZoneE/CrossingLift") as LabMovingPlatform
	key(KEY_E)
	click_target(belt.swap_target)
	click_target(lift.swap_target)
	await step(95)
	await snap("09_machine_carries_crate")
	controller.reset_state()
	key(KEY_E)
	click_target(lift.swap_target)
	click_target(belt.swap_target)
	lab.place_player(Vector2(6240, 599)) # clear of the plate: only the crate can latch it
	await step(230)
	var plate := lab.get_node("World/ZoneE/PressurePlate") as LabPressurePlate
	var puzzle_crate := lab.get_node("World/ZoneE/Crate") as LabCrate
	verify(plate.is_latched() and puzzle_crate.global_position.x > 6060.0, "rendered crate / plate / gate chain completes")
	await snap("10_plate_gate")
	# Mixed encounter, then debug view showing received versus amplified velocity.
	key(KEY_F7)
	await step(35)
	key(KEY_E)
	await step(3)
	await snap("11_mixed_tactical")
	key(KEY_ESCAPE)
	key(KEY_F1)
	await step(8)
	await snap("12_debug")
	FileAccess.open(OUT + "input_replay.json", FileAccess.WRITE).store_string(JSON.stringify({"failures": failed, "frames_sampled": sample, "samples": trace_rows}, "\t"))
	lab.queue_free()
	await process_frame
	print("GRAPHICAL_REPLAY: %d failures / %d samples" % [failed, sample])
	quit(1 if failed else 0)

func profile_runtime() -> void:
	# Ordinary rendered play, with no movie encoding or screenshot work in the sample window.
	lab.visit_zone(5)
	await create_timer(1.5, true, false, true).timeout
	var input_at := Time.get_ticks_usec()
	key(KEY_E)
	await process_frame # timer callbacks can arrive after the current frame's HUD update
	await RenderingServer.frame_post_draw
	var feedback_ms := float(Time.get_ticks_usec() - input_at) / 1000.0
	var feedback_visible := controller.is_selecting() and lab.overlay._veil.visible
	key(KEY_ESCAPE)
	var intervals: Array[float] = []
	var fps_values: Array[float] = []
	var start := Time.get_ticks_usec()
	var last := start
	var max_shots := 0
	var resets := 0
	while Time.get_ticks_usec() - start < 6000000:
		await process_frame
		var now := Time.get_ticks_usec()
		intervals.append(float(now - last) / 1000.0)
		last = now
		fps_values.append(Performance.get_monitor(Performance.TIME_FPS))
		max_shots = maxi(max_shots, get_nodes_in_group("lab_projectiles").size())
		if now - start > (resets + 1) * 2000000:
			lab.visit_zone(5)
			resets += 1
	intervals.sort()
	fps_values.sort()
	var report := {"mode": "normal graphical runtime (not movie mode)", "viewport": "1280x720",
		"renderer": RenderingServer.get_video_adapter_name(), "driver": DisplayServer.get_name(),
		"real_seconds": float(last - start) / 1000000.0, "frames": intervals.size(),
		"fps_median_monitor": fps_values[fps_values.size() / 2], "fps_min_monitor": fps_values[0],
		"frame_ms_median": intervals[intervals.size() / 2], "frame_ms_p95": intervals[int(intervals.size() * 0.95)],
		"max_live_shots": max_shots, "enemies": get_nodes_in_group("lab_enemies").size(),
		"synthetic_E_to_frame_post_draw_ms": feedback_ms, "E_feedback_visible_in_frame": feedback_visible,
		"scope": "mixed encounter with quick zone resets; bounded sample, not worst-case profiling"}
	FileAccess.open(OUT + "performance.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("GRAPHICAL_PROFILE: " + JSON.stringify(report))
	lab.queue_free()
	await process_frame
	quit()
