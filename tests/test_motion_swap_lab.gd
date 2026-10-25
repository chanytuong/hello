extends "res://tests/test_motion_swap_chaos.gd"
## Lab integration gate, updated for E mode and the six chaos zones.
## Shared fixtures use real scenes; ability/contact acceptance is in the base suite.

func _run() -> void:
	await fresh(Vector2(650, 599))
	check(lab._zones.size() == 6, "six original zones retained")
	check(get_nodes_in_group("lab_enemies").size() == 9, "nine reused Patrol/Gunner/Charger instances")
	check(get_nodes_in_group("crates").size() == 11, "eleven physical crates")
	check(get_nodes_in_group("lab_machines").size() == 5, "five compatible machines in zones A-E retained")
	check(get_nodes_in_group("lab_plates").size() == 1 and get_nodes_in_group("lab_gates").size() == 1, "plate/gate puzzle retained")
	check(player.swap_target != null and player.swap_target.is_valid(), "Iven registered as a target")
	var cam := player.get_node("LabCamera") as Camera2D
	check(cam.zoom == Vector2.ONE and cam.limit_right == 7840 and cam.limit_bottom == 720, "camera framing and world limits preserved")
	# Use the empty western floor for locomotion, away from contact damage.
	for n in get_nodes_in_group("lab_enemies"):
		n.set_physics_process(false)
		(n as LabEnemy)._touch_box.end()
	lab.place_player(Vector2(1250, 599))
	await step(5)
	var x := player.global_position.x
	Input.action_press("move_right")
	await step(18)
	check(player.global_position.x > x + 60 and player.movement_visual.state == "RUN", "RUN still responds and uses approved clip")
	Input.action_release("move_right")
	await step(1)
	check(player.movement_visual.state == "SKID_STOP", "release at speed still selects SKID STOP")
	await step(28)
	check(player.movement_visual.state == "IDLE", "skid returns to idle")
	var y := player.global_position.y
	Input.action_press("jump")
	await step(12)
	Input.action_release("jump")
	check(player.global_position.y < y - 60 and player.movement_visual.state == "JUMP", "JUMP and approved airborne clip remain functional")
	await step(40)
	check(player.is_on_floor(), "jump lands with real gravity")
	lab.place_player(Vector2(2500, 599))
	await step(3)
	x = player.global_position.x
	Input.action_press("dash")
	await step(2)
	Input.action_release("dash")
	check(player.roll_remaining > 0.0 and player.movement_visual.state == "DODGE_ROLL", "DODGE ROLL still enters approved clip")
	await step(44)
	check(player.roll_remaining == 0.0 and absf(player.global_position.x - x) >= 195.0 and absf(player.global_position.x - x) <= 205.0, "final dodge completes without motion lock")
	# Machinery command exchange and the actual crate -> plate -> gate chain.
	await fresh(Vector2(5900, 599))
	var belt := lab.get_node("World/ZoneE/BeltE") as LabConveyor
	var lift := lab.get_node("World/ZoneE/CrossingLift") as LabMovingPlatform
	var crate := lab.get_node("World/ZoneE/Crate") as LabCrate
	var plate := lab.get_node("World/ZoneE/PressurePlate") as LabPressurePlate
	var gate := lab.get_node("World/ZoneE/ZoneEGate") as LabGate
	key(KEY_E)
	controller.select_target(belt.swap_target)
	controller.select_target(lift.swap_target)
	check(belt.surface_speed == 0.0 and lift.travel_speed == 120.0, "belt / lift command exchange is exact (Overdrive not applied to settings)")
	await step(155)
	check(belt.surface_speed == 0.0 and lift.travel_speed == 120.0, "machine commands persist beyond character recovery")
	check(crate.global_position.x > 5790.0, "crate physically rides the lift", {"crate_x": crate.global_position.x})
	lab.place_player(Vector2(5900, 599))
	await real_wait(0.52)
	key(KEY_E)
	controller.select_target(lift.swap_target)
	controller.select_target(belt.swap_target)
	check(belt.surface_speed == 120.0 and lift.travel_speed == 0.0, "reverse-order machine swap restores belt and parks lift")
	lab.place_player(Vector2(5400, 599))
	await step(290)
	check(crate.global_position.x >= 6060.0, "belt physically delivers crate to pressure plate", {"crate_x": crate.global_position.x})
	check(plate.is_latched() and gate.is_open(), "crate latches plate and opens gate")
	lab.reset_zone()
	await step(8)
	check(not plate.is_latched() and not gate.is_open(), "zone reset restores puzzle without stale overlap latch")
	check(absf(crate.global_position.x - 5700.0) < 5 and lift.travel_speed == 0.0 and belt.surface_speed == 120.0, "zone reset restores crate / lift / belt")
	lab.place_player(Vector2(6140, 599))
	await step(15)
	check(plate.is_latched() and gate.is_open(), "player weight remains a no-softlock fallback")
	lab.place_player(Vector2(5400, 599))
	await step(10)
	check(gate.is_open(), "latched gate remains open after leaving plate")
	# Moving platform carries Iven through the existing CharacterBody platform solver.
	await fresh(Vector2(4920, 559))
	lift = lab.get_node("World/ZoneD/Lift") as LabMovingPlatform
	lift.reset_state()
	lab.place_player(Vector2(4920, 555))
	await step(6)
	y = player.global_position.y
	await step(30)
	check(player.global_position.y < y - 20 and player.is_on_floor(), "moving platform carries Iven without overriding motion-swap velocity", {"rise": y - player.global_position.y})
	# Hazards still use the normal hurtbox route during a self launch.
	# Zone F no longer has unavoidable floor spikes: isolate the same hazard
	# route here so its immunity regression does not depend on arena layout.
	await fresh(Vector2(2700, 599))
	lab._hazard(lab.get_node("World/ZoneC"), Rect2(2740, 588, 120, 12))
	var p := shot(Vector2(2650, 440), Vector2(900, 0))
	var hp := player.health.hp
	key(KEY_E)
	key(KEY_Q)
	controller.select_target(p.swap_target)
	await step(6)
	check(player.health.hp < hp, "self launch does not grant hazard invulnerability", {"hp": player.health.hp})
	for i in 6:
		lab.visit_zone(i)
		await step(2)
		check(lab.current_zone() == lab._zones[i] and Engine.time_scale == 1.0 and player.motion_stun_t == 0.0, "quick reset/access zone " + String.chr(65+i))
	lab.queue_free()
	await step(3)
	var out := FileAccess.open("res://artifacts/motion_swap_chaos/lab_results.json", FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks": checks, "failures": failures, "results": receipts}, "\t"))
	out.close()
	print("CHAOS_LAB: %d checks / %d failures" % [checks, failures])
	quit(1 if failures else 0)
