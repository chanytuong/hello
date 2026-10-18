extends SceneTree
## MOTION SWAP LAB — review capture. RUN THIS NON-HEADLESS:
##   godot --path E:\neverlookback --script res://tests/capture_lab.gd
## Drives the REAL lab scene and screenshots it as a player sees it: every zone,
## the debug overlay, and two live exchanges caught mid-flight.
## Output: res://artifacts/motion_swap/shots/*.png

const SHOT_DIR := "res://artifacts/motion_swap/shots/"

var lab: NLBMotionSwapLab
var player: NLBPlayer
var controller: NLBMotionSwapController
var cam: Camera2D
var _n: int = 0

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	# A re-run renumbers every shot, so stale PNGs from an older run would sit next
	# to the fresh ones and look like part of this evidence set. Clear them first.
	var d := DirAccess.open(SHOT_DIR)
	if d != null:
		for f in d.get_files():
			if f.ends_with(".png"):
				DirAccess.remove_absolute(SHOT_DIR + f)
	lab = load("res://labs/motion_swap_lab.tscn").instantiate() as NLBMotionSwapLab
	get_root().add_child(lab)
	current_scene = lab
	call_deferred("_run")

func _step(n: int) -> void:
	for _i in n:
		await physics_frame

func _shot(tag: String) -> void:
	await process_frame
	var img := get_root().get_texture().get_image()
	_n += 1
	img.save_png(SHOT_DIR + "%02d_%s.png" % [_n, tag])
	print("SHOT %02d %-26s player=(%.0f, %.0f)" % [_n, tag, player.global_position.x, player.global_position.y])

## Park Iven somewhere, let the frame settle, and take the picture.
## `place_player` (not a raw position set) so a screenshot can never become the
## teleport-into-a-crate artifact generator.
func _go(x: float, tag: String, settle: int = 34) -> void:
	lab.place_player(Vector2(x, 596.0))
	if cam != null:
		cam.reset_smoothing()
	await _step(settle)
	await _shot(tag)

func _run() -> void:
	await physics_frame
	await _step(10)
	player = lab.player
	controller = lab.controller
	cam = player.get_node_or_null("LabCamera") as Camera2D
	if lab.overlay != null:
		lab.overlay.visible = true

	await _go(560.0, "zoneA_patrol_and_crates")
	await _go(1750.0, "zoneB_gunner_perch_cannon")
	await _go(3020.0, "zoneC_charger_spikes_wall")
	await _go(4420.0, "zoneD_two_belts_and_lift")
	await _go(5980.0, "zoneE_pit_belt_plate_gate")
	await _go(7100.0, "zoneF_mixed_encounter")

	# A live exchange, photographed: the zone E crossing in progress.
	# Stand clear of the parked crate: 5820 is belt, 5700 is the crate's tile.
	lab.place_player(Vector2(5820.0, 596.0))
	await _step(10)
	var belt := lab.get_node_or_null("World/ZoneE/BeltE") as LabConveyor
	var lift := lab.get_node_or_null("World/ZoneE/CrossingLift") as LabMovingPlatform
	if belt != null and lift != null:
		controller.select_at(belt.swap_target.anchor_world())
		await _step(4)
		await _shot("zoneE_selected_belt_as_A")
		controller.select_at(lift.swap_target.anchor_world())
		await _step(20)
		await _shot("zoneE_lift_carrying_crate_after_swap")

	# A live exchange with a character: the zone A walk into a crate.
	var patrol: LabEnemy = null
	for n in get_nodes_in_group("lab_enemies"):
		var e := n as LabEnemy
		if e != null and e.get_parent() != null and String(e.get_parent().name) == "ZoneA":
			patrol = e
			break
	var crate: LabCrate = null
	for n in get_nodes_in_group("crates"):
		var c := n as LabCrate
		if c != null and absf(c.global_position.x - 820.0) < 60.0:
			crate = c
			break
	lab.place_player(Vector2(700.0, 596.0))
	if cam != null:
		cam.reset_smoothing()
	await _step(30)
	if patrol != null and crate != null:
		# The zone E exchange was seconds ago: let the cooldown clear, then wait
		# for a walk (a turn-around pause is not a walk to photograph).
		var guard := 0
		while controller.cooldown_left > 0.0 and guard < 300:
			guard += 1
			await physics_frame
		# Wait for a RIGHTWARD walk so the crate runs away from Iven (a rightward
		# walk is the leg whose result reads most clearly in a still frame), and
		# only while the patrol is still far enough that it cannot bump Iven.
		guard = 0
		while not (patrol.velocity.x > 60.0 and patrol.global_position.x < 620.0) and guard < 400:
			guard += 1
			await physics_frame
		controller.cancel_selection()
		var sel_a := controller.select_at(patrol.swap_target.anchor_world())
		await _step(2)
		print("PICK A ok=%s  selected=%s  feedback=%s" % [
			str(sel_a), str(controller.target_a != null), controller.last_feedback])
		await _shot("zoneA_patrol_selected_as_A")
		var sel_b := controller.select_at(crate.swap_target.anchor_world())
		await _step(6)
		print("PICK B ok=%s  feedback=%s  crate_vx=%.0f  patrol_override=%.2f" % [
			str(sel_b), controller.last_feedback, crate.linear_velocity.x, patrol.swap_override_t])
		await _shot("zoneA_crate_running_walk_after_swap")
		await _step(90)
		await _shot("zoneA_patrol_ai_resumed")

	if lab.overlay != null:
		lab.overlay.visible = false
	await _go(5980.0, "zoneE_overlay_hidden")
	print("CAPTURE: %d shots in %s" % [_n, SHOT_DIR])
	quit(0)
