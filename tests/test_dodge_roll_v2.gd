extends "res://tests/test_foundation_repair.gd"
## Real player, collision solver, floor and Motion Swap lab fixtures.
var measurements: Dictionary = {}

func _run() -> void:
	root.unfocusable = true
	await prepare()
	var x := player.position.x
	var ticks := 0
	await roll_press()
	check(player.roll_remaining > 0 and player.position.x > x, "ready roll moves on accepting update")
	ticks += 1
	while player.roll_remaining > 0:
		await step(1)
		ticks += 1
	measurements = {"configured_duration_s":player.roll_duration,"speed_px_s":player.roll_speed,"distance_px":player.position.x-x,"active_ticks":ticks-1,"time_including_exit_s":ticks/60.0,"cooldown_on_exit_s":player.roll_cooldown_remaining}
	check(player.position.x-x >= 90 and player.position.x-x <= 105, "roll travel within90-105px", measurements)
	check(player.roll_cooldown_remaining > .349 and not player.can_movement_roll(), "natural end starts full0.35s cooldown")
	Input.action_press("move_right")
	await step(1)
	check(player.velocity.x > 0 and player.roll_remaining==0, "RUN accepts during cooldown")
	Input.action_press("jump")
	await step(1)
	check(player.velocity.y < -600 and player.roll_remaining==0, "JUMP accepts during cooldown")
	Input.action_release("jump")
	Input.action_release("move_right")
	await prepare()
	await roll_press()
	while player.roll_remaining>0:await step(1)
	var cooldown_ticks := 0
	while not player.can_movement_roll():
		await step(1)
		cooldown_ticks += 1
	measurements["cooldown_ticks_after_end"] = cooldown_ticks
	check(cooldown_ticks==21, "cooldown lasts21 game-physics ticks at60Hz", {"ticks":cooldown_ticks})
	await roll_press()
	check(player.roll_remaining>0 and absf(player.velocity.x-player.roll_speed)<.01, "fresh input after readiness has no startup")
	for age in [2,8,15]:
		await prepare()
		await roll_press()
		await step(age-1)
		Input.action_press("move_left")
		Input.action_press("dash") # ignored for the rest of the clip, not cancelled into
		await step(1)
		Input.action_release("dash")
		check(player.roll_remaining>0 and is_equal_approx(player.velocity.x,player.roll_speed), "tick%d direction and roll spam are ignored" % age)
		while player.roll_remaining>0:
			await step(1)
		check(is_equal_approx(player.roll_cooldown_remaining,.35), "tick%d full clip arms the 0.35s cooldown on completion" % age)
		check(player.velocity.x==-player.run_speed, "tick%d held direction resumes after the clip" % age)
		var previous := player.roll_cooldown_remaining
		await step(2)
		await roll_press()
		check(player.roll_remaining==0 and player.roll_cooldown_remaining < previous, "tick%d rejected retry neither bypasses nor resets cooldown" % age)
		check(player.velocity.x==-player.run_speed, "tick%d unavailable roll preserves RUN" % age)
		Input.action_release("move_left")
	await prepare()
	var starts := [0]
	player.dashed.connect(func(): starts[0]+=1)
	var peak := 0.0
	for i in 120:
		if i%2==0:Input.action_press("dash")
		else:Input.action_release("dash")
		await step(1)
		peak=maxf(peak,absf(player.velocity.x))
	check(starts[0]==3, "120-tick spam accepts only3 separated rolls", {"starts":starts[0],"peak":peak})
	check(peak<=player.roll_speed+.01, "spam never stacks velocity")
	measurements["spam_starts_in120ticks"] = starts[0]
	await prepare()
	await roll_press()
	await step(3)
	Input.action_press("move_right")
	await step(1)
	Input.action_release("move_right")
	await roll_press()
	# Keep rejected button held through expiry: there is no deferred roll.
	Input.action_press("dash")
	await step(45)
	check(player.can_movement_roll() and player.roll_remaining==0, "rejected held input is discarded, no queued charge")
	Input.action_release("dash")
	await step(1)
	await roll_press()
	check(player.roll_remaining>0, "fresh re-press after a discarded hold starts immediately")
	await prepare(Vector2(2700,300))
	var budget := player._air_dashes
	var vy := player.velocity.y
	await roll_press()
	check(player.roll_remaining>0 and player.velocity.y>=vy and player._air_dashes==budget and player._coyote<=0, "air roll keeps gravity and jump budget")
	Input.action_press("move_left")
	await step(1)
	check(player.roll_remaining>0 and player.velocity.x>0 and not player.is_on_floor(), "air roll ignores direction input until the clip completes")
	while player.roll_remaining>0:
		await step(1)
	check(player.velocity.x==-player.run_speed, "air control resumes after the air roll clip")
	Input.action_release("move_left")
	await prepare()
	await roll_press()
	player.motion_swap_apply(Vector2(600,-50),.24)
	check(player.roll_remaining==0 and is_equal_approx(player.roll_cooldown_remaining,.35), "Motion Swap interruption starts cooldown without changing received velocity")
	check(player.velocity==Vector2(600,-50), "roll cleanup preserves actual swapped motion")
	await step(3)
	check(player.roll_cooldown_remaining<.35 and player.roll_cooldown_remaining>.29, "cooldown continues through forced-motion updates")
	await prepare()
	await roll_press()
	while player.roll_remaining>0:
		await step(1)
	var cd_before_slow := player.roll_cooldown_remaining
	Engine.time_scale=.12
	await step(5)
	var slow_elapsed := cd_before_slow-player.roll_cooldown_remaining
	Engine.time_scale=1.0
	check(absf(slow_elapsed-.01)<.0001, "cooldown uses same game-time authority under tactical0.12 scale", {"five_scaled_ticks_s":slow_elapsed})
	await prepare(Vector2(2770,300))
	lab._solid(lab,"V2ThinWall",Rect2(2800,-200,2,1000))
	await step(2)
	await roll_press()
	await step(25)
	check(player.position.x<=2786.1 and player.health.hp==5, "air roll still stops at2px wall without damage")
	FileAccess.open("res://artifacts/dodge_roll_v2/control_results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"results":receipts,"measurements":measurements},"\t"))
	lab.queue_free()
	await process_frame
	print("DODGE_V2_TESTS: %d checks / %d failures" % [checks,failures])
	quit(1 if failures else 0)
