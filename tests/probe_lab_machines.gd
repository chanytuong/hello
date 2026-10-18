extends SceneTree
## Focused probe: the zone E crossing timeline and the zone D lift carry.
## Not part of the suite; used to TUNE the layout against real physics numbers.
## Run: godot --headless --path E:\neverlookback --script res://tests/probe_lab_machines.gd

func _init() -> void:
	call_deferred("_run")

func _frames(n: int) -> void:
	for _i in n:
		await physics_frame

func _run() -> void:
	var lab := load("res://labs/motion_swap_lab.tscn").instantiate() as NLBMotionSwapLab
	root.add_child(lab)
	current_scene = lab
	await physics_frame
	var player: NLBPlayer = lab.player
	var ctrl: NLBMotionSwapController = lab.controller
	var belt := lab.get_node("World/ZoneE/BeltE") as LabConveyor
	var lift := lab.get_node("World/ZoneE/CrossingLift") as LabMovingPlatform
	var crate: LabCrate = null
	for n in get_nodes_in_group("crates"):
		var c := n as LabCrate
		if c != null and absf(c.global_position.x - 5670.0) < 80.0:
			crate = c
	print("=== zone E phase 1: belt(+120) -> lift ===")
	player.reset_movement(Vector2(5690.0, 599.0))
	await _frames(8)
	print("belt=%+.0f lift=%+.0f crate=(%.1f, %.1f)" % [belt.surface_speed, lift.travel_speed, crate.global_position.x, crate.global_position.y])
	print("pick belt=", ctrl.select_at(belt.swap_target.anchor_world()),
		" pick lift=", ctrl.select_at(lift.swap_target.anchor_world()))
	for i in 16:
		await _frames(15)
		print("f%03d belt=%+.0f lift=%+.0f t=%.1f/%.0f crate=(%.1f, %.1f) cratev=(%.0f, %.0f)" % [
			(i + 1) * 15, belt.surface_speed, lift.travel_speed, lift.progress(), lift.path_length,
			crate.global_position.x, crate.global_position.y, crate.linear_velocity.x, crate.linear_velocity.y])

	print("=== zone E phase 2: swap back (belt drives) ===")
	player.reset_movement(Vector2(5400.0, 599.0))
	await _frames(70)
	print("pick belt=", ctrl.select_at(belt.swap_target.anchor_world()),
		" pick lift=", ctrl.select_at(lift.swap_target.anchor_world()))
	for i in 20:
		await _frames(15)
		print("f%03d belt=%+.0f lift=%+.0f crate=(%.1f, %.1f) cratev=(%.0f, %.0f) plate=%s gate=%s" % [
			(i + 1) * 15, belt.surface_speed, lift.travel_speed,
			crate.global_position.x, crate.global_position.y, crate.linear_velocity.x, crate.linear_velocity.y,
			str(lab.get_node("World/ZoneE/PressurePlate").is_latched()),
			str(lab.get_node("World/ZoneE/ZoneEGate").is_open())])

	print("=== zone D lift carry ===")
	var dlift := lab.get_node("World/ZoneD/Lift") as LabMovingPlatform
	# Stand in zone D BEFORE resetting, or the reset targets the wrong zone.
	player.reset_movement(Vector2(4930.0, 599.0))
	await _frames(6)
	lab.reset_zone()
	await _frames(6)
	print("D lift t=%.0f/%.0f speed=%+.0f pos=(%.0f, %.0f)" % [
		dlift.progress(), dlift.path_length, dlift.travel_speed, dlift.global_position.x, dlift.global_position.y])
	player.reset_movement(Vector2(4930.0, 552.0))
	await _frames(12)
	print("player on lift? pos=(%.1f, %.1f) floor=%s" % [
		player.global_position.x, player.global_position.y, str(player.is_on_floor())])
	for i in 20:
		await _frames(12)
		print("f%03d dlift t=%.1f player=(%.1f, %.1f) onfloor=%s vy=%.0f" % [
			(i + 1) * 12, dlift.progress(), player.global_position.x, player.global_position.y,
			str(player.is_on_floor()), player.velocity.y])
	await _frames(10)
	quit(0)
