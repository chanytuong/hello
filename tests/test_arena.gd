extends SceneTree
## V2 logic tests: Health iframes, HitBox one-hit-per-epoch, melee AI timings,
## damage-clears-jump-buffer. (The BlinkManager flow tests and the arena
## spawn-eject math were removed with the mechanic: solids can no longer appear
## on top of the player, so there is nothing to eject from.)
## Run: godot --headless --path E:\neverlookback --script res://tests/test_arena.gd

var _failures: int = 0

func _init() -> void:
	_test_health()
	_test_hitbox_epoch()
	_test_melee_timings()
	_test_damage_clears_jump_buffer()
	if _failures == 0:
		print("ARENA_TESTS: ALL PASS")
	else:
		printerr("ARENA_TESTS: %d FAILURES" % _failures)
	quit(1 if _failures > 0 else 0)

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS: " + name)
	else:
		printerr("FAIL: " + name)
		_failures += 1

func _test_health() -> void:
	var h := NLBHealth.new()
	h.max_hp = 5
	h.iframes = 1.0
	get_root().add_child(h)
	_check(h.damage(1), "health applies damage")
	_check(h.hp == 4, "health hp=4 after 1 dmg")
	_check(not h.damage(1), "health iframes block repeat hit")
	_check(h.hp == 4, "health hp unchanged during iframes")
	h.reset()
	_check(h.hp == 5, "health reset restores hp")
	h.queue_free()

func _test_hitbox_epoch() -> void:
	var holder := Node.new()
	get_root().add_child(holder)
	var health := NLBHealth.new()
	health.name = "Health"
	health.max_hp = 10
	health.iframes = 0.0  # no time gate: epoch marking is what we test
	holder.add_child(health)
	var hurt := NLBHurtBox.new()
	holder.add_child(hurt)
	var hit := NLBHitBox.new()
	hit.damage = 1
	holder.add_child(hit)
	hit.begin()
	hit._try_hit(hurt)
	hit._try_hit(hurt)  # same epoch: must not double-hit
	_check(health.hp == 9, "hitbox one hit per epoch (hp=%d)" % health.hp)
	hit.begin()  # new swing: hits again
	hit._try_hit(hurt)
	_check(health.hp == 8, "hitbox new epoch hits again (hp=%d)" % health.hp)
	holder.queue_free()

func _test_melee_timings() -> void:
	var scene: PackedScene = load("res://scenes/melee_chaser.tscn")
	var m := scene.instantiate() as NLBMeleeChaser
	get_root().add_child(m)
	_check(m.ai_state == NLBMeleeChaser.AIState.CHASE, "melee starts in CHASE")
	m._enter(NLBMeleeChaser.AIState.WINDUP)
	_check(m._state_t == m.windup_time, "melee windup timed")
	m._enter(NLBMeleeChaser.AIState.STRIKE)
	_check(m._state_t == m.strike_time, "melee strike timed")
	m.queue_free()

func _test_damage_clears_jump_buffer() -> void:
	# Rule: damage drops pending jump INTENT (no stale-buffer launch),
	# while coyote grace (physics state) is preserved.
	var scene: PackedScene = load("res://scenes/player.tscn")
	var p := scene.instantiate() as NLBPlayer
	get_root().add_child(p)
	p._jump_buf = 0.12
	p._coyote = 0.1
	p.clear_jump_intent()
	_check(p._jump_buf == 0.0, "damage clears jump buffer")
	_check(p._coyote == 0.1, "damage preserves coyote grace")
	# Full path: buffer set -> HurtBox.take_hit -> buffer gone.
	p._jump_buf = 0.12
	var hb := p.get_node("HurtBox") as NLBHurtBox
	var applied: bool = hb.take_hit(1, Vector2.ZERO)
	# NOTE: read HP through health_node(), not p.health. This test runs inside
	# SceneTree._init(), so the player's _ready() has not fired yet and the
	# @onready `health` is still Nil - reading p.health here threw a script
	# error that silently skipped every assertion below it while the suite
	# still printed ALL PASS.
	_check(applied, "fixture hit applies (hp=%d)" % hb.health_node().hp)
	_check(hb.health_node().hp == 4, "fixture hit took exactly 1 hp (hp=%d)" % hb.health_node().hp)
	_check(p._jump_buf == 0.0, "take_hit path clears jump buffer")
	p.queue_free()
