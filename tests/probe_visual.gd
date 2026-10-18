extends SceneTree
## Visual-state probe: dump what the renderer WOULD show.
## Checks: active camera, canvas transform, every visual node's global rect,
## visibility chain, z-index, modulate. No changes to the game.

var _frames: int = 0

func _init() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	get_root().add_child(main)

func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames < 30:
		return false
	var vp := get_root()
	print("PROBE: viewport_size=%s stretch canvas_items/keep" % str(vp.size))
	var cam := vp.get_camera_2d()
	print("PROBE: active_camera_2d=%s" % ("NONE" if cam == null else str(cam.get_path()) + " pos=" + str(cam.global_position)))
	print("PROBE: canvas_transform=%s" % str(vp.get_canvas_transform()))
	_dump(vp.get_node("Main"), 0)
	quit(0)
	return true

func _dump(n: Node, depth: int) -> void:
	if depth > 4:
		return
	var pad := ""
	for i in depth:
		pad += "  "
	if n is ColorRect:
		var c := n as ColorRect
		var top_vis: bool = c.is_visible_in_tree()
		print("PROBE: %sColorRect %s rect=%s global=%s vis=%s z=%d mod=%s" % [
			pad, c.get_path(), str(c.get_rect()), str(c.get_global_rect()),
			str(top_vis), c.z_index, str(c.modulate)])
	elif n is Label:
		var l := n as Label
		print("PROBE: %sLabel %s text='%s' vis=%s" % [pad, l.get_path(), l.text, str(l.is_visible_in_tree())])
	elif n is Camera2D:
		var c2 := n as Camera2D
		print("PROBE: %sCamera2D %s current=%s pos=%s" % [pad, c2.get_path(), str(c2.is_current()), str(c2.global_position)])
	elif n is Node2D:
		var n2 := n as Node2D
		print("PROBE: %sNode2D %s pos=%s vis=%s" % [pad, n2.get_path(), str(n2.global_position), str(n2.is_visible_in_tree())])
	for ch in n.get_children():
		_dump(ch, depth + 1)
