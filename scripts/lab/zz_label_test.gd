extends Node2D
func _ready() -> void:
	var c := ColorRect.new()
	c.size = Vector2(1280, 720)
	c.color = Color(0.05, 0.06, 0.08)
	add_child(c)
	var l := Label.new()
	l.text = "IVEN / JUMP v01  ?  LABEL TEST"
	l.position = Vector2(100, 100)
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color("#e9eff7"))
	add_child(l)
	var l2 := Label.new()
	l2.text = "SECOND LINE / 82x82 / 30 FPS"
	l2.position = Vector2(100, 200)
	l2.add_theme_font_size_override("font_size", 14)
	l2.add_theme_color_override("font_color", Color("#8f9db2"))
	add_child(l2)
	var cl := CanvasLayer.new()
	cl.layer = 10
	add_child(cl)
	var ctl := Control.new()
	ctl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(ctl)
	var l3 := Label.new()
	l3.text = "CANVASLAYER LABEL / 24 PX"
	l3.position = Vector2(100, 300)
	l3.add_theme_font_size_override("font_size", 24)
	l3.add_theme_color_override("font_color", Color("#ffb35c"))
	ctl.add_child(l3)
