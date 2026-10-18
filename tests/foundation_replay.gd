extends "res://tests/test_motion_swap_chaos.gd"
## Same fixture and input sequence before/after the repair. Real controller,
## real collision/hurtbox routes; unrelated threats are removed for diagnosis.
var stage: String = "before"
var samples: Array[Dictionary] = []
var metrics: Dictionary = {}
var caption: Label

func _run() -> void:
	stage = "before" if "--before" in OS.get_cmdline_user_args() else "after"
	DirAccess.make_dir_recursive_absolute("res://artifacts/foundation_repair/" + stage)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	await fresh(Vector2(2700, 599))
	clear_threats(null)
	add_caption("GROUND ROLL · Shift, then no movement input")
	await observe(8)
	var start_x := player.global_position.x
	var first_frame := Engine.get_physics_frames()
	Input.action_press("dash")
	await observe(1)
	metrics.roll_starts_on_next_update = player.roll_remaining > 0.0
	metrics.first_update_velocity = str(player.velocity)
	Input.action_release("dash")
	var active_frames := 1
	while player.roll_remaining > 0.0 and active_frames < 80:
		await observe(1)
		active_frames += 1
	metrics.roll_distance_px = player.global_position.x - start_x
	metrics.roll_physics_seconds = float(Engine.get_physics_frames() - first_frame) / 60.0
	metrics.configured_duration = player.roll_duration
	await snapshot("01_ground_roll_complete")
	await observe(12)
	player.reset_movement(Vector2(2700, 599))
	await observe(3)
	caption.text = stage.to_upper() + " · ROLL → REVERSE"
	Input.action_press("dash")
	await observe(1)
	Input.action_release("dash")
	Input.action_press("move_left")
	await observe(1)
	metrics.reverse_velocity_next_update = player.velocity.x
	metrics.reverse_roll_remaining = player.roll_remaining
	await observe(18)
	Input.action_release("move_left")
	await snapshot("02_reverse")
	player.reset_movement(Vector2(2700, 599))
	await observe(3)
	caption.text = stage.to_upper() + " · JUMP → AIR ROLL"
	Input.action_press("jump")
	await observe(6)
	Input.action_release("jump")
	var old_y_velocity := player.velocity.y
	Input.action_press("dash")
	await observe(1)
	Input.action_release("dash")
	metrics.air_roll_active = player.roll_remaining > 0.0
	metrics.air_roll_vy_before = old_y_velocity
	metrics.air_roll_vy_after = player.velocity.y
	await snapshot("03_air_roll")
	await observe(30)
	# A 33px centre separation is outside the solid capsules (14+15px),
	# but inside the old touch Area. No attack or physical impact is arranged.
	await fresh(Vector2(3000, 599))
	var patrol := enemy_in("ZoneC", "PATROL") as LabPatrolEnemy
	clear_threats(patrol)
	patrol.speed = 0.0
	patrol.global_position = Vector2(3033, 599)
	patrol.set_physics_process(false)
	add_caption("STANDING BESIDE PATROL · no attack, no movement input")
	var hp_before := player.health.hp
	start_x = player.global_position.x
	if patrol._touch_box != null:
		patrol._touch_box.landed.connect(func() -> void:
			print("BASELINE_DAMAGE source=Patrol/TouchHitBox amount=%d knockback=%s hp=%d velocity=%s" % [patrol._touch_box.damage, str(patrol._touch_box.knockback), player.health.hp, str(player.velocity)]))
	await observe(90)
	metrics.proximity_hp_before = hp_before
	metrics.proximity_hp_after = player.health.hp
	metrics.proximity_player_displacement = player.global_position.x - start_x
	await snapshot("04_patrol_proximity")
	var base := "res://artifacts/foundation_repair/" + stage + "/"
	FileAccess.open(base + "reproduction.json", FileAccess.WRITE).store_string(JSON.stringify({"metrics": metrics, "samples": samples}, "\t"))
	print("FOUNDATION_REPRO: " + JSON.stringify(metrics))
	lab.queue_free()
	await process_frame
	quit()

func add_caption(text: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	lab.add_child(layer)
	caption = Label.new()
	caption.position = Vector2(20, 148)
	caption.add_theme_font_size_override("font_size", 22)
	caption.text = stage.to_upper() + " · " + text
	layer.add_child(caption)

func clear_threats(keep: LabEnemy) -> void:
	for n in get_nodes_in_group("lab_enemies"):
		if n != keep:
			n.retire()
	for n in get_nodes_in_group("crates"):
		n.queue_free()
	for n in get_nodes_in_group("lab_cannons"):
		n.set_physics_process(false)
	for n in get_nodes_in_group("lab_projectiles"):
		n.retire_now()

func observe(frames: int) -> void:
	for i in frames:
		await step(1)
		samples.append({"frame": Engine.get_physics_frames(), "position": str(player.global_position),
			"velocity": str(player.velocity), "roll": player.roll_remaining,
			"state": player.movement_visual.state, "hp": player.health.hp})

func snapshot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/foundation_repair/" + stage + "/" + name + ".png")
