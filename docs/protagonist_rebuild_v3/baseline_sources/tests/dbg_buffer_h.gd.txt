extends SceneTree
## Deterministic: airborne stale-buffer + mid-air damage, then landing.
## Proves whether a jump pressed BEFORE damage fires AFTER it.

var _frames: int = 0

func _init() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	get_root().add_child(main)
	current_scene = main

func _physics_process(_delta: float) -> bool:
	_frames += 1
	var p := get_first_node_in_group("player") as NLBPlayer
	if _frames == 1:
		p.global_position = Vector2(640, 300)  # airborne, falling
		p.velocity = Vector2.ZERO
		for e in get_nodes_in_group("enemies"):
			if e is NLBMeleeChaser:
				e.global_position = Vector2(640, 599)  # touch column below
				e.velocity = Vector2.ZERO
	if _frames == 25:
		# Simulate a jump press made ~0.07s before touchdown (buffer live).
		p._jump_buf = 0.1
		print("H-PROBE: buffer armed late-fall at f=25")
	if _frames == 20:
		# Force a slam strike while the player is mid-fall in range.
		for e in get_nodes_in_group("enemies"):
			if e is NLBMeleeChaser:
				e.ai_state = NLBMeleeChaser.AIState.WINDUP
				e._state_t = 0.01
	if _frames >= 120:
		print("H-PROBE: done hp=%d y=%.0f" % [p.health.hp, p.global_position.y])
		Engine.time_scale = 1.0
		quit(0)
		return true
	return false
