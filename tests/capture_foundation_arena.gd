extends "res://tests/capture_motion_swap_chaos.gd"
## Rendered replay of the one authored arena. No injected velocities or enemies;
## movement uses actions and swaps use E and actual LMB target events.
const ARENA_OUT := "res://artifacts/foundation_repair/arena/"

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ARENA_OUT)
	lab = load("res://labs/motion_swap_lab.tscn").instantiate() as NLBMotionSwapLab
	root.add_child(lab)
	current_scene = lab
	player = lab.player
	controller = lab.controller
	await step(3)
	key(KEY_F7)
	await step(10)
	await arena_snap("01_charge_warning")
	await step(65)
	await arena_snap("02_aim_and_cover")
	var p: LabProjectile = null
	var guard := 0
	while p == null and guard < 90:
		for n in get_nodes_in_group("lab_projectiles"):
			if n is LabProjectile and n.source is LabGunnerEnemy and n.global_position.x > 6500 and not n.is_retiring():
				p = n
				break
		if p == null:
			await step(1)
		guard += 1
	verify(p != null, "authored Gunner produces a fast exchangeable shot")
	if p != null:
		await step(9) # let the shot separate from its emitter before selecting it
		key(KEY_E)
		await step(2)
		print("ARENA_SHOT_PICK point=%s screen=%s nearest=%s" % [str(p.swap_target.anchor_world()), str(lab.get_global_transform_with_canvas() * p.swap_target.anchor_world()), str(controller.target_near(p.swap_target.anchor_world()))])
		click_target(p.swap_target)
		print("ARENA_SHOT_FEEDBACK " + controller.last_feedback)
		verify(controller.target_a == p.swap_target, "real LMB selects the separated live shot")
		await step(2)
		await arena_snap("03_select_live_shot")
		var gunner := enemy("ZoneF", "GUNNER")
		click_target(gunner.swap_target)
		print("ARENA_SWAP_FEEDBACK " + controller.last_feedback)
		verify(not controller.is_selecting() and gunner.swap_override_t > 0.0, "live projectile / Gunner exchange executes through real target clicks")
		await step(16)
		await arena_snap("04_physical_launch")
	Input.action_press("move_right")
	await step(5)
	Input.action_press("jump")
	await step(8)
	Input.action_press("dash")
	await step(1)
	Input.action_release("dash")
	await arena_snap("05_air_roll")
	Input.action_release("jump")
	await step(24)
	Input.action_release("move_right")
	key(KEY_1)
	await step(8)
	verify(player.health.hp == 5 and Engine.time_scale == 1.0, "quick reset restores the arena after the exchange")
	await arena_snap("06_reset")
	await step(20)
	FileAccess.open(ARENA_OUT + "replay.json", FileAccess.WRITE).store_string(JSON.stringify({"failures": failed, "samples": trace_rows}, "\t"))
	lab.queue_free()
	await process_frame
	print("FOUNDATION_ARENA_CAPTURE: %d failures" % failed)
	quit(1 if failed else 0)

func arena_snap(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ARENA_OUT + label + ".png")
	print("ARENA_CAPTURE " + label)
