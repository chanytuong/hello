extends CharacterBody2D
class_name LabEnemy
## Shared body for every lab enemy: gravity, collisions, hp, hit feedback and —
## the important one — THE MOTION-SWAP OVERRIDE CONTRACT.
##
## A short received-motion window suspends AI acceleration. Gravity and contact
## solves continue, and collision responses are never overwritten next frame.
## After recovery, each existing AI resumes from its current position.

signal died
signal impact(strength: float)   # wall/body impacts worth a camera beat

@export_group("Body")
@export var hp: int = 3
@export var body_color: Color = Color(0.9, 0.3, 0.45)
@export var swapped_color: Color = Color(0.72, 0.55, 1.0)
@export_group("Motion Swap")
## How long a received motion owns this body before the AI resumes.
@export var swap_override_duration: float = 0.65
@export var gravity: float = 1400.0
@export_group("Contact impact thresholds")
@export var heavy: bool = false
@export var impact_stagger_speed: float = 220.0
@export var impact_damage_speed: float = 430.0
@export var impact_lethal_speed: float = 680.0
@export var human_projectile_kill_speed: float = 480.0
@export var impact_stun_duration: float = 0.30

var swap_override_t: float = 0.0
var swapped_motion: Vector2 = Vector2.ZERO
var spawn_position: Vector2 = Vector2.ZERO
var spawned: bool = false

var _kb: Vector2 = Vector2.ZERO
var _flash_t: float = 0.0
var _stagger_t: float = 0.0
var _alive: bool = true
var _combat_hitstop_left := 0.0
var _indicator: Line2D
var _touch_box: NLBHitBox = null

@onready var body_vis: ColorRect = $Body
@onready var health: NLBHealth = $Health
@onready var swap_target: NLBMotionSwapTarget = $SwapTarget

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("fighters")
	add_to_group("lab_enemies")
	collision_mask |= 2 | 4 # real player/enemy and enemy/enemy contacts
	if not spawned:
		spawn_position = global_position
	if body_vis != null:
		body_vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body_vis.pivot_offset = body_vis.size * 0.5
	if health != null:
		health.max_hp = hp
		health.iframes = 0.35
		health.reset()
		health.changed.connect(_on_damaged)
		health.died.connect(_on_health_died)
	_indicator = Line2D.new()
	_indicator.name = "MotionIndicator"
	_indicator.width = 3.0
	_indicator.z_index = 3
	add_child(_indicator)
	if swap_target != null:
		var adapter := NLBMotionCharacterAdapter.new(self)
		adapter.override_time = swap_override_duration
		swap_target.adapter = adapter
		if swap_target.display_name == "TARGET":
			swap_target.display_name = type_label()
	# Body presence is never an attack. Only Charger explicitly arms this
	# existing component, and its damage requires real physical contact.
	_touch_box = get_node_or_null("TouchHitBox") as NLBHitBox
	if _touch_box != null:
		_touch_box.end()
	platform_floor_layers &= ~6 # characters are not moving platforms
	_reset_ai()

func set_spawn(pos: Vector2) -> void:
	spawn_position = pos
	spawned = true

func type_label() -> String:
	return "ENEMY"

## The player as a node, or null (headless runs may have no player).
func player_node() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

## One line for the debug overlay / tests.
func debug_line() -> String:
	var s := "%s v=(%.0f, %.0f)" % [type_label(), velocity.x, velocity.y]
	if swap_override_t > 0.0:
		s += " HOLDING %.1fs" % swap_override_t
	return s

## Public state name for the overlay and tests. Subclasses override.
func ai_state_name() -> String:
	return "-"

## Lab recovery rule: an enemy that has fallen out of its zone is retired
## (freed) and the lab respawns a fresh copy at its spawn point. Deliberately
## NOT die(): it is not damage, and it must not leave a body behind.
func retire() -> void:
	if not _alive:
		return
	_alive = false
	if swap_target != null:
		swap_target.enabled = false
	remove_from_group("enemies")
	remove_from_group("fighters")
	died.emit()
	queue_free()

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	if _combat_hitstop_left>0.000001:
		_combat_hitstop_left=maxf(0.0,_combat_hitstop_left-delta)
		_update_body_visual()
		return
	_flash_t = maxf(_flash_t - delta, 0.0)
	_stagger_t = maxf(_stagger_t - delta, 0.0)
	if swap_override_t > 0.0:
		_drive_swapped_motion(delta)
		swap_override_t = maxf(swap_override_t - delta, 0.0)
		if swap_override_t <= 0.0:
			_on_swap_override_end()
	elif _stagger_t > 0.0:
		_apply_gravity(delta)
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	else:
		_ai_step(delta)
	# Exchange knockback lives OUTSIDE the movement arms so a hit can always
	# move the body, even while a swapped motion owns it.
	_kb = _kb.move_toward(Vector2.ZERO, 1400.0 * delta)
	velocity += _kb
	var incoming := velocity
	move_and_slide()
	NLBImpactResponse.solve_slides(self, incoming)
	_update_body_visual()
	_update_indicator()

## The override arm integrates received motion, with gravity and real collisions.
func _drive_swapped_motion(delta: float) -> void:
	# Integrate the received velocity. Never reassert it after a collision.
	if not is_on_floor() or velocity.y < 0.0:
		velocity.y += gravity * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

# ------------------------------------------------------- Motion Swap contract

func motion_swap_read() -> Vector2:
	return velocity

func motion_swap_apply(motion: Vector2, duration: float) -> void:
	swapped_motion = motion
	velocity = motion
	swap_override_t = maxf(duration, 0.0)
	_on_swapped(motion)

func is_swap_selectable() -> bool:
	return _alive and health != null and health.hp > 0 and not is_queued_for_deletion()

func receive_contact_motion(motion: Vector2) -> void:
	if not _alive:
		return
	velocity += motion * (0.65 if heavy else 1.0)
	swap_override_t = maxf(swap_override_t, 0.25)

func receive_motion_impact(speed: float, normal: Vector2, other: Object, incoming: Vector2, context: Dictionary = {}) -> void:
	if not _alive:
		return
	if swap_target != null:
		swap_target.clear_overdrive()
	if speed >= impact_stagger_speed:
		_stagger_t = maxf(_stagger_t, impact_stun_duration)
		_flash_t = 0.08
		impact.emit(speed)
	var human_hit := other is NLBPlayer and (other as NLBPlayer).living_projectile
	var damage_amount := 0
	if speed >= impact_lethal_speed or (human_hit and speed >= human_projectile_kill_speed):
		damage_amount = 3 if heavy else health.max_hp
	elif speed >= impact_damage_speed:
		damage_amount = 2
	elif speed >= impact_stagger_speed:
		damage_amount = 1
	if damage_amount > 0:
		var info := context.duplicate()
		info.merge({"kind": "impact", "source": str(other.get_path()) if other is Node else str(other),
			"velocity": incoming, "normal": normal, "closing_speed": speed}, true)
		health.damage(damage_amount, info)
	# A real wall removes its normal component; empty flight never comes here.
	if other is StaticBody2D and absf(normal.x) > 0.5:
		velocity = incoming.slide(normal)
		swap_override_t = 0.0
		_on_swap_override_end()

func reset_motion() -> void:
	velocity = Vector2.ZERO
	swapped_motion = Vector2.ZERO
	swap_override_t = 0.0
	_kb = Vector2.ZERO
	_stagger_t = 0.0
	if swap_target != null:
		swap_target.clear_overdrive()
	_on_swap_override_end()

func fall_distance() -> float:
	return global_position.y - spawn_position.y

# -------------------------------------------------------------- damage / life

func apply_knockback(kb: Vector2) -> void:
	_kb += kb
	_stagger_t = maxf(_stagger_t, 0.12)
	if swap_override_t <= 0.0:
		_flash_t = 0.05

func apply_combat_hitstop(seconds: float) -> void:
	_combat_hitstop_left=maxf(_combat_hitstop_left,seconds)

func _on_damaged(_cur: int, _maximum: int) -> void:
	_flash_t = 0.06

func _on_health_died() -> void:
	die()

func die() -> void:
	if not _alive:
		return
	_alive = false
	if swap_target != null:
		swap_target.enabled = false
	remove_from_group("enemies")
	remove_from_group("fighters")
	died.emit()
	queue_free()

func _update_body_visual() -> void:
	if body_vis == null:
		return
	if _flash_t > 0.0:
		body_vis.color = Color.WHITE
	elif swap_override_t > 0.0:
		# Swapped state is a DIFFERENT colour, not a variation: at a glance you
		# can tell an object that is running someone else's motion.
		body_vis.color = swapped_color
	elif _stagger_t > 0.0:
		body_vis.color = body_color.lightened(0.4)
	else:
		body_vis.color = body_color

## Motion indicator: an arrow along the body's actual velocity. Length is
## speed-scaled, and it turns into the swapped colour while a received motion
## is running. This is the visible counterpart of the debug overlay's numbers.
func _update_indicator() -> void:
	if _indicator == null:
		return
	var v := velocity
	if v.length() < 8.0:
		_indicator.clear_points()
		return
	var dir := v.normalized()
	var length: float = clampf(v.length() / 8.0, 6.0, 44.0)
	var origin := Vector2(0, -22)
	_indicator.clear_points()
	_indicator.add_point(origin)
	_indicator.add_point(origin + dir * length)
	var arrow := dir * (length - 6.0)
	_indicator.add_point(origin + arrow + dir.rotated(PI * 0.5) * 4.0)
	_indicator.add_point(origin + arrow + dir.rotated(-PI * 0.5) * 4.0)
	_indicator.add_point(origin + arrow)
	_indicator.default_color = swapped_color if swap_override_t > 0.0 else body_color.lightened(0.25)

# ------------------------------------------------------------- reset (lab API)

func reset_state() -> void:
	_combat_hitstop_left=0.0
	if not is_instance_valid(self):
		return
	global_position = spawn_position
	if swap_target != null:
		swap_target.clear_overdrive()
	velocity = Vector2.ZERO
	swapped_motion = Vector2.ZERO
	swap_override_t = 0.0
	_kb = Vector2.ZERO
	_flash_t = 0.0
	_stagger_t = 0.0
	_alive = true
	if swap_target != null:
		swap_target.enabled = true
	if health != null:
		health.reset()
	_reset_ai()

# ------------------------------------------------------------------- hooks

func _ai_step(_delta: float) -> void:
	_apply_gravity(_delta)
	velocity.x = 0.0

func _on_swapped(_motion: Vector2) -> void:
	pass

func _on_swap_override_end() -> void:
	pass

func _reset_ai() -> void:
	pass
