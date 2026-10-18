extends Node2D
class_name NLBGame
## Thin orchestrator for the single-room combat prototype. Owns NO combat
## geometry or ability logic: it places fighters on arena marks, wires signals,
## runs camera shake, hitstop and restart.
##
## The old Blink transition (fight freeze, projectile wipe on transition,
## full-screen veil, A/B arena swap, arrival pose, HUD state bar) is REMOVED
## with the mechanic. Combat itself is unchanged.

var kills: int = 0
var _dead_t: float = -1.0
var _shake: float = 0.0
var _run_id: int = 0  # guards late callbacks across restarts

@onready var arena: NLBArena = $Arena
@onready var player: NLBPlayer = $Player
@onready var melee: NLBMeleeChaser = $Melee
@onready var ranged: NLBRangedEnemy = $Ranged
@onready var hud: NLBHUD = $HUD
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	_run_id += 1
	# A restart during hitstop strands Engine.time_scale (the old tree's timer
	# fires after this node is freed, and the stale token blocks the restore).
	# A fresh run always starts at normal speed — no exceptions.
	Engine.time_scale = 1.0
	player.global_position = arena.player_spawn.global_position
	melee.global_position = arena.melee_spawn.global_position
	ranged.global_position = NLBArena.RANGED_PERCH_A
	player.health.changed.connect(hud.set_hp)
	player.health.changed.emit(player.health.hp, player.health.max_hp)
	player.health.died.connect(_on_player_died)
	player.landed_hard.connect(_on_landed_hard)
	player.health.changed.connect(_on_player_hurt)
	player.swing_box.landed.connect(_on_player_hit_landed)
	melee.died.connect(_on_enemy_died)
	ranged.died.connect(_on_enemy_died)
	hud.set_message("Clear the room. R = restart. Motion Swap lives in labs/motion_swap_lab.tscn.")

func _process(delta: float) -> void:
	# Runs after node physics and before this frame is drawn, so the gap it
	# sets is the gap that is actually drawn (verified: solve follows move).
	separate_bodies()
	if Input.is_action_just_pressed("restart"):
		_restart()
	if _dead_t > 0.0:
		_dead_t -= delta
		if _dead_t <= 0.0:
			_restart()
	_shake = maxf(_shake - delta * 1.5, 0.0)
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake * 18.0

## Soft body separation. Fixes three measured defects:
##  1. It used to split the correction 50/50, teleporting the PLAYER back up to
##     ~2.7px every frame an enemy was near. Measured player travel fell to
##     161 px/s against 266 px/s with no enemy nearby — a ~40% invisible drag
##     that made combat feel muddy.
##  2. It ran before move_and_slide, so the corrected gap was undone by the
##     frame's own motion and the rendered result was a permanent ~5px overlap.
##     It now runs after physics (idle), so the gap it sets is the one drawn.
##  3. Fix 1 made the enemy the only body that ever yielded, so holding forward
##     carried a chaser backwards at full run speed for as long as the input
##     was held — measured 538px of continuous bulldozing in 2s of held input.
##
## Current rule: each body undoes only the encroachment IT caused this frame.
##   - you walking into someone => your advance is rejected (you stop at
##     contact; you are never slowed, never dragged — full speed until touch)
##   - someone walking into you  => they are shouldered back to contact
##   - you DASHING into someone  => your advance is kept, they yield (the
##     aggressive body-check stays; a dash must never dead-end on contact)
## So the standoff holds at exactly 30px with neither body sliding, and the
## only way to pass through someone is to dash or jump over them.
## Horizontal ONLY (y and velocity untouched — launch-impossible by
## construction).
const SEP_MIN_DIST := 30.0   # player half-width 14 + enemy half-width 16
const SEP_GUARD := 24.0      # > any legit single-frame travel (dash 10.8 + kb 8)
const SEP_MAX_STEP := 12.0   # never yank a body further than one dash

var _prev_px: float = 0.0
var _prev_foe_x: Dictionary = {}   # instance_id -> x

func separate_bodies() -> void:
	if not is_instance_valid(player):
		return
	# Ground truth for "how far did the player actually advance this frame".
	# A test snap or respawn moves far more than SEP_GUARD, so it reads as 0
	# encroachment and heals via the enemy instead of yanking the player back.
	var pdx := player.global_position.x - _prev_px
	if absf(pdx) > SEP_GUARD:
		pdx = 0.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is CharacterBody2D):
			continue
		var foe := e as CharacterBody2D
		var fdx := 0.0
		var fid := foe.get_instance_id()
		if _prev_foe_x.has(fid):
			fdx = foe.global_position.x - float(_prev_foe_x[fid])
			if absf(fdx) > SEP_GUARD:
				fdx = 0.0
		_prev_foe_x[fid] = foe.global_position.x
		if absf(foe.global_position.y - player.global_position.y) > 50.0:
			continue
		var dx: float = foe.global_position.x - player.global_position.x
		if absf(dx) >= SEP_MIN_DIST:
			continue
		var sgn := signf(dx)
		if sgn == 0.0:
			sgn = float(player.facing)  # exactly stacked: deterministic side
		var deficit := SEP_MIN_DIST - absf(dx)
		# How much each body closed the gap this frame (0 if it moved away).
		var player_enc := clampf(sgn * pdx, 0.0, SEP_GUARD)
		var foe_enc := clampf(-sgn * fdx, 0.0, SEP_GUARD)
		# A dash keeps its momentum and shoves; everything else is held.
		var pull := 0.0
		if player.move_state != NLBPlayer.MoveState.DASH:
			pull = minf(minf(player_enc, deficit), SEP_MAX_STEP)
		var push := minf(deficit - pull, SEP_MAX_STEP)
		if pull > 0.0:
			player.global_position.x -= pull * sgn
		if push > 0.0:
			foe.global_position.x += push * sgn
	_prev_px = player.global_position.x

## Confirmed player hit: freeze + small shake. Misses feel like nothing.
## The resolution comes from the impact SNAPSHOT taken at swing start (see
## player.gd): reading live weapon_power here would let the prop rewrite its
## own payoff hit before this handler runs.
func _on_player_hit_landed() -> void:
	add_shake(player.impact_shake())
	NLBAudio.play(&"hit")
	hitstop(player.impact_hitstop(), 0.05)

func _on_player_hurt(_cur: int, _maximum: int) -> void:
	add_shake(0.35)
	NLBAudio.play(&"hurt")

func _on_landed_hard(_fall_speed: float) -> void:
	add_shake(0.15)

func add_shake(amount: float) -> void:
	_shake = minf(_shake + amount, 0.6)

## Restrained hitstop: token-guarded so overlapping hits can't strand time_scale.
var _hitstop_token: int = 0

func hitstop(duration: float = 0.045, scale: float = 0.05) -> void:
	_hitstop_token += 1
	var token := _hitstop_token
	Engine.time_scale = scale
	await get_tree().create_timer(duration, true, false, true).timeout
	if token == _hitstop_token and is_instance_valid(self):
		Engine.time_scale = 1.0

func _on_enemy_died() -> void:
	kills += 1
	if kills >= 2:
		hud.set_message("ROOM CLEAR — R to restart.")

func _on_player_died() -> void:
	hud.set_message("DIED — press R or wait to restart.")
	_dead_t = 1.2

func _restart() -> void:
	_run_id += 1
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
