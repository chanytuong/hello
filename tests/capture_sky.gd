extends SceneTree
## PHASE 11 supplement: jump-peak shots against open sky (the documented
## trousers-vs-#0D0F17 contrast weak point was never framed in the main run).

const SHOT_DIR := "res://art/prototype/character/capture/"
var _f := 0
var _t := 0
var _m: Node = null

func _init() -> void:
	_m = load("res://scenes/main.tscn").instantiate()
	get_root().add_child(_m)

func _physics_process(_delta: float) -> bool:
	_f += 1
	if _f < 30:
		return false
	_t += 1
	if _t == 3:
		Input.action_press("jump")
	elif _t == 17 or _t == 22 or _t == 27 or _t == 32:
		var p = _m.get_node("Player")
		var tag := "21_air_rise_%02d" % _t if _t < 22 else "22_air_peak_%02d" % _t
		get_root().get_texture().get_image().save_png(SHOT_DIR + tag + ".png")
		print("SHOT %s y=%.1f feet_head_span=%.0f..%.0f shown=%s vy=%.0f" % [
			tag, p.global_position.y, p.global_position.y - 62, p.global_position.y,
			p._frame_shown, p.velocity.y])
	elif _t >= 60:
		Input.action_release("jump")
		print("DONE")
		quit(0)
		return true
	return false
