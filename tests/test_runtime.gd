extends SceneTree
## Headless runtime: instantiate the real main scene, drive it with synthetic
## input across physics frames, assert observable state changes.
## Run: godot --headless --path E:\neverlookback --script res://tests/test_runtime.gd

var _failures: int = 0
var _frames: int = 0
var _main: Node
var _x0: float = 0.0
var _y_before_jump: float = 0.0
var _jumped_up: bool = false

func _init() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	get_root().add_child(_main)

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS: " + name)
	else:
		printerr("FAIL: " + name)
		_failures += 1

func _physics_process(_delta: float) -> bool:
	_frames += 1
	var player := get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		printerr("FAIL: no player in scene")
		return true
	if _frames == 1:
		_x0 = player.global_position.x
		Input.action_press("move_right")
	if _frames == 25:
		_check(player.global_position.x > _x0 + 40.0, "runtime player runs right (x=%.0f)" % player.global_position.x)
		_check(player.is_on_floor(), "runtime player landed on floor")
		_y_before_jump = player.global_position.y
		Input.action_press("jump")
	if _frames == 32:
		if player.global_position.y < _y_before_jump - 10.0:
			_jumped_up = true
		Input.action_release("jump")
	if _frames == 45:
		_check(_jumped_up, "runtime jump rises")
		Input.action_release("move_right")
	if _frames == 75:
		var plat := _main.get_node("Arena/PlatformA") as StaticBody2D
		_check(plat.visible, "runtime platform present (one authored arena)")
		var hz := _main.get_node("Arena/Hazard") as NLBHazard
		_check(hz.active, "runtime hazard strip live")
	if _frames == 120:
		var enemies := get_nodes_in_group("enemies")
		_check(enemies.size() >= 1, "runtime enemies present (%d)" % enemies.size())
		_check(player.health.hp > 0, "runtime player alive (hp=%d)" % player.health.hp)
		if _failures == 0:
			print("RUNTIME_TESTS: ALL PASS")
		else:
			printerr("RUNTIME_TESTS: %d FAILURES" % _failures)
		quit(1 if _failures > 0 else 0)
		return true
	return false
