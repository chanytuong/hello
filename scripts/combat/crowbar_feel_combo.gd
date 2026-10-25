extends "res://scripts/combat/crowbar_combo.gd"
## Live crowbar feel layer. The pose clock is authored per strike; local contact
## stops use game seconds. A press is never dropped: it is either buffered to
## the chain gate, used immediately once recovery is cancellable, or kept in the
## post-strike combo window so a deliberate late click still advances the combo.
signal contact_feedback(event: Dictionary, victim: Node)
signal whoosh(strike: int)
@export var playback_rate := 1.0
@export var impact_enabled := true
@export var trails_enabled := true
@export var recovery_run_cancel := true
@export var bounded_buffer := true
## After M1/M2 ends, the next authored step stays available this long. A press
## inside this real-time window continues the combo; after it, a press is a
## fresh M1. This is deliberately much longer than the old 0.12 s grace.
@export var combo_reset_timeout := 0.45
@export var stops := Vector3(0.03, 0.04, 0.05)
var trail: Array[Dictionary] = []
var whoosh_sent := false
var contact_sample_shown := false
var takedown_lock := 0.0
var recoil_pixels := 0.0
var previous_clock := -1.0
var sampled_contacts: Array[Dictionary] = []
var combo_window_left := 0.0
var combo_next := -1

func _ready() -> void:
	super._ready()
	# The buffer covers a full M2 chain gate from the first frame of a strike.
	buffer_seconds = 0.25
	feedback_enabled = true

func reset() -> void:
	trail.clear()
	recoil_pixels = 0
	sprite.position = Vector2.ZERO
	combo_window_left = 0.0
	combo_next = -1
	super.reset()

func _start(strike: int, direction: int) -> void:
	trail.clear()
	super._start(strike,direction)
	whoosh_sent = false
	contact_sample_shown = false
	previous_clock = -1
	combo_window_left = 0.0
	combo_next = -1

func _facing_for(input_dir: float) -> int:
	return player.facing if is_zero_approx(input_dir) else (1 if input_dir > 0 else -1)

func _recovery_cancel_time(cfg: Dictionary) -> float:
	return float(cfg.get("recovery_cancel", cfg.duration))

func _remember_strike_end(finished_index: int) -> void:
	# M1/M2 keep the next step alive for the authored window. M3 is the end of
	# the sentence; its next press is handled as a fresh opener at its cancel
	# gate, so no window is armed here.
	if finished_index < 2:
		combo_next = finished_index + 1
		combo_window_left = combo_reset_timeout
	else:
		combo_next = -1
		combo_window_left = 0.0

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
	# The post-strike window is real time, so waiting a beat does not rewind the
	# combo. It only expires after 0.45 s of no attack.
	if combo_window_left > 0.0:
		combo_window_left = maxf(0.0,combo_window_left-dt)
		if combo_window_left <= 0.0: combo_next = -1
	if busy():
		pending = maxf(0,pending-dt)
		restart_pending = maxf(0,restart_pending-dt)
		previous_clock = age
		if stop_left > 0.000001: stop_left = maxf(0,stop_left-dt)
		else: age += dt*playback_rate
		var cfg := _config()
		var chain := float(cfg.chain)
		var duration := float(cfg.duration)
		var cancel_at := _recovery_cancel_time(cfg)
		var move_cancel_at := duration if index < 2 else cancel_at
		# Reversal stays an immediate deliberate cancel. Same-direction RUN waits
		# for the authored strike/recovery gate so it cannot eat a live chain.
		if input_dir != 0.0 and (
				(input_dir*attack_facing < 0 and age >= float(cfg.active_end)-0.000001)
				or (recovery_run_cancel and not press and pending <= 0.000001 and age >= move_cancel_at-0.000001)):
			cancel_for("recovery_run")
			return input_dir
		if press:
			if index < 2 and chain >= 0.0:
				var until_gate := chain-age
				if until_gate > 0.000001:
					# Buffer through startup/active. The intent survives to the
					# exact gate tick instead of expiring just before it.
					if not bounded_buffer or until_gate <= buffer_seconds*playback_rate+0.000001:
						pending = maxf(pending,until_gate+0.05)
				else:
					# Recovery is already cancellable: branch on this update.
					_start(index+1,attack_facing)
			elif index == 2:
				if age >= cancel_at-0.000001:
					# M3 recovery cancel: the finisher tail is skippable at 0.35 s.
					reset()
					_start(0,_facing_for(input_dir))
				else:
					# Queue any early finisher press. The click is not swallowed;
					# it restarts M1 the moment the cancel gate opens.
					restart_pending = maxf(restart_pending,(cancel_at-age)+0.05)
		if busy() and index < 2 and chain >= 0.0 and age >= chain-0.000001:
			if pending > 0.000001:
				_start(index+1,attack_facing)
		if busy() and index == 2 and age >= cancel_at-0.000001 and restart_pending > 0.000001:
			reset()
			_start(0,_facing_for(input_dir))
		if busy() and age >= duration-0.000001:
			var finished_index := index
			var was_chainable := finished_index < 2 and chain >= 0.0
			var restart := restart_pending > 0.000001 or press
			reset()
			if was_chainable:
				branch_closed = true
				events.append({"event":"stop_branch","index":finished_index,"age":duration,"frame":Engine.get_physics_frames()})
				_remember_strike_end(finished_index)
			if restart: _start(0,_facing_for(input_dir))
	elif press:
		var reversed := input_dir != 0.0 and input_dir*attack_facing < 0.0
		if combo_window_left > 0.000001 and combo_next >= 0 and combo_next < 3 and not reversed:
			var next := combo_next
			combo_next = -1
			combo_window_left = 0.0
			_start(next,attack_facing)
		else:
			_start(0,_facing_for(input_dir))
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
