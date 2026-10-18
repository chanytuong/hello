extends SceneTree
## MOTION SWAP — contract tests (pure logic: channels, adapters, exchange).
## No lab scene, no frames, no rendering. The runtime/lab end-to-end suite is
## tests/test_motion_swap_lab.gd.
## Run: godot --headless --path E:\neverlookback --script res://tests/test_motion_swap.gd

const CRATE_SCENE: PackedScene = preload("res://labs/objects/lab_crate.tscn")

var _failures: int = 0
var _spawned: Array[Node] = []
## Logic-only hosts (`LabCrate.new()` etc.) are never added to the tree, so the
## tree cannot free them and an unfreed Node stays alive until the process dies —
## which Godot then reports as leaked RIDs at exit. `_temp()` keeps them so
## `_run_tree_tests` can free them properly.
var _scratch: Array[Node] = []

func _temp(n: Node) -> Node:
	_scratch.append(n)
	return n

## Minimal host for the character adapter: the adapter must forward to whatever
## host it was given, without knowing the host's class. The REAL character
## semantics (velocity, gravity, AI resume) are tested on LabPatrolEnemy below.
class FakeCharacter extends Node2D:
	var velocity_value: Vector2 = Vector2.ZERO
	var swap_override_t: float = 0.0

	func motion_swap_read() -> Vector2:
		return velocity_value

	func motion_swap_apply(motion: Vector2, duration: float) -> void:
		velocity_value = motion
		swap_override_t = maxf(duration, 0.0)

	func is_swap_selectable() -> bool:
		return true


func _init() -> void:
	_test_channel_table()
	_test_adapters_read_real_quantities()
	_test_zero_is_a_value_not_a_freeze()
	_test_machine_speeds_persist()
	_test_ai_resumes_from_current_position()
	_test_no_blink_remnants()
	# Nodes added during SceneTree._init are not in the tree yet (ENTER_TREE is
	# deferred until the tree starts), so the exchange test runs one frame later.
	call_deferred("_run_tree_tests")

func _run_tree_tests() -> void:
	await physics_frame
	_test_exchange_is_atomic_and_two_way()
	# Hand the tree back clean (no leaked RIDs for the next suite / the user).
	for n in _spawned:
		if is_instance_valid(n):
			n.queue_free()
	# queue_free resolves at the end of the frame and the physics server hands the
	# RIDs back a moment later: give it three frames so the suite cannot be
	# mistaken for leaking (it printed `... leaked at exit` before this).
	for _i in 3:
		await process_frame
	# Scratch hosts never entered the tree: free() is the correct call for them.
	for n in _scratch:
		if is_instance_valid(n):
			n.free()
	_scratch.clear()
	_finish()

func _finish() -> void:
	if _failures == 0:
		print("MOTION_SWAP_TESTS: ALL PASS")
	else:
		printerr("MOTION_SWAP_TESTS: %d FAILURES" % _failures)
	quit(1 if _failures > 0 else 0)

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS: " + name)
	else:
		printerr("FAIL: " + name)
		_failures += 1

# ------------------------------------------------------------------ channels

func _test_channel_table() -> void:
	var l := NLBMotionChannels.Channel.LINEAR
	var s := NLBMotionChannels.Channel.SURFACE
	var p := NLBMotionChannels.Channel.PLATFORM
	_check(NLBMotionChannels.compatible(l, l), "LINEAR <-> LINEAR allowed")
	_check(NLBMotionChannels.compatible(s, s), "SURFACE <-> SURFACE allowed")
	_check(NLBMotionChannels.compatible(p, p), "PLATFORM <-> PLATFORM allowed")
	_check(NLBMotionChannels.compatible(s, p) and NLBMotionChannels.compatible(p, s),
		"SURFACE <-> PLATFORM allowed both ways")
	_check(not NLBMotionChannels.compatible(l, s), "LINEAR <-> SURFACE refused")
	_check(not NLBMotionChannels.compatible(l, p), "LINEAR <-> PLATFORM refused")
	var refusal := NLBMotionChannels.refusal(l, p)
	_check(refusal.contains("INCOMPATIBLE") and refusal.contains("LINEAR") and refusal.contains("PLATFORM"),
		"refusal names both sides: %s" % refusal)
	_check(NLBMotionChannels.label(l) == "LINEAR" and NLBMotionChannels.label(s) == "SURFACE"
		and NLBMotionChannels.label(p) == "PLATFORM", "channel labels are stable")

# ------------------------------------------------------------------ adapters

func _test_adapters_read_real_quantities() -> void:
	# Crate: the physics body's own linear velocity.
	var crate := _temp(LabCrate.new()) as LabCrate
	crate.linear_velocity = Vector2(210, -40)
	var ca := NLBMotionRigidBodyAdapter.new(crate)
	_check(ca.read_motion() == Vector2(210, -40), "crate adapter reads the real linear velocity")
	ca.apply_motion(Vector2(-90, 15))
	_check(crate.linear_velocity == Vector2(-90, 15), "crate adapter writes the received velocity")

	# Character: its own velocity, written through the override contract.
	var host := _temp(FakeCharacter.new()) as FakeCharacter
	host.velocity_value = Vector2(90, 0)
	var pa := NLBMotionCharacterAdapter.new(host)
	_check(pa.read_motion() == Vector2(90, 0), "character adapter reads its own velocity")
	pa.override_time = 2.5
	pa.apply_motion(Vector2(520, -30))
	_check(host.velocity_value == Vector2(520, -30) and host.swap_override_t == 2.5,
		"character adapter applies motion + override window")

	# Projectile: velocity is read/written, lifetime is not a swap quantity.
	var shot := _temp(LabProjectile.new()) as LabProjectile
	shot.velocity = Vector2(200, 0)
	shot.life = 3.0
	var sa := NLBMotionProjectileAdapter.new(shot)
	_check(sa.read_motion() == Vector2(200, 0), "projectile adapter reads its real velocity")
	sa.apply_motion(Vector2.ZERO)
	_check(shot.velocity == Vector2.ZERO and shot.life == 3.0,
		"projectile receives zero velocity and KEEPS its remaining lifetime")

	# Machines: a persistent operating speed, never the body's own velocity.
	var belt := _temp(LabConveyor.new()) as LabConveyor
	belt.surface_speed = 120.0
	var la := NLBMotionConveyorAdapter.new(belt)
	_check(la.channel() == NLBMotionChannels.Channel.SURFACE, "belt adapter speaks SURFACE")
	_check(la.read_motion() == Vector2(120, 0), "belt adapter reads its surface speed")
	la.apply_motion(Vector2(-60, 0))
	_check(belt.surface_speed == -60.0, "belt adapter writes the received surface speed")
	var lift := _temp(LabMovingPlatform.new()) as LabMovingPlatform
	lift.travel_speed = 80.0
	var pl := NLBMotionPlatformAdapter.new(lift)
	_check(pl.channel() == NLBMotionChannels.Channel.PLATFORM, "lift adapter speaks PLATFORM")
	pl.apply_motion(Vector2(240, 0))
	_check(lift.travel_speed == 240.0, "lift adapter writes the received travel speed")

# ------------------------------------------------------------------ exchange

func _test_exchange_is_atomic_and_two_way() -> void:
	# Real crate scenes, so this also pins the scene layout the lab relies on.
	var a := CRATE_SCENE.instantiate() as LabCrate
	var b := CRATE_SCENE.instantiate() as LabCrate
	root.add_child(a)
	root.add_child(b)
	_spawned.append(a)
	_spawned.append(b)
	a.linear_velocity = Vector2(300, 0)
	b.linear_velocity = Vector2(-120, 40)
	var ta := a.get_node("SwapTarget") as NLBMotionSwapTarget
	var tb := b.get_node("SwapTarget") as NLBMotionSwapTarget
	ta.setup(a, NLBMotionRigidBodyAdapter.new(a), "CRATE A")
	tb.setup(b, NLBMotionRigidBodyAdapter.new(b), "CRATE B")
	var ctrl := NLBMotionSwapController.new()
	root.add_child(ctrl)
	_spawned.append(ctrl)
	_check(ta.is_valid() and tb.is_valid(), "both crate targets are valid in-scene")
	_check(ctrl.target_a == null, "controller starts with no selection")
	ctrl.exchange(ta, tb)
	_check(a.linear_velocity == Vector2(-120, 40), "A received B's exact motion")
	_check(b.linear_velocity == Vector2(300, 0), "B received A's exact motion")
	_check(ctrl.target_a == null, "exchange clears the selection")
	_check(ctrl.phase == NLBMotionSwapController.Phase.COOLDOWN, "exchange enters cooldown")
	_check(ctrl.cooldown_left > 0.0, "swap cooldown is armed")
	_check(not ctrl.last_feedback.is_empty(), "exchange reports what happened: %s" % ctrl.last_feedback)
	# Opposed movers: a head-on pair must actually reverse, not cancel.
	a.linear_velocity = Vector2(300, 0)
	b.linear_velocity = Vector2(-300, 0)
	ctrl.exchange(ta, tb)
	_check(a.linear_velocity == Vector2(-300, 0) and b.linear_velocity == Vector2(300, 0),
		"opposed movers reverse through each other's motion")

# ----------------------------------------------------------------- semantics

func _test_zero_is_a_value_not_a_freeze() -> void:
	var patrol := _temp(LabPatrolEnemy.new()) as LabPatrolEnemy
	patrol.motion_swap_apply(Vector2.ZERO, 2.5)
	_check(patrol.velocity.x == 0.0, "zero exchange means zero controllable motion")
	patrol._drive_swapped_motion(0.1)
	_check(patrol.velocity.y > 0.0,
		"zero exchange is NOT a freeze: gravity still acts (vy=%.0f)" % patrol.velocity.y)
	_check(patrol.swap_override_t == 2.5, "the override window is the received duration, not shorter")

func _test_machine_speeds_persist() -> void:
	var belt := _temp(LabConveyor.new()) as LabConveyor
	belt.surface_speed = 120.0
	belt.authored_speed = 120.0  # scene _ready copies this; logic hosts have no tree
	var lift := _temp(LabMovingPlatform.new()) as LabMovingPlatform
	lift.travel_speed = 80.0
	lift.authored_speed = 80.0
	var ba := NLBMotionConveyorAdapter.new(belt)
	var la := NLBMotionPlatformAdapter.new(lift)
	var belt_motion := ba.read_motion()
	var lift_motion := la.read_motion()
	ba.apply_motion(lift_motion)
	la.apply_motion(belt_motion)
	_check(belt.surface_speed == 80.0 and lift.travel_speed == 120.0,
		"machine settings exchanged (belt=%.0f lift=%.0f)" % [belt.surface_speed, lift.travel_speed])
	_check(ba.override_remaining() < 0.0 and la.override_remaining() < 0.0,
		"machines have no override clock: their setting is persistent")
	var patrol := _temp(LabPatrolEnemy.new()) as LabPatrolEnemy
	patrol.motion_swap_apply(Vector2(300, 0), 2.5)
	patrol.swap_override_t = 0.0
	patrol._on_swap_override_end()
	_check(belt.surface_speed == 80.0 and lift.travel_speed == 120.0,
		"machine settings survive a character override ending")
	belt.reset_state()
	lift.reset_state()
	_check(belt.surface_speed == 120.0 and lift.travel_speed == 80.0,
		"an explicit lab reset is the only thing that restores authored machine speeds")

func _test_ai_resumes_from_current_position() -> void:
	var patrol := _temp(LabPatrolEnemy.new()) as LabPatrolEnemy
	patrol.configure_patrol(300.0, 700.0)
	patrol.spawn_position = Vector2(400, 599)
	# As if a swap had carried it far outside its stretch.
	patrol.global_position = Vector2(1000, 599)
	patrol.velocity = Vector2(500, 0)
	patrol.swap_override_t = 0.0
	patrol._on_swap_override_end()
	_check(patrol.global_position == Vector2(1000, 599),
		"override end never restores the original position")
	_check(patrol.dir < 0.0, "AI re-derives its walk from where the body actually is")
	patrol._ai_step(0.016)
	_check(patrol.velocity.x < 0.0, "AI resumes with real motion on the next step")

func _test_no_blink_remnants() -> void:
	_check(not InputMap.has_action("blink"), "no 'blink' input action remains")
	_check(not ResourceLoader.exists("res://scripts/blink_manager.gd"), "BlinkManager script is gone")
	_check(not ResourceLoader.exists("res://tests/test_killblink.gd"), "Blink-only test removed")
	_check(not ResourceLoader.exists("res://scripts/blink_manager.gd"), "no Blink script is still referenced")
	# The ability must be reachable only through the Motion Swap controller.
	_check(ResourceLoader.exists("res://scripts/motion_swap/motion_swap_controller.gd")
		and ResourceLoader.exists("res://scripts/motion_swap/motion_swap_target.gd"),
		"Motion Swap controller + target are the ability surface")
