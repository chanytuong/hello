extends "res://tests/test_motion_swap_chaos.gd"
## One shipped Zone F arena: authored population, readable opening, physical
## cover, live-input escape, and a complete quick reset after destructive play.

func _run() -> void:
	root.unfocusable = true
	await fresh()
	lab.hitstop_enabled = false
	key(KEY_F7)
	await step(3)
	var zone := lab.get_node("World/ZoneF")
	var gunners: Array[LabGunnerEnemy] = []
	var crates: Array[LabCrate] = []
	var charger: LabChargerEnemy
	var charger_count := 0
	for n in zone.get_children():
		if n is LabGunnerEnemy:
			gunners.append(n)
		elif n is LabChargerEnemy:
			charger = n
			charger_count += 1
		elif n is LabCrate:
			crates.append(n)
	check(lab.current_zone() == zone and player.global_position.distance_to(lab.ZONE_SPAWNS[5]) < 2.0, "F7 enters the one arena at its clear central spawn")
	check(gunners.size() == 2 and charger_count == 1,
		"arena has exactly two Gunners and one Charger")
	check(crates.size() == 2 and not crates[0].freeze and not crates[1].freeze, "arena has two movable physical objects")
	check(zone.has_node("ImpactCover") and zone.get_node("ImpactCover").get_child(0).shape.size.y == 84.0,
		"arena has solid jumpable cover for charge crashes and physical throws")
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := player.get_node("CollisionShape2D") as CollisionShape2D
	query.shape = shape.shape
	query.transform = shape.global_transform
	query.collision_mask = 4 | 256
	query.exclude = [player.get_rid()]
	check(player.get_world_2d().direct_space_state.intersect_shape(query).is_empty(), "spawn overlaps no enemy or crate")
	check(charger.state == LabChargerEnemy.State.WINDUP and charger.telegraph.visible and not charger._touch_box.monitoring,
		"opening Charger warning is visible with damage inactive")
	await step(42)
	check(player.health.hp == 5, "first 0.75 seconds at spawn allow reading and movement without damage")
	await step(33)
	check(charger.global_position.x > 7360 and charger.state == LabChargerEnemy.State.STUN,
		"cover physically stops and stuns the opening charge", {"x": charger.global_position.x, "state": charger.ai_state_name(), "hp": charger.health.hp})
	check(gunners[0].state == LabGunnerEnemy.State.AIM and gunners[1].state == LabGunnerEnemy.State.AIM
		and gunners[0].aim_line.visible and gunners[1].aim_line.visible, "both Gunners expose their existing aim telegraphs before the staggered shots")
	var clear_shot: LabProjectile = null
	for i in 45:
		for n in get_nodes_in_group("lab_projectiles"):
			if n is LabProjectile and n.source == gunners[0] and not n.is_retiring() and n.global_position.x > 6850:
				clear_shot = n
				break
		if clear_shot != null:
			break
		await step(1)
	check(clear_shot != null and controller.target_near(clear_shot.global_position) == clear_shot.swap_target,
		"natural Gunner shot clears its perch and becomes an exchangeable arena threat")
	var deaths := [0]
	player.health.died.connect(func() -> void: deaths[0] += 1)
	Input.action_press("jump")
	Input.action_press("move_left")
	await step(8)
	Input.action_press("dash")
	await step(1)
	Input.action_release("dash")
	Input.action_release("jump")
	await step(18)
	Input.action_release("move_left")
	key(KEY_E)
	check(controller.is_selecting() and is_equal_approx(Engine.time_scale, 0.12), "arena supports tactical slow motion during the live opening")
	key(KEY_ESCAPE)
	await step(75)
	check(deaths[0] == 0 and player.health.hp >= 3, "normal jump / air roll / movement escapes the opening without death", {"hp": player.health.hp, "deaths": deaths[0]})
	# Disturb actual bodies and remove a threat; the shipped 1 key must rebuild it.
	crates[0].global_position += Vector2(80, -20)
	crates[0].linear_velocity = Vector2(600, 0)
	gunners[0].retire()
	await step(2)
	key(KEY_E)
	key(KEY_1)
	await step(2)
	check(Engine.time_scale == 1.0 and not controller.is_selecting() and player.health.hp == 5,
		"one-key arena reset restores time, selection and player HP")
	check(player.global_position.distance_to(lab.ZONE_SPAWNS[5]) < 2.0
		and crates[0].global_position.distance_to(crates[0].spawn_position) < 2.0,
		"quick reset restores spawn and displaced physical props")
	var live_gunners := 0
	for n in zone.get_children():
		if n is LabGunnerEnemy and n._alive:
			live_gunners += 1
	check(live_gunners == 2 and charger.health.hp == charger.hp and charger.state == LabChargerEnemy.State.WINDUP,
		"quick reset respawns the removed Gunner and restores the Charger warning")
	lab.queue_free()
	await step(3)
	FileAccess.open("res://artifacts/foundation_repair/arena_results.json", FileAccess.WRITE).store_string(
		JSON.stringify({"checks": checks, "failures": failures, "results": receipts}, "\t"))
	print("FOUNDATION_ARENA: %d checks / %d failures" % [checks, failures])
	quit(1 if failures else 0)
