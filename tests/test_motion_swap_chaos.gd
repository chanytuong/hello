extends SceneTree
## Runtime acceptance tests. Input events exercise the shipped controller; contact
## scenarios use real bodies and Godot collision solves, not direct damage calls.

var lab: NLBMotionSwapLab
var player: NLBPlayer
var controller: NLBMotionSwapController
var checks: int = 0
var failures: int = 0
var receipts: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, title: String, values: Dictionary = {}) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("%s: %s %s" % ["PASS" if ok else "FAIL", title, str(values)])
	receipts.append({"pass": ok, "test": title, "values": values})

func step(frames: int) -> void:
	for i in frames:
		await physics_frame
		await process_frame

func real_wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout

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

func fresh(at: Vector2 = Vector2(120, 599)) -> void:
	if is_instance_valid(lab):
		lab.queue_free()
		await step(3)
	lab = load("res://labs/motion_swap_lab.tscn").instantiate() as NLBMotionSwapLab
	root.add_child(lab)
	current_scene = lab
	player = lab.player
	controller = lab.controller
	lab.place_player(at)
	await step(3)

func enemy_in(zone: String, type: String) -> LabEnemy:
	for n in get_nodes_in_group("lab_enemies"):
		var e := n as LabEnemy
		if e.get_parent().name == zone and e.type_label() == type:
			return e
	return null

func shot(at: Vector2, motion: Vector2, hostile: bool = false) -> LabProjectile:
	var p := load("res://labs/objects/lab_projectile.tscn").instantiate() as LabProjectile
	p.team = LabProjectile.Team.ENEMY if hostile else LabProjectile.Team.LAB
	lab.get_node("Projectiles").add_child(p)
	p.launch(at, motion)
	return p

func wall(at: Vector2) -> StaticBody2D:
	return lab._solid(lab, "TestThinWall", Rect2(at, Vector2(2, 150)))

func _run() -> void:
	await fresh()
	await test_tactical_clock()
	await test_human_projectile()
	await test_wall_and_bullets()
	await test_overdrive_and_zero()
	await test_physical_chains()
	await test_recovery_edges()
	await test_modifier_provenance_and_ccd()
	await test_self_crate_and_tangential_contact()
	check(not InputMap.has_action("blink") and get_nodes_in_group("blinkables").is_empty(), "Blink inactive")
	lab.queue_free()
	await step(3)
	check(is_equal_approx(Engine.time_scale, 1.0), "scene exit restores normal time")
	DirAccess.make_dir_recursive_absolute("res://artifacts/motion_swap_chaos")
	var file := FileAccess.open("res://artifacts/motion_swap_chaos/acceptance_results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "results": receipts}, "\t"))
	file.close()
	print("CHAOS_ACCEPTANCE: %d checks / %d failures" % [checks, failures])
	quit(1 if failures else 0)

func test_tactical_clock() -> void:
	key(KEY_E)
	check(controller.is_selecting() and is_equal_approx(Engine.time_scale, 0.12), "E enters 0.12 tactical time")
	var p := shot(Vector2(200, 300), Vector2(1200, 0))
	var start := Time.get_ticks_usec()
	var x := p.global_position.x
	await real_wait(0.20)
	var elapsed := float(Time.get_ticks_usec() - start) / 1000000.0
	var expected := 1200.0 * 0.12 * elapsed
	check(absf(p.global_position.x - x - expected) < 8.0, "world projectile motion visibly slows", {"distance": p.global_position.x - x, "expected": expected})
	check(controller.target_near(p.global_position + Vector2(0, 45)) == p.swap_target, "fast projectile has enlarged targeting region")
	key(KEY_ESCAPE)
	check(not controller.is_selecting() and Engine.time_scale == 1.0, "Escape immediately restores time")
	key(KEY_E)
	start = Time.get_ticks_usec()
	while controller.is_selecting() and Time.get_ticks_usec() - start < 2200000:
		await process_frame
	elapsed = float(Time.get_ticks_usec() - start) / 1000000.0
	check(elapsed >= 1.48 and elapsed < 1.85 and Engine.time_scale == 1.0, "selection lasts 1.5 real seconds", {"seconds": elapsed})
	key(KEY_E)
	key(KEY_E)
	check(Engine.time_scale == 1.0 and not controller.is_selecting(), "E again cancels")
	key(KEY_E)
	controller.select_target(p.swap_target)
	p.queue_free()
	await step(2)
	check(not controller.is_selecting() and Engine.time_scale == 1.0, "target deletion restores time without stale reference")

func test_human_projectile() -> void:
	await fresh(Vector2(3040, 599))
	var charger := enemy_in("ZoneC", "CHARGER") as LabChargerEnemy
	var patrol := enemy_in("ZoneC", "PATROL") as LabPatrolEnemy
	patrol.speed = 0.0
	patrol.global_position.x = 3140
	var guard := 0
	while charger.state != LabChargerEnemy.State.CHARGE and guard < 100:
		await step(1)
		guard += 1
	await step(1)
	key(KEY_E)
	var old_player := player.motion_swap_read()
	var old_charger := charger.motion_swap_read()
	check(old_charger.x > 590.0, "actual Charger AI supplies rightward 600 px/s", {"velocity": str(old_charger)})
	controller.select_at(charger.swap_target.anchor_world())
	key(KEY_Q)
	check(Engine.time_scale == 1.0 and controller.phase == controller.Phase.COOLDOWN, "completed pair restores time immediately")
	check(charger.velocity.is_equal_approx(old_player) and player.swap_target.received_velocity.is_equal_approx(old_charger), "Charger to Iven is a faithful two-way exchange")
	check(player.velocity.x > 740.0 and player.velocity.y == old_charger.y, "Overdrive explicitly raises rightward launch to 750", {"velocity": str(player.velocity)})
	var start_x := player.global_position.x
	Input.action_press("move_left")
	await step(5)
	check(player.global_position.x > start_x + 35.0 and player.velocity.x > 500.0, "held opposite movement cannot erase launch", {"distance": player.global_position.x - start_x, "velocity": str(player.velocity)})
	Input.action_release("move_left")
	await step(8)
	check(not is_instance_valid(patrol) or patrol.health.hp <= 0, "high-speed Iven physically hits and kills normal enemy")
	await step(25)
	check(player.swap_override_t == 0.0 and player.motion_stun_t == 0.0, "launch recovers in under half a second")
	await real_wait(0.52)
	controller._refresh_clock()
	check(controller.cooldown_left == 0.0, "cooldown expires after 0.5 real seconds")
	# Reverse order and direction in clear air: faithful vertical component too.
	await fresh(Vector2(3000, 300))
	var p := shot(Vector2(3100, 300), Vector2(-1200, -120))
	key(KEY_E)
	key(KEY_Q)
	controller.select_target(p.swap_target)
	check(player.swap_target.received_velocity == Vector2(-1200, -120) and player.velocity.x == -1500.0 and player.velocity.y == -150.0, "Iven first / projectile second preserves left and vertical direction")
	var old_x := player.global_position.x
	var old_y := player.global_position.y
	await step(4)
	check(player.global_position.x < old_x - 50.0 and player.global_position.y < old_y, "leftward projectile swap physically moves Iven up-left", {"delta": str(player.global_position - Vector2(old_x, old_y))})

func test_wall_and_bullets() -> void:
	await fresh(Vector2(1010, 599))
	var p := shot(Vector2(980, 430), Vector2(1200, 0))
	key(KEY_E)
	key(KEY_Q)
	controller.select_target(p.swap_target)
	await step(4)
	check(player.motion_stun_t > 0.0 and player.health.hp > 0, "Iven wall crash produces short nonlethal self-stun", {"stun": player.motion_stun_t, "hp": player.health.hp})
	var x := player.global_position.x
	Input.action_press("move_left")
	await step(5)
	check(absf(player.global_position.x - x) < 1.0, "wall stun briefly rejects movement input")
	Input.action_release("move_left")
	await step(23)
	check(player.motion_stun_t == 0.0, "wall stun releases control")
	await fresh()
	var thin := wall(Vector2(750, 250))
	await step(2)
	p = shot(Vector2(700, 300), Vector2(1400, 0))
	await step(4)
	check(p.is_retiring() and p.last_hit == thin and p.global_position.x < 750.0, "1400 px/s swept bullet hits a 2px wall", {"x": p.global_position.x})
	lab.place_player(Vector2(600, 599))
	await step(2)
	var hp := player.health.hp
	p = shot(Vector2(500, 578), Vector2(1400, 0), true)
	await step(7)
	check(player.health.hp == hp - 1 and p.is_retiring(), "fast enemy bullet reliably hits player once")

func test_overdrive_and_zero() -> void:
	await fresh(Vector2(500, 250))
	controller.overdrive_enabled = false
	var p := shot(Vector2(600, 250), Vector2(1000, -100))
	key(KEY_E)
	key(KEY_Q)
	controller.select_target(p.swap_target)
	check(player.velocity == Vector2(1000, -100), "Overdrive can be disabled for exact A/B exchange")
	await fresh(Vector2(500, 250))
	p = shot(Vector2(600, 250), Vector2.ZERO)
	player.velocity = Vector2.ZERO
	key(KEY_E)
	key(KEY_Q)
	controller.select_target(p.swap_target)
	check(player.velocity == Vector2.ZERO and p.velocity == Vector2.ZERO, "zero exchange never invents motion")
	await step(5)
	check(player.velocity.y > 0.0 and player.global_position.y > 250.0, "gravity continues after zero exchange")
	await fresh(Vector2(500, 250))
	p = shot(Vector2(600, 250), Vector2(1000, 0))
	key(KEY_E)
	key(KEY_Q)
	controller.select_target(p.swap_target)
	check(player.swap_target.received_velocity == Vector2(1000, 0) and player.swap_target.overdrive_velocity == Vector2(1250, 0), "debug stores original received and final Overdrive velocities")
	await step(9)
	check(player.swap_target.overdrive_left == 0.0 and player.velocity.x < 1000.0, "Overdrive expires after 0.12s without frame-by-frame stacking", {"velocity": str(player.velocity)})
	key(KEY_E)
	lab.reset_zone()
	check(Engine.time_scale == 1.0, "zone reset restores normal time")

func test_physical_chains() -> void:
	await fresh(Vector2(650, 599))
	var gunner := enemy_in("ZoneA", "GUNNER")
	gunner.global_position = Vector2(700, 300)
	gunner.motion_swap_apply(Vector2.ZERO, 0.65)
	var p := shot(Vector2(550, 300), Vector2(1200, 0))
	var gunner_hp := gunner.health.hp
	key(KEY_E)
	controller.select_target(p.swap_target)
	controller.select_target(gunner.swap_target)
	check(gunner.velocity == Vector2(1500, 0) and p.velocity == Vector2.ZERO, "bullet to enemy exchanges both current velocities")
	await step(5)
	check(gunner.health.hp == gunner_hp and gunner.global_position.x > 790.0, "fast enemy takes no unexplained damage in open space")
	# Body/body consequence after receiving a shot, in a clear isolated contact lane.
	await fresh(Vector2(650, 599))
	gunner = enemy_in("ZoneA", "GUNNER")
	var patrol := enemy_in("ZoneA", "PATROL")
	gunner.global_position = Vector2(700, 599)
	patrol.global_position = Vector2(810, 599)
	patrol.motion_swap_apply(Vector2.ZERO, 0.65)
	gunner.motion_swap_apply(Vector2.ZERO, 0.65)
	p = shot(Vector2(600, 450), Vector2(1200, 0))
	key(KEY_E)
	controller.select_target(gunner.swap_target)
	controller.select_target(p.swap_target)
	await step(12)
	check(not is_instance_valid(patrol) or patrol.health.hp <= 0, "launched enemy collides with and kills another enemy")
	await fresh(Vector2(1800, 599))
	var charger := enemy_in("ZoneB", "CHARGER") as LabChargerEnemy
	var crate := lab.get_node("World/ZoneB/Crate") as LabCrate
	var guard := 0
	while charger.state != LabChargerEnemy.State.CHARGE and guard < 90:
		await step(1)
		guard += 1
	await step(1)
	key(KEY_E)
	var source_motion := charger.velocity
	var crate_motion := crate.linear_velocity
	controller.select_target(charger.swap_target)
	controller.select_target(crate.swap_target)
	check(charger.velocity.is_equal_approx(crate_motion) and crate.swap_target.received_velocity == source_motion, "actual charging enemy to crate exchanges faithfully")
	var old_x := crate.global_position.x
	await step(6)
	check(crate.global_position.x > old_x + 35.0, "crate physically travels with received charge")
	await fresh(Vector2(650, 599))
	gunner = enemy_in("ZoneA", "GUNNER")
	gunner.global_position = Vector2(720, 599)
	gunner.motion_swap_apply(Vector2.ZERO, 0.65)
	crate = lab.get_node("World/ZoneA/Crate") as LabCrate
	crate.freeze = true
	crate.global_position = Vector2(600, 579)
	crate.freeze = false
	await step(2)
	# This source enters through the real two-target exchange, not an impact callback.
	p = shot(Vector2(550, 430), Vector2(1200, 0))
	key(KEY_E)
	controller.select_target(p.swap_target)
	controller.select_target(crate.swap_target)
	await step(14)
	check(not is_instance_valid(gunner) or gunner.health.hp <= 0, "swept rigid crate contact can kill a gunner")
	check(crate.global_position.is_finite() and crate.linear_velocity.is_finite(), "crate chain stays finite")
	await fresh(Vector2(3000, 599))
	charger = enemy_in("ZoneC", "CHARGER") as LabChargerEnemy
	charger.global_position = Vector2(3090, 599)
	charger.motion_swap_apply(Vector2.ZERO, 0.65)
	p = shot(Vector2(2950, 450), Vector2(900, 0))
	key(KEY_E)
	key(KEY_Q)
	controller.select_target(p.swap_target)
	await step(8)
	check(is_instance_valid(charger) and charger.health.hp > 0 and charger.health.hp < charger.health.max_hp,
		"heavy enemy receives strong damage without automatic death", {"hp": charger.health.hp if is_instance_valid(charger) else 0})
	check(is_instance_valid(charger) and (charger._stagger_t > 0.0 or charger.swap_override_t > 0.0), "heavy collision produces stun or physical displacement")
	await fresh(Vector2(740, 599))
	patrol = enemy_in("ZoneA", "PATROL")
	patrol.global_position.x = 810
	patrol.motion_swap_apply(Vector2.ZERO, 0.65)
	var hp := patrol.health.hp
	Input.action_press("move_right")
	await step(16)
	Input.action_release("move_right")
	check(is_instance_valid(patrol) and patrol.health.hp > 0 and not player.living_projectile, "ordinary running contact never produces instant kill", {"hp": patrol.health.hp if is_instance_valid(patrol) else 0, "before": hp})
	# Opposite enemy velocities: no homing, teleport or AI overwrite.
	await fresh(Vector2(650, 300))
	gunner = enemy_in("ZoneA", "GUNNER")
	patrol = enemy_in("ZoneA", "PATROL")
	gunner.global_position = Vector2(500, 300)
	patrol.global_position = Vector2(800, 300)
	gunner.motion_swap_apply(Vector2(600, -60), 0.65)
	patrol.motion_swap_apply(Vector2(-600, 30), 0.65)
	controller.overdrive_enabled = false
	key(KEY_E)
	controller.select_target(patrol.swap_target)
	controller.select_target(gunner.swap_target)
	check(gunner.velocity == Vector2(-600, 30) and patrol.velocity == Vector2(600, -60), "enemy to enemy exchanges opposite world velocities")
	await step(4)
	check(gunner.global_position.x < 475.0 and patrol.global_position.x > 825.0, "enemy AI does not erase received direction")
	await fresh(Vector2(960, 599))
	gunner = enemy_in("ZoneA", "GUNNER")
	gunner.global_position = Vector2(1010, 599)
	gunner.motion_swap_apply(Vector2.ZERO, 0.65)
	p = shot(Vector2(850, 450), Vector2(1200, 0))
	key(KEY_E)
	controller.select_target(p.swap_target)
	controller.select_target(gunner.swap_target)
	await step(12)
	check(not is_instance_valid(gunner) or gunner.health.hp <= 0, "enemy launched into a real wall suffers lethal collision")

func test_recovery_edges() -> void:
	await fresh(Vector2(500, 300))
	var p := shot(Vector2(550, 300), Vector2(1000, 0))
	key(KEY_E)
	controller.select_target(p.swap_target)
	controller.select_target(p.swap_target)
	check(not controller.is_selecting() and Engine.time_scale == 1.0, "same-target conflict safely cancels")
	key(KEY_E)
	controller.select_target(p.swap_target)
	player.health.damage(100)
	await step(2)
	check(Engine.time_scale == 1.0 and player.health.hp == player.health.max_hp and player.swap_override_t == 0.0, "death during selection respawns and restores time")
	await fresh(Vector2(5900, 599))
	var lift := lab.get_node("World/ZoneE/CrossingLift") as LabMovingPlatform
	var crate := lab.get_node("World/ZoneE/Crate") as LabCrate
	key(KEY_E)
	controller.select_target(crate.swap_target)
	var prior := lift.travel_speed
	check(not controller.select_target(lift.swap_target) and Engine.time_scale == 1.0 and lift.travel_speed == prior, "invalid channel refuses all writes and restores time")
	check(not NLBMotionChannels.compatible(99, 99), "unknown motion channels are refused")
	key(KEY_E)
	key(KEY_Q)
	lab.reset_targets()
	check(Engine.time_scale == 1.0 and not controller.is_selecting() and player.swap_override_t == 0.0, "reset targets clears motion and tactical clock")
	key(KEY_E)
	lab.visit_zone(2)
	check(Engine.time_scale == 1.0 and lab.current_zone().name == "ZoneC", "direct zone access restores clock and reaches Human Projectile")
	key(KEY_E)
	check(controller.is_selecting(), "can enter tactical selection again after reset")
	# Freeing the controller itself tests its cleanup even without the lab lifecycle.
	controller.cancel_selection()
	var temporary_controller := NLBMotionSwapController.new()
	lab.add_child(temporary_controller)
	temporary_controller.begin_selection()
	temporary_controller.queue_free()
	await step(2)
	check(Engine.time_scale == 1.0, "controller exit restores the clock")

func test_modifier_provenance_and_ccd() -> void:
	await fresh(Vector2(500, 300))
	var a := shot(Vector2(600, 300), Vector2(1000, 0))
	var b := shot(Vector2(700, 300), Vector2.ZERO)
	key(KEY_E)
	controller.select_target(a.swap_target)
	controller.select_target(b.swap_target)
	check(b.velocity == Vector2(1250, 0), "one-shot Overdrive scales a received projectile once")
	controller.reset_state() # explicit QA bypass of cooldown tests provenance in the same frame
	key(KEY_E)
	key(KEY_Q)
	controller.select_target(b.swap_target)
	check(player.velocity == Vector2(1250, 0) and player.swap_target.received_velocity == Vector2(1250, 0), "an already boosted source transfers faithfully without multiplying twice")
	await step(9)
	check(player.swap_target.overdrive_left == 0.0 and player.velocity.x < 1000.0, "inherited boost keeps original short expiry")
	await fresh(Vector2(500, 599))
	var thin := wall(Vector2(750, 250))
	var crate := lab.get_node("World/ZoneA/Crate") as LabCrate
	crate.freeze = true
	crate.global_position = Vector2(600, 300)
	crate.freeze = false
	await step(2)
	a = shot(Vector2(550, 430), Vector2(1400, 0))
	key(KEY_E)
	controller.select_target(a.swap_target)
	controller.select_target(crate.swap_target)
	await step(12)
	check(crate.global_position.x < thin.global_position.x + 20.0, "shape CCD prevents fast crate tunneling through 2px wall", {"crate_x": crate.global_position.x})
	await fresh(Vector2(500, 300))
	key(KEY_E)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	Input.parse_input_event(click)
	Input.flush_buffered_events()
	click = click.duplicate()
	click.pressed = false
	Input.parse_input_event(click)
	Input.flush_buffered_events()
	check(controller.target_a == player.swap_target, "right mouse quick-selects Iven")
	key(KEY_ESCAPE)
	key(KEY_E)
	await real_wait(1.0)
	key(KEY_Q)
	check(controller._timeout_left < 0.55, "selecting A does not extend the total real-time window")
	await real_wait(0.6)
	check(Engine.time_scale == 1.0 and not controller.is_selecting(), "armed selection also expires in real time")
	# Actual reload while selecting, through the shipped restart input.
	key(KEY_E)
	key(KEY_R)
	await step(4)
	lab = current_scene as NLBMotionSwapLab
	player = lab.player
	controller = lab.controller
	check(Engine.time_scale == 1.0 and not controller.is_selecting() and player.swap_override_t == 0.0, "R reload during selection restores world and time")

func test_self_crate_and_tangential_contact() -> void:
	await fresh(Vector2(500, 300))
	var crate := lab.get_node("World/ZoneA/Crate") as LabCrate
	crate.freeze = true
	crate.global_position = Vector2(600, 300)
	crate.freeze = false
	await step(2)
	crate.swap_target.apply_motion(Vector2(600, 80))
	var old_player := player.velocity
	key(KEY_E)
	key(KEY_Q)
	controller.select_target(crate.swap_target)
	check(player.swap_target.received_velocity == Vector2(600, 80) and crate.linear_velocity.is_equal_approx(old_player), "Iven / movable crate exchanges full actual world velocity")
	check(player.velocity == Vector2(750, 100), "self / crate Overdrive preserves vector direction")
	await fresh(Vector2(500, 599))
	crate = lab.get_node("World/ZoneA/Crate") as LabCrate
	crate.freeze = true
	crate.global_position = Vector2(620, 579)
	crate.freeze = false
	await step(2)
	var p := shot(Vector2(450, 440), Vector2(1000, 0))
	key(KEY_E)
	key(KEY_Q)
	controller.select_target(p.swap_target)
	await step(12)
	check(crate.global_position.x > 640.0 and player.global_position.x < crate.global_position.x, "high-speed Iven physically transfers momentum into a crate", {"crate_x": crate.global_position.x, "crate_v": str(crate.linear_velocity)})
	check(absf(player.velocity.x) < 350.0, "Iven loses launch momentum on crate impact")
	await fresh(Vector2(650, 599))
	var gunner := enemy_in("ZoneA", "GUNNER")
	gunner.global_position = Vector2(700, 599)
	gunner.motion_swap_apply(Vector2(1000, 0), 0.65)
	var hp := gunner.health.hp
	await step(3)
	check(gunner.is_on_floor() and gunner.health.hp == hp, "fast tangential floor contact causes no impact damage")
	await fresh(Vector2(500, 300))
	p = shot(Vector2(600, 300), Vector2(400, 0))
	key(KEY_E)
	key(KEY_Q)
	controller.select_target(p.swap_target)
	check(player.velocity.x == 500.0 and player.living_projectile, "Overdrive crossing the living-projectile threshold enables physical impact state")
