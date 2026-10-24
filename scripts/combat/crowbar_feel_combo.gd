extends "res://scripts/combat/crowbar_combo.gd"
## The source pose clock alone runs at 1.25. Local contact stop uses game seconds.
signal contact_feedback(event: Dictionary, victim: Node)
signal whoosh(strike: int)
@export var playback_rate := 1.25
@export var impact_enabled := true
@export var trails_enabled := true
@export var recovery_run_cancel := true
@export var bounded_buffer := true
@export var stops := Vector3(0.035, 0.045, 0.055)
var trail: Array[Dictionary] = []
var whoosh_sent := false
var contact_sample_shown := false
var takedown_lock := 0.0
var recoil_pixels := 0.0
var previous_clock := -1.0
var sampled_contacts: Array[Dictionary] = []

func _ready() -> void:
	super._ready()
	buffer_seconds = 0.16
	feedback_enabled = true

func reset() -> void:
	trail.clear()
	recoil_pixels = 0
	sprite.position = Vector2.ZERO
	super.reset()

func _start(strike: int, direction: int) -> void:
	trail.clear()
	super._start(strike,direction)
	whoosh_sent = false
	contact_sample_shown = false
	previous_clock = -1

func before_movement(dt: float, input_dir: float) -> float:
	for point in trail: point.life -= dt
	trail = trail.filter(func(p): return p.life > 0)
	if takedown_lock > 0:
		takedown_lock = maxf(0,takedown_lock-dt)
		player.velocity.x = 0
		return 0
	if not manifest_valid: return input_dir
	var press := Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("swap_select")
	var jump_valid := player._coyote > 0 and (Input.is_action_just_pressed("jump") or player._jump_buf > 0)
	var roll_valid := Input.is_action_just_pressed("dash") and player.can_movement_roll()
	if _selection_blocks() or player.swap_override_t > 0 or player.motion_stun_t > 0 or player.health.hp <= 0:
		cancel_for("motion_swap_or_unavailable")
		return input_dir
	if jump_valid or roll_valid or not player.is_on_floor() or player.roll_remaining > 0:
		cancel_for("jump" if jump_valid else ("roll" if roll_valid else "air_or_roll"))
		return input_dir
	if busy():
		pending = maxf(0,pending-dt)
		restart_pending = maxf(0,restart_pending-dt)
		previous_clock = age
		if stop_left > 0.000001: stop_left = maxf(0,stop_left-dt)
		else: age += dt*playback_rate
		var cfg := _config()
		# Same existing reversal cancel; optional same-direction RUN after active
		# is a recovery cancel, never a lunge or animation-triggered displacement.
		if input_dir != 0 and age >= float(cfg.active_end) and (input_dir*attack_facing < 0 or (recovery_run_cancel and not press and pending <= 0)):
			cancel_for("recovery_run")
			return input_dir
		var gate := float(cfg.chain)
		if press:
			# One fresh edge stores one follow-up. Reject presses too early to live
			# until the gate; holding never refreshes the buffer.
			if index < 2 and not branch_closed and age <= gate+0.000001 and (not bounded_buffer or gate-age <= buffer_seconds*playback_rate):
				pending = buffer_seconds
			elif age >= float(cfg.duration)-buffer_seconds*playback_rate:
				restart_pending = buffer_seconds
		if index < 2 and not branch_closed and age >= gate-0.000001:
			if pending > 0.000001: _start(index+1,attack_facing)
			else:
				branch_closed = true
				pending = 0
		elif age >= float(cfg.duration)-0.000001:
			var restart := restart_pending > 0.000001
			reset()
			if restart or press: _start(0,player.facing if input_dir == 0 else (1 if input_dir > 0 else -1))
	elif press: _start(0,player.facing if input_dir == 0 else (1 if input_dir > 0 else -1))
	if busy():
		player.facing = attack_facing
		player.velocity.x = 0
		return 0
	return input_dir

func apply_attack_motion(dt: float) -> void:
	super.apply_attack_motion(dt)
	if takedown_lock > 0: player.velocity.x = 0

func present() -> void:
	if not busy(): return
	var clock := age
	var cfg := _config()
	# Always present the authored contact sample for one 60 Hz tick when the
	# 1.25 source clock crosses it. Physics and VFX inspect this same sample.
	var contact := float(cfg.get("contact", cfg.startup+1.0/60.0))
	if not contact_sample_shown and clock >= contact and previous_clock < contact:
		age = contact
		contact_sample_shown = true
		sampled_contacts.append({"strike":index+1,"frame":Engine.get_physics_frames(),"source_age":contact})
	super.present()
	var presented_age := age
	age = clock
	if not whoosh_sent and presented_age >= float(cfg.startup)-1.0/60.0:
		whoosh_sent = true
		if impact_enabled: whoosh.emit(index)
	# Recoil is visual only, integer pixels, contact gated. Never moves collision.
	recoil_pixels = move_toward(recoil_pixels,0,0.7)
	sprite.position = Vector2(-attack_facing*roundf(recoil_pixels),0)
	if trails_enabled and weapon_visible and presented_age >= float(cfg.startup)-2.0/60.0 and presented_age <= float(cfg.active_end)+1.0/60.0:
		var tip_data: Array = current.get("tip", [0,0])
		var tip := (player.global_position + sprite.position + Vector2(tip_data[0],tip_data[1])-pivot).round()
		if trail.is_empty() or (tip-trail[-1].position).length() >= 1:
			trail.append({"position":tip,"life":0.085 if index < 2 else 0.10,"strike":index})
		while trail.size() > 7: trail.pop_front()

func _feedback(event: Dictionary, victim: Node) -> void:
	if not impact_enabled: return
	var pause: float = [stops.x,stops.y,stops.z][index]
	stop_left = maxf(stop_left,pause)
	if victim.has_method("apply_combat_hitstop"): victim.apply_combat_hitstop(pause)
	recoil_pixels = 1 if index < 2 else 2
	contact_feedback.emit(event,victim)

func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not trails_enabled or not busy() or trail.size() < 2: return
	for i in range(1,trail.size()):
		var a: Vector2 = to_local(trail[i-1].position).round()
		var b: Vector2 = to_local(trail[i].position).round()
		var width := 1.0
		if i > 1 and i < trail.size()-1: width = 2.0 if index == 0 else 3.0
		var alpha := clampf(float(trail[i].life)/0.05,0,1)*0.8
		draw_line(a,b,Color(0.66,0.79,0.83,alpha),width,false)
		draw_line(a,b,Color(0.91,0.94,0.89,alpha*0.75),1,false)
