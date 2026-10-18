extends Area2D
class_name NLBProjectile
## Slow readable enemy shot. Dies on player hit (via HurtBox) or world contact.

var velocity: Vector2 = Vector2.ZERO
var life: float = 3.0

@onready var hit_box: NLBHitBox = $HitBox

func _ready() -> void:
	add_to_group("projectiles")
	hit_box.begin()  # continuous: hurts on touch until it expires or lands

func launch(pos: Vector2, vel: Vector2) -> void:
	global_position = pos
	velocity = vel

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	for body in get_overlapping_bodies():
		if body is StaticBody2D or body is TileMapLayer:
			queue_free()
			return

func _exit_tree() -> void:
	remove_from_group("projectiles")
