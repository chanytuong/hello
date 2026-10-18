extends SceneTree
## NEWDESIGN scale + cleanup comparison (NON-DESTRUCTIVE).
##
## Shows the original and the teal-cleaned newdesign frames side by side at
##   row 1/2: native 64x128 (scale 1.0)
##   row 3/4: 50% display scale (scale 0.5)
## all with TEXTURE_FILTER_NEAREST, feet on a drawn ground line (pivot proof),
## and runs independent in-engine pixel checks (binary alpha, ground row,
## cyan contamination) on every loaded texture.
##
## RUN GRAPHICALLY (not --headless, a real renderer is required for the shot):
##   godot --path E:\neverlookback -s res://tests/scale_compare.gd
## Writes: res://maincharacter/newdesign_clean/godot_scale_compare.png
## Exit code 0 only when every check passes. Source assets are only read.

const ORIG := "res://maincharacter/newdesign/"
const CLEAN := "res://maincharacter/newdesign_clean/"
const SHOT := "res://maincharacter/newdesign_clean/godot_scale_compare.png"
const COLS := 8
const SHOT_FRAME := 40   # first frames render blank on this machine - verified

var _fail := 0
var _pass := 0
var _warn := 0
var _f := 0
var _graphical := false
var _report := []
var _orig_opaque := {}


func _check(ok: bool, msg: String) -> void:
	if ok:
		_pass += 1
		print("PASS: " + msg)
	else:
		_fail += 1
		print("FAIL: " + msg)
	_report.append(("PASS " if ok else "FAIL ") + msg)


func _label(text: String, pos: Vector2, size: int = 16) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
	return l


func _load_checked(path: String, tag: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		_check(false, "%s exists (%s)" % [tag, path])
		return null
	var tex := load(path) as Texture2D
	if tex == null:
		_check(false, "%s loads as Texture2D" % tag)
		return null
	_check(tex.get_width() == 64 and tex.get_height() == 128,
		"%s is 64x128 (got %dx%d)" % [tag, tex.get_width(), tex.get_height()])
	return tex


## Independent in-engine verification of the pixel facts (never trusts the
## python side): binary alpha, ground row = 126, cyan contamination count.
func _pixel_checks(tex: Texture2D, tag: String, expect_cyan: bool) -> Dictionary:
	var out := {"cyan": -1, "ground": -1, "opaque": -1, "alpha_binary": false}
	var img := tex.get_image()
	if img == null or img.is_empty():
		_warn += 1
		print("WARN: %s get_image() unavailable - pixel checks skipped" % tag)
		return out
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var opaque := 0
	var ground := -1
	var cyan := 0
	var binary := true
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a >= 1.0:
				opaque += 1
				ground = y
				# cyan family: green+blue clearly above red
				if c.g > 0.45 and c.b > 0.40 and c.r < 0.45 and (c.g - c.r) > 0.2:
					cyan += 1
			elif c.a > 0.0:
				binary = false
	out["cyan"] = cyan
	out["ground"] = ground
	out["opaque"] = opaque
	out["alpha_binary"] = binary
	_check(binary, "%s alpha is binary 0/1 in-engine" % tag)
	_check(ground == 126, "%s lowest opaque row (feet) == 126 (got %d)" % [tag, ground])
	if expect_cyan:
		_check(cyan == 0, "%s has no cyan-family pixels (got %d)" % [tag, cyan])
	else:
		print("INFO: %s cyan-family pixels in ORIGINAL (expected >0): %d" % [tag, cyan])
	return out


func _init() -> void:
	_graphical = DisplayServer.get_name() != "headless"
	print("scale_compare: display=%s graphical=%s" % [DisplayServer.get_name(), _graphical])

	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.10, 0.12)
	bg.size = Vector2(1280, 720)
	get_root().add_child(bg)

	get_root().add_child(_label("NEWDESIGN: original vs teal-cleaned  |  rows 1-2 native 1:1, rows 3-4 at 50% display scale",
		Vector2(24, 10), 18))

	var rows := [
		{"name": "ORIGINAL native 1:1", "dir": ORIG, "scale": 1.0, "clean": false},
		{"name": "CLEANED  native 1:1", "dir": CLEAN, "scale": 1.0, "clean": true},
		{"name": "ORIGINAL 50% (nearest)", "dir": ORIG, "scale": 0.5, "clean": false},
		{"name": "CLEANED  50% (nearest)", "dir": CLEAN, "scale": 0.5, "clean": true},
	]

	var y := 46.0
	for row in rows:
		var s: float = row["scale"]
		var cell: float = 64.0 * s + 40.0
		var x0: float = 300.0
		get_root().add_child(_label("%s   scale=%.2f" % [row["name"], s], Vector2(24, y + 40.0 * s), 15))
		# ground line under the row (feet row = y + 126*s)
		var line := ColorRect.new()
		line.color = Color(1, 1, 1, 0.30)
		line.position = Vector2(x0 - 12.0, y + 127.0 * s)
		line.size = Vector2(COLS * cell + 8.0, 1.0)
		get_root().add_child(line)
		for i in COLS:
			var fname := "the_character_animation_sheet (%d).png" % (i + 1)
			var tag := "%s frame %d" % [("CLEAN" if row["clean"] else "ORIG"), i + 1]
			var tex := _load_checked(row["dir"] + fname, tag)
			if tex == null:
				continue
			var info := _pixel_checks(tex, tag, row["clean"])
			if row["clean"]:
				# cleaned frames must keep the ORIGINAL opaque-pixel count exactly
				if _orig_opaque.has(i):
					_check(info["opaque"] == _orig_opaque[i],
						"%s opaque px == original (%d vs %d)" % [tag, info["opaque"], _orig_opaque[i]])
			elif info["opaque"] >= 0:
				_orig_opaque[i] = info["opaque"]
			var sp := Sprite2D.new()
			sp.texture = tex
			sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sp.centered = false          # top-left; feet land on y+126 (ground line)
			sp.scale = Vector2(s, s)
			sp.position = Vector2(x0 + i * cell, y)
			get_root().add_child(sp)
			_check(sp.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
				"%s filter is NEAREST" % tag)
		y += 127.0 * s + 54.0

	get_root().add_child(_label("pivot contract: feet row y=126 in every 64x128 cell -> Godot offset Vector2(-31,-127); ground lines drawn at the feet row of each row",
		Vector2(24, 700), 14))
	print("scale_compare: built scene, graphical=%s" % _graphical)


func _physics_process(_delta: float) -> bool:
	_f += 1
	if _f == SHOT_FRAME:
		if _graphical:
			var img := get_root().get_texture().get_image()
			var out := ProjectSettings.globalize_path(SHOT)
			DirAccess.make_dir_recursive_absolute(out.get_base_dir())
			img.save_png(out)
			print("SHOT saved: %s (%dx%d)" % [out, img.get_width(), img.get_height()])
			_check(img.get_width() > 0 and img.get_height() > 0, "screenshot captured")
			# blank-shot guard: a real render has many distinct colours
			var seen := {}
			var y := 0
			while y < img.get_height() and seen.size() < 24:
				var x := 0
				while x < img.get_width() and seen.size() < 24:
					seen[img.get_pixel(x, y)] = true
					x += 3
				y += 3
			_check(seen.size() >= 8,
				"screenshot is not blank (%d distinct colours sampled)" % seen.size())
		else:
			_warn += 1
			print("WARN: headless run - no screenshot (rerun without --headless)")
	if _f >= SHOT_FRAME + 4:
		print("SCALE_COMPARE: %s (%d pass, %d fail, %d warn)" %
			["ALL PASS" if _fail == 0 else "FAILURES", _pass, _fail, _warn])
		for line in _report:
			if line.begins_with("FAIL"):
				print("  " + line)
		quit(1 if _fail > 0 else 0)
		return true
	return false
