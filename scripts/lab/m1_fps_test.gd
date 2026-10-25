extends Node2D
## Isolated M1 performance lab.
##
## One flat floor, one static camera, one stationary PATROL dummy (or five in
## stress mode). No scrolling, no background, no Motion Swap selection.
## The scene runs a fixed, automated timeline so BEFORE and AFTER runs are
## directly comparable:
##   WARMUP 1.5 s -> IDLE 3 s -> RUN 3 s -> M1 combo 4 s -> DONE 1 s
##
## Modes (pass after `--` on the Godot command line):
##   --mode=bench    vsync off, precise frame-time capture, writes JSON
##   --mode=record   vsync on, HUD only, for external real-time video capture
##   --mode=stress   five simultaneous melee enemies, vsync off, writes JSON
##   --mode=monitor  vsync on, collision shapes on, saves profiler screenshot
##
## Output goes to res://scripts/lab/m1_fps_debug/.

const OUT_DIR := "res://scripts/lab/m1_fps_debug"
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const PATROL_SCENE := preload("res://labs/enemies/patrol.tscn")
const CONTROLLER_SCRIPT := preload("res://scripts/motion_swap/motion_swap_controller.gd")

const PHASE_NAMES := ["WARMUP", "IDLE", "RUN", "M1", "DONE"]
enum Phase { WARMUP, IDLE, RUN, M1, DONE }

const WARMUP_SECONDS := 1.5
const IDLE_SECONDS := 3.0
const RUN_SECONDS := 3.0
const M1_SECONDS := 4.0
const DONE_SECONDS := 1.0

## Relative offsets of the three fresh presses inside one combo, measured from
## the first press. Chosen from the authored chain gates (0.10 s / 0.15 s).
const COMBO_STARTS := [0.0, 1.30, 2.60]
const FOLLOWUP_AGES := [0.08, 0.15]

var mode := "bench"
var tag := "before"
var enemy_count := 1
var ab := ""
var drive_mode := "auto"
var profile := false

var phase: Phase = Phase.WARMUP
var phase_t := 0.0
var total_t := 0.0
var last_us := 0
var recording := false
var rows: Array[Dictionary] = []

var player: NLBPlayer
var combo: Node
var enemies: Array = []
var controller: NLBMotionSwapController

var hud: Label
var monitor: Label
var phase_label: Label
var hint_label: Label
var hud_layer: CanvasLayer

var press_queue: Array[Dictionary] = []
var active_presses: Array[String] = []
var strike_seen: Dictionary = {}
var hits_seen := 0
var combo_starts_seen := 0
var shot_taken := false
var shot_requested := false
var sequence_start_unix_ms := 0
var sequence_end_unix_ms := 0
var run_wall_start_unix_ms := 0
var phase_marks: Array[Dictionary] = []

var _hud_refresh := 0.0
var _hud_fps_samples: Array[float] = []
var _peak_dt_ms := 0.0
var _peak_phase := ""
var _next_combo_at := 0.0
var _followup_sent: Dictionary = {}
var _combo_count := 0


func _ready() -> void:
	_parse_args()
	_configure_engine()
	_build_room()
	_build_hud()
	if mode == "snap":
		# Freeze the phase timeline: the snap sequence drives present() directly.
		set_process(false)
		_run_snap.call_deferred()
		return
	last_us = Time.get_ticks_usec()
	run_wall_start_unix_ms = int(Time.get_unix_time_from_system() * 1000.0)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	print("[M1FPS] mode=%s tag=%s enemies=%d godot=%s renderer=%s" % [
		mode, tag, enemy_count, Engine.get_version_info().string,
		RenderingServer.get_video_adapter_name()])
	print("[M1FPS] display=%s vsync=%d" % [
		DisplayServer.window_get_size(), DisplayServer.window_get_vsync_mode()])


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			mode = arg.trim_prefix("--mode=")
		elif arg.begins_with("--tag="):
			tag = arg.trim_prefix("--tag=")
		elif arg.begins_with("--enemies="):
			enemy_count = maxi(1, int(arg.trim_prefix("--enemies=")))
		elif arg.begins_with("--ab="):
			ab = arg.trim_prefix("--ab=")
		elif arg.begins_with("--drive="):
			drive_mode = arg.trim_prefix("--drive=")
		elif arg.begins_with("--profile="):
			profile = arg.trim_prefix("--profile=") == "1"
	if mode == "stress":
		enemy_count = 5


func _configure_engine() -> void:
	RenderingServer.set_default_clear_color(Color("222a30"))
	if mode == "bench" or mode == "stress":
		# Uncapped frame rate: wall-clock frame time becomes the real cost signal
		# instead of being quantised to 60/30 by the display refresh.
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		Engine.max_fps = 0
	Engine.physics_ticks_per_second = 60
	if mode == "monitor":
		get_tree().debug_collisions_hint = true


func _build_room() -> void:
	# Static camera, flat floor. Nothing else in the scene.
	var camera := Camera2D.new()
	camera.name = "StaticCamera"
	camera.position = Vector2(640, 360)
	camera.enabled = true
	add_child(camera)

	var ground := StaticBody2D.new()
	ground.name = "Ground"
	ground.collision_layer = 1
	ground.collision_mask = 0
	var ground_shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(4000, 80)
	ground_shape.shape = box
	ground_shape.position = Vector2(640, 600)
	ground.add_child(ground_shape)
	add_child(ground)

	# Flat lab floor visual (no parallax, no scrolling).
	var floor_vis := Polygon2D.new()
	floor_vis.name = "FloorVisual"
	floor_vis.polygon = PackedVector2Array([
		Vector2(0, 560), Vector2(1280, 560), Vector2(1280, 720), Vector2(0, 720)])
	floor_vis.color = Color("2c353b")
	add_child(floor_vis)
	var floor_line := Line2D.new()
	floor_line.name = "FloorLine"
	floor_line.points = PackedVector2Array([Vector2(0, 560), Vector2(1280, 560)])
	floor_line.width = 2.0
	floor_line.default_color = Color("596b6d")
	add_child(floor_line)

	# A wall behind the player stops RUN from leaving the static frame.
	var wall := StaticBody2D.new()
	wall.name = "LeftWall"
	var wall_shape := CollisionShape2D.new()
	var wall_box := RectangleShape2D.new()
	wall_box.size = Vector2(40, 400)
	wall_shape.shape = wall_box
	wall_shape.position = Vector2(120, 400)
	wall.add_child(wall_shape)
	add_child(wall)

	player = PLAYER_SCENE.instantiate()
	player.name = "Player"
	player.movement_preview = true
	player.m1_crowbar_enabled = true
	player.position = Vector2(300, 559)
	add_child(player)
	player.enable_motion_swap()
	combo = player.movement_attack_preview
	combo.hit_confirmed.connect(_on_hit)
	combo.strike_started.connect(_on_strike)
	if profile:
		combo.profile = true

	# Diagnostic A/B switches. These only exist in the lab harness; production
	# defaults are untouched.
	match ab:
		"novfx":
			combo.vfx_enabled = false
		"noimpact":
			if combo.impact_vfx != null:
				combo.impact_vfx.visible = false
		"nohit":
			combo.damage_enabled = false
		"nofeedback":
			combo.feedback_enabled = false
			combo.impact_enabled = false
		"legacy":
			combo.batched_draw = false
	if not ab.is_empty():
		print("[M1FPS] A/B: ", ab)

	controller = CONTROLLER_SCRIPT.new()
	controller.name = "Controller"
	add_child(controller)

	# Keep Iven alive through the whole stress run; the load, not death, is
	# what is being measured.
	if mode == "stress":
		player.health.max_hp = 999
		player.health.hp = 999

	_spawn_enemies()


func _spawn_enemies() -> void:
	var offsets := [30.0]
	if enemy_count >= 5:
		offsets = [-86.0, -60.0, 22.0, 48.0, 74.0]
	for i in enemy_count:
		var enemy := PATROL_SCENE.instantiate()
		enemy.name = "Dummy%d" % i
		enemy.position = player.position + Vector2(offsets[i % offsets.size()], 0)
		enemy.hp = 999
		enemy.speed = 0.0
		add_child(enemy)
		# The dummy's body never blocks Iven (lab fixture); its HurtBox on layer
		# 32 and its TouchHitBox on layer 64 keep working exactly as production.
		enemy.collision_layer = 0
		enemy.collision_mask = 1
		enemy.configure_patrol(-100000, 100000)
		enemy.set_meta("lab_offset", float(offsets[i % offsets.size()]))
		enemy.health.max_hp = 999
		enemy.health.hp = 999
		enemies.append(enemy)


func _set_enemies_active(active: bool) -> void:
	for enemy in enemies:
		enemy.visible = active
		enemy.set_physics_process(active)
		if active:
			enemy.global_position = player.global_position + Vector2(float(enemy.get_meta("lab_offset", 30.0)), 0)
			enemy.velocity = Vector2.ZERO
		else:
			enemy.global_position = Vector2(-600, 559)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "PerfHUD"
	layer.layer = 100
	add_child(layer)
	hud_layer = layer

	# FPS / frame-time overlay (the deliverable's visible measurement).
	hud = Label.new()
	hud.name = "FPSOverlay"
	hud.position = Vector2(14, 10)
	hud.add_theme_font_size_override("font_size", 22)
	hud.add_theme_color_override("font_color", Color("eaf4ef"))
	hud.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	hud.add_theme_constant_override("shadow_offset_x", 2)
	hud.add_theme_constant_override("shadow_offset_y", 2)
	hud.add_theme_constant_override("outline_size", 4)
	hud.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	layer.add_child(hud)

	# Godot Monitor panel equivalent, live at runtime.
	monitor = Label.new()
	monitor.name = "Monitors"
	monitor.position = Vector2(14, 120)
	monitor.add_theme_font_size_override("font_size", 15)
	monitor.add_theme_color_override("font_color", Color("9fd6c8"))
	monitor.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	monitor.add_theme_constant_override("shadow_offset_x", 1)
	monitor.add_theme_constant_override("shadow_offset_y", 1)
	layer.add_child(monitor)

	phase_label = Label.new()
	phase_label.name = "Phase"
	phase_label.position = Vector2(14, 660)
	phase_label.add_theme_font_size_override("font_size", 26)
	phase_label.add_theme_color_override("font_color", Color("ffcf8a"))
	phase_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	phase_label.add_theme_constant_override("outline_size", 5)
	layer.add_child(phase_label)

	hint_label = Label.new()
	hint_label.name = "Hint"
	hint_label.position = Vector2(880, 12)
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color("b9c7c3"))
	layer.add_child(hint_label)
	var noun := "dummy" if enemy_count == 1 else "dummies"
	hint_label.text = "M1 FPS LAB\nstatic camera / flat floor\n%d %s at melee range" % [enemy_count, noun]


func _on_strike(index: int, _id: String) -> void:
	combo_starts_seen += 1
	strike_seen[index + 1] = int(strike_seen.get(index + 1, 0)) + 1
	# Chain the next strike with a fresh edge inside the authored buffer window,
	# exactly as a player pressing on the beat would.
	if phase == Phase.M1 and drive_mode == "input" and index < 2:
		press_queue.append({"action": "attack", "at": phase_t + float(FOLLOWUP_AGES[index]) + 0.05})


func _on_hit(_event: Dictionary) -> void:
	hits_seen += 1


func _physics_process(delta: float) -> void:
	# Real input edges through the same Input singleton the game uses.
	for action in active_presses:
		Input.action_release(action)
	active_presses.clear()
	if drive_mode == "auto":
		# Stray OS mouse/key events must not start an extra combo in the
		# deterministic benchmark.
		Input.action_release("attack")
		Input.action_release("swap_select")

	if phase == Phase.RUN:
		# Shuttle inside the static frame: 0.75 s legs return Iven to the start.
		var leg := int(phase_t / 0.75)
		if leg % 2 == 0:
			Input.action_press("move_right")
			Input.action_release("move_left")
		else:
			Input.action_press("move_left")
			Input.action_release("move_right")
	else:
		Input.action_release("move_right")
		Input.action_release("move_left")

	if phase == Phase.M1:
		if drive_mode == "auto":
			_drive_auto()
		else:
			_schedule_presses(delta)


## Deterministic combo driver. It calls the SAME production _start()/present()/
## hitbox path; it only replaces the physical input edge so a 250 ms stall
## cannot silently drop the buffered follow-up and change the measured load.
func _drive_auto() -> void:
	if not combo.busy():
		if _combo_count < 3 and phase_t >= _next_combo_at:
			combo._start(0, player.facing)
			_combo_count += 1
			_next_combo_at = phase_t + 1.25
			_followup_sent.clear()
		return
	var idx := int(combo.get("index"))
	if idx < 2:
		var id := String(combo.get("attack_instance_id"))
		if not _followup_sent.has(id) and float(combo.get("age")) >= float(FOLLOWUP_AGES[idx]):
			combo.pending = float(combo.get("buffer_seconds"))
			_followup_sent[id] = true


func _schedule_presses(_delta: float) -> void:
	var due := -1
	for i in press_queue.size():
		if phase_t >= float(press_queue[i]["at"]):
			due = i
			break
	if due < 0:
		return
	var action := String(press_queue[due]["action"])
	press_queue.remove_at(due)
	Input.action_press(action)
	active_presses.append(action)
	print("[M1FPS] press %s at t=%.3f combo=%d age=%.3f pending=%.3f" % [
		action, phase_t, int(combo.get("index")), float(combo.get("age")), float(combo.get("pending"))])


func _process(delta: float) -> void:
	var now := Time.get_ticks_usec()
	var dt_ms := float(now - last_us) / 1000.0
	last_us = now
	total_t += delta
	phase_t += delta

	if dt_ms > _peak_dt_ms and phase >= Phase.IDLE and phase <= Phase.M1:
		_peak_dt_ms = dt_ms
		_peak_phase = PHASE_NAMES[phase]

	if recording:
		_capture_row(dt_ms)

	_advance_phase()
	_update_hud(delta)

	if (mode == "record" or mode == "monitor") and phase == Phase.M1 and not shot_requested:
		if _ribbon_tris() >= 200 or phase_t >= 3.5:
			shot_requested = true
	if shot_requested and not shot_taken:
		shot_taken = true
		_save_screenshot()


func _advance_phase() -> void:
	var limit := 0.0
	match phase:
		Phase.WARMUP: limit = WARMUP_SECONDS
		Phase.IDLE: limit = IDLE_SECONDS
		Phase.RUN: limit = RUN_SECONDS
		Phase.M1: limit = M1_SECONDS
		Phase.DONE: limit = DONE_SECONDS
	if phase_t < limit:
		return
	if phase == Phase.DONE:
		if not recording:
			_finish()
		return
	phase_t = 0.0
	var previous := phase
	_peak_dt_ms = 0.0
	_peak_phase = ""
	phase = (phase + 1) as Phase
	phase_marks.append({"phase": PHASE_NAMES[phase], "t": total_t, "unix_ms": int(Time.get_unix_time_from_system() * 1000.0)})
	if phase == Phase.RUN:
		_set_enemies_active(false)
	if phase == Phase.IDLE:
		_set_enemies_active(true)
		recording = true
		sequence_start_unix_ms = int(Time.get_unix_time_from_system() * 1000.0)
		phase_marks[-1]["sequence_start"] = true
		print("[M1FPS] SEQUENCE START (IDLE)")
	if phase == Phase.M1:
		_set_enemies_active(true)
		player.facing = 1
		player.velocity = Vector2.ZERO
		_combo_count = 0
		_next_combo_at = 0.0
		_followup_sent.clear()
		if drive_mode == "input":
			for start in COMBO_STARTS:
				press_queue.append({"action": "attack", "at": float(start)})
		# One profiler screenshot at the peak of the first combo's ribbon, with a
		# time fallback in case a stall skips the dense frames.
		if mode == "monitor" or mode == "record":
			shot_requested = false
	if phase == Phase.DONE:
		recording = false
		sequence_end_unix_ms = int(Time.get_unix_time_from_system() * 1000.0)
		print("[M1FPS] SEQUENCE END: idle=%s run=%s m1=%s hits=%d strikes=%s" % [
			_phase_stat("IDLE"), _phase_stat("RUN"), _phase_stat("M1"),
			hits_seen, str(strike_seen)])
		if mode == "bench" or mode == "stress":
			_finish()
	if previous == Phase.M1 and phase == Phase.DONE:
		Input.action_release("move_right")


func _capture_row(dt_ms: float) -> void:
	var tris := 0
	var layers: Variant = combo.get("drawn_layers")
	if layers is Array:
		for layer in layers:
			tris += int(layer.tri_count)
	rows.append({
		"phase": PHASE_NAMES[phase],
		"t": total_t,
		"dt_ms": dt_ms,
		"fps": Engine.get_frames_per_second(),
		"proc_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"phys_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"draws": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"prims": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"canvas_items": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"vram": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
		"ribbon_tris": tris,
		"build_ms": float(combo.get("build_us")) / 1000.0,
		"draw_ms": float(combo.get("draw_us")) / 1000.0,
		"px": player.global_position.x,
		"vx": player.velocity.x,
		"vis_state": String(player.movement_visual.state),
		"combo_index": int(combo.get("index")),
		"combo_age": float(combo.get("age")),
		"busy": bool(combo.busy()),
	})


func _update_hud(delta: float) -> void:
	_hud_refresh -= delta
	if _hud_refresh > 0.0:
		return
	_hud_refresh = 0.1
	var fps := Engine.get_frames_per_second()
	var frame_ms := 1000.0 / maxf(1.0, fps)
	hud.text = "FPS: %d\nFrame: %.2f ms\nPeak: %.1f ms (%s)" % [fps, frame_ms, _peak_dt_ms, _peak_phase]
	monitor.text = "GODOT MONITORS (live)\nProcess:  %.2f ms\nPhysics:  %.2f ms\nDraw calls: %d\nCanvas items: %d\nNodes: %d\nObjects: %d\nVideo RAM: %.1f MB\nM1 ribbon tris: %d\nHits: %d  Strikes: %s" % [
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		_ribbon_tris(), hits_seen, str(strike_seen)]
	var names := ["WARMUP", "IDLE", "RUN", "M1 COMBO", "DONE"]
	var remain := 0.0
	match phase:
		Phase.WARMUP: remain = WARMUP_SECONDS - phase_t
		Phase.IDLE: remain = IDLE_SECONDS - phase_t
		Phase.RUN: remain = RUN_SECONDS - phase_t
		Phase.M1: remain = M1_SECONDS - phase_t
		Phase.DONE: remain = DONE_SECONDS - phase_t
	phase_label.text = "%s   %.1f s" % [names[phase], maxf(0.0, remain)]
	if phase == Phase.M1:
		phase_label.text += "   | combo %d  hits %d  tris %d" % [
			maxi(0, int(combo.get("index")) + 1), hits_seen, _ribbon_tris()]


func _ribbon_tris() -> int:
	var total := 0
	var layers: Variant = combo.get("drawn_layers")
	if layers is Array:
		for layer in layers:
			total += int(layer.tri_count)
	return total


func _save_screenshot() -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "%s/M1_MONITOR_%s.png" % [OUT_DIR, tag.to_upper()]
	image.save_png(ProjectSettings.globalize_path(path))
	print("[M1FPS] saved screenshot ", path, " ", image.get_size())


## Deterministic pose snapshots for pixel-level before/after comparison.
## Physics is frozen and the production present()/_draw path is stepped through
## the authored samples, so BEFORE and AFTER use identical geometry and timing.
func _run_snap() -> void:
	hud_layer.visible = false
	player.set_physics_process(false)
	combo.set_physics_process(false)
	controller.set_physics_process(false)
	# Snapshot comparison must isolate the ribbon draw path: no hit knockback or
	# impact FX may move the dummy between the two authored poses.
	combo.damage_enabled = false
	if is_instance_valid(combo.impact_vfx):
		combo.impact_vfx.visible = false
	for enemy in enemies:
		enemy.set_physics_process(false)
	if not enemies.is_empty():
		enemies[0].global_position = player.global_position + Vector2(55, 0)
	await get_tree().process_frame
	await _snap_strike(1, 9, "strike2")
	await _snap_strike(2, 20, "strike3")
	get_tree().quit()


func _snap_strike(index: int, last_sample: int, label: String) -> void:
	combo.reset()
	combo._start(index, 1)
	player.facing = 1
	var cfg: Dictionary = combo.metadata.configs[index]
	for sample in range(0, last_sample + 1):
		combo.age = float(cfg.times[sample])
		combo.present()
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "%s/SNAP_%s_%s.png" % [OUT_DIR, label, tag]
	image.save_png(ProjectSettings.globalize_path(path))
	print("[M1FPS] snap ", path, " tris=", _ribbon_tris())


func _phase_stat(name: String) -> String:
	var values: Array[float] = []
	for row in rows:
		if row.phase == name:
			values.append(row.dt_ms)
	if values.is_empty():
		return "-"
	values.sort()
	var sum := 0.0
	for v in values:
		sum += v
	var avg := sum / values.size()
	return "avg %.2f ms (%.1f fps) min %.1f fps max %.2f ms n=%d" % [
		avg, 1000.0 / maxf(0.001, avg), 1000.0 / maxf(0.001, values[-1]), values[-1], values.size()]


func _finish() -> void:
	if not recording:
		_write_json()
		get_tree().quit()


func _write_json() -> void:
	var path := "%s/%s_%s.json" % [OUT_DIR, mode, tag]
	var payload := {
		"mode": mode,
		"tag": tag,
		"godot": Engine.get_version_info().string,
		"renderer": RenderingServer.get_video_adapter_name(),
		"window": DisplayServer.window_get_size(),
		"refresh": DisplayServer.screen_get_refresh_rate(),
		"enemies": enemy_count,
		"hits": hits_seen,
		"strikes": strike_seen,
		"combo_starts": combo_starts_seen,
		"combo_events": combo.get("events"),
		"peak_dt_ms": _peak_dt_ms,
		"peak_phase": _peak_phase,
		"sequence_start_unix_ms": sequence_start_unix_ms,
		"sequence_end_unix_ms": sequence_end_unix_ms,
		"run_wall_start_unix_ms": run_wall_start_unix_ms,
		"phase_marks": phase_marks,
		"rows": rows,
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	print("[M1FPS] wrote ", path, " rows=", rows.size())
