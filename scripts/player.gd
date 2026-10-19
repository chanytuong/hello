extends CharacterBody2D
class_name NLBPlayer
## Graybox fighter: run / jump / dash / one melee swing.
## Identity: barely-held-together/aggressive/restless, but deterministic.
## Rhythm rules (see cancel matrix in docs): buffered everything, dash
## cancels swing RECOVERY only, swings slide and bite on connect.
## Motion Swap is a WORLD mechanic: it never freezes or teleports the player.
## The lab opts into velocity exchange and a short forced-motion arm. Normal
## run/jump/skid/roll tuning and the approved visual clips remain shared.

signal jumped
signal dashed
signal swung
signal landed_hit  # every confirmed swing; the perception prop counts uses
signal landed_hard(fall_speed: float)

enum MoveState { NORMAL, DASH }

## Opt-in for the movement integration scene. Legacy combat scene keeps its
## original dash/visual behavior; both paths share the same run/jump physics.
@export_group("Movement prototype")
@export var movement_preview: bool = false
@export var m1_combo_enabled: bool = false
@export var roll_duration: float = 0.29
@export var roll_speed: float = 333.3333333 # 100 px across 18 active ticks at 60 Hz
@export var roll_cooldown: float = 0.35 # starts on completion or cancellation
var roll_remaining: float = 0.0
var roll_cooldown_remaining: float = 0.0
var roll_direction: int = 1
var movement_visual: Node2D
## Optional attack driver; movement-only scenes leave this null.
var movement_attack_preview: Node = null
var _movement_jumped: bool = false
var _previous_input: float = 0.0
## Carrier hook (movement mode only): a conveyor belt or moving platform writes
## the world-space step it owes the player this physics frame, and the player
## consumes it with ONE move_and_collide before its own move_and_slide. Written
## every frame by the carrier and cleared here, so a stopped belt cannot keep
## carrying. Never touches `velocity`: carrying is not the player's own motion.
var carry_motion: Vector2 = Vector2.ZERO

@export_group("Motion Swap launch")
@export var swap_launch_duration: float = 0.24
@export var swap_launch_drag: float = 650.0
@export var living_projectile_threshold: float = 480.0
@export var wall_stun_duration: float = 0.28
@export var crate_impact_damage_speed: float = 520.0
var swap_override_t: float = 0.0
var motion_stun_t: float = 0.0
var living_projectile: bool = false
var swap_target: NLBMotionSwapTarget = null
var motion_swap_enabled: bool = false

func enable_motion_swap() -> void:
	if swap_target != null:
		return
	motion_swap_enabled = true
	collision_mask |= 4 | 256 | 512
	platform_floor_layers &= ~4 # enemy detection/contact cannot carry Iven as a platform
	swap_target = NLBMotionSwapTarget.new()
	swap_target.name = "SwapTarget"
	swap_target.anchor_offset = Vector2(0, -30)
	swap_target.display_name = "IVEN"
	add_child(swap_target)
	swap_target.adapter = NLBMotionCharacterAdapter.new(self)

func motion_swap_read() -> Vector2:
	return velocity

func is_swap_selectable() -> bool:
	return health != null and health.hp > 0 and not is_queued_for_deletion()

func motion_swap_apply(motion: Vector2, _duration: float) -> void:
	if is_instance_valid(movement_attack_preview) and movement_attack_preview.has_method("cancel_for"):
		movement_attack_preview.cancel_for("motion_swap")
	velocity = motion
	swap_override_t = swap_launch_duration
	motion_stun_t = 0.0
	living_projectile = motion.length() >= living_projectile_threshold
	_end_movement_roll()
	move_state = MoveState.NORMAL
	_dash_buf = 0.0
	_jump_buf = 0.0
	# Orientation follows real received motion; no new drawings or animation lock.
	if absf(motion.x) > 8.0:
		facing = 1 if motion.x > 0.0 else -1

func receive_contact_motion(motion: Vector2) -> void:
	if motion_stun_t > 0.0:
		return
	velocity += motion
	swap_override_t = maxf(swap_override_t, 0.12)

func motion_overdrive_changed() -> void:
	if swap_override_t > 0.0:
		living_projectile = velocity.length() >= living_projectile_threshold

func receive_motion_impact(speed: float, normal: Vector2, other: Object, incoming: Vector2, context: Dictionary = {}) -> void:
	if swap_target != null:
		swap_target.clear_overdrive()
	if living_projectile and speed >= living_projectile_threshold:
		if other is StaticBody2D and absf(normal.x) > 0.5:
			motion_stun_t = wall_stun_duration
			swap_override_t = 0.0
			velocity = incoming.slide(normal) * 0.30
		else:
			velocity = incoming.slide(normal) + normal * speed * 0.08
			swap_override_t = minf(swap_override_t, 0.08)
		living_projectile = false
	elif other is RigidBody2D and speed >= crate_impact_damage_speed:
		motion_stun_t = maxf(motion_stun_t, 0.16)
		var info := context.duplicate()
		info.merge({"kind": "impact", "source": str(other.get_path()), "velocity": incoming,
			"normal": normal, "closing_speed": speed}, true)
		health.damage(1, info)

func _motion_forced_physics(delta: float) -> bool:
	if swap_override_t <= 0.0 and motion_stun_t <= 0.0:
		living_projectile = false
		return false
	# Hand the SAME update to normal movement; do not consume a new action and
	# then return before it can execute. Wall self-stun remains a commitment.
	if motion_stun_t <= 0.0 and swap_override_t < swap_launch_duration - 0.10 and (Input.is_action_just_pressed("dash") or Input.is_action_just_pressed("jump")):
		swap_override_t = 0.0
		living_projectile = false
		if swap_target != null:
			swap_target.clear_overdrive()
		return false
	var old_velocity := velocity
	_tick_timers(delta)
	_apply_gravity(delta)
	if motion_stun_t > 0.0:
		motion_stun_t = maxf(motion_stun_t - delta, 0.0)
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		_dash_buf = 0.0
		_jump_buf = 0.0
	else:
		swap_override_t = maxf(swap_override_t - delta, 0.0)
		velocity.x = move_toward(velocity.x, 0.0, swap_launch_drag * delta)
	if carry_motion != Vector2.ZERO:
		move_and_collide(carry_motion)
		carry_motion = Vector2.ZERO
	var incoming := velocity
	move_and_slide()
	NLBImpactResponse.solve_slides(self, incoming)
	if movement_visual != null:
		movement_visual.advance(delta, 0.0, false, old_velocity)
	return true

## --- perception-weapon experiment ---------------------------------------
## The player does NOT know what it is holding. The prop writes exactly two
## fields; every combat number below is derived from them, so "armed" is one
## coherent change and there is no weapon system. 0 = bare hands, 1 = pipe.
## weapon_finish = this swing is the last use: deliberately heavier, and the
## prop breaks ON the confirm (payoff, not random breakage).
## design/PERCEPTION_WEAPON_EXPERIMENT.md §6
var weapon_power: float = 0.0
var weapon_finish: bool = false

const BASE_REACH := 82.0
const BASE_KB := 260.0
const BASE_HITSTOP := 0.045

func weapon_reach() -> float:
	return BASE_REACH + 22.0 * weapon_power

func weapon_kb_x() -> float:
	return BASE_KB + 200.0 * weapon_power + (200.0 if weapon_finish else 0.0)

func weapon_bite() -> float:
	# bite = velocity kept on confirm. Lower = harder stop = more impact.
	var b := hit_brake - 0.20 * weapon_power
	return b - 0.10 if weapon_finish else b

func weapon_hitstop() -> float:
	return BASE_HITSTOP + 0.030 * weapon_power + (0.025 if weapon_finish else 0.0)

func weapon_shake() -> float:
	# add_shake() already caps at 0.6, so the finisher lands exactly on the cap.
	return 0.30 + 0.18 * weapon_power + (0.12 if weapon_finish else 0.0)

## Impact is snapshotted at SWING START. The prop reacts to `landed_hit`
## before game.gd does (player._ready runs first, so its connection to
## swing_box.landed comes first), so reading weapon_power at confirm time
## would let the prop rewrite its OWN impact: the 4th hit would inherit the
## finisher's numbers and the 5th - the payoff - would inherit bare hands.
var _impact_hitstop: float = BASE_HITSTOP
var _impact_shake: float = 0.30

func impact_hitstop() -> float:
	return _impact_hitstop

func impact_shake() -> float:
	return _impact_shake

@export_group("Move")
@export var run_speed: float = 280.0
@export var acceleration: float = 2600.0
@export var reverse_accel: float = 4200.0  # 180° turns: input opposing velocity
@export var friction: float = 3200.0
@export var air_control_mult: float = 0.7
@export_group("Jump")
@export var jump_velocity: float = -640.0
@export var rise_gravity: float = 1600.0
@export var fall_gravity_mult: float = 1.8
@export var coyote_time: float = 0.1
@export var jump_buffer: float = 0.12
@export var jump_cut_mult: float = 0.45
@export_group("Dash")
@export var dash_speed: float = 650.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.8
@export var dash_buffer: float = 0.12
@export var dash_strike_window: float = 0.06  # swing may start in late dash
@export_group("Attack")
@export var attack_startup: float = 0.05
@export var attack_active: float = 0.12
@export var attack_recovery: float = 0.08
@export var attack_cooldown: float = 0.35
# PHASE 8 - INPUT TRUST. This must cover a FULL attack cycle
# (attack_cooldown 0.35 + startup/active/recovery 0.25 = 0.60), because
# `_atk_cd` is armed to 0.60 at swing start and `_atk_buf` is zeroed by
# that same swing. With the old 0.20, a press registering anywhere from
# 0.08s to 0.43s after swing start decayed to 0 BEFORE `_atk_cd` cleared:
# a 0.35s dead hole covering the entire animation, measured by
# tests/probe_input.gd. That is dropped input, not commitment - the swing
# is already uninterruptible during that window, so animation priority
# (not a swallowed press) is what enforces commitment.
# At 0.60 every deliberate press is queued exactly one swing ahead; the
# press that STARTS a swing is consumed by it, so this is still a queue
# of one. Not an auto-combo: no swing fires without a new press, and
# holding the button only counts as one press.
@export var attack_buffer: float = 0.6
@export var attack_step: float = 60.0  # forward slide on swing start
@export var hit_brake: float = 0.55  # momentum kept on connect (bite)
@export_group("Impact")
@export var hard_landing_speed: float = 700.0

var move_state: int = MoveState.NORMAL
var facing: int = 1

## Frame-transition tracer (player-only, no cross-file dependency).
## Off by default; repro scripts set NLBPlayer.trace = true.
static var trace: bool = false
var _tr_vy_before: float = 0.0
var _tr_was_floor: bool = false
var _tr_jump_pressed: bool = false
var _tr_dmg: bool = false
var _tr_kb: Vector2 = Vector2.ZERO

static func _tr_log(tag: String, data: Dictionary = {}) -> void:
	if trace:
		print("TR %s %s" % [tag, str(data)])

var _coyote: float = 0.0
var _jump_buf: float = 0.0
var _dash_t: float = 0.0
var _dash_cd: float = 0.0
var _dash_dir: int = 1
var _air_dashes: int = 1
var _atk_t: float = -1.0   # <0 idle; else time since swing start
var _atk_cd: float = 0.0
var _atk_buf: float = 0.0
var _hurt_t: float = 0.0
var _dash_buf: float = 0.0
var _skid: float = 0.0
var _fall_peak: float = 0.0
var _bite_done: bool = false
var _prev_floor: bool = true

@onready var body_vis: ColorRect = $Body
## PHASE 10 - authored sprite layer (art/prototype/character, PIL-authored PNGs).
## Presentation only: the parametric pose math below keeps running untouched
## (tests/test_identity.gd asserts body_vis.rotation/scale); its ColorRect is
## hidden so the real frames carry the read.
const ART_DIR := "res://art/prototype/character/"
## A2 HORIZONTAL IMPOSSIBLE LINE production set (identity locked by review).
## Presentation layer only: identical frame names, identical 64x64 / ground
## row 62 / grip (48,32) contract, identical _pick_frame() timeline. The V key
## toggles it against the baseline set at runtime for the before/after review;
## combat code and mechanics untouched.
const ART_DIR_A2 := "res://art/prototype/character_a2/"
const FRAME_FILES := [
	"neutral.png",
	"d0_entry.png", "d1_hold.png", "d2_exit.png",
	"attack_a0.png", "attack_a1.png", "attack_a2.png", "attack_a3.png", "attack_a4.png",
]
## RUN - approved PixelLab South-East 8-frame cycle (source of truth:
## maincharacter/Idle_running-8-frames_south-east.gif, extracted losslessly).
## 88x88 frames; texture (44,71) = feet centre = player origin. Used by both
## the A2 and baseline sets (V toggle only swaps the non-run frames).
## RIGHT = South-East as authored; LEFT = the same frames mirrored by facing.
const RUN_SE_DIR := "res://art/character/player/run_southeast/"
const RUN_SE_COUNT := 8
const RUN_SE_PIVOT := Vector2(44.0, 71.0)
const LEGACY_PIVOT := Vector2(32.0, 62.0)   # 64x64 neutral / dash / attack frames
## Run advances one drawing per 24 px travelled (192 px / 8-frame cycle):
## ~11.7 drawings/s (~3 steps/s) at the 280 px/s top speed, slower while
## accelerating. Source GIF is 200 ms/frame; that rate would skate badly at
## gameplay speed, so the cycle stays distance-driven like before.
const RUN_FRAME_PX := 24.0
const RUN_MIN_SPEED := 20.0  # below this the run cycle freezes out to neutral
var _run_cache: Dictionary = {}
var sprite: Sprite2D = null
var _frame_cache: Dictionary = {}
var _frame_cache_a2: Dictionary = {}
var use_a2: bool = true      # A2 identity on; V toggles baseline for runtime compare
var _frame_shown: String = ""
var _run_dist: float = 0.0
@onready var swing_box: NLBHitBox = $SwingHitBox
## Reach is radius-only: position.x stays at 40, so the near edge stays
## behind the body (unchanged) while the far edge grows 82 -> 104 when armed.
@onready var _swing_shape: CircleShape2D = ($SwingHitBox/Shape as CollisionShape2D).shape
@onready var health: NLBHealth = $Health
var _struck_from_dash: bool = false

## PHASE 3.5 - written by NLBProp (which owns the perception timeline),
## rendered by _update_visuals. -1 = none, 0 = reach/coil, 1 = recoil at the
## hard snap, 2 = settle. Keeping the beat boundaries in prop.gd only means
## the pose and the fracture can never drift apart.
var perception_pose: int = -1

## Called by the prop on pickup / break. One function, no weapon knowledge
## beyond the shape radius; everything else flows from weapon_power.
func set_armed(power: float, finish: bool) -> void:
	weapon_power = power
	weapon_finish = finish
	if _swing_shape != null:
		_swing_shape.radius = 42.0 + 22.0 * minf(power, 1.0)

func _ready() -> void:
	add_to_group("player")
	add_to_group("fighters")
	health.changed.connect(_on_damaged)
	swing_box.landed.connect(_on_swing_landed)
	if body_vis != null:
		body_vis.pivot_offset = Vector2(14, 22)
	if movement_preview:
		body_vis.hide()
		movement_visual = preload("res://scripts/iven_movement_visual.gd").new()
		movement_visual.name = "IvenVisual"
		add_child(movement_visual)
		jumped.connect(_on_movement_jump)
		if m1_combo_enabled:
			var combo := preload("res://scripts/combat/m1_combo.gd").new()
			combo.name = "M1Combo"
			add_child(combo)
	else:
		_setup_sprite()

## Hit "bite": first confirm per swing brakes momentum. Misses keep sliding.
func _on_swing_landed() -> void:
	if _bite_done:
		return
	_bite_done = true
	velocity.x *= weapon_bite()
	landed_hit.emit()

func apply_knockback(kb: Vector2) -> void:
	# Impulse straight into velocity; accel/friction absorb it within ~0.1s.
	# No extra state, no double-integration.
	_tr_kb = kb
	_tr_log("KNOCKBACK_APPLIED", {"kb": kb, "vy_before": velocity.y, "grounded": is_on_floor()})
	velocity += kb

## Damage drops pending jump intent (called by HurtBox). Coyote grace is
## physics state, not intent, and is intentionally preserved.
func clear_jump_intent() -> void:
	_jump_buf = 0.0

func _on_damaged(_cur: int, _maximum: int) -> void:
	if is_instance_valid(movement_attack_preview) and movement_attack_preview.has_method("cancel_for"):
		movement_attack_preview.cancel_for("damage")
	_hurt_t = 0.12
	_tr_dmg = true
	_tr_log("DAMAGE_RECEIVED", {"hp": _cur, "vy": velocity.y, "grounded": is_on_floor()})

func total_attack_time() -> float:
	return attack_startup + attack_active + attack_recovery

func is_attack_busy() -> bool:
	if is_instance_valid(movement_attack_preview):
		return movement_attack_preview.busy()
	return _atk_t >= 0.0

func _physics_process(delta: float) -> void:
	# One game-time physics authority, including tactical slow motion/forced motion.
	if movement_preview:
		roll_cooldown_remaining = maxf(0.0, roll_cooldown_remaining - delta)
	if motion_swap_enabled and _motion_forced_physics(delta):
		if is_instance_valid(movement_attack_preview) and movement_attack_preview.has_method("cancel_for"):
			movement_attack_preview.cancel_for("forced_motion")
		return
	if movement_preview:
		_movement_physics(delta)
		return
	_tick_timers(delta)
	_prev_floor = is_on_floor()
	_tr_vy_before = velocity.y
	_tr_was_floor = _prev_floor
	_tr_jump_pressed = Input.is_action_just_pressed("jump")
	_tr_dmg = false
	_tr_kb = Vector2.ZERO
	var dir: float = Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
	_update_jump(delta, dir)
	_update_dash(delta, dir)
	_update_attack(delta)
	_update_visuals(delta)
	move_and_slide()
	_update_sprite(delta)
	if not _prev_floor and is_on_floor() and _fall_peak > hard_landing_speed:
		landed_hard.emit(_fall_peak)
	if is_on_floor():
		_fall_peak = 0.0
	elif velocity.y > 0.0:
		_fall_peak = maxf(_fall_peak, velocity.y)
	if trace and _tr_vy_before > -150.0 and velocity.y < -150.0:
		_tr_log("UNEXPECTED_UPWARD_VELOCITY", {
			"vy_before": _tr_vy_before, "vy_after": velocity.y,
			"jump_pressed": _tr_jump_pressed, "buffer": _jump_buf, "coyote": _coyote,
			"floor_before": _tr_was_floor, "floor_after": is_on_floor(),
			"damage": _tr_dmg, "kb": _tr_kb, "dash": move_state,
			"attack": _atk_t >= 0.0})

func _on_movement_jump() -> void:
	_movement_jumped = true
	_end_movement_roll()

func can_movement_roll() -> bool:
	return roll_remaining <= 0.0 and roll_cooldown_remaining <= 0.000001

func _end_movement_roll() -> void:
	if roll_remaining <= 0.0:
		return
	roll_remaining = 0.0
	roll_cooldown_remaining = maxf(roll_cooldown_remaining, roll_cooldown)

func _movement_physics(delta: float) -> void:
	var before_velocity := velocity
	var was_floor := is_on_floor()
	var was_rolling := roll_remaining > 0.0
	_tick_timers(delta)
	_movement_jumped = false
	_tr_was_floor = was_floor
	var dir := Input.get_axis("move_left", "move_right")
	if is_instance_valid(movement_attack_preview):
		dir = movement_attack_preview.before_movement(delta, dir)
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
	# Reuse existing input buffer/coyote/cut/gravity/acceleration/reversal.
	_update_jump(delta, dir)
	if roll_remaining > 0.0:
		if roll_remaining <= delta:
			_end_movement_roll()
		else:
			roll_remaining -= delta
	if was_rolling and roll_remaining <= 0.0 and not _movement_jumped:
		velocity.x = dir * run_speed # resume intended RUN / IDLE speed without overshoot or recovery
	var fresh_roll := Input.is_action_just_pressed("dash")
	var fresh_direction := dir != 0.0 and (dir != _previous_input or Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"))
	var released_direction := dir == 0.0 and _previous_input != 0.0
	if roll_remaining > 0.0 and (fresh_direction or released_direction):
		_end_movement_roll()
		velocity.x = dir * run_speed # immediate intentional reversal, no residual roll drive
	if _movement_jumped:
		_dash_buf = 0.0 # simultaneous jump wins; never queue a surprise roll
	elif fresh_roll and can_movement_roll():
		roll_direction = facing if dir == 0.0 else (1 if dir > 0.0 else -1)
		facing = roll_direction
		roll_remaining = roll_duration
		_dash_buf = 0.0
		dashed.emit() # existing movement notification; no immunity or attack
	if roll_remaining > 0.0:
		velocity.x = float(roll_direction) * roll_speed # assignment, never accumulated impulses
		facing = roll_direction
	# Carrier step FIRST, through the same collision solver: a belt can never
	# push Iven through a wall, and being carried stays separate from `velocity`
	# (so friction/acceleration cannot silently eat a moving platform).
	if carry_motion != Vector2.ZERO:
		move_and_collide(carry_motion)
		carry_motion = Vector2.ZERO
	var incoming := velocity
	move_and_slide()
	if motion_swap_enabled:
		NLBImpactResponse.solve_slides(self, incoming)
	var released_at_speed := not was_rolling and dir == 0.0 and _previous_input != 0.0 and absf(before_velocity.x) > 200.0
	if is_instance_valid(movement_attack_preview) and movement_attack_preview.busy():
		released_at_speed = false
	movement_visual.advance(delta, dir, released_at_speed, before_velocity)
	if is_instance_valid(movement_attack_preview):
		movement_attack_preview.present()
	_previous_input = dir

func reset_movement(at: Vector2) -> void:
	if is_instance_valid(movement_attack_preview):
		movement_attack_preview.reset()
	# Test-room reset; no gameplay teleport or physics change.
	global_position = at
	velocity = Vector2.ZERO
	swap_override_t = 0.0
	motion_stun_t = 0.0
	living_projectile = false
	carry_motion = Vector2.ZERO
	if swap_target != null:
		swap_target.clear_overdrive()
	roll_remaining = 0.0
	roll_cooldown_remaining = 0.0 # explicit room retry, not an action cancel
	_dash_cd = 0.0
	_dash_buf = 0.0
	_jump_buf = 0.0
	_coyote = 0.0
	_previous_input = 0.0
	if movement_visual != null:
		movement_visual.reset_state()

func _tick_timers(delta: float) -> void:
	_coyote = coyote_time if is_on_floor() else _coyote - delta
	_jump_buf -= delta
	_dash_cd -= delta
	_dash_buf -= delta
	_atk_cd -= delta
	_atk_buf -= delta
	_hurt_t -= delta
	_skid = maxf(_skid - delta, 0.0)
	if is_on_floor():
		_air_dashes = 1

func _apply_gravity(delta: float) -> void:
	var g := rise_gravity * fall_gravity_mult if velocity.y > 0.0 else rise_gravity
	velocity.y += g * delta

func _update_jump(delta: float, dir: float) -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buf = jump_buffer
		_tr_log("JUMP_PRESSED", {"grounded": _tr_was_floor})
		if not _tr_was_floor and _coyote <= 0.0:
			_tr_log("BUFFER_CREATED", {"buffer": _jump_buf, "vy": velocity.y})
	if _jump_buf > 0.0 and _coyote > 0.0:
		_tr_log("COYOTE_JUMP" if not _tr_was_floor else "BUFFER_CONSUMED", {
			"vy_before": velocity.y, "coyote": _coyote, "buffer": _jump_buf,
			"grounded": _tr_was_floor})
		velocity.y = jump_velocity
		_jump_buf = 0.0
		_coyote = 0.0
		jumped.emit()
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_mult
	_apply_gravity(delta)
	if move_state == MoveState.DASH:
		_dash_t -= delta
		if _dash_t <= 0.0:
			move_state = MoveState.NORMAL
			return
		velocity.x = float(_dash_dir) * dash_speed
		return
	var accel := acceleration if is_on_floor() else acceleration * air_control_mult
	if _atk_t >= 0.0 and _bite_done and _atk_t <= attack_startup + attack_active:
		# Confirmed: the swing BITES — it anchors the body for the rest of the
		# active window. This arm must sit ABOVE the held-input arm: the whole
		# bite used to be one `velocity.x *= hit_brake`, and both acceleration
		# arms ramped straight back out of it within ~50ms. Measured with a
		# direction held (i.e. always, in real play) a hit and a whiff had
		# identical velocity curves — the bite was a non-event, and a landed
		# hit ended CLOSER to the enemy than it started.
		var bite_decel := friction if is_on_floor() else friction * 0.5
		velocity.x = move_toward(velocity.x, 0.0, bite_decel * delta)
	elif dir != 0.0:
		# Reversal gets its own (higher) accel so 180° turns snap.
		# A hard reversal at speed also kicks a brief visual skid.
		if signf(velocity.x) != 0.0 and signf(dir) != signf(velocity.x) and absf(velocity.x) > 40.0:
			accel = reverse_accel if is_on_floor() else reverse_accel * air_control_mult
			if is_on_floor() and absf(velocity.x) > 200.0:
				_skid = 0.12
		velocity.x = move_toward(velocity.x, dir * run_speed, accel * delta)
	elif _atk_t >= 0.0 and _atk_t <= attack_startup + attack_active:
		# Whiff: momentum carries through startup+active, no braking.
		velocity.x = move_toward(velocity.x, signf(velocity.x) * run_speed, acceleration * 0.15 * delta)
	else:
		var decel := friction if is_on_floor() else friction * 0.5
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)

func _update_dash(_delta: float, dir: float) -> void:
	if Input.is_action_just_pressed("dash"):
		_dash_buf = dash_buffer
	if _dash_buf <= 0.0 or _dash_cd > 0.0 or move_state == MoveState.DASH:
		return
	# Commitment rule: dash cancels swing RECOVERY, never startup/active.
	# A buffered dash therefore fires the moment recovery begins.
	if _atk_t >= 0.0 and _atk_t <= attack_startup + attack_active:
		return
	if _atk_t >= 0.0:
		_end_swing()
	if is_on_floor() or _air_dashes > 0:
		if not is_on_floor():
			_air_dashes -= 1
		_dash_cd = dash_cooldown
		_dash_buf = 0.0
		_dash_t = dash_duration
		_dash_dir = facing if dir == 0.0 else (1 if dir > 0.0 else -1)
		move_state = MoveState.DASH
		velocity.y = 0.0
		health.grant_iframes(dash_duration + 0.05)
		dashed.emit()

func _update_attack(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		_atk_buf = attack_buffer
	if _atk_t < 0.0:
		if _atk_buf <= 0.0 or _atk_cd > 0.0:
			return
		# Dash-strike: swings may start only in late dash, keeping dash
		# momentum; anything earlier stays buffered until dash ends.
		if move_state == MoveState.DASH and _dash_t > dash_strike_window:
			return
		if move_state == MoveState.DASH:
			_struck_from_dash = true
			move_state = MoveState.NORMAL
		else:
			_struck_from_dash = false
		_atk_t = 0.0
		_atk_cd = attack_cooldown + total_attack_time()
		_atk_buf = 0.0
		_bite_done = false
		_impact_hitstop = weapon_hitstop()
		_impact_shake = weapon_shake()
		velocity.x += float(facing) * attack_step
		# Horizontal ONLY: a grounded swing must never hand the target an
		# upward impulse (the -80 used to hop every grounded enemy 2px).
		swing_box.knockback = Vector2(float(facing) * weapon_kb_x(), 0.0)
		# NOTE: the box is deliberately NOT opened here. Startup is wind-up;
		# opening it for one frame let a hit resolve at _atk_t == 0 and
		# freeze the game on the very first frame of the anticipation, which
		# meant hitstop always framed a pose that had not struck yet. The
		# box now follows the declared timeline exactly: off through startup,
		# live from `attack_startup` onward.
		swung.emit()
		return
	_atk_t += delta
	swing_box.position.x = absf(swing_box.position.x) * float(facing)
	var total := total_attack_time()
	if _atk_t < attack_startup or _atk_t > attack_startup + attack_active:
		if swing_box.monitoring:
			swing_box.end()
	elif not swing_box.monitoring:
		swing_box.begin()
	if _atk_t >= total:
		_atk_t = -1.0
		_struck_from_dash = false
		swing_box.end()

func _end_swing() -> void:
	_atk_t = -1.0
	_struck_from_dash = false
	swing_box.end()

func _setup_sprite() -> void:
	sprite = Sprite2D.new()
	sprite.centered = false
	# Texture (32,62) = feet centre = player origin (game_x = col-32, game_y = row-62).
	sprite.offset = -LEGACY_PIVOT
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)   # prop is a sibling AFTER Main/Player, so the weapon draws on top
	for fn in FRAME_FILES:
		if ResourceLoader.exists(ART_DIR + fn):
			_frame_cache[fn] = load(ART_DIR + fn)
		if ResourceLoader.exists(ART_DIR_A2 + fn):
			_frame_cache_a2[fn] = load(ART_DIR_A2 + fn)
	for i in RUN_SE_COUNT:
		var rn := "run_se_%02d.png" % i
		if ResourceLoader.exists(RUN_SE_DIR + rn):
			_run_cache[rn] = load(RUN_SE_DIR + rn)
		else:
			push_error("[NLB] missing approved run frame: " + RUN_SE_DIR + rn)
	_show_frame("neutral.png")
	if body_vis != null:
		body_vis.visible = false   # hidden, NOT skipped: the pose math still runs

## Visual-only compare toggle (review tooling, not gameplay): V swaps the
## A2 production set against the baseline set on the next frame pick.
func _unhandled_input(event: InputEvent) -> void:
	if movement_preview:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V:
		use_a2 = not use_a2
		_frame_shown = ""
		if sprite != null:
			_show_frame(_pick_frame())
		print("[NLB] sprite set -> %s" % ("A2 HORIZONTAL LINE" if use_a2 else "baseline"))

func _show_frame(frame_name: String) -> void:
	var tex: Texture2D = null
	var pivot := LEGACY_PIVOT
	if _run_cache.has(frame_name):
		tex = _run_cache[frame_name]
		pivot = RUN_SE_PIVOT
	else:
		if use_a2:
			tex = _frame_cache_a2.get(frame_name)
		if tex == null:
			tex = _frame_cache.get(frame_name, _frame_cache.get("neutral.png"))
	if tex != null:
		sprite.texture = tex
		# Feet centre stays on the player origin whichever frame size is shown.
		sprite.offset = -pivot
	_frame_shown = frame_name

## PHASE 10 frame picker: pure function of existing combat state, so the
## authored frames and the hitbox timeline can never disagree.
## contact frame == active window == swing_box live, held through hitstop.
func _pick_frame() -> String:
	if _atk_t >= 0.0:
		var st := attack_startup
		var ae := st + attack_active
		if _atk_t < st:
			# A0 coil is skipped for a dash-strike: the dash IS the wind-up.
			return "attack_a1.png" if _struck_from_dash else "attack_a0.png"
		if _atk_t <= ae:
			if _bite_done:
				return "attack_a2.png"   # contact HELD for the rest of active
			return "attack_a1.png"
		# Whiff is certain only once the box has closed: it overshoots deeper
		# (A3) than any hit, then takes the clean return (A4). No snap-back.
		if not _bite_done and (_atk_t - ae) < attack_recovery * 0.5:
			return "attack_a3.png"
		return "attack_a4.png"
	if move_state == MoveState.DASH:
		var e := dash_duration - _dash_t   # elapsed this dash
		if e < 0.02:
			return "d0_entry.png"
		if e < 0.11:
			return "d1_hold.png"
		return "d2_exit.png"
	if _hurt_t > 0.0:
		return "neutral.png"   # knockback slide never pumps the run cycle
	if _is_running_visual():
		return "run_se_%02d.png" % (int(_run_dist / RUN_FRAME_PX) % RUN_SE_COUNT)
	return "neutral.png"   # idle, jump, fall, pickup beats

## Run shows only while the body ACTUALLY travels on the ground. Uses the
## displacement achieved by the last move_and_slide (get_real_velocity), so
## pushing into a wall shows idle instead of a treadmill run and the cycle
## cadence follows real ground travel. Presentation only - movement untouched.
func _is_running_visual() -> bool:
	return is_on_floor() and absf(get_real_velocity().x) > RUN_MIN_SPEED

func _update_visuals(delta: float) -> void:
	if body_vis == null:
		return
	var c := Color(0.55, 0.85, 0.9)
	if _hurt_t > 0.0:
		c = Color(1.0, 0.35, 0.35)  # hurt reads instantly, distinct from swing orange
	elif move_state == MoveState.DASH:
		c = Color.WHITE
	elif _atk_t >= 0.0:
		c = Color(1.0, 0.7, 0.25)
	body_vis.color = c
	# POSE carries the swing (the removed Swoosh overlay is still gone):
	# the body is the animation, the weapon is dragged by it. Every phase is
	# a pure function of `_atk_t`, so the sequence is deterministic frame for
	# frame - controlled insanity on a timeline, never on a random number.
	var tgt := Vector2.ONE
	var lean := 0.0
	var blend := minf(delta * 22.0, 1.0)
	if _atk_t >= 0.0:
		var st := attack_startup
		var ae := st + attack_active
		if _atk_t <= st:
			# ANTICIPATION. The torso coils AWAY from the strike while the
			# weapon raises - the two disagree, which is what makes the strike
			# read as loaded instead of as a rectangle sliding sideways.
			blend = minf(delta * 40.0, 1.0)
			if _struck_from_dash:
				# Dash-strike has no backward coil: the dash IS the wind-up.
				# The target used to START back at (1.24, 0.94) - behind the
				# dash posture - which pulled the body backwards for ~3 frames
				# before the strike: a reversal hidden inside a gesture that
				# has to read as ONE. It now starts exactly on the dash posture
				# and loads slightly further forward instead.
				var k := _atk_t / maxf(st, 0.001)
				tgt = Vector2(lerpf(1.34, 1.38, k), lerpf(0.80, 0.76, k))
				lean = lerpf(0.30, 0.32, k) * float(facing)
			else:
				var k := _atk_t / maxf(st, 0.001)
				tgt = Vector2(lerpf(1.0, 0.80, k), lerpf(1.0, 1.28, k))
				lean = lerpf(0.0, -0.42, k) * float(facing)
		elif _atk_t <= ae:
			var k := (_atk_t - st) / maxf(attack_active, 0.001)
			# Front-load the response: most of the pose change lands in the
			# first frames of the active window.
			blend = minf(delta * 44.0, 1.0)
			if _bite_done:
				# CONTACT. One readable pose, compact and braced, then it
				# HOLDS for the rest of the active window - the hit is what
				# arrests the body, and hitstop extends the read.
				# A dash strike keeps MORE forward lean than a standing one, so
				# the gesture never straightens up at the moment of impact:
				# the body PLANTS - it does not recoil from its own blow.
				tgt = Vector2(1.16, 1.16)
				lean = (0.32 if _struck_from_dash else 0.26) * float(facing)
				blend = minf(delta * 52.0, 1.0)
			elif _struck_from_dash:
				tgt = Vector2(lerpf(1.38, 1.56, k), lerpf(0.76, 0.74, k))
				lean = 0.36 * float(facing)
			else:
				# WHIFF: nothing stops it, so the body keeps extending past
				# where a hit would have stopped it.
				tgt = Vector2(lerpf(1.16, 1.48, k), lerpf(1.06, 0.78, k))
				lean = 0.34 * float(facing)
		else:
			# FOLLOW-THROUGH -> RECOVERY. Overshoot is already in the pose;
			# the job here is a quick, clean snap back to movement, never a
			# drift. Starts exactly where the active pose ended (no pop).
			var k := clampf((_atk_t - ae) / maxf(attack_recovery, 0.001), 0.0, 1.0)
			blend = minf(delta * 30.0, 1.0)
			if _bite_done:
				tgt = Vector2(lerpf(1.16, 1.0, k), lerpf(1.16, 1.0, k))
				lean = lerpf((0.32 if _struck_from_dash else 0.26), 0.0, k) * float(facing)
			elif _struck_from_dash:
				tgt = Vector2(lerpf(1.56, 1.0, k), lerpf(0.74, 1.0, k))
				lean = lerpf(0.36, 0.0, k) * float(facing)
			else:
				tgt = Vector2(lerpf(1.48, 1.0, k), lerpf(0.78, 1.0, k))
				lean = lerpf(0.34, 0.0, k) * float(facing)
	elif move_state == MoveState.DASH:
		# DASH posture: one committed forward diagonal. This is the stance a
		# late dash-strike launches from, which is what ties the two together.
		tgt = Vector2(1.34, 0.80)
		lean = 0.30 * float(facing)
		blend = minf(delta * 26.0, 1.0)
	elif perception_pose == 0:
		# PHASE 3.5 - the BODY reaches for the pipe. The object must never
		# appear to transform on its own beside the character.
		tgt = Vector2(0.90, 1.16)
		lean = -0.20 * float(facing)
		blend = minf(delta * 16.0, 1.0)
	elif perception_pose == 1:
		# Recoil at the hard snap - the protagonist reacts to their own
		# perception breaking, then settles.
		tgt = Vector2(1.16, 1.24)
		lean = 0.24 * float(facing)
		blend = minf(delta * 46.0, 1.0)
	elif perception_pose == 2:
		blend = minf(delta * 18.0, 1.0)   # settle back to neutral
	elif _skid > 0.0:
		var k := _skid / 0.12
		tgt = Vector2(1.0 + 0.35 * k, 1.0 - 0.3 * k)
	body_vis.scale = body_vis.scale.lerp(tgt, blend)
	body_vis.rotation = lerpf(body_vis.rotation, lean, blend)

## PHASE 10 - authored frames carry presentation now (body_vis is hidden).
## Called AFTER move_and_slide so the frame reflects this tick's real floor
## contact and displacement (no one-tick run frame after takeoff). Run
## distance accrues only while the cycle is showing, so stopping and
## restarting resumes the stride where it left off instead of snapping.
## The texture is swapped only when the picked frame actually changes.
func _update_sprite(delta: float) -> void:
	if sprite == null:
		return
	if _is_running_visual():
		_run_dist += absf(get_real_velocity().x) * delta
	var want := _pick_frame()
	if want != _frame_shown:
		_show_frame(want)
	# Frames are authored facing right; mirroring around the origin keeps
	# the feet centre (the frame's pivot) pinned to the player origin.
	sprite.scale.x = -1.0 if facing < 0 else 1.0
