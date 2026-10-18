extends SceneTree
## Regression: (1) restart inside a hitstop window must not strand
## Engine.time_scale; (2) continuous HitBoxes re-arm every tick.
## Run: godot --headless --path E:\neverlookback --script res://tests/test_strand.gd

var _failures: int = 0
var _frames: int = 0
var _main: Node
var _phase: int = 0
var _pf: int = 0
var _saw_slow: bool = false

func _init() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	get_root().add_child(_main)
	current_scene = _main

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS: " + name)
	else:
		printerr("FAIL: " + name)
		_failures += 1

func _physics_process(_delta: float) -> bool:
	_frames += 1
	_pf += 1
	match _phase:
		0:  # land a swing -> hitstop engages (time_scale dips)
			var p := get_first_node_in_group("player") as NLBPlayer
			if _pf == 1:
				p.global_position = Vector2(990, 599)
				p.facing = 1
				for e in get_nodes_in_group("enemies"):
					if e is NLBMeleeChaser:
						e.global_position = Vector2(1005, 599)
				Input.action_press("attack")
			if _pf == 3:
				Input.action_release("attack")
			if Engine.time_scale < 1.0:
				_saw_slow = true
			if _pf == 10:
				_check(_saw_slow, "strand hitstop engaged (slow-mo seen)")
				var g := _main.get_node(".") as NLBGame
				g._restart()  # restart INSIDE the 45ms freeze window
				_phase = 1
				_pf = 0
		1:  # after reload + real time past the freeze, speed must be normal
			if _pf == 40:
				_check(Engine.time_scale == 1.0, "strand no stranded time_scale (%.2f)" % Engine.time_scale)
				_phase = 2
				_pf = 0
				_test_rearm_setup()
		2:
			if _pf == 60:
				_check(_rearm_health.hp < 10, "strand continuous re-arms (hp=%d)" % _rearm_health.hp)
				if _failures == 0:
					print("STRAND_TESTS: ALL PASS")
				else:
					printerr("STRAND_TESTS: %d FAILURES" % _failures)
				Engine.time_scale = 1.0
				quit(1 if _failures > 0 else 0)
				return true
	return false

var _rearm_health: NLBHealth
var _rearm_hit: NLBHitBox
var _rearm_hurt: NLBHurtBox

func _test_rearm_setup() -> void:
	var holder := Node.new()
	get_root().add_child(holder)
	_rearm_health = NLBHealth.new()
	_rearm_health.name = "Health"
	_rearm_health.max_hp = 10
	_rearm_health.iframes = 0.0
	holder.add_child(_rearm_health)
	_rearm_hurt = NLBHurtBox.new()
	holder.add_child(_rearm_hurt)
	var hurt_shape := CollisionShape2D.new()
	var hurt_circle := CircleShape2D.new()
	hurt_circle.radius = 10.0
	hurt_shape.shape = hurt_circle
	_rearm_hurt.add_child(hurt_shape)
	_rearm_hit = NLBHitBox.new()
	_rearm_hit.damage = 1
	_rearm_hit.continuous = true
	_rearm_hit.tick = 0.05
	holder.add_child(_rearm_hit)
	var hit_shape := CollisionShape2D.new()
	var hit_circle := CircleShape2D.new()
	hit_circle.radius = 10.0
	hit_shape.shape = hit_circle
	_rearm_hit.add_child(hit_shape)
	_rearm_hit.begin()
