extends "res://tests/test_foundation_repair.gd"
## Focused live-scene gate for the roll colour/transition repair.
##
## This deliberately exercises the two paths reported from gameplay:
##   JUMP -> AIR ROLL
##   LAND -> GROUND ROLL
## and samples every update around entry. It fails if a stale jump/land body
## remains visible, if a roll starts on a non-zero drawing, if the active body
## is not nearest-filtered, or if the rendered roll palette does not match RUN.

const IvenRollPalette = preload("res://scripts/iven_roll_palette.gd")
## Every colour the palette-sync shader can emit must already be a RUN colour.
const PALETTE_TOLERANCE := 0.05

var rows: Array[Dictionary] = []
var events: Array[Dictionary] = []
var case_name: String = ""
var capture: bool = false
var saved_frames: int = 0
var caption: Label
var details: Label

func _run() -> void:
	root.unfocusable = true
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute(out_dir() + "frames")
	await prepare()
	lab.get_node("HUD").hide()
	var cam := player.get_node("LabCamera") as Camera2D
	cam.zoom = Vector2(4, 4)
	cam.offset = Vector2(0, -30)
	cam.position_smoothing_enabled = false
	var layer := CanvasLayer.new()
	layer.layer = 30
	lab.add_child(layer)
	caption = Label.new()
	caption.position = Vector2(24, 20)
	caption.add_theme_font_size_override("font_size", 25)
	layer.add_child(caption)
	details = Label.new()
	details.position = Vector2(24, 635)
	details.add_theme_font_size_override("font_size", 19)
	layer.add_child(details)

	await case_jump_to_air_roll()
	await case_land_to_ground_roll()
	verify_results()
	DirAccess.make_dir_recursive_absolute(out_dir())
	FileAccess.open(out_dir() + "results.json", FileAccess.WRITE).store_string(JSON.stringify({
		"checks": checks, "failures": failures, "assertions": receipts,
		"events": events, "samples": rows, "capture_frames": saved_frames,
	}, "\t"))
	print("ROLL_VISUAL_FIX_TESTS: %d checks / %d failures / %d samples" % [checks, failures, rows.size()])
	lab.queue_free()
	await step(3)
	quit(1 if failures else 0)

func out_dir() -> String:
	return "res://artifacts/roll_visual_fixes/"

func begin_case(value: String) -> void:
	for action in ["move_left", "move_right", "jump", "dash"]:
		Input.action_release(action)
	player.reset_movement(Vector2(2700, 599))
	player.facing = 1
	case_name = value
	caption.text = "ROLL VISUAL FIX / " + value + "  (4x inspection view)"
	await observe(5)

func case_jump_to_air_roll() -> void:
	await begin_case("JUMP -> AIR ROLL")
	Input.action_press("jump")
	await observe(1)
	Input.action_release("jump")
	await observe(7)
	check(not player.is_on_floor(), "jump->air roll fixture is airborne before roll")
	Input.action_press("dash")
	await observe(1)
	mark("air_roll_entry")
	Input.action_release("dash")
	await observe(12)

func case_land_to_ground_roll() -> void:
	await begin_case("LAND -> GROUND ROLL")
	Input.action_press("jump")
	await observe(1)
	Input.action_release("jump")
	var landed := false
	for i in 120:
		await observe(1)
		if player.is_on_floor() and player._jump_land_t > 0.0:
			landed = true
			break
	check(landed and player.movement_visual.state == "LAND", "land->roll fixture reaches the live LAND drawing")
	await observe(1)
	Input.action_press("dash")
	await observe(1)
	mark("ground_roll_entry")
	Input.action_release("dash")
	await observe(12)

func observe(count: int) -> void:
	for i in count:
		await step(1)
		var vis := player.movement_visual
		var row := {
			"index": rows.size(), "case": case_name, "physics_frame": Engine.get_physics_frames(),
			"state": vis.state, "clip": str(vis.body.animation), "drawing": vis.body.frame,
			"body_visible": vis.body.visible, "legacy_visible": player.body_vis.visible,
			"roll_visible": vis.ground_roll.visible or vis.air_roll.visible,
			"roll_material": vis.ground_roll.material != null and vis.air_roll.material != null,
			"body_texture_filter": vis.body.texture_filter,
			"modulate": [vis.body.modulate.r, vis.body.modulate.g, vis.body.modulate.b, vis.body.modulate.a],
			"roll": player.roll_remaining, "floor": player.is_on_floor(),
			"facing": player.facing, "land_t": player._jump_land_t,
			"flame_visible": vis.flame.visible,
		}
		rows.append(row)
		details.text = "%s  |  visual %s / %d  |  body %s  legacy %s" % [
			vis.state, str(vis.body.animation), vis.body.frame,
			str(vis.body.visible), str(player.body_vis.visible),
		]
		if capture:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out_dir() + "frames/%04d.png" % saved_frames)
			saved_frames += 1

func mark(kind: String) -> void:
	events.append({"kind": kind, "index": rows.size() - 1, "case": case_name})

func verify_results() -> void:
	check(is_equal_approx(player.roll_duration, 0.50) and is_equal_approx(player.roll_speed, 400.0),
		"approved roll tuning remains 0.50 s / 400 px/s")
	for event in events:
		var entry: Dictionary = rows[event.index]
		var family := "AIR_ROLL" if event.kind == "air_roll_entry" else "DODGE_ROLL"
		check(entry.state == family and str(entry.clip).begins_with(family + "_"),
			event.case + ": roll entry selects its own clip on the first visible update", entry)
		check(entry.drawing == 0,
			event.case + ": roll entry hard-resets the active drawing to 0", {"drawing": entry.drawing})
		check(not entry.body_visible and entry.roll_visible and not entry.legacy_visible,
			event.case + ": the roll sprite alone draws at roll entry")
		check(entry.body_texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
			event.case + ": roll body uses nearest texture filtering")
		var tail: Array[Dictionary] = rows.slice(event.index)
		var roll_rows := tail.filter(func(r: Dictionary) -> bool: return r.state == family)
		check(not roll_rows.is_empty() and roll_rows.all(func(r: Dictionary) -> bool:
			return str(r.clip).begins_with(family + "_")),
			event.case + ": no jump/land drawing leaks into the roll clip")
		check(roll_rows.all(func(r: Dictionary) -> bool:
			return not r.body_visible and r.roll_visible and not r.legacy_visible),
			event.case + ": no second body becomes visible during the roll")
		check(roll_rows.all(func(r: Dictionary) -> bool: return r.drawing >= 0),
			event.case + ": every displayed roll drawing is valid")
		check(roll_rows.all(func(r: Dictionary) -> bool: return r.roll_material),
			event.case + ": every roll drawing uses the palette-sync material")
		check(_roll_palette_matches_run(family + ("_right" if entry.facing > 0 else "_left")),
			event.case + ": rendered roll palette matches the live RUN palette")
	check(rows.all(func(r: Dictionary) -> bool:
		return not (r.body_visible and r.legacy_visible)),
		"legacy ColorRect and authored body never draw together")
	check(rows.all(func(r: Dictionary) -> bool:
		return r.body_texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST),
		"authored body is nearest-filtered on every sampled update")
	check(_roll_palette_matches_run("DODGE_ROLL_left") and _roll_palette_matches_run("AIR_ROLL_left"),
		"left-facing ground and air roll frames also match the RUN palette")

## The shader emits exact RUN colours, so verify the material's target table
## rather than re-applying a modulate to the raw source textures. The earlier
## version of this gate did exactly that, which is why it passed while the
## shipped roll still rendered pale.
func _roll_palette_matches_run(clip: String) -> bool:
	var vis := player.movement_visual
	var frames: SpriteFrames = vis.body.sprite_frames
	var run_palette := IvenRollPalette.from_sprite_frames(frames, ["RUN_right", "RUN_left"])
	var material: ShaderMaterial = vis.ground_roll.material if clip.begins_with("DODGE_ROLL") else vis.air_roll.material
	if run_palette.is_empty() or material == null:
		return false
	if not frames.has_animation(clip):
		return false
	var count: int = material.get_shader_parameter("palette_count")
	var targets: PackedColorArray = material.get_shader_parameter("target_palette")
	if count <= 0 or count > targets.size():
		return false
	for i in count:
		if targets[i].a <= 0.001:
			continue
		if _nearest_distance(targets[i], run_palette) > PALETTE_TOLERANCE:
			return false
	# The coat base must land on RUN's coat base, not its lit coat.
	var coat: Variant = IvenRollPalette.role_target(Color8(0x43, 0x50, 0x60, 0xFF))
	return coat is Color and _nearest_distance(coat, [Color8(0x2D, 0x37, 0x45, 0xFF)]) <= PALETTE_TOLERANCE

func _nearest_distance(color: Color, palette: Array[Color]) -> float:
	var best := 1.0e20
	for candidate in palette:
		var dr := color.r - candidate.r
		var dg := color.g - candidate.g
		var db := color.b - candidate.b
		best = minf(best, dr * dr + dg * dg + db * db)
	return sqrt(best)
