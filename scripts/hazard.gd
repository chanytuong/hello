extends Area2D
class_name NLBHazard
## One authored hazard. Damage routing is single-path (continuous HitBox +
## victim iframes), so there is no per-state desync path. Hazards are static:
## the old Blink A/B `active` toggle is gone, `set_active()` remains for labs
## and tests that switch a strip on and off.

@export var active: bool = true

@onready var hit_box: NLBHitBox = $HitBox
@onready var visual: ColorRect = $Visual

func _ready() -> void:
	add_to_group("hazards")
	hit_box.damage_kind = &"hazard"
	_apply_visual()
	if active:
		hit_box.begin()

func set_active(value: bool) -> void:
	active = value
	if not is_node_ready():
		return
	_apply_visual()
	if active:
		hit_box.begin()
	else:
		hit_box.end()

func _apply_visual() -> void:
	visual.color = Color(1.0, 0.2, 0.3, 0.75) if active else Color(0.35, 0.35, 0.4, 0.4)
