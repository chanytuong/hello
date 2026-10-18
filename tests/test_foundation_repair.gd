extends "res://tests/test_motion_swap_chaos.gd"
## Real-scene tests for the rejected movement/contact behavior. Run before arena expansion.
var damage_events: Array[Dictionary] = []

func _run() -> void:
	root.unfocusable = true
	await test_roll_foundation()
	await test_enemy_damage_rules()
	await test_scene_loading()
	lab.queue_free()
	await step(3)
	var result := {"checks": checks, "failures": failures, "results": receipts, "damage_events": damage_events}
	FileAccess.open("res://artifacts/foundation_repair/foundation_results.json", FileAccess.WRITE).store_string(JSON.stringify(result, "\t"))
	print("FOUNDATION_TESTS: %d checks / %d failures" % [checks, failures])
	quit(1 if failures else 0)

func prepare(at: Vector2 = Vector2(2700, 599), keep_type: String = "") -> LabEnemy:
	for action in ["move_left", "move_right", "jump", "dash"]:
		Input.action_release(action)
	await fresh(at)
	lab.hitstop_enabled = false
	var kept: LabEnemy = null
	for e in get_nodes_in_group("lab_enemies"):
		if kept == null and e.get_parent().name == "ZoneC" and e.type_label() == keep_type:
			kept = e
		else:
			e.retire()
	for n in get_nodes_in_group("crates"):
		n.queue_free()
	for n in get_nodes_in_group("lab_cannons"):
		n.set_physics_process(false)
	for n in get_nodes_in_group("lab_projectiles"):
		n.retire_now()
	await step(2)
	return kept

func roll_press() -> void:
	Input.action_press("dash")
	await step(1)
	Input.action_release("dash")

func test_roll_foundation() -> void:
	await prepare()
	var x := player.global_position.x
	var frames := Engine.get_physics_frames()
	await roll_press()
	check(player.roll_remaining > 0.0 and is_equal_approx(player.velocity.x, player.roll_speed) and player.global_position.x > x,
		"roll activates and moves on the accepting gameplay update")
	while player.roll_remaining > 0.0:
		await step(1)
	var travel := player.global_position.x - x
	var duration := float(Engine.get_physics_frames() - frames) / 60.0
	check(is_equal_approx(player.roll_duration, 0.29) and travel >= 95 and travel <= 105 and duration >= 0.29 and duration <= 0.33,
		"roll duration and displacement meet final-roll budget", {"px": travel, "seconds_including_exit": duration})
	check(player.movement_visual.state == "IDLE" and player.velocity.x == 0.0, "roll has no forced recovery or extra root-motion travel")
	await prepare()
	await roll_press()
	Input.action_press("move_right")
	await step(1)
	check(player.roll_remaining == 0.0 and player.velocity.x == player.run_speed, "fresh movement immediately cancels idle-origin roll")
	await prepare()
	Input.action_press("move_right")
	await step(12)
	await roll_press()
	check(player.roll_remaining > 0.0, "RUN to ROLL accepts while prior movement remains held")
	Input.action_release("move_right")
	Input.action_press("move_left")
	await step(1)
	check(player.roll_remaining == 0.0 and player.velocity.x < 0.0 and player.facing == -1, "ROLL to REVERSE changes direction on the next update")
	await prepare()
	Input.action_press("move_right")
	await step(8)
	await roll_press()
	Input.action_release("move_right")
	await step(1)
	check(player.roll_remaining == 0.0 and player.velocity.x == 0.0, "releasing prior movement cancels roll without a recovery slide")
	await prepare()
	await roll_press()
	Input.action_press("jump")
	await step(1)
	check(player.roll_remaining == 0.0 and player.velocity.y < -600.0, "ROLL to JUMP cancels immediately with normal jump impulse")
	await prepare(Vector2(2700, 300))
	var vy := player.velocity.y
	var jump_budget := player._air_dashes
	await roll_press()
	check(player.roll_remaining > 0.0 and player.movement_visual.state == "DODGE_ROLL", "air roll activates and displays existing roll clip")
	check(player.velocity.y >= vy and player._air_dashes == jump_budget and player._coyote <= 0.0, "air roll adds no vertical boost or extra jump budget")
	Input.action_press("move_left")
	await step(1)
	check(player.roll_remaining == 0.0 and player.velocity.x < 0.0 and not player.is_on_floor(), "JUMP to AIR ROLL to MOVE remains responsive")
	await prepare()
	var max_speed := 0.0
	var starts := [0]
	player.dashed.connect(func() -> void: starts[0] += 1)
	for i in 5:
		await roll_press()
		max_speed = maxf(max_speed, absf(player.velocity.x))
		await step(2)
	check(starts[0] == 5 and max_speed <= player.roll_speed + 0.01, "ROLL to ROLL is immediate and never stacks speed", {"starts": starts[0], "max_speed": max_speed})
	await prepare(Vector2(3430, 599))
	await roll_press()
	await step(20)
	check(player.global_position.x <= 3466.1 and player.motion_stun_t == 0.0 and player.health.hp == 5, "ground roll stops at wall without self-swap stun or damage")
	Input.action_press("move_right")
	await step(20)
	check(player.motion_stun_t == 0.0 and player.health.hp == 5, "normal RUN wall contact is not a supernatural crash")
	await prepare(Vector2(2770, 300))
	lab._solid(lab, "FullHeightThinWall", Rect2(2800, -200, 2, 1000))
	await step(2)
	await roll_press()
	await step(15)
	check(player.global_position.x <= 2786.1, "air roll cannot tunnel through a 2px solid wall")
	# Early recovery from a swap must execute the newly requested roll, not drop it.
	await prepare(Vector2(2700, 300))
	player.motion_swap_apply(Vector2(700, 0), 0.24)
	await step(8)
	await roll_press()
	check(player.swap_override_t == 0.0 and player.roll_remaining > 0.0 and absf(player.velocity.x) <= player.roll_speed + 0.1,
		"permitted dodge recovery from swapped motion executes on the same update")

func test_enemy_damage_rules() -> void:
	var patrol := await prepare(Vector2(3000, 599), "PATROL") as LabPatrolEnemy
	patrol.global_position = Vector2(3033, 599)
	patrol.speed = 0.0
	patrol.set_physics_process(false)
	var x := player.global_position.x
	NLBHealth.trace_damage = true
	player.health.damage_recorded.connect(func(e: Dictionary) -> void: damage_events.append(e))
	await step(90)
	check(player.health.hp == 5 and damage_events.is_empty(), "standing beside Patrol causes no proximity damage")
	check(absf(player.global_position.x - x) < 0.1 and player.velocity.x == 0.0, "passive detection/contact never pulls or shoves Iven")
	Input.action_press("move_right")
	await step(25)
	Input.action_release("move_right")
	await roll_press()
	await step(16)
	check(player.health.hp == 5 and patrol.health.hp == 4 and damage_events.is_empty(), "normal RUN / ROLL body contact hurts neither character")
	check(player.swap_override_t == 0.0 and player.motion_stun_t == 0.0, "ordinary body collision never creates forced motion")
	NLBHealth.trace_damage = false
	var charger := await prepare(Vector2(3000, 599), "CHARGER") as LabChargerEnemy
	charger.global_position = Vector2(3035, 599)
	charger.reset_motion()
	charger._reset_ai()
	damage_events.clear()
	player.health.damage_recorded.connect(func(e: Dictionary) -> void: damage_events.append(e))
	player.health.iframes = 0.0 # epoch/contact authority, not invulnerability, must prevent duplicates
	NLBHealth.trace_damage = true
	x = player.global_position.x
	await step(18)
	check(charger.state == LabChargerEnemy.State.WINDUP and not charger._touch_box.monitoring and player.health.hp == 5,
		"Charger windup/proximity does no damage and has no active hitbox")
	check(absf(player.global_position.x - x) < 0.1, "Charger detection does not pull Iven")
	await step(24)
	var accepted := damage_events.filter(func(e: Dictionary) -> bool: return e.accepted)
	check(player.health.hp == 4 and accepted.size() == 1 and accepted[0].kind == "enemy_attack", "genuine charge contact deals one intended attack hit")
	check(charger.health.hp == 5 and not damage_events.any(func(e: Dictionary) -> bool: return e.kind == "impact"),
		"charge contact does not also count as generic impact damage")
	check(accepted.size() == 1 and accepted[0].has("contact") and accepted[0].has("normal") and accepted[0].has("velocity") and accepted[0].hp_before == 5 and accepted[0].hp_after == 4,
		"damage trace records exact source, contact, velocity, amount and HP transition")
	await step(15)
	check(player.health.hp == 4, "one charge cannot damage every physics frame even with iframes disabled")
	NLBHealth.trace_damage = false
	charger = await prepare(Vector2(3000, 599), "CHARGER") as LabChargerEnemy
	charger.global_position = Vector2(2945, 599)
	charger.state = LabChargerEnemy.State.CHARGE
	charger._state_t = 1.0
	charger._locked_dir = 1.0
	charger._touch_box.begin()
	Input.action_press("move_right")
	await step(18)
	Input.action_release("move_right")
	check(player.health.hp == 4 and charger.health.hp == 5,
		"active charge can catch a running player below the generic impact threshold")
	await prepare(Vector2(2700, 599))
	damage_events.clear()
	player.health.iframes = 0.0
	player.health.damage_recorded.connect(func(e: Dictionary) -> void: damage_events.append(e))
	NLBHealth.trace_damage = true
	var p := shot(Vector2(2600, 578), Vector2(1400, 0), true)
	await step(13)
	accepted = damage_events.filter(func(e: Dictionary) -> bool: return e.accepted)
	check(player.health.hp == 4 and accepted.size() == 1 and accepted[0].kind == "projectile", "fast physical projectile applies damage exactly once")
	check(not is_instance_valid(p) or p.is_retiring(), "spent projectile is retired")
	NLBHealth.trace_damage = false
	await prepare(Vector2(2700, 599))
	var old_shot := load("res://scenes/projectile.tscn").instantiate() as NLBProjectile
	lab.get_node("Projectiles").add_child(old_shot)
	old_shot.launch(Vector2(2660, 578), Vector2(360, 0))
	player.health.iframes = 0.0
	await step(25)
	check(player.health.hp == 4 and not is_instance_valid(old_shot), "legacy projectile also deals one hit and retires")
	check(not NLBHealth.trace_damage, "verbose damage logging is disabled for normal gameplay")

func test_scene_loading() -> void:
	for path in ["res://scenes/movement_test.tscn", "res://scenes/main.tscn", "res://labs/motion_swap_lab.tscn"]:
		var scene := load(path) as PackedScene
		check(scene != null and scene.can_instantiate(), "existing scene continues to load: " + path)
