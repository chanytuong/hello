extends SceneTree
## Debug: why is the scale_compare screenshot pure black?
## Captures at several frame counts and reports pixel samples.

var _f := 0
var _done := [false, false, false]
var _frames := [4, 20, 60]

func _init() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.12)
	bg.size = Vector2(1280, 720)
	get_root().add_child(bg)
	var sp := Sprite2D.new()
	var t: Texture2D = load("res://maincharacter/newdesign_clean/the_character_animation_sheet (1).png")
	print("texture loaded=", t != null, " size=", t.get_width() if t != null else -1,
		" exists=", ResourceLoader.exists("res://maincharacter/newdesign_clean/the_character_animation_sheet (1).png"))
	sp.texture = t
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.centered = false
	sp.position = Vector2(600, 200)
	get_root().add_child(sp)
	print("sprite visible=", sp.visible, " rect=", sp.get_rect())
	var l := Label.new()
	l.text = "debug label"
	l.position = Vector2(50, 50)
	get_root().add_child(l)
	print("viewport size=", get_root().size, " usable=", get_root().get_visible_rect().size)

func _physics_process(_d: float) -> bool:
	_f += 1
	for i in _frames.size():
		if _f == _frames[i] and not _done[i]:
			_done[i] = true
			var img := get_root().get_texture().get_image()
			print("frame=", _f, " img=", img.get_width(), "x", img.get_height(),
				" format=", img.get_format(),
				" px(5,5)=", img.get_pixel(5, 5),
				" px(640,360)=", img.get_pixel(640, 360),
				" px(610,210)=", img.get_pixel(610, 210))
			img.save_png("res://maincharacter/newdesign_clean/debug_cap_f%d.png" % _f)
	if _f >= 65:
		quit(0)
		return true
	return false
