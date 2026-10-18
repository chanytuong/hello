extends Node2D
class_name LabCannon
## Test cannon — zone B's pellet source.
##
## Fires slow LAB pellets (Team.LAB = 0 damage) straight along the barrel on a
## fixed cadence. It exists to be swapped with: catch a pellet in flight and
## give its velocity to a crate, or watch a parked pellet deflate. It never
## homes, it never leads its target, and it keeps at most `max_alive` of its
## own shots flying — a field of parked shots stops new fire until they expire.

const ProjectileScene: PackedScene = preload("res://labs/objects/lab_projectile.tscn")

@export var direction: Vector2 = Vector2.LEFT
@export var speed: float = 200.0
@export var interval: float = 1.7
@export var max_alive: int = 4
@export var muzzle_offset: Vector2 = Vector2(-26.0, 0.0)
@export var barrel_color: Color = Color(0.55, 0.62, 0.7)

var _t: float = 0.8
var _flash: float = 0.0
var _font: Font = null

func _ready() -> void:
	add_to_group("lab_cannons")
	_font = ThemeDB.fallback_font

func ready_to_fire() -> bool:
	return _t <= 0.0 and _count_mine() < max_alive

func debug_line() -> String:
	return "CANNON x%d firing" % _count_mine()

func _physics_process(delta: float) -> void:
	_t -= delta
	_flash = maxf(_flash - delta, 0.0)
	if ready_to_fire():
		fire()
	queue_redraw()

func fire() -> LabProjectile:
	var holder := get_tree().current_scene
	if holder == null:
		holder = get_tree().root
	var container := holder.get_node_or_null("Projectiles")
	if container == null:
		container = holder
	var p := ProjectileScene.instantiate() as LabProjectile
	p.team = LabProjectile.Team.LAB
	p.color = Color(0.85, 0.95, 0.35)
	p.max_life = 6.0
	p.source = self
	container.add_child(p)
	p.launch(global_position + muzzle_offset.rotated(direction.angle()), direction.normalized() * speed)
	_t = interval
	_flash = 0.12
	return p

func _count_mine() -> int:
	var n := 0
	for node in get_tree().get_nodes_in_group("lab_projectiles"):
		var p := node as LabProjectile
		if p != null and p.source == self and not p.is_retiring():
			n += 1
	return n

func _draw() -> void:
	var side := signf(direction.x)
	if side == 0.0:
		side = -1.0
	# Base.
	draw_rect(Rect2(-16, -22, 32, 22), Color("2f3946"), true)
	draw_line(Vector2(-16, -22), Vector2(16, -22), barrel_color.darkened(0.2), 2.0)
	# Barrel.
	draw_rect(Rect2(-26 if side < 0 else 0, -14, 26, 10), barrel_color, true)
	draw_rect(Rect2(-26 if side < 0 else 0, -14, 26, 10), barrel_color.darkened(0.4), false, 1.0)
	if _flash > 0.0:
		draw_circle(Vector2(muzzle_offset.x, muzzle_offset.y), 9.0, Color(1.0, 0.95, 0.4, _flash / 0.12))
	if _font != null:
		draw_string(_font, Vector2(-40, -32), "PELLETS %d/%d" % [_count_mine(), max_alive],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.75, 0.85, 0.95, 0.85))
