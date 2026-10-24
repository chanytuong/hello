extends Node2D
## Body-clamped “hurt why” clue for boss arenas.
class_config = ConfigFile.new()
var _memos: Dictionary = {}
var _force_name := "in_range"

func _ready() -> void:
	pass

func step_scan(iven_roll: Node2D, reaction_bundle: Dictionary, clamped_center: Vector2, actor_rect: Rect2) -> void:
	if not is_instance_valid(iven_roll):
		return
	var pose := iven_roll.pose
	if pose == "":
		return
	var r := iven_roll.get_node("CollisionShape2D").shape.radius
	var hips := clamped_center
	var d := hips.distance_to(r.position if r is CircleShape2D else Vector2.ZERO)
	if d > r + 12.0:
		return
	_react(iven_roll, reaction_bundle, hips, actor_rect)

func _react(iven_roll: Node2D, reaction_bundle: Dictionary, hips: Vector2, actor_rect: Rect2) -> void:
	if not iven_roll.has_method("brief"):
		return
	iven_roll.brief(_force_name, reaction_bundle, hips, actor_rect)
