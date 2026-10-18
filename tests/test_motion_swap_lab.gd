extends SceneTree
## MOTION SWAP LAB — runtime suite. Loads the real playable lab scene and drives
## it across physics frames: selection, refusals, exchanges, machine persistence,
## the zone E plate/gate chain, the reset tools, recovery rules and the
## Blink-free guarantee. Pure contract tests live in tests/test_motion_swap.gd.
## Run: godot --headless --path E:\neverlookback --script res://tests/test_motion_swap_lab.gd

var _failures: int = 0
var _checks: int = 0
var lab: NLBMotionSwapLab
var controller: NLBMotionSwapController
var player: NLBPlayer
var _zone_e_belt: LabConveyor
var _zone_e_lift: LabMovingPlatform
var _zone_e_crate: LabCrate
var _zone_e_plate: LabPressurePlate
var _zone_e_gate: LabGate

func _init() -> void:
	call_deferred("_run")

func _check(cond: bool, name: String) -> void:
	_checks += 1
	if cond:
		print("PASS: " + name)
	else:
		printerr("FAIL: " + name)
		_failures += 1

func _step(frames: int) -> void:
	for _i in frames:
		await physics_frame

func _wait_cooldown() -> void:
	var guard := 0
	while controller != null and controller.cooldown_left > 0.0 and guard < 300:
		guard += 1
		await physics_frame
	await physics_frame

# ------------------------------------------------------------------- helpers

func _crate_near(x: float) -> LabCrate:
	var best: LabCrate = null
	var best_d := 1.0e20
	for n in get_nodes_in_group("crates"):
		var c := n as LabCrate
		if c == null or not is_instance_valid(c):
			continue
		if absf(c.global_position.x - x) < best_d:
			best_d = absf(c.global_position.x - x)
			best = c
	return best if best_d < 400.0 else null

func _enemy_near(x: float) -> LabEnemy:
	var best: LabEnemy = null
	var best_d := 1.0e20
	for n in get_nodes_in_group("lab_enemies"):
		var e := n as LabEnemy
		if e == null or not is_instance_valid(e):
			continue
		if absf(e.global_position.x - x) < best_d:
			best_d = absf(e.global_position.x - x)
			best = e
	return best if best_d < 500.0 else null

func _enemy_count() -> int:
	return get_nodes_in_group("lab_enemies").size()

func _enemy_in(zone_name: String, type_class: Variant) -> LabEnemy:
	for n in get_nodes_in_group("lab_enemies"):
		var e := n as LabEnemy
		if e == null or not is_instance_valid(e):
			continue
		var z := e.get_parent()
		if z == null or String(z.name) != zone_name:
			continue
		if type_class != null and not is_instance_of(e, type_class):
			continue
		return e
	return null

func _live_shot(team: int) -> LabProjectile:
	var best: LabProjectile = null
	var best_d := 460.0
	for n in get_nodes_in_group("lab_projectiles"):
		var p := n as LabProjectile
		if p == null or p.team != team or p.is_retiring() or not (p.source is LabGunnerEnemy):
			continue
		var d := p.global_position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = p
	return best

# ---------------------------------------------------------------------- run

func _run() -> void:
	root.unfocusable = true
	lab = load("res://labs/motion_swap_lab.tscn").instantiate() as NLBMotionSwapLab
	root.add_child(lab)
	current_scene = lab
	await physics_frame
	player = lab.player
	controller = lab.controller
	_zone_e_belt = lab.get_node_or_null("World/ZoneE/BeltE") as LabConveyor
	_zone_e_lift = lab.get_node_or_null("World/ZoneE/CrossingLift") as LabMovingPlatform
	_zone_e_crate = _crate_near(5700.0)
	_zone_e_plate = lab.get_node_or_null("World/ZoneE/PressurePlate") as LabPressurePlate
	_zone_e_gate = lab.get_node_or_null("World/ZoneE/ZoneEGate") as LabGate

	await _t_zones_built()
	await _t_player_control()
	await _t_hazards()
	await _t_channel_refusal()
	await _t_zone_e_chain()
	await _t_plate_player_route()
	await _t_reset_tools()
	await _t_patrol_crate()
	await _t_charger_crate()
	await _t_gunner_shot()
	await _t_pellet_lost_selection()
	await _t_belt_carry()
	await _t_lift_carry()
	await _t_fallen_enemy()
	await _t_finish_line()

	_teardown()

func _teardown() -> void:
	for _i in 3:
		await process_frame
	if _failures == 0:
		print("MOTION_SWAP_LAB_TESTS: ALL PASS (%d checks)" % _checks)
	else:
		printerr("MOTION_SWAP_LAB_TESTS: %d FAILURES of %d checks" % [_failures, _checks])
	quit(1 if _failures > 0 else 0)

# ------------------------------------------------------------------- checks

func _t_zones_built() -> void:
	var world := lab.get_node("World") as Node2D
	var zones := 0
	for child in world.get_children():
		if String(child.name).begins_with("Zone"):
			zones += 1
	_check(zones == 6, "six zones built (found %d)" % zones)
	_check(_enemy_count() == 7, "seven enemies spawned (%d)" % _enemy_count())
	_check(get_nodes_in_group("crates").size() == 12, "twelve crates placed (%d)" % get_nodes_in_group("crates").size())
	_check(get_nodes_in_group("lab_machines").size() == 6, "six machines placed (%d)" % get_nodes_in_group("lab_machines").size())
	_check(get_nodes_in_group("lab_plates").size() == 1, "one pressure plate")
	_check(get_nodes_in_group("lab_gates").size() == 1, "one gate")
	_check(get_nodes_in_group("swap_targets").size() >= 25,
		"every object carries a swap target (%d)" % get_nodes_in_group("swap_targets").size())
	_check(controller != null and player != null, "lab wires the controller and the player")
	var cam := player.get_node_or_null("LabCamera") as Camera2D
	_check(cam != null and cam.is_current(), "a camera follows the player (the lab is 7840 px wide)")
	_check(cam != null and cam.limit_right >= 7840, "the camera's limits cover the whole lab")

func _t_player_control() -> void:
	await _step(12)
	_check(player.is_on_floor(), "player spawns standing on the lab floor")
	_check((player.collision_mask & 256) != 0 and (player.collision_mask & 512) != 0,
		"player collides with props and machines inside the lab")
	var x0 := player.global_position.x
	Input.action_press("move_right")
	await _step(30)
	Input.action_release("move_right")
	_check(player.global_position.x - x0 > 90.0,
		"RUN still works here (%.0f px in 0.5 s)" % (player.global_position.x - x0))
	await _step(10)
	var y0 := player.global_position.y
	Input.action_press("jump")
	await _step(14)
	Input.action_release("jump")
	_check(player.global_position.y < y0 - 40.0,
		"JUMP still works here (rose %.0f px)" % (y0 - player.global_position.y))
	await _step(40)
	_check(player.is_on_floor(), "player lands again")
	# DODGE ROLL / dash must still be mapped and do something.
	var x1 := player.global_position.x
	Input.action_press("move_right")
	Input.action_press("dash")
	await _step(10)
	Input.action_release("dash")
	Input.action_release("move_right")
	_check(absf(player.global_position.x - x1) > 20.0, "DODGE ROLL still moves the player")
	await _step(20)

func _t_hazards() -> void:
	player.health.reset()
	lab.place_player(Vector2(3180.0, 599.0))
	await _step(20)
	_check(player.health.hp < player.health.max_hp, "spike strip damages the player (hp %d)" % player.health.hp)
	player.health.reset()
	lab.place_player(Vector2(3000.0, 599.0))
	await _step(10)

func _t_channel_refusal() -> void:
	# Zone E: a LINEAR crate next to a PLATFORM lift. This pairing must be
	# refused with a reason, and refusing must change nothing.
	_check(_zone_e_lift != null and _zone_e_crate != null, "zone E objects found")
	if _zone_e_lift == null or _zone_e_crate == null:
		return
	controller.cancel_selection()
	lab.place_player(Vector2(5690.0, 599.0))
	await _step(8)
	var crate_v := _zone_e_crate.linear_velocity
	_check(controller.select_at(_zone_e_crate.swap_target.anchor_world()), "first pick selects the crate as A")
	_check(controller.target_a == _zone_e_crate.swap_target, "A is the crate")
	_check(not controller.select_at(_zone_e_lift.swap_target.anchor_world()), "crate -> lift is refused")
	_check(controller.last_feedback.contains("INCOMPATIBLE"),
		"the refusal is readable: %s" % controller.last_feedback)
	_check(_zone_e_crate.linear_velocity == crate_v and _zone_e_lift.travel_speed == 0.0,
		"a refused swap changes neither side")
	_check(controller.target_a == _zone_e_crate.swap_target, "a refusal does not eat the selection")
	controller.cancel_selection()
	await _step(4)
	_check(controller.target_a == null, "cancel clears the selection")

func _t_zone_e_chain() -> void:
	# The designed crossing: swap the belt's SURFACE speed into the lift, then
	# swap it back. Nothing here may reset on its own.
	if _zone_e_belt == null or _zone_e_lift == null or _zone_e_crate == null:
		_check(false, "zone E chain skipped: objects missing")
		return
	await _wait_cooldown()
	# Stand on the belt's far end, not on the crate's tile: a body teleported
	# into a crate is an engine artifact generator, not a test setup.
	lab.place_player(Vector2(5900.0, 599.0))
	await _step(6)
	_check(_zone_e_belt.surface_speed == 120.0 and _zone_e_lift.travel_speed == 0.0,
		"authored machine state (belt +120, lift parked)")
	_check(controller.select_at(_zone_e_belt.swap_target.anchor_world()), "pick the belt (SURFACE)")
	_check(controller.select_at(_zone_e_lift.swap_target.anchor_world()),
		"belt <-> lift accepted across SURFACE/PLATFORM")
	_check(_zone_e_belt.surface_speed == 0.0 and _zone_e_lift.travel_speed == 120.0,
		"machines exchanged speeds (belt %.0f, lift %.0f)" % [_zone_e_belt.surface_speed, _zone_e_lift.travel_speed])
	await _step(150)
	_check(_zone_e_belt.surface_speed == 0.0 and _zone_e_lift.travel_speed == 120.0,
		"machine speeds PERSIST past the 2.5 s character override window")
	_check(_zone_e_crate.global_position.x > 5790.0 and _zone_e_crate.global_position.x < 6100.0,
		"the crate rode the lift across the gap (x=%.0f)" % _zone_e_crate.global_position.x)
	await _wait_cooldown()
	lab.place_player(Vector2(5900.0, 599.0))
	await _step(6)
	_check(controller.select_at(_zone_e_belt.swap_target.anchor_world()), "pick the belt again")
	_check(controller.select_at(_zone_e_lift.swap_target.anchor_world()), "swap the speeds back")
	_check(_zone_e_belt.surface_speed == 120.0 and _zone_e_lift.travel_speed == 0.0,
		"belt drives again, lift parks where it is")
	# Step off the belt: from here on the crate must be the thing that presses
	# the plate, not the player riding the belt onto it.
	lab.place_player(Vector2(5400.0, 599.0))
	await _step(260)
	_check(_zone_e_crate.global_position.x > 6060.0 and _zone_e_crate.global_position.x < 6600.0,
		"the belt drove the crate onto the plate (x=%.0f)" % _zone_e_crate.global_position.x)
	_check(_zone_e_plate != null and _zone_e_plate.is_latched(), "the crate latched the plate")
	_check(_zone_e_gate != null and _zone_e_gate.is_open(), "the latched plate opened the gate")

func _t_plate_player_route() -> void:
	# The fallback that makes the zone unstrandable: the player's own body
	# presses the plate just as well as a crate does.
	if _zone_e_plate == null:
		return
	lab.reset_zone()  # the player is still in zone E, so this is a clean slate
	await _step(8)
	_check(not _zone_e_plate.is_latched(), "reset zone left a clear plate to test against")
	lab.place_player(Vector2(6140.0, 599.0))
	await _step(20)
	_check(_zone_e_plate.is_latched(), "the player's own weight latches the plate")
	_check(_zone_e_gate != null and _zone_e_gate.is_open(), "the gate is open for the player")

func _t_reset_tools() -> void:
	if _zone_e_belt == null:
		return
	# 1 — reset zone: everything in the player's zone returns to authored state.
	lab.place_player(Vector2(5300.0, 599.0))
	await _step(4)
	lab.reset_zone()
	await _step(10)
	_check(not _zone_e_plate.is_latched(), "reset zone un-latches the plate")
	_check(not _zone_e_gate.is_open(), "reset zone closes the gate")
	_check(_zone_e_belt.surface_speed == 120.0 and _zone_e_lift.travel_speed == 0.0,
		"reset zone restores the authored machine speeds")
	_check(absf(_zone_e_crate.global_position.x - 5700.0) < 40.0,
		"reset zone returns the crate to its spawn (x=%.0f)" % _zone_e_crate.global_position.x)
	_check(absf(_zone_e_lift.global_position.x - 5620.0) < 6.0,
		"reset zone returns the lift to its origin (x=%.0f)" % _zone_e_lift.global_position.x)
	_check(controller.target_a == null, "reset zone clears any selection")

	# 2 — reset targets: exchanged motion cleared IN PLACE.
	await _wait_cooldown()
	_zone_e_crate.linear_velocity = Vector2(250.0, 0.0)
	_zone_e_belt.set_surface_speed(40.0)
	var pos_before := _zone_e_crate.global_position
	lab.reset_targets()
	await _step(6)
	_check(_zone_e_belt.surface_speed == 120.0, "reset targets restores the authored machine speed")
	_check(_zone_e_crate.linear_velocity.length() < 60.0,
		"reset targets clears the crate's exchanged motion")
	_check(_zone_e_crate.global_position.distance_to(pos_before) < 80.0,
		"reset targets does not teleport the crate")

	# 3 — respawn enemies: killed enemies come back at their spawn point.
	var charger := _enemy_in("ZoneC", LabChargerEnemy)
	_check(charger != null, "zone C charger found")
	if charger != null:
		charger.die()
		await _step(4)
		_check(_enemy_count() == 6, "one enemy down (%d)" % _enemy_count())
		lab.respawn_enemies()
		await _step(4)
		_check(_enemy_count() == 7, "respawn restores the roster (%d)" % _enemy_count())
		var back := _enemy_in("ZoneC", LabChargerEnemy)
		_check(back != null and absf(back.global_position.x - 2760.0) < 60.0,
			"the respawned enemy is at its spawn point")
		_check(back != null and back.ai_state_name() == "IDLE", "the respawned charger is idle again")

func _t_patrol_crate() -> void:
	# Zone A: the headline exchange. A walk becomes a crate's velocity.
	controller.cancel_selection()
	var patrol := _enemy_in("ZoneA", LabPatrolEnemy)
	var crate := _crate_near(820.0)
	if patrol == null or crate == null:
		_check(false, "zone A patrol/crate found")
		return
	lab.place_player(Vector2(700.0, 599.0))
	await _step(6)
	# Wait for the walk to be a walk, not a turn-around pause.
	var guard := 0
	while absf(patrol.velocity.x) < 60.0 and guard < 240:
		guard += 1
		player.health.reset()
		await physics_frame
	_check(absf(patrol.velocity.x) >= 60.0, "patrol is walking (vx=%.0f)" % patrol.velocity.x)
	await _wait_cooldown()
	_check(controller.select_at(patrol.swap_target.anchor_world()), "pick the PATROL as A")
	_check(controller.select_at(crate.swap_target.anchor_world()), "PATROL <-> CRATE accepted (both LINEAR)")
	await _step(4)
	_check(crate.linear_velocity.x > 40.0,
		"the crate is running the patrol's walk (vx=%.0f)" % crate.linear_velocity.x)
	_check(patrol.swap_override_t > 0.0, "the patrol is holding the crate's standstill")
	var patrol_x := patrol.global_position.x
	var spawn_x := patrol.spawn_position.x
	await _step(200)
	_check(patrol.swap_override_t == 0.0, "the patrol's override window expired")
	_check(absf(patrol.global_position.x - patrol_x) < 250.0,
		"the patrol resumed from where it was (%.0f -> %.0f)" % [patrol_x, patrol.global_position.x])
	_check(absf(patrol.global_position.x - spawn_x) > 1.0 or absf(patrol_x - spawn_x) < 1.0,
		"nothing teleported the patrol back to its spawn")
	_check(absf(patrol.velocity.x) > 10.0, "the patrol is walking again under its own AI")

func _t_charger_crate() -> void:
	# Zone C: a committed charge is a real velocity, and it can be exchanged.
	controller.cancel_selection()
	# Fresh zone C first: the charger may be anywhere after earlier tests.
	lab.place_player(Vector2(2600.0, 599.0))
	await _step(6)
	lab.reset_zone()
	await _step(6)
	var charger := _enemy_in("ZoneC", LabChargerEnemy) as LabChargerEnemy
	var crate := _crate_near(3420.0)
	if charger == null or crate == null:
		_check(false, "zone C charger/crate found")
		return
	_check(absf(charger.global_position.x - 2760.0) < 60.0,
		"reset zone put the charger back at its post (x=%.0f)" % charger.global_position.x)
	player.health.reset()
	# Stand just inside its trigger, on clear ground west of the spikes.
	lab.place_player(Vector2(3080.0, 599.0))
	await _step(10)
	var exchanged := false
	var charge_vx := 0.0
	var guard := 0
	while guard < 420:
		guard += 1
		await physics_frame
		# Wait for a REAL committed run: the state flips one frame before the
		# charge velocity is written, and an empty run is not worth exchanging.
		if charger.state == LabChargerEnemy.State.CHARGE and absf(charger.velocity.x) > 300.0:
			controller.cancel_selection()
			if controller.cooldown_left > 0.0:
				continue
			charge_vx = charger.velocity.x
			if controller.select_at(charger.swap_target.anchor_world()) \
					and controller.select_at(crate.swap_target.anchor_world()):
				exchanged = true
			break
	_check(exchanged, "the charger's committed run can be exchanged into a crate")
	if exchanged:
		await _step(3)
		_check(absf(crate.linear_velocity.x - charge_vx) < 40.0,
			"the crate received the charge exactly (%.0f -> %.0f px/s)" % [charge_vx, crate.linear_velocity.x])
		_check(absf(charger.velocity.x) < 150.0,
			"the charger received the crate's standstill and stopped (vx=%.0f)" % charger.velocity.x)
	_check(player.health.hp > 0, "the charger's contact did not delete the player")
	player.health.reset()

func _t_gunner_shot() -> void:
	# Zone B: a shot's velocity is real, it never homes, and a parked shot
	# deflates instead of accumulating.
	controller.cancel_selection()
	var gunner := _enemy_in("ZoneB", LabGunnerEnemy) as LabGunnerEnemy
	if gunner == null:
		_check(false, "zone B gunner found")
		return
	# Clear the sky of shots left over from earlier tests, so the one we pick is
	# the one this gunner fires at the player standing right here.
	for n in get_nodes_in_group("lab_projectiles"):
		var old := n as LabProjectile
		if old != null and not old.is_retiring():
			old.retire_now()
	player.health.reset()
	lab.place_player(Vector2(1750.0, 599.0))
	await _step(6)
	await _wait_cooldown()
	var shot: LabProjectile = null
	var guard := 0
	while shot == null and guard < 300:
		guard += 1
		await physics_frame
		shot = _live_shot(LabProjectile.Team.ENEMY)
	_check(shot != null, "the gunner fires a shot")
	if shot == null:
		return
	_check(controller.select_at(shot.swap_target.anchor_world()), "pick the shot in flight as A")
	_check(controller.select_at(gunner.swap_target.anchor_world()), "SHOT <-> GUNNER accepted")
	await _step(3)
	_check(gunner.swap_override_t > 0.0, "the gunner received the shot's velocity")
	_check(shot.velocity.length() < 30.0, "the shot received the gunner's standstill")
	var life_before := shot.life
	await _step(45)
	_check(not is_instance_valid(shot) or shot.is_retiring() or shot.life < life_before,
		"the parked shot's lifetime kept running")
	await _step(150)
	_check(not is_instance_valid(shot), "the parked shot deflated instead of piling up")
	_check(controller.last_feedback.length() > 0, "the exchange reported itself: %s" % controller.last_feedback)
	# Gunner AI resume, from wherever it ended up.
	await _step(60)
	_check(gunner.swap_override_t == 0.0, "the gunner's override expired")
	_check(absf(gunner.velocity.x) < 6.0, "the gunner's AI holds its ground again")
	player.health.reset()

func _t_pellet_lost_selection() -> void:
	# A selected target that dies mid-selection must clear itself, loudly.
	controller.cancel_selection()
	if _zone_e_crate == null:
		return
	await _wait_cooldown()
	var pellet: LabProjectile = null
	for n in get_nodes_in_group("lab_cannons"):
		var cannon := n as LabCannon
		if cannon != null and absf(cannon.global_position.x - 2390.0) < 200.0:
			pellet = cannon.fire()
			break
	_check(pellet != null, "the test cannon fires a pellet")
	if pellet == null:
		return
	await _step(2)
	lab.place_player(Vector2(pellet.global_position.x - 80.0, 599.0))
	await _step(2)
	_check(controller.select_at(pellet.swap_target.anchor_world()), "pick the pellet as A")
	_check(controller.target_a == pellet.swap_target, "the pellet is selected")
	pellet.retire_now()
	await _step(6)
	_check(controller.target_a == null, "a dying target clears the selection")
	_check(controller.last_feedback.contains("LOST"), "and says why: %s" % controller.last_feedback)

func _t_belt_carry() -> void:
	# Zone D: a belt is a real surface — it carries a standing player.
	lab.place_player(Vector2(4050.0, 599.0))
	await _step(12)
	var x0 := player.global_position.x
	await _step(60)
	_check(player.global_position.x - x0 > 80.0,
		"belt A carries the player (%.0f px in 1 s)" % (player.global_position.x - x0))
	_check(player.is_on_floor(), "the player is standing, not sliding")

func _t_lift_carry() -> void:
	# Zone D lift: riding it must actually lift the player (AnimatableBody2D
	# carry, or the explicit carrier fallback — measured, not assumed).
	var lift := lab.get_node_or_null("World/ZoneD/Lift") as LabMovingPlatform
	if lift == null:
		_check(false, "zone D lift found")
		return
	# Stand in zone D before resetting, so the reset targets this zone's lift.
	lab.place_player(Vector2(4700.0, 599.0))
	await _step(6)
	lab.reset_zone()
	await _step(2)
	_check(lift.global_position.y > 500.0,
		"reset zone put the lift back near its origin (y=%.0f)" % lift.global_position.y)
	lab.place_player(Vector2(4930.0, lift.global_position.y - 24.0))
	await _step(24)
	_check(player.is_on_floor(), "the player is standing on the lift")
	var lift_y0 := lift.global_position.y
	var y0 := player.global_position.y
	await _step(150)
	var lift_dy := lift_y0 - lift.global_position.y
	var dy := y0 - player.global_position.y
	_check(lift_dy > 100.0, "the lift travelled up (%.0f px in 2.5 s)" % lift_dy)
	_check(dy > lift_dy - 30.0,
		"the lift carries the player with it (player %.0f px, lift %.0f px)" % [dy, lift_dy])

func _t_fallen_enemy() -> void:
	# Lab recovery rule: a body that leaves the world is retired and respawned.
	var patrol := _enemy_in("ZoneD", LabPatrolEnemy)
	if patrol == null:
		_check(false, "zone D patrol found")
		return
	var spawn := patrol.spawn_position
	patrol.global_position = Vector2(spawn.x, 900.0)
	await _step(120)
	await _step(180)
	var back := _enemy_in("ZoneD", LabPatrolEnemy)
	_check(not is_instance_valid(patrol), "the fallen enemy body was removed, not left stuck")
	_check(back != null and absf(back.global_position.x - spawn.x) < 80.0,
		"a replacement spawned at the patrol's post (x=%.0f)" % (back.global_position.x if back != null else -1.0))
	_check(_enemy_count() == 7, "the roster is whole again (%d)" % _enemy_count())

func _t_finish_line() -> void:
	_check(not lab.completed, "the lab is not complete yet")
	lab.place_player(Vector2(7775.0, 599.0))
	await _step(20)
	_check(lab.completed, "reaching the finish line completes the lab")
	_check(lab.lab_status_line().contains("COMPLETE"), "the lab status reports completion")
