extends SceneTree
## One question: does teleporting the player INTO a resting crate launch it?
## Prints the crate's velocity for 30 frames after the overlap. Tuning probe only.
## Run: godot --headless --path E:\neverlookback --script res://tests/probe_lab_overlap.gd

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
	await _frames(30)
	var player: NLBPlayer = lab.player
	var crate: LabCrate = null
	for n in get_nodes_in_group("crates"):
		var c := n as LabCrate
		if c != null and absf(c.global_position.x - 820.0) < 60.0:
			crate = c
	print("crate spawn=(%.0f, %.0f) v=(%.0f, %.0f)" % [
		crate.global_position.x, crate.global_position.y, crate.linear_velocity.x, crate.linear_velocity.y])
	print("--- teleport player INTO the crate (same x) ---")
	player.reset_movement(crate.global_position + Vector2(-10.0, 20.0))
	for i in 30:
		await physics_frame
		if i % 5 == 0:
			print("f%02d crate=(%.0f, %.0f) v=(%.0f, %.0f) player=(%.0f, %.0f) pv=(%.0f, %.0f)" % [
				i, crate.global_position.x, crate.global_position.y,
				crate.linear_velocity.x, crate.linear_velocity.y,
				player.global_position.x, player.global_position.y,
				player.velocity.x, player.velocity.y])
	print("--- now the same, but 6 frames of settling first ---")
	await _frames(60)
	print("crate=(%.0f, %.0f) v=(%.0f, %.0f)" % [
		crate.global_position.x, crate.global_position.y, crate.linear_velocity.x, crate.linear_velocity.y])
	quit(0)
