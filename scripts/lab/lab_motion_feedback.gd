extends Node2D
class_name LabMotionFeedback
## Bounded contact sparks / motion streaks. No damage, forces, or area effects.

@export var particles_enabled: bool = true
@export var streaks_enabled: bool = true
var _sparks: Array[Dictionary] = []
var _streaks: Array[Dictionary] = []

func impact_at(point: Vector2, normal: Vector2, speed: float) -> void:
	if not particles_enabled:
		return
	for i in 6:
		var direction := normal.rotated(-1.15 + float(i) * 0.46)
		_sparks.append({"pos": point, "velocity": direction * minf(speed * 0.15, 160.0), "time": 0.16})
	while _sparks.size() > 60:
		_sparks.pop_front()

func _physics_process(delta: float) -> void:
	for i in range(_sparks.size() - 1, -1, -1):
		_sparks[i].time -= delta
		_sparks[i].pos += _sparks[i].velocity * delta
		if _sparks[i].time <= 0.0:
			_sparks.remove_at(i)
	for i in range(_streaks.size() - 1, -1, -1):
		_streaks[i].time -= delta
		if _streaks[i].time <= 0.0:
			_streaks.remove_at(i)
	if streaks_enabled:
		for n in get_tree().get_nodes_in_group("swap_targets"):
			var target := n as NLBMotionSwapTarget
			if target == null or not target.is_valid() or target.channel() != NLBMotionChannels.Channel.LINEAR or target.kind() == "PROJECTILE":
				continue
			var v := target.read_motion()
			if v.length() > 650.0:
				_streaks.append({"pos": target.anchor_world(), "tail": -v.normalized() * 18.0, "time": 0.065})
	while _streaks.size() > 48:
		_streaks.pop_front()
	queue_redraw()

func _draw() -> void:
	for spark in _sparks:
		draw_line(spark.pos, spark.pos - spark.velocity.normalized() * 4.0, Color(1.0, 0.75, 0.45, spark.time / 0.16), 1.5)
	for streak in _streaks:
		draw_line(streak.pos, streak.pos + streak.tail, Color(0.65, 0.85, 1.0, 0.35 * streak.time / 0.065), 1.0)
