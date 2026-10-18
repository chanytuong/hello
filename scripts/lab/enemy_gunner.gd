extends LabEnemy
class_name LabGunnerEnemy
## GUNNER — a turret. HOLD -> AIM (tracks, aim line drawn) -> the last slice of
## the aim window LOCKS the direction -> FIRE one shot -> RECOVER.
##
## Standing still is deliberate: its exchangeable motion is ~zero, so swapping
## the gunner with a projectile parks the projectile and launches the gunner.
## The shot never homes: it flies the direction that was locked at fire time.

enum State { HOLD, AIM, RECOVER }

const ProjectileScene: PackedScene = preload("res://labs/objects/lab_projectile.tscn")

@export var fire_cycle: float = 1.15
@export var aim_time: float = 0.65
@export var lock_time: float = 0.22
@export var recover_time: float = 0.4
@export var projectile_speed: float = 1200.0
## A turret holds its ground and only fires at what it can SEE. 620 px keeps its
## attention inside its own zone: it covers the zone B floor (920..2160) and the
## two teaching crates, but it cannot reach back into zone A's patrol lane.
@export var sight_range: float = 620.0
@export var vertical_sight: float = 260.0

var state: int = State.HOLD
var _state_t: float = 0.0
var _locked_dir: Vector2 = Vector2.LEFT
var _muzzle_flash: float = 0.0

@onready var aim_line: Line2D = $AimLine
@onready var muzzle: Marker2D = $Muzzle

func type_label() -> String:
	return "GUNNER"

func ai_state_name() -> String:
	match state:
		State.HOLD:
			return "HOLD"
		State.AIM:
			return "AIM(LOCKED)" if _state_t <= lock_time else "AIM"
	return "RECOVER"

func _ai_step(delta: float) -> void:
	_muzzle_flash = maxf(_muzzle_flash - delta, 0.0)
	queue_redraw()
	_apply_gravity(delta)
	velocity.x = 0.0  # a turret holds its ground; its velocity is ~zero by design
	_state_t -= delta
	var p := player_node()
	match state:
		State.HOLD:
			body_color = Color(0.65, 0.4, 0.95)
			aim_line.visible = false
			if _state_t <= 0.0:
				if p != null and _in_sight(p):
					state = State.AIM
					_state_t = aim_time
				else:
					_state_t = 0.3  # retry soon; nothing is fired while waiting
		State.AIM:
			body_color = Color(1.0, 0.45, 0.2) if _state_t > lock_time else Color(1.0, 0.25, 0.25)
			if _state_t > lock_time and p != null:
				# Tracking is only allowed before the lock slice. After the
				# lock, the line shown IS the line that will be fired.
				_locked_dir = (p.global_position - muzzle.global_position).normalized()
			_draw_aim()
			if _state_t <= 0.0:
				_fire()
				state = State.RECOVER
				_state_t = recover_time
				aim_line.visible = false
		State.RECOVER:
			body_color = Color(0.65, 0.4, 0.95)
			aim_line.visible = false
			if _state_t <= 0.0:
				state = State.HOLD
				_state_t = fire_cycle

func _in_sight(p: Node2D) -> bool:
	return absf(p.global_position.x - global_position.x) <= sight_range \
		and absf(p.global_position.y - global_position.y) <= vertical_sight

func _draw_aim() -> void:
	aim_line.visible = true
	aim_line.modulate = Color(1.0, 1.0, 1.0, 0.35) if _state_t > lock_time else Color(1.0, 0.3, 0.25, 0.9)
	aim_line.clear_points()
	aim_line.add_point(muzzle.position)
	aim_line.add_point(muzzle.position + _locked_dir * 520.0)

func _fire() -> void:
	var holder := get_tree().current_scene
	if holder == null:
		holder = get_tree().root
	var container := holder.get_node_or_null("Projectiles")
	if container == null:
		container = holder
	var p := ProjectileScene.instantiate() as LabProjectile
	p.team = LabProjectile.Team.ENEMY
	p.damage = 1
	p.knockback = Vector2(signf(_locked_dir.x) * 220.0, -70.0)
	p.source = self
	container.add_child(p)
	p.launch(muzzle.global_position, _locked_dir * projectile_speed)
	_muzzle_flash = 0.055
	queue_redraw()

func _draw() -> void:
	if _muzzle_flash > 0.0:
		draw_line(muzzle.position, muzzle.position + _locked_dir * 18.0, Color(1.0, 0.85, 0.5), 3.0)

func _reset_ai() -> void:
	state = State.HOLD
	_state_t = fire_cycle * 0.5
	_locked_dir = Vector2.LEFT
	if aim_line != null:
		aim_line.visible = false
