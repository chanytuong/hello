extends CharacterBody2D
class_name NLBRangedEnemy
## Vertical pressure with explicit flow: HOLD -> AIM (0.5s, aim line tracks,
## then direction LOCKS) -> FIRE (one projectile along locked dir) -> RECOVER.
## Never spams: full 2.2s cycle. Touch damage included like the chaser.

signal died
signal fired

enum AIState { HOLD, AIM, RECOVER }

@export var gravity: float = 1400.0
@export var fire_cycle: float = 2.0
@export var aim_time: float = 0.45
@export var lock_freeze: float = 0.15  # final aim window: no tracking, shot is committed
@export var recover_time: float = 0.3
@export var projectile_speed: float = 360.0
@export var sight_range: float = 900.0

var ai_state: int = AIState.HOLD

const RECOIL_TIME := 0.18   # visual only; identical to the chaser's

var _state_t: float = 0.0
var _locked_dir: Vector2 = Vector2.LEFT
var _flash_t: float = 0.0
var _recoil_t: float = 0.0   # PHASE 7: visual hit reaction, same rules as melee
var _recoil_dir: float = 1.0
var _kb: Vector2 = Vector2.ZERO  # see melee_chaser: must live outside `velocity`

@onready var body_vis: ColorRect = $Body
@onready var aim_line: Line2D = $AimLine
@onready var touch_box: NLBHitBox = $TouchHitBox
@onready var health: NLBHealth = $Health
@onready var muzzle: Marker2D = $Muzzle

const ProjectileScene: PackedScene = preload("res://scenes/projectile.tscn")

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("fighters")
	touch_box.end() # detection/body contact never causes damage
	touch_box.knockback = Vector2.ZERO  # set per-frame below (directional)
	if body_vis != null:
		body_vis.pivot_offset = Vector2(15, 19)
	aim_line.visible = false
	health.changed.connect(_on_damaged)
	health.died.connect(func() -> void:
		died.emit()
		queue_free())

func apply_knockback(kb: Vector2) -> void:
	_kb = kb
	if kb.x != 0.0:
		_recoil_dir = signf(kb.x)
		_recoil_t = RECOIL_TIME

func _on_damaged(_cur: int, _maximum: int) -> void:
	# Same 0.03s as melee: mark the contact frame, then get out of the way.
	_flash_t = 0.03
	_recoil_t = RECOIL_TIME

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	velocity.x = 0.0  # holds ground
	_kb = _kb.move_toward(Vector2.ZERO, 1400.0 * delta)
	velocity += _kb
	move_and_slide()
	_apply_pose()
	var player := get_tree().get_first_node_in_group("player") as Node2D
	_state_t -= delta
	_flash_t -= delta
	_recoil_t = maxf(_recoil_t - delta, 0.0)
	if player != null:
		touch_box.knockback = Vector2(signf(player.global_position.x - global_position.x) * 120.0, 0.0)
	match ai_state:
		AIState.HOLD:
			_set_body_color(Color(0.65, 0.4, 0.95))
			aim_line.visible = false
			if _state_t <= 0.0 and player != null and _in_sight(player):
				ai_state = AIState.AIM
				_state_t = aim_time
		AIState.AIM:
			_set_body_color(Color(1.0, 0.4, 0.2))
			if _state_t > lock_freeze and player != null:
				# Track only until the lock window; the final slice is committed
				# and the aim line shows exactly what will fire.
				_locked_dir = (player.global_position - muzzle.global_position).normalized()
			_draw_locked_aim()
			if _state_t <= 0.0:
				_fire_locked()
				ai_state = AIState.RECOVER
				_state_t = recover_time
				aim_line.visible = false
		AIState.RECOVER:
			_set_body_color(Color(0.65, 0.4, 0.95))
			if _state_t <= 0.0:
				ai_state = AIState.HOLD
				_state_t = fire_cycle

func _set_body_color(c: Color) -> void:
	if body_vis != null and _flash_t <= 0.0:
		body_vis.color = c
	elif body_vis != null:
		body_vis.color = Color.WHITE

## PHASE 7, ranged copy: directional lean + squash on the ColorRect only.
## No transform, no velocity, no collision change - so it can never launch,
## spin or ragdoll. Instant onset, settle over RECOIL_TIME.
func _apply_pose() -> void:
	if body_vis == null:
		return
	if _recoil_t <= 0.0:
		body_vis.rotation = 0.0
		body_vis.scale = Vector2.ONE
		return
	var raw := clampf(_recoil_t / RECOIL_TIME, 0.0, 1.0)
	# Hold the extreme pose first, then release - identical to melee, so
	# both enemies react the same way on the contact frame.
	var e := clampf(raw * 1.25, 0.0, 1.0)
	body_vis.rotation = 0.42 * _recoil_dir * e
	body_vis.scale = Vector2(1.0 + 0.28 * e, 1.0 - 0.34 * e)

func _in_sight(player: Node2D) -> bool:
	return absf(player.global_position.x - global_position.x) <= sight_range

func _draw_locked_aim() -> void:
	aim_line.visible = true
	aim_line.clear_points()
	aim_line.add_point(Vector2.ZERO)
	aim_line.add_point(_locked_dir * 600.0)

func _fire_locked() -> void:
	var p := ProjectileScene.instantiate() as NLBProjectile
	var host := get_tree().current_scene
	if host == null:
		host = get_tree().root  # headless/test fallback; game always has a scene
	host.add_child(p)
	p.launch(muzzle.global_position, _locked_dir * projectile_speed)
	fired.emit()
