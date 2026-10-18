extends SceneTree
## PHASE 3 / PHASE 11 probe: does the perception fracture read as AUTHORED?
## Prints the transform frame by frame so the peak can be seen HOLDING
## before the snap - that hold is the difference between an authored beat
## and a rendering bug. Read-only: stages the pickup, changes no game code.

var _f: int = 0
var _main: Node
var _started := false
var _rows: Array = []

func _init() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	get_root().add_child(_main)
	current_scene = _main

func _p() -> NLBPlayer:
	return get_first_node_in_group("player") as NLBPlayer

func _prop() -> NLBProp:
	return get_first_node_in_group("props") as NLBProp

func _physics_process(_delta: float) -> bool:
	_f += 1
	var p := _p()
	var prop := _prop()
	if p == null or prop == null:
		return false

	if _f == 1:
		# Clear the room so nothing interferes with the read.
		for e in get_nodes_in_group("enemies"):
			e.global_position = Vector2(1230, 599)
		p.global_position = prop.global_position
		p.velocity = Vector2.ZERO
		return false

	if not _started and prop.state == NLBProp.State.HELD:
		_started = true

	if _started:
		_rows.append({
			"f": _f,
			"t": snappedf(prop._tf_t, 0.001),
			"real_vis": prop.reality.visible,
			"rsx": snappedf(prop.reality.scale.x, 0.01),
			"rsy": snappedf(prop.reality.scale.y, 0.01),
			"rrot": snappedf(prop.reality.rotation, 0.01),
			"bands": "%.2f/%.2f/%.2f" % [
				prop.seg1.rotation, prop.seg2.rotation, prop.seg3.rotation],
			"hero_vis": prop.hero.visible,
			"ha": snappedf(prop.hero.modulate.a, 0.01),
			"hsx": snappedf(prop.hero.scale.x, 0.01),
			"hrot": snappedf(prop.hero.rotation, 0.01),
			"pose": p.perception_pose,
		})

	if _started and (prop._tf_t >= NLBProp.TRANSFORM_TIME or _rows.size() >= 45):
		_report()
		Engine.time_scale = 1.0
		quit(0)
		return true
	if _f > 400:
		print("TRANSFORM_TIMELINE: no pickup started (t=%.3f)" % prop._tf_t)
		quit(1)
		return true
	return false

func _report() -> void:
	print("TRANSFORM_TIMELINE frames through the perception break")
	for r in _rows:
		print("f%-3d t=%.3f real=%-5s rsc(%5.2f,%5.2f) rrot=%+.2f bands=%-22s | hero=%-5s a=%.2f hsx=%.2f hrot=%+.2f | pose=%d" % [
			r["f"], r["t"], r["real_vis"], r["rsx"], r["rsy"], r["rrot"], r["bands"],
			r["hero_vis"], r["ha"], r["hsx"], r["hrot"], r["pose"]])
	print("TRANSFORM_TIMELINE_DONE rows=%d" % _rows.size())
