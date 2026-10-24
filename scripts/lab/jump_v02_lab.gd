extends Node2D
## IVEN / JUMP V02 gameplay lab.
##
## 15.0 s, two facings, one gap, deterministic 60 Hz capture:
##   PASS 01 (right) 0.00-7.00 s
##   PASS 02 (left)  7.00-14.00 s
##   outro           14.00-15.00 s
## Each pass: IDLE 2 s -> RUN 2 s -> full jump arc over the gap -> LAND -> RUN.
## Art is the production-palette V02 sheet; the approved V01 sheet is untouched.
##
## Movie:
##   godot --path . --scene res://scripts/lab/jump_v02_test_scene.tscn \
##     --fixed-fps 60 --write-movie <dir>/jump.png -- --auto

const SHEET_R := preload("res://art/iven/jump_v02/IVEN_JUMP_V02_SHEET.png")
const SHEET_L := preload("res://art/iven/jump_v02/IVEN_JUMP_V02_SHEET_LEFT.png")
const BODY_FRAMES := preload("res://art/iven/movement/body_frames.tres")
const UI_FONT := preload("res://art/iven/jump_v02/Roboto-Regular.ttf")
const FLAME_SCRIPT := preload("res://scripts/iven_flame.gd")

const CELL := 82
const CLIP_FRAMES := 30
const ART_FPS := 30.0
const PIVOT := Vector2(40.499926203, 75.579576591)
const FOOT_JUMP := 77.0
const FOOT_GROUND := 75.0

const FLOOR_Y := 224.0
const WORLD_W := 1500.0
const GAP_L := 680.0
const GAP_R := 820.0
const WORLD_SCALE := 3.0
const VIEW_W := 1280.0
const VIEW_H := 720.0

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
const RECOVERY := 5.0 / ART_FPS
const SHOT_DURATION := 7.0
const TOTAL_TIME := 15.0

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
	[16, 17, "APEX", Color("#ffd166")],
	[18, 20, "RELEASE", Color("#7f9bd1")],
	[21, 23, "FALL", Color("#8d8ad6")],
	[24, 24, "REACH", Color("#9b8ad6")],
	[25, 26, "IMPACT", Color("#e2777f")],
	[27, 27, "RECOVER", Color("#c95f68")],
	[28, 28, "RISE", Color("#8bd49c")],
	[29, 30, "RUN ENTRY", Color("#8bd49c")],
]

const SHOTS := [
	{
		"title": "PASS 01  /  RIGHT",
		"sub": "IDLE 2 s  ·  RUN 2 s  ·  JUMP THE GAP  ·  LAND → RUN 2 s",
		"start_x": 80.0,
		"face": 1,
		"events": [[2.0, "run"], [4.0, "prejump"]],
	},
	{
		"title": "PASS 02  /  LEFT",
		"sub": "mirrored art  ·  IDLE 2 s  ·  RUN 2 s  ·  JUMP THE GAP  ·  LAND → RUN 2 s",
		"start_x": 1408.0,
		"face": -1,
		"events": [[2.0, "run"], [4.0, "prejump"]],
	},
]

var phase := "SHOT"
var demo_t := 0.0
var outro_t := 0.0
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
var title_root: Control
var outro_dim: ColorRect
var outro_panel: Panel
var callout: Label

var shot_beat: Label
var shot_title: Label
var shot_sub: Label
var facing_label: Label
var color_badge: Label

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
		draw_circle(Vector2(934, 164), 104, Color(0.56, 0.74, 0.88, 0.035))
		draw_circle(Vector2(934, 164), 74, Color(0.62, 0.80, 0.92, 0.055))
		draw_circle(Vector2(934, 164), 43, Color(0.76, 0.87, 0.95, 0.075))
		var xs := [-20.0, 64.0, 150.0, 232.0, 322.0, 408.0, 506.0, 596.0, 702.0, 792.0, 886.0, 982.0, 1080.0, 1180.0, 1260.0]
		var hs := [150.0, 232.0, 188.0, 288.0, 210.0, 258.0, 174.0, 310.0, 196.0, 246.0, 166.0, 276.0, 204.0, 238.0, 186.0]
		for i in xs.size():
			var ww := 54.0 + float((i * 37) % 46)
			var hh: float = float(hs[i])
			draw_rect(Rect2(xs[i], h - hh, ww, hh), Color(0.055, 0.078, 0.110, 0.88))
			draw_rect(Rect2(xs[i] + 5, h - hh + 8, 2, hh - 8), Color(0.10, 0.13, 0.17, 0.35))
			draw_rect(Rect2(xs[i] + ww - 8, h - hh + 22, 2, hh - 22), Color(0.10, 0.13, 0.17, 0.25))
		for i in 5:
			var fy := 574.0 + i * 26.0
			draw_rect(Rect2(0, fy, w, 22), Color(0.30, 0.40, 0.52, 0.018 + i * 0.008))
		draw_rect(Rect2(0, 0, w, 46), Color(0.01, 0.015, 0.025, 0.35))
		draw_rect(Rect2(0, h - 112, w, 112), Color(0.01, 0.015, 0.025, 0.30))


class Ground extends Node2D:
	var world_w := 1500.0
	var gap_l := 680.0
	var gap_r := 820.0

	func _draw() -> void:
		# Two platforms with a real visual gap between them.
		draw_rect(Rect2(0, 224, gap_l, 40), Color("#0e1520"))
		draw_rect(Rect2(gap_r, 224, world_w - gap_r, 40), Color("#0e1520"))
		draw_rect(Rect2(gap_l, 224, gap_r - gap_l, 116), Color("#04070c"))
		draw_rect(Rect2(gap_l, 224, gap_r - gap_l, 3), Color("#020306"))
		draw_rect(Rect2(0, 224, gap_l, 2), Color("#4a5a70"))
		draw_rect(Rect2(gap_r, 224, world_w - gap_r, 2), Color("#4a5a70"))
		draw_rect(Rect2(0, 226, gap_l, 1), Color("#2a3748"))
		draw_rect(Rect2(gap_r, 226, world_w - gap_r, 1), Color("#2a3748"))
		draw_rect(Rect2(0, 227, gap_l, 2), Color("#16202c"))
		draw_rect(Rect2(gap_r, 227, world_w - gap_r, 2), Color("#16202c"))

		var cols := int(world_w / 24.0)
		for i in cols:
			var gx := float(i) * 24.0
			if gx < gap_l - 8.0 or gx > gap_r + 8.0:
				draw_line(Vector2(gx, 228), Vector2(gx, 258), Color(0.18, 0.23, 0.30, 0.28), 1.0)
		for i in 26:
			var cx := 18.0 + float(i) * 63.0
			if cx < gap_l - 8.0 or cx > gap_r + 8.0:
				draw_line(Vector2(cx, 225), Vector2(cx + 7, 230), Color("#6d7e94"), 1.0)
				draw_line(Vector2(cx + 7, 230), Vector2(cx + 9, 234), Color(0.20, 0.26, 0.33, 0.75), 1.0)
		for i in 18:
			var px := 34.0 + float(i) * 82.0
			if px < gap_l - 4.0 or px > gap_r + 4.0:
				draw_rect(Rect2(px, 221, 3, 3), Color(0.36, 0.42, 0.50, 0.55))

		# Chipped lips and a deep, cold pit.
		draw_rect(Rect2(gap_l - 5, 224, 5, 3), Color("#7f8fa4"))
		draw_rect(Rect2(gap_r, 224, 5, 3), Color("#7f8fa4"))
		draw_line(Vector2(gap_l - 3, 227), Vector2(gap_l - 10, 252), Color(0.36, 0.43, 0.51, 0.55), 2.0)
		draw_line(Vector2(gap_r + 3, 227), Vector2(gap_r + 12, 250), Color(0.36, 0.43, 0.51, 0.55), 2.0)
		for i in 7:
			var gx := gap_l + 8.0 + float(i) * 20.0
			draw_line(Vector2(gx, 230), Vector2(gx + 5, 336), Color(0.12, 0.16, 0.21, 0.55), 1.0)
		for i in 3:
			var gy := 252.0 + float(i) * 24.0
			draw_line(Vector2(gap_l, gy), Vector2(gap_r, gy + 4), Color(0.10, 0.14, 0.19, 0.40), 1.0)
		draw_rect(Rect2(gap_l, 336, gap_r - gap_l, 4), Color(0.06, 0.09, 0.12, 0.75))
		draw_rect(Rect2(0, 260, gap_l, 3), Color(0.03, 0.045, 0.065, 0.9))
		draw_rect(Rect2(gap_r, 260, world_w - gap_r, 3), Color(0.03, 0.045, 0.065, 0.9))

		# Small rubble at both ledges.
		for i in 5:
			var rx := gap_l - 14.0 - float(i) * 7.0
			draw_rect(Rect2(rx, 220, 3, 4), Color(0.42, 0.48, 0.55, 0.55))
		for i in 5:
			var rx := gap_r + 6.0 + float(i) * 8.0
			draw_rect(Rect2(rx, 220, 3, 4), Color(0.42, 0.48, 0.55, 0.55))


class Motes extends Node2D:
	var pts: Array[Vector3] = []
	func _ready() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = 4411
		for i in 84:
			pts.append(Vector3(r.randf_range(0, 1500), r.randf_range(40, 218), r.randf_range(0, TAU)))
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
	const PITCH := 22.0
	const CW := 20.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func phase_color(f: int) -> Color:
		var table := [
			[1, 2, Color("#5d6d83")], [3, 3, Color("#b18a5a")], [4, 4, Color("#d9a441")],
			[5, 8, Color("#7fd4e8")], [9, 11, Color("#6aa9d8")], [12, 15, Color("#74c7c9")],
			[16, 17, Color("#ffd166")], [18, 20, Color("#7f9bd1")], [21, 23, Color("#8d8ad6")],
			[24, 24, Color("#9b8ad6")], [25, 26, Color("#e2777f")], [27, 27, Color("#c95f68")],
			[28, 28, Color("#8bd49c")], [29, 30, Color("#8bd49c")],
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
		draw_string(font, Vector2(0, 8), "PRE 0.10 s", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#8f9db2"))
		draw_string(font, Vector2(74, 8), "AIRBORNE 0.70 s", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#8f9db2"))
		draw_string(font, Vector2(556, 8), "RECOVER 0.17 s", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#8f9db2"))
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
	_start_shot(0)
	print("JUMP_V02_LAB ready auto=", auto, " sheet=", SHEET_R.get_size(), " left=", SHEET_L.get_size())


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
	anchors_jump = JSON.parse_string(FileAccess.get_file_as_string("res://art/iven/jump_v02/jump_anchors.json"))


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

	var ground := Ground.new()
	ground.world_w = WORLD_W
	ground.gap_l = GAP_L
	ground.gap_r = GAP_R
	world.add_child(ground)

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

	_bar(root, Rect2(0, 0, 1280, 48), Color(0.020, 0.028, 0.043, 0.88))
	_bar(root, Rect2(0, 48, 1280, 1), LINE)
	_bar(root, Rect2(0, 620, 1280, 100), Color(0.018, 0.025, 0.038, 0.94))
	_bar(root, Rect2(0, 620, 1280, 1), LINE)

	_label(root, "IVEN / JUMP V02", Vector2(36, 14), 15, INK)
	_label(root, "COLOR + WEIGHT PASS", Vector2(190, 16), 10, ACCENT)
	_label(root, "82×82 NATIVE   ·   30 FPS ART   ·   60 Hz PHYSICS", Vector2(760, 16), 10, MUTED)
	_label(root, "PALETTE LOCKED", Vector2(1150, 16), 10, GREEN)

	_bar(root, Rect2(36, 66, 452, 92), Color(0.035, 0.048, 0.068, 0.62))
	_bar(root, Rect2(36, 66, 3, 92), ACCENT)
	shot_beat = _label(root, "PASS 01 / 02", Vector2(52, 76), 10, ACCENT)
	shot_title = _label(root, "PASS 01  /  RIGHT", Vector2(52, 94), 22, INK)
	shot_sub = _label(root, "IDLE 2 s  ·  RUN 2 s  ·  JUMP THE GAP  ·  LAND → RUN 2 s", Vector2(52, 128), 9, MUTED)

	facing_label = _label(root, "FACING RIGHT", Vector2(1110, 78), 11, INK)
	color_badge = _label(root, "RUN PALETTE / 21", Vector2(1110, 98), 9, GREEN)
	_label(root, "SOURCE  art/iven/movement/body_atlas.png", Vector2(1016, 118), 8, DIM)

	_label(root, "CLIP TIMELINE", Vector2(36, 640), 10, ACCENT)
	_label(root, "30 frames  ·  1.000 s  ·  f01 ready → f30 run entry", Vector2(36, 658), 9, MUTED)
	_label(root, "JUMP PHYSICS  −640 / 1600 / ×1.8", Vector2(1008, 640), 9, MUTED)
	_label(root, "APEX 122.7 px  ·  AIR 0.700 s", Vector2(1008, 656), 9, MUTED)
	_label(root, "GAP 140 px  ·  both facings", Vector2(1008, 672), 9, DIM)

	timeline = PhaseTimeline.new()
	timeline.name = "Timeline"
	timeline.position = Vector2(280, 646)
	timeline.size = Vector2(700, 54)
	timeline.font = UI_FONT
	root.add_child(timeline)

	callout = _label(root, "", Vector2(0, 0), 10, CYAN)
	callout.size = Vector2(200, 16)
	callout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Launch title overlay.
	title_root = Control.new()
	title_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title_root)
	_bar(title_root, Rect2(424, 196, 2, 214), ACCENT)
	_label(title_root, "JUMP", Vector2(448, 182), 76, INK)
	_label(title_root, "V02", Vector2(452, 262), 28, ACCENT)
	_label(title_root, "Colour-locked. Weighted. Snappy.", Vector2(452, 316), 17, INK)
	_label(title_root, "30 FRAMES   ·   21 AIRBORNE   ·   0.700 s   ·   82×82", Vector2(452, 346), 10, MUTED)
	_bar(title_root, Rect2(452, 372, 430, 1), LINE)
	_label(title_root, "IDLE 2 s  →  RUN 2 s  →  JUMP THE GAP  →  LAND → RUN", Vector2(452, 384), 9, DIM)

	# End card.
	outro_dim = ColorRect.new()
	outro_dim.color = Color(0.015, 0.020, 0.030, 0.0)
	outro_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outro_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(outro_dim)
	outro_panel = Panel.new()
	outro_panel.position = Vector2(250, 198)
	outro_panel.size = Vector2(780, 322)
	outro_panel.modulate = Color(1, 1, 1, 0)
	var osb := StyleBoxFlat.new()
	osb.bg_color = Color(0.043, 0.058, 0.080, 0.98)
	osb.border_color = Color("#3a4a60")
	osb.set_border_width_all(1)
	osb.set_corner_radius_all(3)
	outro_panel.add_theme_stylebox_override("panel", osb)
	root.add_child(outro_panel)
	_label(outro_panel, "CAPTURE COMPLETE  /  JUMP V02", Vector2(32, 24), 10, ACCENT)
	_label(outro_panel, "PASS", Vector2(32, 48), 46, GREEN)
	_label(outro_panel, "Production RUN palette  ·  21 colours  ·  zero out-of-palette pixels", Vector2(34, 112), 12, INK)
	_label(outro_panel, "Two-frame takeoff hold  ·  compact bent-arm apex  ·  forward fall", Vector2(34, 140), 12, INK)
	_label(outro_panel, "Two-frame landing squash  ·  five-frame run entry  ·  mirrored left", Vector2(34, 168), 12, INK)
	_bar(outro_panel, Rect2(34, 204, 712, 1), LINE)
	_label(outro_panel, "15.0 s   ·   2 facings   ·   full arc over a 140 px gap   ·   82×82 native", Vector2(34, 220), 10, MUTED)
	_label(outro_panel, "source: IVEN_JUMP_V02.blend  ·  IVEN_JUMP_V02_SHEET.png", Vector2(34, 250), 9, DIM)
	_label(outro_panel, "QA detail: JUMP_V02_QA_REPORT.md  ·  color proof: COLOR_SYNC_TEST.png", Vector2(34, 270), 9, DIM)

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
	shot_beat.text = "PASS %02d / 02" % (index + 1)
	shot_title.text = data.title
	shot_sub.text = data.sub
	facing_label.text = "FACING RIGHT" if facing > 0 else "FACING LEFT"
	timeline.active = false
	title_root.modulate.a = 1.0 if index == 0 else 0.0
	outro_dim.color.a = 0.0
	outro_panel.modulate.a = 0.0
	callout.text = ""
	camera.position = Vector2(clampf(x * WORLD_SCALE, CAM_MIN_X, CAM_MAX_X), CAM_Y)
	camera.reset_smoothing()
	trace.append({"t": demo_t, "event": "pass_start", "pass": index + 1, "x": x, "facing": facing})
	_apply_visual()


func _start_outro() -> void:
	phase = "OUTRO"
	outro_t = 0.0
	input_dir = 0.0
	jump_queued = false
	callout.text = ""
	trace.append({"t": demo_t, "event": "capture_end", "launches": launch_count})


func _physics_process(dt: float) -> void:
	if dt <= 0.0:
		return
	if demo_t >= TOTAL_TIME:
		return
	demo_t += dt
	match phase:
		"SHOT":
			shot_t += dt
			_fire_events()
			_update_locomotion(dt)
			_update_pose(dt)
			_apply_visual()
			_update_hud()
			if shot_t >= SHOT_DURATION:
				if shot < SHOTS.size() - 1:
					_start_shot(shot + 1)
				else:
					_start_outro()
		"OUTRO":
			outro_t += dt
			_update_locomotion(dt)
			_update_pose(dt)
			_apply_visual()
			_update_hud()
	_update_fade()
	if demo_t >= TOTAL_TIME:
		_write_trace()
		if auto:
			get_tree().quit()
		else:
			_start_shot(0)


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
				trace.append({"t": demo_t, "event": "jump_queued", "pass": shot + 1, "x": x})
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
	x = clampf(x + vx * dt, 26.0, WORLD_W - 26.0)
	if x <= 26.0 or x >= WORLD_W - 26.0:
		vx = 0.0
	if on_floor and mode == "RUN":
		run_time += dt
	if on_floor and (mode == "IDLE" or mode == "RUN"):
		mode = "RUN" if absf(vx) > 20.0 else "IDLE"
		if mode == "IDLE":
			run_time = 0.0


func _update_pose(dt: float) -> void:
	if on_floor and jump_queued and mode != "PRE" and mode != "JUMP":
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
					jump_frame = 0
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
		"t": demo_t, "event": "launch", "launch": launch_count, "pass": shot + 1,
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
		"t": demo_t, "event": "contact", "launch": launch_count, "pass": shot + 1,
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
		clip = "JUMP V02"
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
	var over_gap := x > GAP_L and x < GAP_R
	shadow.visible = not (over_gap and -y > 1.0)
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
		return "LAND → RUN"
	if mode == "JUMP":
		return jump_phase(jump_frame + 1).to_upper()
	if mode == "PRE":
		return "TAKEOFF"
	if mode == "RUN":
		return "RUN"
	return "IDLE"


func jump_phase(f: int) -> String:
	for row in PHASES:
		if f >= int(row[0]) and f <= int(row[1]):
			return String(row[2])
	return "READY"


func _update_hud() -> void:
	var intro_a := 0.0
	if phase == "SHOT" and shot == 0:
		intro_a = clampf(1.0 - (demo_t - 0.35) / 0.55, 0.0, 1.0)
	title_root.modulate.a = intro_a
	var oa := 0.0
	if phase == "OUTRO":
		oa = clampf((outro_t - 0.16) / 0.20, 0.0, 1.0)
	outro_dim.color.a = 0.82 * oa
	outro_panel.modulate.a = oa
	facing_label.text = "FACING RIGHT" if facing > 0 else "FACING LEFT"
	color_badge.text = "RUN PALETTE / 21" if absf(vx) > 20.0 or mode == "JUMP" else "IDLE + RUN PALETTE / 21"


func _update_fade() -> void:
	var a := 0.0
	if demo_t < 0.12:
		a = 1.0 - demo_t / 0.12
	if phase == "SHOT":
		if shot == 0 and shot_t > SHOT_DURATION - 0.08:
			a = maxf(a, clampf((shot_t - (SHOT_DURATION - 0.08)) / 0.08, 0.0, 1.0))
		if shot == 1 and shot_t < 0.08:
			a = maxf(a, 1.0 - shot_t / 0.08)
	elif phase == "OUTRO":
		var reveal := clampf(outro_t / 0.22, 0.0, 1.0)
		var hide := clampf((outro_t - 0.78) / 0.22, 0.0, 1.0)
		a = maxf(1.0 - reveal, hide)
	fade.color = Color(0, 0, 0, a)


func _write_trace() -> void:
	if trace_written:
		return
	trace_written = true
	var out := {
		"schema": 1,
		"source": "scripts/lab/jump_v02_lab.gd",
		"fps": 60,
		"art_fps": 30,
		"total_seconds": TOTAL_TIME,
		"shot_seconds": SHOT_DURATION,
		"physics": {
			"jump_velocity": JUMP_VELOCITY,
			"rise_gravity": RISE_GRAVITY,
			"fall_gravity": FALL_GRAVITY,
			"fall_mult": 1.8,
		},
		"clip": {
			"frames": 30,
			"air_frames": 21,
			"air_seconds": 0.7,
			"pre_roll": PRE_ROLL,
			"recovery": RECOVERY,
			"gap": [GAP_L, GAP_R],
		},
		"events": trace,
	}
	var path := ProjectSettings.globalize_path("res://artifacts/iven_jump_redesign/JUMP_V02_LAB_TRACE.json")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(out, "  "))
		f.close()
		print("WROTE TRACE ", path, " events=", trace.size())
