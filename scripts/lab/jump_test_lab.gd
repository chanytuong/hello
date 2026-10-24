extends Node2D
## IVEN jump redesign lab / 82x82 native, 30 fps art, 60 Hz physics.
##
## This is a REVIEW RIG, not production code.  It reproduces the jump physics
## from scripts/player.gd verbatim (jump_velocity -640, rise gravity 1600,
## fall multiplier 1.8) and drives the authored 30-frame IVEN_JUMP clip with the
## same 0.100 s / 0.700 s / 0.200 s contract used by the sprite sheet:
##   f01-f03  anticipation pre-roll (lab-only, shown before physics launch)
##   f04-f24  21 airborne frames (0.700 s)
##   f25      contact
##   f25-f30  recovery to READY
##
## Land -> RUN uses the existing approved RUN clips from body_frames.tres so the
## cut can be judged against the current game.  Left-facing art is the same
## 30-frame clip mirrored at the pivot, matching player.gd's facing rule.
##
## Run:   godot --path . --scene res://scripts/lab/jump_test_scene.tscn
## Movie: godot --path . --scene ... --fixed-fps 60 --write-movie out.avi -- --auto

const SHEET_R := preload("res://art/iven/jump_v01/IVEN_JUMP_SHEET.png")
const SHEET_L := preload("res://art/iven/jump_v01/IVEN_JUMP_SHEET_LEFT.png")
const BODY_FRAMES := preload("res://art/iven/movement/body_frames.tres")
const UI_FONT := preload("res://art/iven/jump_v01/Roboto-Regular.ttf")
const FLAME_SCRIPT := preload("res://scripts/iven_flame.gd")

const CELL := 82
const CLIP_FRAMES := 30
const ART_FPS := 30.0
const PIVOT := Vector2(40.499926203, 75.579576591)
const FOOT_JUMP := 77.0
const FOOT_GROUND := 75.0

const FLOOR_Y := 224.0
const WORLD_W := 900.0
const VIEW_W := 1280.0
const VIEW_H := 720.0
const WORLD_SCALE := 3.0
## The 82 px art is authored for a 600 px game floor, but the lab enlarges the
## world 3x to judge native pixels. A 0.75 camera zoom keeps the 368 px jump
## apex and the floor inside the 48..620 px stage band (the HUD owns the rest).
const CAM_ZOOM := 0.75
const CAM_Y := 382.0
const CAM_HALF_W := 640.0 / CAM_ZOOM
const CAM_MIN_X := CAM_HALF_W
const CAM_MAX_X := WORLD_W * WORLD_SCALE - CAM_HALF_W

const RUN_SPEED := 280.0
const ACCEL := 2600.0
const DECEL := 3200.0
const REVERSE_ACCEL := 4200.0
const JUMP_VELOCITY := -640.0
const RISE_GRAVITY := 1600.0
const FALL_GRAVITY := 2880.0
const PRE_ROLL := 3.0 / ART_FPS
const AIR_TIME := 0.700
const RECOVERY := 6.0 / ART_FPS

const INK := Color("#e9eff7")
const MUTED := Color("#8f9db2")
const DIM := Color("#5d6a7e")
const ACCENT := Color("#ffb35c")
const CYAN := Color("#7fd4e8")
const GREEN := Color("#8bd49c")
const RED := Color("#e2777f")
const PANEL := Color(0.047, 0.063, 0.090, 0.90)
const LINE := Color("#2a3648")

const PHASES := [
	[1, 2, "READY", Color("#5d6d83")],
	[3, 3, "ANTICIPATION", Color("#b18a5a")],
	[4, 4, "PUSH", Color("#d9a441")],
	[5, 8, "STRETCH", Color("#7fd4e8")],
	[9, 11, "TUCK", Color("#6aa9d8")],
	[12, 15, "RISE", Color("#74c7c9")],
	[16, 18, "APEX", Color("#ffd166")],
	[19, 22, "FALL", Color("#7f9bd1")],
	[23, 24, "REACH", Color("#9b8ad6")],
	[25, 25, "CONTACT", Color("#e2777f")],
	[26, 27, "COMPRESSION", Color("#c95f68")],
	[28, 30, "RECOVER", Color("#8bd49c")],
]

const SHOTS := [
	{
		"title": "STANDING JUMP → RUN",
		"sub": "one launch  ·  land at f25  ·  recovery → existing RUN",
		"duration": 3.0,
		"start_x": 80.0,
		"face": 1,
		"events": [[0.30, "run"], [0.60, "prejump"], [2.30, "stop"]],
	},
	{
		"title": "CHAIN JUMP",
		"sub": "land · recover · 0.10 s pre-roll · two launches",
		"duration": 3.6,
		"start_x": 150.0,
		"face": 1,
		"events": [[0.20, "run"], [0.45, "prejump"], [1.43, "prejump"], [2.65, "stop"]],
	},
	{
		"title": "LEFT-FACING JUMP",
		"sub": "same clip, mirrored at the pivot  ·  land → RUN left",
		"duration": 3.2,
		"start_x": 760.0,
		"face": -1,
		"events": [[0.35, "run"], [0.65, "prejump"], [2.30, "stop"]],
	},
]

var phase := "INTRO"
var phase_t := 0.0
var demo_t := 0.0
var shot := 0
var shot_t := 0.0
var event_i := 0

var x := 80.0
var y := 0.0
var vx := 0.0
var vy := 0.0
var facing := 1
var on_floor := true
var mode := "IDLE"
var input_dir := 0.0
var jump_frame := 0
var pre_roll_t := 0.0
var air_t := 0.0
var recovery_t := 0.0
var run_time := 0.0
var jump_queued := false
var launch_count := 0
var apex_recorded := false
var apex_height := 0.0
var apex_time := 0.0

var auto := false
var trace: Array[Dictionary] = []
var trace_written := false
var rng := RandomNumberGenerator.new()

var world: Node2D
var camera: Camera2D
var body: Sprite2D
var flame: Node2D
var shadow: Node2D
var dust: Node2D
var motes: Node2D
var timeline: Control
var fade: ColorRect
var intro_root: Control
var outro_dim: ColorRect
var outro_panel: Panel
var callout: Label

var shot_beat: Label
var shot_title: Label
var shot_sub: Label
var launch_label: Label
var diag_frame: Label
var diag_phase: Label
var diag_facing: Label
var diag_vy: Label
var diag_height: Label
var diag_clip: Label

var jump_r: Array[Texture2D] = []
var jump_l: Array[Texture2D] = []
var anchors_ground: Dictionary = {}
var anchors_jump: Dictionary = {}


class Backdrop extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		var w := 1280.0
		var h := 720.0
		for i in 32:
			var t := float(i) / 31.0
			var c := Color("#080c14").lerp(Color("#1b2634"), t)
			draw_rect(Rect2(0, h * t, w, h / 31.0 + 1.0), c)
		# low moon / cold key light
		draw_circle(Vector2(934, 164), 104, Color(0.56, 0.74, 0.88, 0.035))
		draw_circle(Vector2(934, 164), 74, Color(0.62, 0.80, 0.92, 0.055))
		draw_circle(Vector2(934, 164), 43, Color(0.76, 0.87, 0.95, 0.075))
		# ruined far silhouette
		var xs := [-20.0, 64.0, 150.0, 232.0, 322.0, 408.0, 506.0, 596.0, 702.0, 792.0, 886.0, 982.0, 1080.0, 1180.0, 1260.0]
		var hs := [150.0, 232.0, 188.0, 288.0, 210.0, 258.0, 174.0, 310.0, 196.0, 246.0, 166.0, 276.0, 204.0, 238.0, 186.0]
		for i in xs.size():
			var ww := 54.0 + float((i * 37) % 46)
			var hh: float = float(hs[i])
			draw_rect(Rect2(xs[i], h - hh, ww, hh), Color(0.055, 0.078, 0.110, 0.88))
			draw_rect(Rect2(xs[i] + 5, h - hh + 8, 2, hh - 8), Color(0.10, 0.13, 0.17, 0.35))
			draw_rect(Rect2(xs[i] + ww - 8, h - hh + 22, 2, hh - 22), Color(0.10, 0.13, 0.17, 0.25))
		# low fog banks
		for i in 5:
			var fy := 574.0 + i * 26.0
			draw_rect(Rect2(0, fy, w, 22), Color(0.30, 0.40, 0.52, 0.018 + i * 0.008))
		# vignette blocks
		draw_rect(Rect2(0, 0, w, 46), Color(0.01, 0.015, 0.025, 0.35))
		draw_rect(Rect2(0, h - 112, w, 112), Color(0.01, 0.015, 0.025, 0.30))


class Ground extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0, 224, 900, 40), Color("#0e1520"))
		draw_rect(Rect2(0, 224, 900, 2), Color("#4a5a70"))
		draw_rect(Rect2(0, 226, 900, 1), Color("#2a3748"))
		draw_rect(Rect2(0, 227, 900, 2), Color("#16202c"))
		for i in 38:
			var gx := float(i) * 24.0
			draw_line(Vector2(gx, 228), Vector2(gx, 258), Color(0.18, 0.23, 0.30, 0.28), 1.0)
		for i in 14:
			var cx := 18.0 + float(i) * 63.0
			draw_line(Vector2(cx, 225), Vector2(cx + 7, 230), Color("#6d7e94"), 1.0)
			draw_line(Vector2(cx + 7, 230), Vector2(cx + 9, 234), Color(0.20, 0.26, 0.33, 0.75), 1.0)
		for i in 9:
			var px := 34.0 + float(i) * 97.0
			draw_rect(Rect2(px, 221, 3, 3), Color(0.36, 0.42, 0.50, 0.55))
		# foreground lip
		draw_rect(Rect2(0, 260, 900, 3), Color(0.03, 0.045, 0.065, 0.9))


class Motes extends Node2D:
	var pts: Array[Vector3] = []
	func _ready() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = 4411
		for i in 46:
			pts.append(Vector3(r.randf_range(0, 900), r.randf_range(40, 218), r.randf_range(0, TAU)))
		z_index = -1
	func _process(dt: float) -> void:
		for i in pts.size():
			var q: Vector3 = pts[i]
			q.z += dt * (0.25 + 0.2 * float(i % 3))
			pts[i] = q
		queue_redraw()
	func _draw() -> void:
		for i in pts.size():
			var p := pts[i]
			var dx := sin(p.z) * 3.0
			var dy := cos(p.z * 0.7) * 2.0
			var a := 0.10 + 0.10 * (0.5 + 0.5 * sin(p.z * 1.7))
			draw_rect(Rect2(p.x + dx, p.y + dy, 1.4, 1.4), Color(0.65, 0.80, 0.92, a))


class Shadow extends Node2D:
	var strength := 1.0
	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * float(i) / 24.0
			pts.append(Vector2(cos(a) * 15.0, sin(a) * 4.2))
		draw_colored_polygon(pts, Color(0, 0, 0, 0.42 * strength))


class DustFX extends Node2D:
	var puffs: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	func burst(at: Vector2, dir: float, count: int, power := 1.0) -> void:
		for i in count:
			var vx0 := rng.randf_range(-52.0, 52.0) + dir * rng.randf_range(8.0, 44.0)
			var vy0 := rng.randf_range(-58.0, -10.0) * power
			puffs.append({
				"p": at + Vector2(rng.randf_range(-7.0, 7.0), rng.randf_range(-2.0, 1.0)),
				"v": Vector2(vx0, vy0),
				"life": rng.randf_range(0.26, 0.52),
				"t": 0.0,
				"s": rng.randf_range(1.0, 2.6),
			})
	func _process(dt: float) -> void:
		for p in puffs:
			p.t += dt
			p.p += p.v * dt
			p.v.y += 90.0 * dt
			p.v.x *= 0.985
		puffs = puffs.filter(func(p): return p.t < p.life)
		queue_redraw()
	func _draw() -> void:
		for p in puffs:
			var k: float = 1.0 - p.t / p.life
			draw_rect(Rect2(p.p, Vector2(p.s, p.s)), Color(0.64, 0.72, 0.82, 0.30 * k))


class PhaseTimeline extends Control:
	var current := -1
	var active := false
	var font: Font
	var facing_left := false
	const PITCH := 24.0
	const CW := 22.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func phase_color(f: int) -> Color:
		var table := [
			[1, 2, Color("#5d6d83")], [3, 3, Color("#b18a5a")], [4, 4, Color("#d9a441")],
			[5, 8, Color("#7fd4e8")], [9, 11, Color("#6aa9d8")], [12, 15, Color("#74c7c9")],
			[16, 18, Color("#ffd166")], [19, 22, Color("#7f9bd1")], [23, 24, Color("#9b8ad6")],
			[25, 25, Color("#e2777f")], [26, 27, Color("#c95f68")], [28, 30, Color("#8bd49c")],
		]
		for row in table:
			if f >= row[0] and f <= row[1]:
				return row[2]
		return Color("#5d6d83")

	func _draw() -> void:
		var y := 10.0
		for i in 30:
			var f := i + 1
			var c := phase_color(f)
			c.a = 0.95 if active else 0.20
			draw_rect(Rect2(i * PITCH, y, CW, 13), c)
			if active and i == current:
				draw_rect(Rect2(i * PITCH - 1, y - 2, CW + 2, 17), Color(0.96, 0.98, 1.0, 0.95), false, 1.4)
		# phase labels above
		draw_string(font, Vector2(0, 8), "PRE 0.10 s", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#8f9db2"))
		draw_string(font, Vector2(74, 8), "AIRBORNE 0.70 s", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#8f9db2"))
		draw_string(font, Vector2(570, 8), "RECOVERY 0.20 s", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#8f9db2"))
		# markers
		for m in [[3, "f04 LAUNCH"], [15, "f16 APEX"], [24, "f25 CONTACT"]]:
			var mx: float = m[0] * PITCH + CW * 0.5
			draw_line(Vector2(mx, 25), Vector2(mx, 33), Color(0.75, 0.82, 0.92, 0.55), 1.0)
			draw_string(font, Vector2(mx - 16, 45), m[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#77869c"))
		draw_string(font, Vector2(0, 45), "f01", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#77869c"))
		draw_string(font, Vector2(30 * PITCH - 22, 45), "f30", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#77869c"))


func _ready() -> void:
	auto = OS.get_cmdline_user_args().has("--auto") or OS.get_cmdline_args().has("--auto")
	rng.seed = 20261023
	_build_assets()
	_build_world()
	_build_hud()
	_reset_demo()
	print("JUMP_LAB ready auto=", auto, " sheet=", SHEET_R.get_size(), " left=", SHEET_L.get_size())


func _build_assets() -> void:
	for i in CLIP_FRAMES:
		var ar := AtlasTexture.new()
		ar.atlas = SHEET_R
		ar.region = Rect2(i * CELL, 0, CELL, CELL)
		jump_r.append(ar)
		var al := AtlasTexture.new()
		al.atlas = SHEET_L
		al.region = Rect2(i * CELL, 0, CELL, CELL)
		jump_l.append(al)
	anchors_ground = JSON.parse_string(FileAccess.get_file_as_string("res://art/iven/movement/anchors.json"))
	anchors_jump = JSON.parse_string(FileAccess.get_file_as_string("res://art/iven/jump_v01/jump_anchors.json"))


func _build_world() -> void:
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)
	var backdrop := Backdrop.new()
	bg_layer.add_child(backdrop)

	world = Node2D.new()
	world.name = "World"
	world.scale = Vector2(WORLD_SCALE, WORLD_SCALE)
	add_child(world)

	world.add_child(Ground.new())

	motes = Motes.new()
	motes.name = "Motes"
	world.add_child(motes)

	shadow = Shadow.new()
	shadow.name = "Shadow"
	world.add_child(shadow)

	var player := Node2D.new()
	player.name = "PlayerVisual"
	world.add_child(player)

	body = Sprite2D.new()
	body.name = "Body"
	body.centered = false
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player.add_child(body)

	flame = FLAME_SCRIPT.new()
	flame.name = "FlameHead"
	player.add_child(flame)

	dust = DustFX.new()
	dust.name = "Dust"
	world.add_child(dust)

	camera = Camera2D.new()
	camera.name = "LabCamera"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.zoom = Vector2(CAM_ZOOM, CAM_ZOOM)
	# Limits are world-space extents; Camera2D subtracts the zoomed viewport
	# half-size itself. The built corridor is 2700 x 720 native-scaled pixels.
	camera.limit_left = 0
	camera.limit_right = int(WORLD_W * WORLD_SCALE)
	camera.limit_top = -600
	camera.limit_bottom = 1200
	camera.position = Vector2(CAM_MIN_X, CAM_Y)
	add_child(camera)
	camera.make_current()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	# top / bottom bars
	_bar(root, Rect2(0, 0, 1280, 48), Color(0.020, 0.028, 0.043, 0.88))
	_bar(root, Rect2(0, 48, 1280, 1), LINE)
	_bar(root, Rect2(0, 620, 1280, 100), Color(0.018, 0.025, 0.038, 0.94))
	_bar(root, Rect2(0, 620, 1280, 1), LINE)

	_label(root, "IVEN / JUMP v01", Vector2(36, 14), 15, INK)
	_label(root, "REDESIGN LAB", Vector2(192, 16), 10, ACCENT)
	_label(root, "82×82 NATIVE   ·   30 FPS ART   ·   60 Hz PHYSICS   ·   PALETTE B", Vector2(826, 16), 10, MUTED)
	_label(root, "LOCKED", Vector2(1190, 16), 10, GREEN)

	# shot panel
	_bar(root, Rect2(36, 66, 452, 92), Color(0.035, 0.048, 0.068, 0.62))
	_bar(root, Rect2(36, 66, 3, 92), ACCENT)
	shot_beat = _label(root, "BEAT 01 / 03", Vector2(52, 76), 10, ACCENT)
	shot_title = _label(root, "STANDING JUMP → RUN", Vector2(52, 94), 24, INK)
	shot_sub = _label(root, "one launch  ·  land at f25  ·  recovery → existing RUN", Vector2(52, 127), 10, MUTED)
	launch_label = _label(root, "LAUNCH 0 / 4", Vector2(1120, 76), 11, MUTED)
	_label(root, "beat 2 = chain (two launches)", Vector2(1080, 94), 9, DIM)

	# diagnostics
	var dp := Panel.new()
	dp.position = Vector2(996, 138)
	dp.size = Vector2(248, 172)
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL
	sb.border_color = LINE
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	dp.add_theme_stylebox_override("panel", sb)
	root.add_child(dp)
	_label(dp, "LIVE SAMPLE", Vector2(14, 10), 9, ACCENT)
	_label(dp, "60 Hz SIM / 30 FPS ART", Vector2(14, 24), 8, DIM)
	_diag_row(dp, "FRAME", 48)
	diag_frame = _diag_value(dp, 48)
	_diag_row(dp, "PHASE", 68)
	diag_phase = _diag_value(dp, 68)
	_diag_row(dp, "FACING", 88)
	diag_facing = _diag_value(dp, 88)
	_diag_row(dp, "VY", 108)
	diag_vy = _diag_value(dp, 108)
	_diag_row(dp, "HEIGHT", 128)
	diag_height = _diag_value(dp, 128)
	_diag_row(dp, "CLIP", 148)
	diag_clip = _diag_value(dp, 148)

	# bottom labels
	_label(root, "CLIP TIMELINE", Vector2(36, 640), 10, ACCENT)
	_label(root, "30 frames  ·  1.000 s  ·  f01 = f30", Vector2(36, 658), 9, MUTED)
	_label(root, "LAB PRE-ROLL 0.100 s", Vector2(1016, 640), 9, MUTED)
	_label(root, "PHYSICS  −640 / 1600 / ×1.8", Vector2(1016, 656), 9, MUTED)
	_label(root, "SOURCE  scripts/player.gd", Vector2(1016, 672), 9, DIM)

	timeline = PhaseTimeline.new()
	timeline.name = "Timeline"
	timeline.position = Vector2(280, 646)
	timeline.size = Vector2(720, 54)
	timeline.font = UI_FONT
	root.add_child(timeline)

	callout = _label(root, "", Vector2(0, 0), 10, CYAN)
	callout.size = Vector2(200, 16)
	callout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# intro overlay
	intro_root = Control.new()
	intro_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(intro_root)
	_bar(intro_root, Rect2(452, 190, 2, 226), ACCENT)
	_label(intro_root, "JUMP", Vector2(474, 176), 78, INK)
	_label(intro_root, "V01", Vector2(478, 262), 28, ACCENT)
	_label(intro_root, "A four-phase jump on the locked AccuRIG.", Vector2(478, 314), 17, INK)
	_label(intro_root, "30 FRAMES   ·   21 AIRBORNE   ·   0.700 s   ·   82×82", Vector2(478, 344), 10, MUTED)
	_bar(intro_root, Rect2(478, 370, 430, 1), LINE)
	_label(intro_root, "review lab  ·  3-frame pre-roll is shown before physics launch", Vector2(478, 382), 9, DIM)

	# outro
	outro_dim = ColorRect.new()
	outro_dim.color = Color(0.015, 0.020, 0.030, 0.0)
	outro_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outro_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(outro_dim)
	outro_panel = Panel.new()
	outro_panel.position = Vector2(250, 200)
	outro_panel.size = Vector2(780, 320)
	outro_panel.modulate = Color(1, 1, 1, 0)
	var osb := StyleBoxFlat.new()
	osb.bg_color = Color(0.043, 0.058, 0.080, 0.98)
	osb.border_color = Color("#3a4a60")
	osb.set_border_width_all(1)
	osb.set_corner_radius_all(3)
	outro_panel.add_theme_stylebox_override("panel", osb)
	root.add_child(outro_panel)
	_label(outro_panel, "END OF CAPTURE  /  JUMP v01", Vector2(32, 24), 10, ACCENT)
	_label(outro_panel, "THREE JUMP BEATS.  TWO FACINGS.", Vector2(32, 46), 27, INK)
	_label(outro_panel, "01   standing jump  →  land  →  RUN", Vector2(34, 96), 13, INK)
	_label(outro_panel, "02   chain jump: land  →  0.10 s pre-roll  →  launch  →  land  →  RUN", Vector2(34, 120), 13, INK)
	_label(outro_panel, "03   left-facing jump: same clip, mirrored at the pivot", Vector2(34, 144), 13, INK)
	_bar(outro_panel, Rect2(34, 174, 712, 1), LINE)
	_label(outro_panel, "f04 launch   ·   f16 apex   ·   f25 contact   ·   measured apex 122.7 px   ·   0.700 s airtime", Vector2(34, 188), 10, MUTED)
	_label(outro_panel, "TECHNICAL PASS   ·   VISUAL PASS (SELF-REVIEW)   ·   HUMAN SIGN-OFF RECOMMENDED", Vector2(34, 218), 12, ACCENT)
	_label(outro_panel, "chain beat contains two launches  ·  four launches total", Vector2(34, 248), 9, DIM)
	_label(outro_panel, "source: IVEN_JUMP_V01.blend  ·  IVEN_JUMP_SHEET.png  ·  scripts/player.gd", Vector2(34, 274), 9, DIM)

	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade)


func _bar(parent: Node, rect: Rect2, color: Color) -> void:
	var c := ColorRect.new()
	c.position = rect.position
	c.size = rect.size
	c.color = color
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)


func _label(parent: Node, text: String, pos: Vector2, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", ThemeDB.fallback_font if OS.get_cmdline_user_args().has("--defaultfont") else UI_FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _diag_row(parent: Node, name: String, y: int) -> void:
	_label(parent, name, Vector2(14, y), 9, DIM)


func _diag_value(parent: Node, y: int) -> Label:
	var l := _label(parent, "—", Vector2(118, y - 1), 11, INK)
	l.size = Vector2(112, 16)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return l


func _reset_demo() -> void:
	phase = "INTRO"
	phase_t = 0.0
	demo_t = 0.0
	shot = 0
	shot_t = 0.0
	event_i = 0
	jump_queued = false
	launch_count = 0
	apex_recorded = false
	trace.clear()
	trace_written = false
	x = 80.0
	y = 0.0
	vx = 0.0
	vy = 0.0
	facing = 1
	on_floor = true
	mode = "IDLE"
	input_dir = 0.0
	jump_frame = 0
	pre_roll_t = 0.0
	air_t = 0.0
	recovery_t = 0.0
	run_time = 0.0
	callout.text = ""
	intro_root.modulate.a = 1.0
	outro_dim.color.a = 0.0
	outro_panel.modulate.a = 0.0
	timeline.active = false
	camera.position = Vector2(CAM_MIN_X, CAM_Y)
	camera.reset_smoothing()
	_apply_visual()


func _start_shot(index: int) -> void:
	shot = index
	shot_t = 0.0
	event_i = 0
	phase = "SHOT"
	jump_queued = false
	var data: Dictionary = SHOTS[index]
	x = float(data.start_x)
	y = 0.0
	vx = 0.0
	vy = 0.0
	facing = int(data.face)
	on_floor = true
	mode = "IDLE"
	input_dir = 0.0
	jump_frame = 0
	pre_roll_t = 0.0
	air_t = 0.0
	recovery_t = 0.0
	run_time = 0.0
	apex_recorded = false
	rng.seed = 8800 + index * 37
	shot_beat.text = "BEAT %02d / 03" % (index + 1)
	shot_title.text = data.title
	shot_sub.text = data.sub
	timeline.active = false
	camera.position = Vector2(clampf(x * WORLD_SCALE, CAM_MIN_X, CAM_MAX_X), CAM_Y)
	camera.reset_smoothing()
	trace.append({"t": demo_t, "event": "beat_start", "beat": index + 1, "x": x, "facing": facing})
	_apply_visual()


func _start_outro() -> void:
	phase = "OUTRO"
	phase_t = 0.0
	input_dir = 0.0
	mode = "IDLE"
	jump_queued = false
	callout.text = ""
	trace.append({"t": demo_t, "event": "capture_end", "launches": launch_count})


func _physics_process(dt: float) -> void:
	if dt <= 0.0:
		return
	demo_t += dt
	phase_t += dt
	match phase:
		"INTRO":
			_update_locomotion(dt)
			_update_pose(dt)
			_apply_visual()
			_update_hud()
			if phase_t >= 0.90:
				_start_shot(0)
		"SHOT":
			shot_t += dt
			_fire_events()
			_update_locomotion(dt)
			_update_pose(dt)
			_apply_visual()
			_update_hud()
			var dur := float(SHOTS[shot].duration)
			if shot_t >= dur:
				if shot < SHOTS.size() - 1:
					_start_shot(shot + 1)
				else:
					_start_outro()
		"OUTRO":
			_update_locomotion(dt)
			_update_pose(dt)
			_apply_visual()
			_update_hud()
			if phase_t >= 1.45 and not trace_written:
				_write_trace()
				if auto:
					get_tree().quit()
				else:
					_reset_demo()
	_update_fade()


func _fire_events() -> void:
	var evs: Array = SHOTS[shot].events
	while event_i < evs.size() and shot_t >= float(evs[event_i][0]):
		var ev: Array = evs[event_i]
		match String(ev[1]):
			"run":
				input_dir = float(SHOTS[shot].face)
			"stop":
				input_dir = 0.0
			"prejump":
				jump_queued = true
				trace.append({"t": demo_t, "event": "jump_queued", "beat": shot + 1, "x": x})
		event_i += 1


func _update_locomotion(dt: float) -> void:
	var target := input_dir * RUN_SPEED
	if absf(target) < 0.1:
		vx = move_toward(vx, 0.0, DECEL * dt)
	else:
		var a := REVERSE_ACCEL if signf(vx) != signf(target) and absf(vx) > 0.1 else ACCEL
		vx = move_toward(vx, target, a * dt)
	if on_floor and input_dir != 0.0:
		facing = 1 if input_dir > 0.0 else -1
	x = clampf(x + vx * dt, 26.0, 874.0)
	if x <= 26.0 or x >= 874.0:
		vx = 0.0
	if on_floor and mode == "RUN":
		run_time += dt
	if on_floor and (mode == "IDLE" or mode == "RUN"):
		mode = "RUN" if absf(vx) > 20.0 else "IDLE"
		if mode == "IDLE":
			run_time = 0.0


func _update_pose(dt: float) -> void:
	if on_floor and jump_queued and mode != "PRE":
		if mode != "JUMP" or recovery_t >= 0.13:
			jump_queued = false
			mode = "PRE"
			pre_roll_t = 0.0
			jump_frame = 0

	match mode:
		"PRE":
			pre_roll_t += dt
			jump_frame = mini(2, int(pre_roll_t * ART_FPS))
			if pre_roll_t >= PRE_ROLL:
				_launch()
		"JUMP":
			if on_floor:
				recovery_t += dt
				jump_frame = mini(29, 24 + int(recovery_t * ART_FPS))
				if recovery_t >= RECOVERY:
					mode = "RUN" if absf(vx) > 20.0 else "IDLE"
					if mode == "RUN":
						run_time = 0.0
			else:
				var old_vy := vy
				var g := FALL_GRAVITY if vy > 0.0 else RISE_GRAVITY
				vy += g * dt
				y += vy * dt
				air_t += dt
				jump_frame = clampi(3 + int(air_t * ART_FPS), 3, 24)
				if not apex_recorded and old_vy < 0.0 and vy >= 0.0:
					apex_recorded = true
					apex_height = -y
					apex_time = air_t
					trace.append({
						"t": demo_t, "event": "apex", "launch": launch_count,
						"air_t": air_t, "height": apex_height, "vy": vy, "x": x,
					})
				if y >= 0.0 and vy > 0.0:
					_land()


func _launch() -> void:
	on_floor = false
	y = 0.0
	vy = JUMP_VELOCITY
	air_t = 0.0
	jump_frame = 3
	launch_count += 1
	apex_recorded = false
	mode = "JUMP"
	timeline.active = true
	trace.append({
		"t": demo_t, "event": "launch", "launch": launch_count, "beat": shot + 1,
		"x": x, "vx": vx, "vy": vy, "facing": facing,
	})
	dust.rng.seed = 7000 + launch_count * 53
	dust.burst(Vector2(x - facing * 6.0, FLOOR_Y), -facing, 9, 1.0)


func _land() -> void:
	y = 0.0
	vy = 0.0
	on_floor = true
	mode = "JUMP"
	recovery_t = 0.0
	jump_frame = 24
	trace.append({
		"t": demo_t, "event": "contact", "launch": launch_count, "beat": shot + 1,
		"air_t": air_t, "x": x, "vx": vx, "facing": facing,
	})
	dust.rng.seed = 9100 + launch_count * 71
	dust.burst(Vector2(x, FLOOR_Y), 0.0, 14, 1.15)


func _apply_visual() -> void:
	var tex: Texture2D
	var neck := Vector2(40.5, 18.5)
	var foot := FOOT_JUMP
	var clip := "JUMP"
	if mode == "PRE" or mode == "JUMP":
		var idx := clampi(jump_frame, 0, CLIP_FRAMES - 1)
		tex = jump_r[idx] if facing > 0 else jump_l[idx]
		var side := "right" if facing > 0 else "left"
		neck = _jump_neck(side, idx)
		foot = FOOT_JUMP
		clip = "JUMP v01"
	else:
		var cname := ("RUN_" if mode == "RUN" else "IDLE_") + ("right" if facing > 0 else "left")
		var count := BODY_FRAMES.get_frame_count(cname)
		var idx := 0
		if mode == "RUN":
			idx = int(run_time * ART_FPS) % count
		tex = BODY_FRAMES.get_frame_texture(cname, idx)
		neck = _ground_neck(cname, idx)
		foot = FOOT_GROUND
		clip = "RUN (existing)" if mode == "RUN" else "IDLE (existing)"
	body.texture = tex
	body.offset = Vector2(-PIVOT.x, -foot)
	var player := body.get_parent() as Node2D
	player.position = Vector2(x, FLOOR_Y + y)
	flame.position = Vector2(neck.x - PIVOT.x, neck.y - foot).round()
	flame.step(Vector2(vx, vy), Vector2.ZERO, 1.0 / 60.0)
	flame.limit_at_ground(-(y + flame.position.y))
	shadow.position = Vector2(x, FLOOR_Y + 1.0)
	var h := maxf(0.0, -y)
	var sx := clampf(1.0 - h / 260.0, 0.32, 1.0)
	shadow.set("strength", clampf(1.0 - h / 220.0, 0.18, 1.0))
	shadow.scale = Vector2(sx, 1.0)
	timeline.current = clampi(jump_frame, 0, 29) if (mode == "PRE" or mode == "JUMP") else -1
	timeline.active = mode == "PRE" or mode == "JUMP"
	timeline.facing_left = facing < 0
	timeline.queue_redraw()
	callout.text = _callout_text(clip)
	var wp := world.transform * Vector2(x, FLOOR_Y + y - 96.0)
	var sp := get_viewport().get_canvas_transform() * wp
	callout.position = Vector2(sp.x - 100.0, sp.y)
	callout.modulate.a = 0.0 if phase == "OUTRO" else 1.0
	camera.position = Vector2(clampf(x * WORLD_SCALE, CAM_MIN_X, CAM_MAX_X), CAM_Y)


func _jump_neck(side: String, idx: int) -> Vector2:
	var arr: Array = anchors_jump[side]
	var d: Dictionary = arr[idx]
	return Vector2(float(d.neck[0]), float(d.neck[1]))


func _ground_neck(clip: String, idx: int) -> Vector2:
	var arr: Array = anchors_ground[clip]
	var d: Dictionary = arr[idx]
	return Vector2(float(d.neck[0]), float(d.neck[1]))


func _callout_text(clip: String) -> String:
	if mode == "JUMP" and on_floor:
		return "CONTACT → RECOVER"
	if mode == "JUMP":
		return jump_phase(jump_frame + 1).to_upper()
	if mode == "PRE":
		return "ANTICIPATION"
	if mode == "RUN":
		return "RUN"
	return "IDLE"


func jump_phase(f: int) -> String:
	for row in PHASES:
		if f >= int(row[0]) and f <= int(row[1]):
			return String(row[2])
	return "READY"


func _update_hud() -> void:
	diag_frame.text = "%02d / 30" % (jump_frame + 1) if (mode == "PRE" or mode == "JUMP") else "—"
	diag_phase.text = ("ANTICIPATION" if mode == "PRE" else jump_phase(jump_frame + 1)) if (mode == "PRE" or mode == "JUMP") else mode
	diag_facing.text = "RIGHT" if facing > 0 else "LEFT"
	diag_vy.text = "%+.0f px/s" % vy if not on_floor else "0 px/s"
	diag_height.text = "%.1f px" % maxf(0.0, -y)
	if mode == "PRE" or mode == "JUMP":
		diag_clip.text = "JUMP v01"
	else:
		diag_clip.text = "RUN existing" if mode == "RUN" else "IDLE existing"
	launch_label.text = "LAUNCH %d / 4" % launch_count
	launch_label.modulate = Color(1, 1, 1, 0.55) if launch_count == 0 else Color(1, 1, 1, 1)

	var intro_a := 0.0
	if phase == "INTRO":
		intro_a = clampf(1.0 - (phase_t - 0.62) / 0.22, 0.0, 1.0)
	intro_root.modulate.a = intro_a
	var oa := 0.0
	if phase == "OUTRO":
		oa = clampf(phase_t / 0.35, 0.0, 1.0)
	outro_dim.color.a = 0.82 * oa
	outro_panel.modulate.a = oa
	var shot_a := 1.0
	if phase == "SHOT":
		shot_a = clampf(shot_t / 0.18, 0.0, 1.0)
	elif phase == "INTRO":
		shot_a = 0.0
	shot_title.modulate.a = shot_a
	shot_sub.modulate.a = shot_a
	shot_beat.modulate.a = shot_a


func _update_fade() -> void:
	var a := 0.0
	if phase == "INTRO":
		a = maxf(clampf(1.0 - phase_t / 0.30, 0.0, 1.0), clampf((phase_t - 0.70) / 0.20, 0.0, 1.0))
	elif phase == "SHOT":
		var dur := float(SHOTS[shot].duration)
		a = maxf(clampf(1.0 - shot_t / 0.16, 0.0, 1.0), clampf((shot_t - (dur - 0.12)) / 0.12, 0.0, 1.0))
	elif phase == "OUTRO":
		a = clampf(1.0 - phase_t / 0.35, 0.0, 1.0)
		a = maxf(a, clampf((phase_t - 1.02) / 0.36, 0.0, 1.0))
	fade.color = Color(0, 0, 0, a)


func _write_trace() -> void:
	if trace_written:
		return
	trace_written = true
	var out := {
		"schema": 1,
		"source": "scripts/lab/jump_test_lab.gd",
		"fps": 60,
		"art_fps": 30,
		"physics": {
			"jump_velocity": JUMP_VELOCITY,
			"rise_gravity": RISE_GRAVITY,
			"fall_gravity": FALL_GRAVITY,
			"fall_mult": 1.8,
		},
		"clip": {"frames": 30, "air_frames": 21, "air_seconds": 0.7, "pre_roll": 0.1, "recovery": 0.2},
		"events": trace,
	}
	var path := ProjectSettings.globalize_path("res://artifacts/iven_jump_redesign/JUMP_LAB_TRACE.json")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(out, "  "))
		f.close()
		print("WROTE TRACE ", path, " events=", trace.size())
