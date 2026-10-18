extends Area2D
class_name LabProjectile
## Lab shot — the zone B experiment object.
##
## Explicit team rules:
##   LAB   — experiment pellet, 0 damage (motion experiments, not threats)
##   ENEMY — gunner shot, damages the player through the normal HitBox/HurtBox
##           route, with knockback. Never damages other enemies.
##
## Physics rules the swap contract cares about:
##   * `velocity` is the REAL current velocity; the swap adapter reads and
##     writes exactly this value — nothing is stored, nothing is re-derived.
##   * `life` always runs. A shot that has been stopped deflates after a short
##     parked timer instead of accumulating in the level as a fake hazard.
##   * the shot dies on the first solid thing (world, props, machines, player)
##     and can therefore be eaten by a crate.
##   * NO HOMING. The direction is whatever it is flying right now.

enum Team { LAB, ENEMY }

const MAX_LIVE := 16
const PARKED_SPEED := 14.0
const PARKED_LIFE := 1.6
const RETIRE_TIME := 0.14

@export var team: int = Team.LAB
@export var damage: int = 1
@export var knockback: Vector2 = Vector2(200.0, -70.0)
@export var max_life: float = 6.0
@export var radius: float = 7.0
@export var color: Color = Color(0.85, 0.95, 0.35)

var velocity: Vector2 = Vector2.ZERO
var life: float = 6.0
## Who fired this shot (the cannon uses it to cap its own live pellets).
var source: Node = null

var _parked_t: float = 0.0
var _retiring: bool = false
var _retire_t: float = 0.0

@onready var hit_box: NLBHitBox = $HitBox
@onready var visual: ColorRect = $Visual
@onready var swap_target: NLBMotionSwapTarget = $SwapTarget

func _ready() -> void:
	add_to_group("projectiles")
	add_to_group("lab_projectiles")
	life = max_life
	# Solid contact detection happens on THIS area: world, props, machines and
	# the player block a shot. Enemies do not (a shot passes over its own team,
	# and the muzzle must never kill its own shot).
	collision_layer = 0
	collision_mask = 1 | 2 | 256 | 512
	monitoring = true
	if visual != null:
		visual.color = color
		visual.pivot_offset = visual.size * 0.5
	if hit_box != null:
		if team == Team.ENEMY:
			hit_box.damage = damage
			hit_box.knockback = knockback
			hit_box.collision_layer = 64
			hit_box.collision_mask = 128
			hit_box.begin()
		else:
			hit_box.end()
			hit_box.collision_layer = 0
			hit_box.collision_mask = 0
	if swap_target != null:
		swap_target.adapter = NLBMotionProjectileAdapter.new(self)
		swap_target.display_name = "SHOT" if team == Team.ENEMY else "PELLET"
		swap_target.anchor_offset = Vector2.ZERO
	_enforce_live_cap()

func launch(pos: Vector2, vel: Vector2) -> void:
	global_position = pos
	velocity = vel
	life = max_life
	_parked_t = 0.0

func is_swap_selectable() -> bool:
	return not _retiring and life > 0.0

func is_retiring() -> bool:
	return _retiring

## Lab reset tool: retire immediately, no dangling half-freed target.
func retire_now() -> void:
	_retire()

func debug_line() -> String:
	return "%s v=(%.0f, %.0f) life=%.1fs" % [swap_target.display_name, velocity.x, velocity.y, life]

func _physics_process(delta: float) -> void:
	if _retiring:
		_retire_t -= delta
		if visual != null:
			visual.scale = Vector2.ONE * clampf(_retire_t / RETIRE_TIME, 0.0, 1.0)
		if _retire_t <= 0.0:
			queue_free()
		return
	global_position += velocity * delta
	life -= delta
	if velocity.length() < PARKED_SPEED:
		_parked_t += delta
		# A parked shot must LOOK like it is about to go: it shrinks. This is
		# the readable half of "no accumulating stationary shots".
		if visual != null:
			visual.scale = Vector2.ONE * lerpf(1.0, 0.45, clampf(_parked_t / PARKED_LIFE, 0.0, 1.0))
	else:
		_parked_t = 0.0
		if visual != null:
			visual.scale = Vector2.ONE
	if life <= 0.0 or _parked_t >= PARKED_LIFE:
		_retire()
		return
	var bodies := get_overlapping_bodies()
	if not bodies.is_empty():
		_retire()

func _retire() -> void:
	if _retiring:
		return
	_retiring = true
	_retire_t = RETIRE_TIME
	velocity = Vector2.ZERO
	life = 0.0
	if hit_box != null:
		hit_box.end()
	if swap_target != null:
		swap_target.enabled = false

## Bounded population: the oldest live shot (least life left) retires early
## rather than letting a new one pile on top. Stationary shots are already on
## their parked timer, so this can never grow an infinite field.
func _enforce_live_cap() -> void:
	var live := get_tree().get_nodes_in_group("lab_projectiles")
	if live.size() < MAX_LIVE:
		return
	var oldest: LabProjectile = null
	for n in live:
		var p := n as LabProjectile
		if p == null or p == self or p._retiring:
			continue
		if oldest == null or p.life < oldest.life:
			oldest = p
	if oldest != null:
		oldest._retire()

func _exit_tree() -> void:
	remove_from_group("projectiles")
	remove_from_group("lab_projectiles")
