extends Node2D
## IVEN / ROLL REDESIGN gameplay lab.
##
## Demonstrates the authored 8-frame ground somersault, the 6-frame air
## somersault, and the production 0.35 s cooldown measured from the end of the
## roll. The roll visuals are AnimatedSprite2D nodes; one drives the ground
## sheet, the other drives the air sheet.
##
## Movie:
##   godot --path . --scene res://scripts/lab/roll_test_scene.tscn \
##     --fixed-fps 60 --write-movie <dir>/roll.png -- --auto
##
## Controls (manual):
##   A / D       move
##   SPACE       jump
##   SHIFT       roll / air roll
##   R           restart

const SHEET_R := preload("res://art/iven/movement/roll_v03/IVEN_ROLL_SHEET_V03.png")
const SHEET_L := preload("res://art/iven/movement/roll_v03/IVEN_ROLL_SHEET_LEFT.png")
const AIR_SHEET_R := preload("res://art/iven/movement/roll_v03/IVEN_AIR_ROLL_SHEET_V03.png")
const AIR_SHEET_L := preload("res://art/iven/movement/roll_v03/IVEN_AIR_ROLL_SHEET_LEFT.png")
const JUMP_SHEET_R := preload("res://art/iven/movement/jump_v02/IVEN_JUMP_V02_SHEET.png")
const JUMP_SHEET_L := preload("res://art/iven/movement/jump_v02/IVEN_JUMP_V02_SHEET_LEFT.png")
const BODY_FRAMES := preload("res://art/iven/movement/body_frames.tres")
const UI_FONT := preload("res://art/iven/movement/jump_v02/Roboto-Regular.ttf")

const CELL := 82
const PIVOT := Vector2(40.499926203, 75.579576591)
const FOOT_GROUND := 75.0
const FOOT_JUMP := 77.0
const ART_FPS := 30.0
const JUMP_CLIP_FRAMES := 30
const ROLL_FRAMES := 15
const AIR_FRAMES := 7
const ROLL_DURATION := 0.50 # locked production duration (player.gd roll_duration)
const AIR_DURATION := 7.0 / ART_FPS
const ROLL_COOLDOWN := 0.35
const ROLL_TRAVEL := 100.0
const ROLL_SPEED := ROLL_TRAVEL / ROLL_DURATION

const RUN_SPEED := 280.0
const ACCEL := 2600.0
const DECEL := 3200.0
const AIR_ACCEL := 1500.0
const JUMP_VELOCITY := -620.0
const RISE_GRAVITY := 1600.0
const FALL_GRAVITY := 3000.0

const FLOOR_Y := 200.0
const WORLD_W := 2600.0
const WORLD_SCALE := 3.0
const CAM_ZOOM := 0.75
const CAM_Y := 360.0
const CAM_HALF_W := 640.0 / CAM_ZOOM
const CAM_MIN_X := CAM_HALF_W
const CAM_MAX_X := WORLD_W * WORLD_SCALE - CAM_HALF_W

const PASS_DURATION := 4.0
const OUTRO_DURATION := 1.5
const TOTAL_TIME := 17.5 # 4 passes × 4.0 s + 1.5 s outro card

const INK := Color("#e9eff7")
const MUTED := Color("#8f9db2")
const DIM := Color("#5d6a7e")
const ACCENT := Color("#ffb35c")
const CYAN := Color("#7fd4e8")
const GREEN := Color("#8bd49c")
const RED := Color("#e2777f")
const PANEL := Color(0.047, 0.063, 0.090, 0.92)
const LINE := Color("#2a3648")

const GROUND_PHASES := [
	"INITIATION", "PLANT",
	"TUCK_IN", "TUCK_ROTATION", "APEX", "TUCK_HOLD", "TUCK_EXIT",
	"EXTENSION_1", "EXTENSION_2", "EXTENSION_3", "EXTENSION_4",
	"LANDING", "RECOVERY", "UNFOLD", "RUN_READY"
]
const AIR_PHASES := [
	"AIR_LAUNCH", "AIR_TUCK", "AIR_APEX", "AIR_HOLD", "AIR_EXIT", "AIR_EXTEND", "AIR_READY"
]

const PASSES := [
	{
		"title": "PASS 01  /  RUN  >  ROLL  >  RUN",
		"sub": "15 frames · 0.500 s · 100 px · held RUN resumes with no stop",
		"start_x": 260.0,
		"face": 1,
		"events": [[0.35, "run"], [1.05, "roll"], [2.05, "stop"]],
	},
	{
		"title": "PASS 02  /  COMMITMENT + COOLDOWN",
		"sub": "spam during roll is ignored · 0.350 s cooldown from roll end",
		"start_x": 300.0,
		"face": 1,
		"events": [[0.35, "roll"], [0.45, "roll"], [0.55, "roll"], [0.65, "roll"], [0.69, "roll"], [0.72, "roll"], [1.10, "roll"], [1.45, "stop"]],
	},
	{
		"title": "PASS 03  /  AIR ROLL",
		"sub": "7 frames · 0.233 s · full 360° somersault · no ground contact",
		"start_x": 260.0,
		"face": 1,
		"events": [[0.30, "run"], [0.75, "jump"], [1.10, "roll"], [1.95, "stop"]],
	},
	{
		"title": "PASS 04  /  MIRRORED ROLLS",
		"sub": "right then left · per-cell mirrored sheets · facing preserved",
		"start_x": 300.0,
		"face": 1,
		"events": [[0.25, "run"], [0.75, "roll"], [1.45, "left"], [1.75, "roll"], [2.50, "stop"]],
	},
]

var auto := false
var phase := "PASS"
var pass_i := 0
var pass_t := 0.0
var outro_t := 0.0
var demo_t := 0.0
var event_i := 0
var trace: Array[Dictionary] = []
var trace_written := false
var rng := RandomNumberGenerator.new()

var x := 260.0
var y := 0.0
var vx := 0.0
var vy := 0.0
var facing := 1
var on_floor := true
var input_dir := 0.0
var mode := "IDLE"
var run_time := 0.0

var roll_t := 0.0
var roll_frame := 0
var roll_dir := 1
var roll_cd := 0.0
var air_roll_t := 0.0
var air_frame := 0
var air_roll_done := false
var jump_frame := 0
var air_t := 0.0
var recovery_t := 0.0
var jump_r: Array[Texture2D] = []
var jump_l: Array[Texture2D] = []

var attempts := 0
var accepted := 0
var rejected := 0
var gate_text := ""
var gate_color := CYAN
var gate_flash_t := 0.0
var last_reject_remaining := 0.0

var world: Node2D
var camera: Camera2D
var body: Sprite2D
var ground_roll: AnimatedSprite2D
var air_roll: AnimatedSprite2D
var shadow: Node2D
var dust: Node2D
var frame_strip: Control
var fade: ColorRect
var title_root: Control
var outro_dim: ColorRect
var outro_panel: Panel
var outro_metrics: Label

var pass_beat: Label
var pass_title: Label
var pass_sub: Label
var mode_label: Label
var cooldown_label: Label
var cooldown_fill: ColorRect
var stats_label: Label
var gate_label: Label
var state_hint: Label

var ground_frames: SpriteFrames
var air_frames: SpriteFrames


class Backdrop extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		var w := 1280.0
		var h := 720.0
		for i in 36:
			var t := float(i) / 35.0
			var c := Color("#070b12").lerp(Color("#1d2939"), t)
			draw_rect(Rect2(0, h * t, w, h / 35.0 + 1.0), c)
		draw_circle(Vector2(958, 136), 118, Color(0.52, 0.70, 0.84, 0.030))
		draw_circle(Vector2(958, 136), 82, Color(0.60, 0.79, 0.92, 0.052))
		draw_circle(Vector2(958, 136), 48, Color(0.74, 0.87, 0.96, 0.075))
		var xs := [-18.0, 58.0, 146.0, 228.0, 314.0, 404.0, 500.0, 592.0, 698.0, 790.0, 884.0, 978.0, 1072.0, 1170.0, 1258.0]
		var hs := [146.0, 224.0, 184.0, 282.0, 204.0, 252.0, 168.0, 304.0, 190.0, 242.0, 160.0, 270.0, 198.0, 234.0, 182.0]
		for i in xs.size():
			var ww := 48.0 + float((i * 41) % 50)
			var hh: float = float(hs[i])
			draw_rect(Rect2(xs[i], h - hh, ww, hh), Color(0.050, 0.072, 0.102, 0.92))
			draw_rect(Rect2(xs[i] + 4, h - hh + 7, 2, hh - 7), Color(0.10, 0.13, 0.17, 0.35))
			draw_rect(Rect2(xs[i] + ww - 7, h - hh + 19, 2, hh - 19), Color(0.10, 0.13, 0.17, 0.25))
		for i in 5:
			var fy := 574.0 + i * 26.0
			draw_rect(Rect2(0, fy, w, 22), Color(0.30, 0.40, 0.52, 0.016 + i * 0.007))
		draw_rect(Rect2(0, 0, w, 50), Color(0.01, 0.015, 0.025, 0.40))
		draw_rect(Rect2(0, h - 116, w, 116), Color(0.01, 0.015, 0.025, 0.34))


class Arena extends Node2D:
	var font: Font

	func _draw() -> void:
		# Cold training-hall floor and a 100 px ruler.
		draw_rect(Rect2(0, 0, 2600, 200), Color(0.025, 0.037, 0.052, 0.28))
		for i in 13:
			var px := float(i) * 220.0 + 30.0
			draw_rect(Rect2(px, 36, 2, 164), Color(0.08, 0.11, 0.15, 0.5))
			draw_line(Vector2(px, 36), Vector2(px + 42, 36), Color(0.09, 0.12, 0.16, 0.55), 2.0)
		draw_rect(Rect2(0, 200, 2600, 150), Color("#0d141e"))
		draw_rect(Rect2(0, 200, 2600, 3), Color("#56677d"))
		draw_rect(Rect2(0, 203, 2600, 2), Color("#2a3748"))
		draw_rect(Rect2(0, 205, 2600, 12), Color("#141e2a"))
		draw_rect(Rect2(0, 217, 2600, 3), Color("#070b11"))
		draw_rect(Rect2(0, 220, 2600, 1), Color(0.29, 0.36, 0.44, 0.45))
		for i in 53:
			var gx := float(i) * 50.0
			var tall := i % 2 == 0
			draw_line(Vector2(gx, 205), Vector2(gx, 205 + (11 if tall else 6)), Color(0.36, 0.43, 0.51, 0.55 if tall else 0.30), 1.0)
		for i in 14:
			var lx := float(i) * 200.0 + 40.0
			draw_string(font, Vector2(lx, 193), str(int(lx)), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.46, 0.55, 0.66, 0.58))
		for i in 8:
			var ax := 120.0 + i * 300.0
			draw_line(Vector2(ax, 231), Vector2(ax + 22, 231), Color(0.30, 0.39, 0.50, 0.45), 1.0)
			draw_line(Vector2(ax + 16, 227), Vector2(ax + 22, 231), Color(0.30, 0.39, 0.50, 0.45), 1.0)
			draw_line(Vector2(ax + 16, 235), Vector2(ax + 22, 231), Color(0.30, 0.39, 0.50, 0.45), 1.0)
		draw_rect(Rect2(0, 250, 2600, 3), Color(0.02, 0.03, 0.045, 0.95))
		# Start pad and travel box.
		draw_rect(Rect2(252, 198, 16, 3), Color(0.92, 0.67, 0.38, 0.65))
		draw_line(Vector2(252, 190), Vector2(252, 205), Color(0.92, 0.67, 0.38, 0.50), 1.0)
		draw_string(font, Vector2(245, 184), "START", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.92, 0.67, 0.38, 0.60))
		draw_line(Vector2(260, 226), Vector2(360, 226), Color(0.48, 0.82, 0.88, 0.30), 1.0)
		draw_line(Vector2(260, 223), Vector2(260, 229), Color(0.48, 0.82, 0.88, 0.50), 1.0)
		draw_line(Vector2(360, 223), Vector2(360, 229), Color(0.48, 0.82, 0.88, 0.50), 1.0)


class Shadow extends Node2D:
	var strength := 1.0
	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * float(i) / 24.0
			pts.append(Vector2(cos(a) * 15.0, sin(a) * 4.0))
		draw_colored_polygon(pts, Color(0, 0, 0, 0.46 * strength))


class DustFX extends Node2D:
	var puffs: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	func burst(at: Vector2, dir: float, count: int, power := 1.0) -> void:
		for i in count:
			var vx0 := rng.randf_range(-46.0, 46.0) + dir * rng.randf_range(6.0, 38.0)
			var vy0 := rng.randf_range(-52.0, -8.0) * power
			puffs.append({
				"p": at + Vector2(rng.randf_range(-6.0, 6.0), rng.randf_range(-2.0, 1.0)),
				"v": Vector2(vx0, vy0),
				"life": rng.randf_range(0.24, 0.48),
				"t": 0.0,
				"s": rng.randf_range(1.0, 2.4),
			})
	func step(dt: float) -> void:
		for p in puffs:
			p.t += dt
			p.p += p.v * dt
			p.v.y += 100.0 * dt
			p.v.x *= 0.985
		puffs = puffs.filter(func(p): return p.t < p.life)
		queue_redraw()
	func _draw() -> void:
		for p in puffs:
			var k: float = 1.0 - p.t / p.life
			draw_rect(Rect2(p.p, Vector2(p.s, p.s)), Color(0.64, 0.72, 0.82, 0.32 * k))


class FrameStrip extends Control:
	var font: Font
	var sheet: Texture2D
	var clip_name := "GROUND ROLL"
	var count := 8
	var seconds := 0.29
	var current := -1
	var active := false
	var phase_names: Array = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _draw() -> void:
		var cell := 56.0
		var gap := 6.0
		var total := count * cell + (count - 1) * gap
		var ox := (size.x - total) * 0.5
		var oy := 22.0
		draw_string(font, Vector2(0, 13), clip_name + "  /  %dF  /  %.3fs" % [count, seconds], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#ffb35c"))
		var now := "—"
		if active and current >= 0:
			now = "f%02d  %s" % [current + 1, String(phase_names[current])]
		draw_string(font, Vector2(size.x - 158, 13), now, HORIZONTAL_ALIGNMENT_RIGHT, 158, 10, Color("#e9eff7") if active else Color("#5d6a7e"))
		for i in count:
			var rx := ox + i * (cell + gap)
			var bg := Rect2(rx, oy, cell, cell)
			draw_rect(bg, Color(0.02, 0.03, 0.045, 0.86))
			var tint := Color(1, 1, 1, 1) if (not active or i == current) else Color(0.62, 0.68, 0.76, 0.54)
			var mod_tint := tint * Color(0.84, 0.765, 0.739, 1.0)
			draw_texture_rect_region(sheet, bg, Rect2(i * 82.0, 0, 82, 82), mod_tint)
			var gy := oy + (75.579576591 / 82.0) * cell
			draw_line(Vector2(rx, gy), Vector2(rx + cell, gy), Color(0.85, 0.30, 0.34, 0.32), 1.0)
			if active and i == current:
				draw_rect(bg.grow(1.0), Color("#ffe1a6"), false, 2.0)
			elif count <= 8:
				draw_rect(bg, Color(0.18, 0.24, 0.32, 0.55), false, 1.0)
			draw_string(font, Vector2(rx + 2, oy + cell - 4), "f%02d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.78, 0.84, 0.90, 0.75))


func _ready() -> void:
	auto = OS.get_cmdline_user_args().has("--auto") or OS.get_cmdline_args().has("--auto")
	rng.seed = 20261023
	_build_assets()
	_build_world()
	_build_hud()
	if auto:
		_start_pass(0)
	else:
		_start_manual()
	print("ROLL_LAB ready auto=", auto, " ground=", SHEET_R.get_size(), " air=", AIR_SHEET_R.get_size())


func _build_assets() -> void:
	ground_frames = SpriteFrames.new()
	if ground_frames.has_animation("default"):
		ground_frames.remove_animation("default")
	_add_anim(ground_frames, "roll_right", SHEET_R, ROLL_FRAMES)
	_add_anim(ground_frames, "roll_left", SHEET_L, ROLL_FRAMES)
	air_frames = SpriteFrames.new()
	if air_frames.has_animation("default"):
		air_frames.remove_animation("default")
	_add_anim(air_frames, "air_roll_right", AIR_SHEET_R, AIR_FRAMES)
	_add_anim(air_frames, "air_roll_left", AIR_SHEET_L, AIR_FRAMES)

	jump_r.clear()
	jump_l.clear()
	for i in JUMP_CLIP_FRAMES:
		var ar := AtlasTexture.new()
		ar.atlas = JUMP_SHEET_R
		ar.region = Rect2(i * CELL, 0, CELL, CELL)
		jump_r.append(ar)
		var al := AtlasTexture.new()
		al.atlas = JUMP_SHEET_L
		al.region = Rect2(i * CELL, 0, CELL, CELL)
		jump_l.append(al)


func _add_anim(sf: SpriteFrames, anim: String, sheet: Texture2D, count: int) -> void:
	sf.add_animation(anim)
	sf.set_animation_speed(anim, ART_FPS)
	sf.set_animation_loop(anim, false)
	for i in count:
		var at := AtlasTexture.new()
		at.atlas = sheet
		at.region = Rect2(i * CELL, 0, CELL, CELL)
		sf.add_frame(anim, at)


func _build_world() -> void:
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)
	bg_layer.add_child(Backdrop.new())

	world = Node2D.new()
	world.name = "World"
	world.scale = Vector2(WORLD_SCALE, WORLD_SCALE)
	add_child(world)

	var arena := Arena.new()
	arena.name = "Arena"
	arena.font = UI_FONT
	world.add_child(arena)

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
	body.offset = Vector2(-PIVOT.x, -FOOT_GROUND)
	player.add_child(body)

	ground_roll = AnimatedSprite2D.new()
	ground_roll.name = "GroundRoll"
	ground_roll.sprite_frames = ground_frames
	ground_roll.centered = false
	ground_roll.offset = Vector2(-PIVOT.x, -PIVOT.y)
	ground_roll.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ground_roll.modulate = Color(0.84, 0.765, 0.739, 1.0)
	ground_roll.visible = false
	player.add_child(ground_roll)

	air_roll = AnimatedSprite2D.new()
	air_roll.name = "AirRoll"
	air_roll.sprite_frames = air_frames
	air_roll.centered = false
	air_roll.offset = Vector2(-PIVOT.x, -PIVOT.y)
	air_roll.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	air_roll.modulate = Color(0.84, 0.765, 0.739, 1.0)
	air_roll.visible = false
	player.add_child(air_roll)

	dust = DustFX.new()
	dust.name = "Dust"
	world.add_child(dust)

	camera = Camera2D.new()
	camera.name = "LabCamera"
	camera.position_smoothing_enabled = false
	camera.zoom = Vector2(CAM_ZOOM, CAM_ZOOM)
	camera.limit_left = 0
	camera.limit_right = int(WORLD_W * WORLD_SCALE)
	camera.limit_top = -800
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

	_bar(root, Rect2(0, 0, 1280, 50), Color(0.020, 0.028, 0.043, 0.90))
	_bar(root, Rect2(0, 50, 1280, 1), LINE)
	_bar(root, Rect2(0, 604, 1280, 116), Color(0.018, 0.025, 0.038, 0.95))
	_bar(root, Rect2(0, 604, 1280, 1), LINE)

	_label(root, "IVEN / ROLL REDESIGN", Vector2(36, 14), 15, INK)
	_label(root, "GROUND + AIR SOMERSAULT", Vector2(212, 16), 10, ACCENT)
	_label(root, "82×82 NATIVE   ·   30 FPS ART   ·   60 Hz LAB", Vector2(778, 16), 10, MUTED)
	_label(root, "PALETTE B", Vector2(1168, 16), 10, GREEN)

	_bar(root, Rect2(36, 68, 520, 94), PANEL)
	_bar(root, Rect2(36, 68, 3, 94), ACCENT)
	pass_beat = _label(root, "PASS 01 / 04", Vector2(52, 78), 10, ACCENT)
	pass_title = _label(root, "PASS 01  /  RUN  >  ROLL  >  RUN", Vector2(52, 95), 20, INK)
	pass_sub = _label(root, "15 frames · 0.500 s · 100 px · held RUN resumes with no stop", Vector2(52, 129), 9, MUTED)

	_bar(root, Rect2(600, 68, 268, 94), PANEL)
	_bar(root, Rect2(600, 68, 3, 94), CYAN)
	_label(root, "CURRENT STATE", Vector2(616, 78), 9, MUTED)
	mode_label = _label(root, "IDLE", Vector2(616, 95), 20, INK)
	state_hint = _label(root, "0.500 s ROLL  ·  0.350 s COOLDOWN", Vector2(616, 127), 9, CYAN)

	_bar(root, Rect2(902, 68, 344, 94), PANEL)
	_bar(root, Rect2(902, 68, 3, 94), GREEN)
	_label(root, "ROLL COOLDOWN", Vector2(918, 78), 9, MUTED)
	cooldown_label = _label(root, "READY / 0.000 s", Vector2(1090, 76), 13, GREEN)
	_bar(root, Rect2(918, 101, 310, 12), Color(0.10, 0.14, 0.19, 0.95))
	cooldown_fill = ColorRect.new()
	cooldown_fill.position = Vector2(918, 101)
	cooldown_fill.size = Vector2(310, 12)
	cooldown_fill.color = GREEN
	cooldown_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cooldown_fill)
	_label(root, "0.350 s FROM ROLL END  ·  PRODUCTION", Vector2(918, 122), 8, DIM)
	_label(root, "SHIFT ROLLS  ·  SPACE JUMPS", Vector2(918, 140), 9, MUTED)

	gate_label = _label(root, "", Vector2(902, 172), 14, RED)
	gate_label.size = Vector2(350, 20)
	gate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_label(root, "ATTEMPTS", Vector2(36, 628), 9, ACCENT)
	stats_label = _label(root, "0 INPUTS  ·  0 ACCEPTED  ·  0 REFUSED", Vector2(36, 644), 10, INK)
	_label(root, "COOLDOWN STARTS WHEN THE ROLL ENDS", Vector2(36, 670), 8, MUTED)

	frame_strip = FrameStrip.new()
	frame_strip.name = "FrameStrip"
	frame_strip.position = Vector2(326, 612)
	frame_strip.size = Vector2(628, 96)
	frame_strip.font = UI_FONT
	frame_strip.sheet = SHEET_R
	frame_strip.phase_names = GROUND_PHASES
	root.add_child(frame_strip)

	_label(root, "A / D  MOVE   ·   SPACE  JUMP   ·   SHIFT  ROLL", Vector2(986, 628), 9, MUTED)
	_label(root, "R  RESTART", Vector2(986, 646), 9, DIM)
	_label(root, "engine travel: 100 px  ·  no root motion", Vector2(986, 670), 8, DIM)

	# Intro title overlay.
	title_root = Control.new()
	title_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title_root)
	_bar(title_root, Rect2(424, 188, 2, 220), ACCENT)
	_label(title_root, "ROLL", Vector2(450, 172), 78, INK)
	_label(title_root, "REDESIGN", Vector2(454, 260), 27, ACCENT)
	_label(title_root, "A full-body somersault, not a crouch-slide.", Vector2(454, 312), 17, INK)
	_label(title_root, "15F GROUND  ·  6F AIR  ·  0.50 s ROLL  ·  0.35 s COOLDOWN  ·  PALETTE B", Vector2(454, 344), 10, MUTED)
	_bar(title_root, Rect2(454, 372, 458, 1), LINE)
	_label(title_root, "ROTATE THE MESH  ·  TUCK THE LIMBS  ·  PLANT THE EXIT", Vector2(454, 386), 9, DIM)

	# Outro card.
	outro_dim = ColorRect.new()
	outro_dim.color = Color(0.015, 0.020, 0.030, 0.0)
	outro_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outro_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(outro_dim)

	outro_panel = Panel.new()
	outro_panel.position = Vector2(224, 170)
	outro_panel.size = Vector2(832, 372)
	outro_panel.modulate = Color(1, 1, 1, 0)
	var osb := StyleBoxFlat.new()
	osb.bg_color = Color(0.043, 0.058, 0.080, 0.985)
	osb.border_color = Color("#3a4a60")
	osb.set_border_width_all(1)
	osb.set_corner_radius_all(3)
	outro_panel.add_theme_stylebox_override("panel", osb)
	root.add_child(outro_panel)
	_label(outro_panel, "CAPTURE COMPLETE  /  IVEN ROLL", Vector2(34, 24), 10, ACCENT)
	_label(outro_panel, "PASS", Vector2(34, 46), 46, GREEN)
	_label(outro_panel, "Full-body ground somersault  ·  air variant  ·  committed 0.500 s clip", Vector2(36, 110), 13, INK)
	outro_metrics = _label(outro_panel, "", Vector2(36, 142), 11, INK)
	_bar(outro_panel, Rect2(36, 196, 758, 1), LINE)
	_label(outro_panel, "GROUND  15F / 0.500 s / 100 px     AIR  7F / 0.233 s / 360°", Vector2(36, 214), 10, MUTED)
	_label(outro_panel, "Cooldown 0.350 s from roll end     Palette B / 21 opaque colours", Vector2(36, 238), 10, MUTED)
	_label(outro_panel, "source: IVEN_JUMP_V02.blend copy  ·  camera RESEARCH_Y75_P00", Vector2(36, 276), 9, DIM)
	_label(outro_panel, "evidence: ROLL_LAB_TRACE.json  ·  ROLL_V01_QA_REPORT.md  ·  native sheets 82×82", Vector2(36, 296), 9, DIM)
	_label(outro_panel, "No texture or sprite-pixel edits.  Rolls are animated with AnimatedSprite2D.", Vector2(36, 326), 9, DIM)

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
	l.add_theme_font_override("font", UI_FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _start_pass(index: int) -> void:
	pass_i = index
	pass_t = 0.0
	event_i = 0
	phase = "PASS"
	var data: Dictionary = PASSES[index]
	x = float(data.start_x)
	y = 0.0
	vx = 0.0
	vy = 0.0
	facing = int(data.face)
	on_floor = true
	input_dir = 0.0
	mode = "IDLE"
	run_time = 0.0
	roll_t = 0.0
	roll_frame = 0
	roll_cd = 0.0
	air_roll_t = 0.0
	air_frame = 0
	air_roll_done = false
	jump_frame = 0
	air_t = 0.0
	recovery_t = 0.0
	gate_flash_t = 0.0
	gate_text = ""
	outro_t = 0.0
	title_root.modulate.a = 1.0 if index == 0 else 0.0
	outro_dim.color.a = 0.0
	outro_panel.modulate.a = 0.0
	ground_roll.visible = false
	air_roll.visible = false
	body.visible = true
	pass_beat.text = "PASS %02d / %02d" % [index + 1, PASSES.size()]
	pass_title.text = String(data.title)
	pass_sub.text = String(data.sub)
	camera.position = Vector2(clampf(x * WORLD_SCALE, CAM_MIN_X, CAM_MAX_X), CAM_Y)
	camera.reset_smoothing()
	trace.append({
		"t": demo_t, "pass": index + 1, "event": "pass_start",
		"x": x, "facing": facing, "cooldown": roll_cd,
	})
	_apply_visual()
	print("ROLL_LAB pass_start ", index + 1, "/", PASSES.size(), " title=", String(data.title))


func _start_manual() -> void:
	phase = "MANUAL"
	pass_i = 0
	pass_t = 0.0
	event_i = 0
	x = 300.0
	y = 0.0
	vx = 0.0
	vy = 0.0
	facing = 1
	on_floor = true
	input_dir = 0.0
	mode = "IDLE"
	run_time = 0.0
	roll_t = 0.0
	roll_frame = 0
	roll_cd = 0.0
	air_roll_t = 0.0
	air_frame = 0
	air_roll_done = false
	jump_frame = 0
	air_t = 0.0
	recovery_t = 0.0
	gate_flash_t = 0.0
	gate_text = ""
	title_root.modulate.a = 1.0
	outro_dim.color.a = 0.0
	outro_panel.modulate.a = 0.0
	ground_roll.visible = false
	air_roll.visible = false
	body.visible = true
	pass_beat.text = "FREE PLAY"
	pass_title.text = "GROUND + AIR ROLL LAB"
	pass_sub.text = "A / D move · SPACE jump · SHIFT roll · R restart"
	camera.position = Vector2(clampf(x * WORLD_SCALE, CAM_MIN_X, CAM_MAX_X), CAM_Y)
	camera.reset_smoothing()
	_apply_visual()


func _start_outro() -> void:
	phase = "OUTRO"
	outro_t = 0.0
	input_dir = 0.0
	vx = 0.0
	mode = "IDLE"
	y = 0.0
	vy = 0.0
	on_floor = true
	ground_roll.visible = false
	air_roll.visible = false
	body.visible = true
	gate_flash_t = 0.0
	outro_metrics.text = "%d ROLLS ACCEPTED   ·   %d INPUTS REFUSED OR IGNORED" % [accepted, rejected]
	trace.append({
		"t": demo_t, "event": "capture_outro", "attempts": attempts,
		"accepted": accepted, "rejected": rejected,
	})
	_update_hud()
	print("ROLL_LAB outro attempts=", attempts, " accepted=", accepted, " rejected=", rejected)


func _physics_process(dt: float) -> void:
	if dt <= 0.0:
		return
	demo_t += dt
	if auto:
		roll_cd = maxf(0.0, roll_cd - dt)
		gate_flash_t = maxf(0.0, gate_flash_t - dt)
		if phase == "PASS":
			pass_t += dt
			_fire_events()
			_tick_rolls(dt)
			_update_motion(dt)
			_apply_visual()
			_update_hud()
			_update_fade()
			if pass_t >= PASS_DURATION:
				if pass_i < PASSES.size() - 1:
					_start_pass(pass_i + 1)
				else:
					_start_outro()
		elif phase == "OUTRO":
			outro_t += dt
			_tick_rolls(dt)
			_update_motion(dt)
			_apply_visual()
			_update_hud()
			_update_fade()
			if outro_t >= OUTRO_DURATION:
				_write_trace()
				get_tree().quit()
	else:
		roll_cd = maxf(0.0, roll_cd - dt)
		gate_flash_t = maxf(0.0, gate_flash_t - dt)
		_read_manual_input()
		_tick_rolls(dt)
		_update_motion(dt)
		_apply_visual()
		_update_hud()
		_update_fade()
	dust.step(dt)


func _read_manual_input() -> void:
	input_dir = Input.get_axis("move_left", "move_right")
	if Input.is_action_just_pressed("jump"):
		_try_jump()
	if Input.is_action_just_pressed("dash"):
		_try_roll("manual")
	if Input.is_action_just_pressed("restart"):
		_start_manual()


func _fire_events() -> void:
	var evs: Array = PASSES[pass_i].events
	while event_i < evs.size() and pass_t >= float(evs[event_i][0]):
		var ev: Array = evs[event_i]
		match String(ev[1]):
			"run":
				input_dir = float(PASSES[pass_i].face)
			"left":
				input_dir = -1.0
			"right":
				input_dir = 1.0
			"stop":
				input_dir = 0.0
			"jump":
				_try_jump()
			"roll":
				_try_roll("auto")
		event_i += 1


func _try_jump() -> void:
	if not on_floor:
		return
	# Production keeps jump-cancel: a valid jump interrupts the grounded roll
	# and arms the same cooldown. It does not shorten the roll presentation.
	if mode == "GROUND_ROLL":
		_end_ground_roll()
	on_floor = false
	y = 0.0
	vy = JUMP_VELOCITY
	mode = "JUMP"
	air_t = 0.0
	jump_frame = 3
	air_roll_done = false
	air_roll.visible = false
	body.visible = true
	trace.append({
		"t": demo_t, "pass": pass_i + 1, "event": "jump",
		"x": x, "vx": vx, "vy": vy, "cooldown": roll_cd,
	})


func _try_roll(source: String) -> void:
	attempts += 1
	if mode == "GROUND_ROLL" or mode == "AIR_ROLL":
		_reject("active", source)
		return
	if roll_cd > 0.000001:
		_reject("cooldown", source)
		return
	if not on_floor:
		_start_air_roll(source)
	else:
		_start_ground_roll(source)


func _start_ground_roll(source: String) -> void:
	accepted += 1
	roll_t = 0.0
	roll_frame = 0
	roll_dir = facing if absf(input_dir) < 0.1 else (1 if input_dir > 0.0 else -1)
	facing = roll_dir
	vx = float(roll_dir) * ROLL_SPEED
	mode = "GROUND_ROLL"
	ground_roll.visible = true
	air_roll.visible = false
	body.visible = false
	gate_flash_t = 0.55
	gate_text = "ROLL ACCEPTED  ·  COMMITTED 0.500 s"
	gate_color = GREEN
	dust.rng.seed = 6100 + accepted * 37
	dust.burst(Vector2(x - roll_dir * 5.0, FLOOR_Y), -roll_dir, 8, 0.9)
	trace.append({
		"t": demo_t, "pass": pass_i + 1, "event": "roll_accept", "kind": "ground",
		"source": source, "x": x, "facing": facing, "duration": ROLL_DURATION,
		"attempts": attempts, "accepted": accepted, "rejected": rejected,
	})


func _start_air_roll(source: String) -> void:
	accepted += 1
	air_roll_t = 0.0
	air_frame = 0
	air_roll_done = false
	jump_frame = 0
	air_t = 0.0
	recovery_t = 0.0
	mode = "AIR_ROLL"
	air_roll.visible = true
	ground_roll.visible = false
	body.visible = false
	gate_flash_t = 0.55
	gate_text = "AIR ROLL ACCEPTED  ·  COMMITTED 0.233 s"
	gate_color = GREEN
	trace.append({
		"t": demo_t, "pass": pass_i + 1, "event": "roll_accept", "kind": "air",
		"source": source, "x": x, "y": y, "vx": vx, "vy": vy,
		"duration": AIR_DURATION, "attempts": attempts,
		"accepted": accepted, "rejected": rejected,
	})


func _reject(reason: String, source: String) -> void:
	rejected += 1
	last_reject_remaining = roll_cd
	gate_flash_t = 0.55
	if reason == "active":
		gate_text = "IGNORED  ·  ROLL IN PROGRESS (NO EARLY CANCEL)"
	else:
		gate_text = "REFUSED  ·  %.3f s COOLDOWN LEFT" % roll_cd
	gate_color = RED
	trace.append({
		"t": demo_t, "pass": pass_i + 1, "event": "roll_reject",
		"reason": reason, "source": source, "remaining": roll_cd,
		"x": x, "y": y, "on_floor": on_floor, "mode": mode,
		"attempts": attempts, "accepted": accepted, "rejected": rejected,
	})


func _tick_rolls(dt: float) -> void:
	if mode == "GROUND_ROLL":
		roll_t += dt
		roll_frame = mini(ROLL_FRAMES - 1, int(roll_t / ROLL_DURATION * ROLL_FRAMES))
		if roll_t >= ROLL_DURATION:
			_end_ground_roll()
	elif mode == "AIR_ROLL":
		air_roll_t += dt
		air_frame = mini(AIR_FRAMES - 1, int(air_roll_t * ART_FPS))
		if air_roll_t >= AIR_DURATION:
			_end_air_roll()


## Production arms the cooldown when the roll ends or is interrupted, never on
## the press, and never shortens the authored clip for extra presses.
func _end_ground_roll() -> void:
	mode = "RUN" if absf(input_dir) > 0.1 else "IDLE"
	vx = input_dir * RUN_SPEED if absf(input_dir) > 0.1 else 0.0
	ground_roll.visible = false
	body.visible = true
	ground_roll.stop()
	roll_cd = maxf(roll_cd, ROLL_COOLDOWN)
	dust.rng.seed = 7100 + accepted * 43
	dust.burst(Vector2(x, FLOOR_Y), -roll_dir, 6, 0.65)
	trace.append({
		"t": demo_t, "pass": pass_i + 1, "event": "roll_end", "kind": "ground",
		"x": x, "duration": roll_t, "cooldown_set": ROLL_COOLDOWN,
	})


func _end_air_roll() -> void:
	mode = "JUMP"
	air_roll_done = true
	air_roll.visible = true
	body.visible = false
	air_roll.stop()
	roll_cd = maxf(roll_cd, ROLL_COOLDOWN)
	trace.append({
		"t": demo_t, "pass": pass_i + 1, "event": "roll_end", "kind": "air",
		"x": x, "y": y, "duration": air_roll_t, "cooldown_set": ROLL_COOLDOWN,
	})


func _update_motion(dt: float) -> void:
	if mode == "GROUND_ROLL":
		x += roll_dir * ROLL_SPEED * dt
		vx = roll_dir * ROLL_SPEED
		y = 0.0
		vy = 0.0
		on_floor = true
	elif mode == "AIR_ROLL":
		x += vx * dt
		var g := FALL_GRAVITY if vy > 0.0 else RISE_GRAVITY
		vy += g * dt
		y += vy * dt
		if y >= 0.0 and vy > 0.0:
			_land()
	else:
		var target := input_dir * RUN_SPEED
		if absf(target) < 0.1:
			vx = move_toward(vx, 0.0, DECEL * dt)
		else:
			var a := ACCEL if on_floor else AIR_ACCEL
			vx = move_toward(vx, target, a * dt)
		if input_dir != 0.0:
			facing = 1 if input_dir > 0.0 else -1
		x += vx * dt
		if not on_floor:
			if mode == "JUMP" and not air_roll_done:
				air_t += dt
				jump_frame = clampi(3 + int(air_t * ART_FPS), 3, 24)
			var g2 := FALL_GRAVITY if vy > 0.0 else RISE_GRAVITY
			vy += g2 * dt
			y += vy * dt
			if y >= 0.0 and vy > 0.0:
				_land()
		else:
			y = 0.0
			vy = 0.0
			if mode == "LAND":
				recovery_t += dt
				jump_frame = mini(29, 25 + int(recovery_t * ART_FPS))
				if recovery_t >= 5.0 / ART_FPS or absf(input_dir) > 0.1:
					mode = "RUN" if absf(vx) > 20.0 or absf(input_dir) > 0.1 else "IDLE"
					if mode == "RUN":
						run_time = 0.0
					jump_frame = 0
			elif mode == "JUMP":
				mode = "RUN" if absf(vx) > 20.0 else "IDLE"
			elif mode != "GROUND_ROLL":
				mode = "RUN" if absf(vx) > 20.0 else "IDLE" 
	x = clampf(x, 22.0, WORLD_W - 22.0)
	if x <= 22.0 or x >= WORLD_W - 22.0:
		vx = 0.0
	if on_floor and mode == "RUN":
		run_time += dt
	elif on_floor and mode == "IDLE":
		run_time = 0.0


func _land() -> void:
	y = 0.0
	vy = 0.0
	on_floor = true
	if mode == "AIR_ROLL":
		# Touching down interrupts the remaining air frames; the cooldown still
		# starts here, exactly like a completed air roll.
		roll_cd = maxf(roll_cd, ROLL_COOLDOWN)
		air_roll.visible = false
		mode = "RUN" if absf(vx) > 20.0 else "IDLE"
	elif mode == "JUMP":
		mode = "LAND"
		recovery_t = 0.0
		jump_frame = 25
	air_roll.visible = false
	ground_roll.visible = false
	body.visible = true
	air_roll_done = false
	mode = "RUN" if absf(input_dir) > 0.1 else "IDLE"
	vx = input_dir * RUN_SPEED if absf(input_dir) > 0.1 else 0.0
	dust.rng.seed = 8100 + accepted * 47
	dust.burst(Vector2(x, FLOOR_Y), 0.0, 12, 1.1)
	trace.append({
		"t": demo_t, "pass": pass_i + 1, "event": "land",
		"x": x, "vx": vx, "cooldown": roll_cd,
	})


func _apply_visual() -> void:
	var player := body.get_parent() as Node2D
	player.position = Vector2(x, FLOOR_Y + y)
	var side := "right" if facing > 0 else "left"
	if mode == "GROUND_ROLL":
		ground_roll.visible = true
		air_roll.visible = false
		body.visible = false
		_set_anim(ground_roll, "roll_" + side, roll_frame)
	elif mode == "AIR_ROLL":
		air_roll.visible = true
		ground_roll.visible = false
		body.visible = false
		_set_anim(air_roll, "air_roll_" + side, air_frame)
	elif mode == "JUMP" and air_roll_done:
		air_roll.visible = true
		ground_roll.visible = false
		body.visible = false
		_set_anim(air_roll, "air_roll_" + side, AIR_FRAMES - 1)
	elif mode == "JUMP" or mode == "LAND":
		ground_roll.visible = false
		air_roll.visible = false
		body.visible = true
		var idx := clampi(jump_frame, 0, JUMP_CLIP_FRAMES - 1)
		body.texture = jump_r[idx] if facing > 0 else jump_l[idx]
		body.offset = Vector2(-PIVOT.x, -FOOT_JUMP)
	else:
		ground_roll.visible = false
		air_roll.visible = false
		body.visible = true
		body.offset = Vector2(-PIVOT.x, -FOOT_GROUND)
		var cname := ("RUN_" if mode == "RUN" else "IDLE_") + side
		var count := BODY_FRAMES.get_frame_count(cname)
		var idx := int(run_time * ART_FPS) % count if mode == "RUN" else int(demo_t * ART_FPS) % count
		body.texture = BODY_FRAMES.get_frame_texture(cname, idx)
	shadow.position = Vector2(x, FLOOR_Y + 2.0)
	var height := maxf(0.0, -y)
	shadow.visible = true
	shadow.set("strength", clampf(1.0 - height / 240.0, 0.22, 1.0))
	shadow.scale = Vector2(clampf(1.0 - height / 320.0, 0.34, 1.0), 1.0)
	camera.position = Vector2(clampf(x * WORLD_SCALE, CAM_MIN_X, CAM_MAX_X), CAM_Y)


func _set_anim(sprite: AnimatedSprite2D, anim: String, idx: int) -> void:
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)
	sprite.set_frame_and_progress(clampi(idx, 0, sprite.sprite_frames.get_frame_count(anim) - 1), 0.0)


func _update_hud() -> void:
	var now := ""
	var hint := ""
	if mode == "GROUND_ROLL":
		now = "GROUND ROLL"
		hint = "f%02d / %02d  ·  %s" % [roll_frame + 1, ROLL_FRAMES, GROUND_PHASES[roll_frame]]
	elif mode == "AIR_ROLL":
		now = "AIR ROLL"
		hint = "f%02d / %02d  ·  %s" % [air_frame + 1, AIR_FRAMES, AIR_PHASES[air_frame]]
	elif mode == "JUMP":
		now = "AIRBORNE"
		var jphase := "LAUNCH"
		if jump_frame <= 8:
			jphase = "STRETCH / RISE"
		elif jump_frame <= 17:
			jphase = "APEX"
		else:
			jphase = "FALL / REACH"
		hint = ("AIR READY" if air_roll_done else "JUMP f%02d · %s" % [jump_frame + 1, jphase])
	elif mode == "LAND":
		now = "LANDING"
		hint = "f%02d · RECOVERY / RUN ENTRY" % [jump_frame + 1]
	elif mode == "RUN":
		now = "RUN"
		hint = "COOLDOWN" if roll_cd > 0.0 else "ROLL READY"
	else:
		now = "IDLE"
		hint = "ROLL READY" if roll_cd <= 0.0 else "COOLDOWN"
	mode_label.text = now
	state_hint.text = hint
	var rolling := mode == "GROUND_ROLL" or mode == "AIR_ROLL"
	var ready := roll_cd <= 0.000001
	if rolling:
		# The cooldown is armed at the end of the committed clip, not on the press.
		cooldown_label.text = "ARMED AT END"
		cooldown_label.add_theme_color_override("font_color", CYAN)
		cooldown_fill.size.x = 0.0
	else:
		cooldown_label.text = "READY / 0.000 s" if ready else "LOCKED / %.3f s" % roll_cd
		cooldown_label.add_theme_color_override("font_color", GREEN if ready else RED)
		var progress := clampf(1.0 - roll_cd / ROLL_COOLDOWN, 0.0, 1.0)
		cooldown_fill.size.x = 310.0 * progress
	cooldown_fill.color = GREEN if ready else CYAN
	stats_label.text = "%d INPUTS  ·  %d ACCEPTED  ·  %d REFUSED" % [attempts, accepted, rejected]
	if gate_flash_t > 0.0:
		gate_label.text = gate_text
		gate_label.add_theme_color_override("font_color", gate_color)
		gate_label.modulate.a = 1.0
	else:
		gate_label.text = ""
	if pass_i == 2 and phase == "PASS":
		frame_strip.clip_name = "AIR ROLL"
		frame_strip.count = AIR_FRAMES
		frame_strip.phase_names = AIR_PHASES
		frame_strip.seconds = AIR_DURATION
		frame_strip.sheet = AIR_SHEET_R if facing > 0 else AIR_SHEET_L
		frame_strip.current = air_frame if mode == "AIR_ROLL" else (AIR_FRAMES - 1 if air_roll_done else -1)
		frame_strip.active = mode == "AIR_ROLL" or (mode == "JUMP" and air_roll_done)
	else:
		frame_strip.clip_name = "GROUND ROLL"
		frame_strip.count = ROLL_FRAMES
		frame_strip.phase_names = GROUND_PHASES
		frame_strip.seconds = ROLL_DURATION
		frame_strip.sheet = SHEET_R if facing > 0 else SHEET_L
		frame_strip.current = roll_frame if mode == "GROUND_ROLL" else -1
		frame_strip.active = mode == "GROUND_ROLL"
	frame_strip.queue_redraw()
	var intro_a := 0.0
	if (phase == "PASS" and pass_i == 0) or phase == "MANUAL":
		intro_a = clampf(1.0 - (demo_t - 0.36) / 0.52, 0.0, 1.0)
	title_root.modulate.a = intro_a
	var oa := 0.0
	if phase == "OUTRO":
		oa = clampf((outro_t - 0.12) / 0.20, 0.0, 1.0)
	outro_dim.color.a = 0.84 * oa
	outro_panel.modulate.a = oa


func _update_fade() -> void:
	var a := 0.0
	if demo_t < 0.12:
		a = 1.0 - demo_t / 0.12
	if phase == "PASS":
		if pass_t < 0.075:
			a = maxf(a, 1.0 - pass_t / 0.075)
		elif pass_t > PASS_DURATION - 0.075:
			a = maxf(a, (pass_t - (PASS_DURATION - 0.075)) / 0.075)
	elif phase == "OUTRO":
		a = maxf(a, 1.0 - outro_t / 0.18)
	fade.color = Color(0, 0, 0, clampf(a, 0.0, 1.0))


func _write_trace() -> void:
	if trace_written:
		return
	trace_written = true
	var out := {
		"schema": 1,
		"source": "scripts/lab/roll_test_lab.gd",
		"fps": 60,
		"art_fps": 30,
		"total_seconds": TOTAL_TIME,
		"pass_seconds": PASS_DURATION,
		"cooldown": {
			"seconds": ROLL_COOLDOWN,
			"starts": "roll_end_or_interruption",
			"input_during_roll": "ignored",
		},
		"ground": {
			"action": "IVEN_ROLL", "frames": ROLL_FRAMES,
			"seconds": ROLL_DURATION, "travel_px": ROLL_TRAVEL,
			"speed_px_s": ROLL_SPEED,
		},
		"air": {
			"action": "IVEN_AIR_ROLL", "frames": AIR_FRAMES,
			"seconds": AIR_DURATION, "travel": "engine horizontal, no root motion",
		},
		"counts": {
			"attempts": attempts, "accepted": accepted, "rejected": rejected,
		},
		"events": trace,
	}
	var path := ProjectSettings.globalize_path("res://artifacts/iven_roll_redesign/ROLL_LAB_TRACE.json")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		print("ROLL_LAB trace open FAILED ", FileAccess.get_open_error())
	if f:
		f.store_string(JSON.stringify(out, "  "))
		f.close()
		print("WROTE TRACE ", path, " events=", trace.size())
