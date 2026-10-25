extends "res://tests/test_motion_swap_chaos.gd"
## Optional non-headless capture for the three crowbar contact poses. Run with:
##   godot --fixed-fps 60 --path E:\neverlookback -s res://tests/capture_crowbar_juice.gd
## Output: artifacts/crowbar_combo_feel/capture/M1_CONTACT.png ... M3_CONTACT.png

const OUT := "res://artifacts/crowbar_combo_feel/capture/"
var combo: NLBM1Combo
var feedbacks: Array[Dictionary] = []

func _run() -> void:
	var can_capture := DisplayServer.get_name() != "headless"
	await fresh(Vector2(1250, 599))
	combo = player.get_node_or_null("M1Combo") as NLBM1Combo
	if combo == null:
		push_error("capture: M1Combo missing")
		quit(1)
		return
	for n in get_nodes_in_group("lab_enemies"):
		(n as LabEnemy).retire()
	# Zone B's crate sits exactly where the clean contact portrait needs to be.
	for c in get_nodes_in_group("crates"):
		c.queue_free()
	await step(4)
	var enemy := load("res://labs/enemies/patrol.tscn").instantiate() as LabPatrolEnemy
	enemy.position = player.global_position + Vector2(-35, 0)
	enemy.set_spawn(enemy.position)
	enemy.speed = 0.0
	enemy.hp = 99
	lab.get_node("World/ZoneB").add_child(enemy)
	await step(3)
	enemy.health.max_hp = 99
	enemy.health.hp = 99
	await step(2)
	combo.contact_feedback.connect(func(event: Dictionary, _victim: Node) -> void: feedbacks.append(event))
	for strike in 3:
		feedbacks.clear()
		enemy.global_position = player.global_position + Vector2(-35, 0)
		enemy.velocity = Vector2.ZERO
		enemy.health.hp = 99
		enemy.health._invuln = 0.0
		enemy._flash_frames = 0
		enemy._flash_t = 0.0
		enemy.body_vis.color = enemy.body_color
		enemy.body_vis.scale = Vector2.ONE
		combo._start(strike, -1)
		var guard := 0
		while feedbacks.is_empty() and guard < 30:
			await physics_frame
			guard += 1
		# Render the contact tick before the next physics tick can decrement
		# the two-frame flash. A full extra step misses it.
		await process_frame
		if can_capture:
			DirAccess.make_dir_recursive_absolute(OUT)
			root.get_texture().get_image().save_png(OUT + "M%d_CONTACT.png" % (strike + 1))
		combo.reset()
		await step(40)
	lab.queue_free()
	await step(3)
	print("CAPTURE_CROWBAR: %s" % ("saved" if can_capture else "headless"))
	quit(0)
