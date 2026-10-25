extends "res://tests/test_motion_swap_chaos.gd"
## Live crowbar feel gate: M1 > M2 > M3 animation progression, recovery
## canceling, full-strike buffering, the 0.45 s post-strike window, local
## hitstop, directional shake, blood, floating damage, layered sound, enemy
## flash/squash, knockback, and the Motion Swap interruption contract.

var combo: NLBM1Combo
var feedbacks: Array[Dictionary] = []
var strikes: Array[int] = []

func _run() -> void:
	root.unfocusable = true
	await fresh(Vector2(1250, 599))
	combo = player.get_node_or_null("M1Combo") as NLBM1Combo
	check(combo != null, "live crowbar combo is mounted on the preview player")
	if combo == null:
		quit(1)
		return
	combo.strike_started.connect(func(index: int, _id: String) -> void: strikes.append(index))
	combo.contact_feedback.connect(func(event: Dictionary, _victim: Node) -> void: feedbacks.append(event))
	# Isolate locomotion and the combo from enemy AI / projectiles.
	for n in get_nodes_in_group("lab_enemies"):
		(n as LabEnemy).retire()
	await step(3)
	var configs: Array = combo.metadata.configs
	check(is_equal_approx(float(configs[0].recovery_cancel), 0.10)
		and is_equal_approx(float(configs[1].recovery_cancel), 0.15)
		and is_equal_approx(float(configs[2].recovery_cancel), 0.35),
		"recovery_cancel gates are M1 0.10 / M2 0.15 / M3 0.35",
		{"m1": configs[0].recovery_cancel, "m2": configs[1].recovery_cancel, "m3": configs[2].recovery_cancel})
	check(is_equal_approx(float(configs[0].chain), 0.10)
		and is_equal_approx(float(configs[1].chain), 0.15)
		and float(configs[2].chain) < 0.0,
		"chain gates are M1 0.10 / M2 0.15 / M3 none",
		{"m1": configs[0].chain, "m2": configs[1].chain, "m3": configs[2].chain})
	check(is_equal_approx(float(configs[0].duration), 0.20)
		and is_equal_approx(float(configs[1].duration), 0.30)
		and is_equal_approx(float(configs[2].duration), 0.65),
		"authored clip durations are 0.20 / 0.30 / 0.65 s")
	check(is_equal_approx(float(configs[0].kb), 220.0)
		and is_equal_approx(float(configs[1].kb), 240.0)
		and is_equal_approx(float(configs[2].kb), 260.0),
		"knockback values are 220 / 240 / 260 px/s")
	check(is_equal_approx(combo.combo_reset_timeout, 0.45),
		"the post-strike combo window is 0.45 s", {"window": combo.combo_reset_timeout})
	check(is_equal_approx(combo.buffer_seconds, 0.25),
		"the live buffer covers a full strike from the first frame", {"buffer": combo.buffer_seconds})
	check(is_equal_approx(combo.stops.x, 0.03) and is_equal_approx(combo.stops.y, 0.04)
		and is_equal_approx(combo.stops.z, 0.05), "per-strike hitstop is 0.03 / 0.04 / 0.05 s")
	check(is_equal_approx(combo.playback_rate, 1.0),
		"live crowbar plays its authored source timing at 1.0x")

	# The animation itself must advance and each step must use its own atlas row.
	await reset_combo()
	combo._start(0, 1)
	await step(2)
	var m1_early := int(combo.current.get("sample", -1))
	var m1_rect := combo.sprite.region_rect.position
	await step(2)
	var m1_late := int(combo.current.get("sample", -1))
	check(m1_late > m1_early, "M1 sprite advances instead of looping its first frame",
		{"early": m1_early, "late": m1_late})
	combo.reset()
	await step(1)
	combo._start(1, 1)
	await step(4)
	var m2_rect := combo.sprite.region_rect.position
	combo.reset()
	await step(1)
	combo._start(2, 1)
	await step(4)
	var m3_rect := combo.sprite.region_rect.position
	check(m1_rect != m2_rect and m2_rect != m3_rect,
		"M1/M2/M3 render distinct authored atlas regions", {"m1": m1_rect, "m2": m2_rect, "m3": m3_rect})

	# Natural 0.2 s / 0.3 s cadence: late clicks must continue the combo instead
	# of restarting the opener.
	await reset_combo()
	var before := combo.accepted
	await click()
	check(combo.index == 0 and combo.busy(), "first click opens M1")
	await step(12)
	await click()
	check(combo.index == 1 and combo.accepted == before + 2, "0.2 s click chains M1 > M2")
	await step(18)
	await click()
	check(combo.index == 2 and combo.accepted == before + 3, "0.3 s click chains M2 > M3")
	check(strikes.slice(-3) == [0, 1, 2], "three distinct authored strikes were started", {"strikes": strikes})
	await step(40)
	check(not combo.busy(), "M3 completes and releases the combo")

	# A press in recovery must cancel the remaining tail on that update.
	await reset_combo()
	before = combo.accepted
	await click()
	await step(7)
	await click()
	check(combo.index == 1 and combo.accepted == before + 2 and combo.age < 0.05,
		"recovery press cancels M1 into M2 on the same update", {"age": combo.age})

	# Early follow-up is buffered through the authored strike and fires at gate.
	await reset_combo()
	before = combo.accepted
	await click()
	await step(2)
	await click()
	check(combo.index == 0 and combo.pending > 0.0, "early follow-up is buffered, not restarted")
	await step(10)
	check(combo.index == 1 and combo.accepted == before + 2, "buffered follow-up fires at the chain gate")

	# A press in the late active frames is also buffered to the recovery gate.
	await reset_combo()
	before = combo.accepted
	await click()
	await step(4)
	await click()
	check(combo.index == 0 and combo.pending > 0.0, "late-active press is buffered, not swallowed")
	await step(1)
	check(combo.index == 1 and combo.accepted == before + 2, "late-active buffer fires at the chain gate")

	# A single click is still one strike; no auto-chain.
	await reset_combo()
	before = combo.accepted
	await click()
	await step(40)
	check(combo.accepted == before + 1 and not combo.busy(), "one click produces exactly one strike")

	# The combo step survives a deliberate pause inside the 0.45 s window.
	await reset_combo()
	before = combo.accepted
	await click()
	await step(30)
	await click()
	check(combo.index == 1 and combo.accepted == before + 2,
		"a click 0.5 s after M1 starts still continues to M2")

	# Past the window, a new click is a fresh opener, not a teleport into M2.
	await reset_combo()
	await click()
	await step(42)
	before = combo.accepted
	await click()
	check(combo.index == 0 and combo.accepted == before + 1,
		"a click after the 0.45 s combo window restarts M1")

	# M3: any press is queued and restarts M1 at the 0.35 s cancel gate. An
	# early finisher press is never swallowed by the authored 0.65 s tail.
	await reset_combo()
	combo._start(2, 1)
	await step(2)
	await click()
	check(combo.index == 2 and combo.busy() and combo.restart_pending > 0.0,
		"early M3 press is queued, not ignored")
	await step(18)
	check(combo.index == 0, "queued M3 press restarts M1 at 0.35 s")
	await reset_combo()
	combo._start(2, 1)
	await step(21)
	await click()
	check(combo.index == 0, "direct M3 click at 0.35 s restarts M1 immediately")

	# Real contact: all six feedback layers on the same accepted hit.
	await reset_combo()
	var fx = combo.impact_vfx
	fx.blood.clear()
	fx.numbers.clear()
	fx.audio_events.clear()
	var enemy := load("res://labs/enemies/patrol.tscn").instantiate() as LabPatrolEnemy
	enemy.position = player.global_position + Vector2(30, 0)
	enemy.set_spawn(enemy.position)
	enemy.speed = 0.0
	lab.get_node("World/ZoneB").add_child(enemy)
	await step(5)
	var enemy_start := enemy.global_position.x
	feedbacks.clear()
	await click()
	var guard := 0
	while feedbacks.is_empty() and guard < 24:
		await step(1)
		guard += 1
	check(feedbacks.size() == 1, "crowbar contact emits one feedback event", {"events": feedbacks})
	check(feedbacks.size() == 1 and int(feedbacks[0].strike) == 1, "feedback carries the authored strike index")
	check(combo.stop_left >= 0.029, "contact arms 30 ms local hitstop", {"stop": combo.stop_left})
	check(enemy.flash_frames_left() > 0, "enemy hit flash is armed")
	check(enemy.body_vis.scale.x > 1.0, "enemy body squash-punch reacts on contact", {"scale": enemy.body_vis.scale})
	check(lab.combo_shake_pixels >= 3.0 and lab._combo_shake_left > 0.0
		and not is_zero_approx(lab._combo_shake_dir),
		"directional camera shake is 3-5 px", {"px": lab.combo_shake_pixels, "dir": lab._combo_shake_dir})
	check(fx.blood.size() >= 5, "blood burst spawns at the contact", {"blood": fx.blood.size()})
	var number_label: Label = fx.numbers[0].label if not fx.numbers.is_empty() else null
	check(number_label != null and number_label.text == str(feedbacks[0].damage),
		"floating damage number matches the hit", {"text": number_label.text if number_label != null else ""})
	var layered_audio := false
	for event in fx.audio_events:
		var sound_name := String(event.get("sound", ""))
		if sound_name.begins_with("hit_") or sound_name == "organic":
			layered_audio = true
	check(layered_audio, "layered impact audio fired", {"events": fx.audio_events})
	var strike_age := combo.age
	var hold_x := enemy.global_position.x
	await step(1)
	check(absf(combo.age - strike_age) < 0.0001, "attacker strike clock freezes during hitstop",
		{"before": strike_age, "after": combo.age})
	check(enemy.body_vis.color == Color.WHITE, "enemy body renders white on the hit flash")
	check(absf(enemy.global_position.x - hold_x) < 0.5, "victim position freezes during hitstop",
		{"before": hold_x, "after": enemy.global_position.x})
	# The flash must burn down inside hitstop instead of freezing white.
	await step(4)
	check(enemy.flash_frames_left() == 0 and enemy.body_vis.color != Color.WHITE,
		"enemy flash clears after two frames, including hitstop")
	await step(8)
	check(enemy.body_vis.scale.distance_to(Vector2.ONE) < 0.05, "enemy squash settles back to normal")
	var kb_delta := enemy.global_position.x - enemy_start
	check(kb_delta >= 10.0 and kb_delta <= 60.0, "knockback slides the victim 20-30 px",
		{"px": kb_delta})
	enemy.queue_free()
	await step(3)

	# Motion Swap still owns the interruption contract.
	await reset_combo()
	await click()
	await step(2)
	key(KEY_E)
	await step(1)
	check(controller.is_selecting() and not combo.busy(), "Motion Swap selection still interrupts the crowbar combo")
	controller.cancel_selection()
	await step(2)

	lab.queue_free()
	await step(3)
	DirAccess.make_dir_recursive_absolute("res://artifacts/crowbar_combo_feel")
	var out := FileAccess.open("res://artifacts/crowbar_combo_feel/results.json", FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks": checks, "failures": failures, "results": receipts}, "\t"))
	out.close()
	print("CROWBAR_COMBO_FEEL: %d checks / %d failures" % [checks, failures])
	quit(1 if failures else 0)

func reset_combo() -> void:
	for action in ["attack", "swap_select", "move_left", "move_right", "jump", "dash"]:
		Input.action_release(action)
	combo.reset()
	player.velocity = Vector2.ZERO
	player.facing = 1
	lab.place_player(Vector2(1250, 599))
	strikes.clear()
	await step(3)

func click() -> void:
	Input.action_press("attack")
	await step(1)
	Input.action_release("attack")
