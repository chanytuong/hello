extends "res://scripts/combat/m1_combo.gd"
## Authored straight / body hook / forearm blow. Godot applies one bounded travel curve.
## The previous M1 driver and its lab remain available as a rollback fixture.
var motion_step := 0.0
var planned_travel := 0.0
var braced_support := false
var free_lookup: Dictionary = {}
var braced_lookup: Dictionary = {}

func _ready() -> void:
	super._ready()
	metadata = JSON.parse_string(FileAccess.get_file_as_string("res://art/iven/m1_rebuild/metadata.json"))
	lookup.clear()
	for row in metadata.records:
		var key := "%d/%s/%d"%[row.strike,row.direction,row.sample]
		if row.get("support","free")=="braced":braced_lookup[key] = row
		else:free_lookup[key] = row
	lookup = free_lookup
	sprite.texture = load("res://art/iven/m1_rebuild/body.png")
	buffer_seconds = 0.12

func reset() -> void:
	super.reset()
	motion_step = 0.0
	planned_travel = 0.0
	braced_support = false

func _start(strike: int, direction: int) -> void:
	super._start(strike,direction)
	planned_travel = 0.0
	if strike==0:
		# Choose once for this chain. The body keeps attacking when a wall or
		# solid prop prevents the small authored advance; feet stay braced.
		var body_shape := player.get_node("CollisionShape2D") as CollisionShape2D
		var complete_step := 0.0
		for cfg in metadata.configs:complete_step += float(cfg.travel_px)
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = body_shape.shape
		query.transform = body_shape.global_transform
		query.motion = Vector2(direction*complete_step,0)
		# Exclude characters: a close opponent can recoil and open the step.
		# Static geometry and solid props retain the braced support policy.
		query.collision_mask = player.collision_mask & ~6
		query.exclude = [player.get_rid()]
		var fractions := player.get_world_2d().direct_space_state.cast_motion(query)
		var probe_origin := body_shape.global_position
		var half_width := body_shape.shape.get_rect().size.x*.5
		var probe := PhysicsRayQueryParameters2D.create(probe_origin,probe_origin+Vector2(direction*(complete_step+half_width),0),query.collision_mask,[player.get_rid()])
		var blocked := fractions[0]<0.999 or not player.get_world_2d().direct_space_state.intersect_ray(probe).is_empty()
		var close_probe := PhysicsRayQueryParameters2D.create(probe_origin,probe_origin+Vector2(direction*(half_width+.2),0),4,[player.get_rid()])
		close_probe.hit_from_inside = true
		var touching_body := not player.get_world_2d().direct_space_state.intersect_ray(close_probe).is_empty()
		braced_support = not braced_lookup.is_empty() and (blocked or touching_body)
	lookup = braced_lookup if braced_support else free_lookup
	(player.swing_box.get_node("Shape").shape as CircleShape2D).radius = float(_config().radius)
	if braced_support:
		# Small early recoil keeps a close opponent inside the short follow-ups.
		player.swing_box.knockback.x = attack_facing*float(_config().get("braced_kb",_config().kb))

func _distance(t: float) -> float:
	if braced_support:return 0.0
	var profile: Array = _config().profile
	for j in range(1,profile.size()):
		var a: Array = profile[j-1]
		var b: Array = profile[j]
		if t<=float(b[0]):
			var u := clampf((t-float(a[0]))/(float(b[0])-float(a[0])),0.0,1.0)
			return lerpf(float(a[1]),float(b[1]),u*u*(3.0-2.0*u))
	return float(profile[-1][1])

func before_movement(dt: float, input_dir: float) -> float:
	motion_step = 0.0
	var press := Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("swap_select")
	var jump_valid := player._coyote>0.0 and (Input.is_action_just_pressed("jump") or player._jump_buf>0.0)
	var roll_valid := Input.is_action_just_pressed("dash") and player.can_movement_roll()
	if _selection_blocks() or player.swap_override_t>0.0 or player.motion_stun_t>0.0 or player.health.hp<=0:
		cancel_for("motion_swap_or_unavailable")
		return input_dir
	if jump_valid or roll_valid or not player.is_on_floor() or player.roll_remaining>0.0:
		cancel_for("jump" if jump_valid else ("roll" if roll_valid else "air_or_roll"))
		return input_dir
	if busy():
		# A deliberate reversal can leave recoil, never flip a striking pose.
		if input_dir*attack_facing<0.0 and age>=float(_config().active_end):
			cancel_for("recovery_direction_change")
			return input_dir
		pending = maxf(0.0,pending-dt)
		if stop_left>0.000001:
			stop_left = maxf(0.0,stop_left-dt)
		else:
			age += dt
		var next_distance := _distance(age)
		motion_step = maxf(0.0,next_distance-planned_travel)
		planned_travel = next_distance
		if press and index<2:pending = buffer_seconds
		if index<2 and age>=float(_config().chain)-0.000001 and pending>0.000001:
			_start(index+1,attack_facing)
		elif age>=float(_config().duration)-0.000001:
			reset()
			if press:_start(0,player.facing if input_dir==0 else (1 if input_dir>0 else -1))
	elif press:
		_start(0,player.facing if input_dir==0 else (1 if input_dir>0 else -1))
	if busy():
		player.facing = attack_facing
		return 0.0
	return input_dir

func apply_attack_motion(dt: float) -> void:
	if busy() and not player._movement_jumped and player.roll_remaining<=0.0:
		# Assignment through CharacterBody collision solver; never accumulated root impulses.
		player.velocity.x = float(attack_facing)*motion_step/dt

func present() -> void:
	super.present()
	if busy() and braced_support:
		sprite.region_rect.position.y += 6*82

func _resolve_hits() -> void:
	# Geometry behind a solid wall must not receive an invisible through-wall hit.
	var origin := player.global_position+Vector2(0,player.swing_box.position.y)
	var ray := PhysicsRayQueryParameters2D.create(origin,player.swing_box.global_position,player.collision_mask & ~6,[player.get_rid()])
	if not player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():return
	super._resolve_hits()

func _draw() -> void:
	for f in fx:
		var pos: Vector2 = player.to_local(f.position)
		var k: float = f.t/.075
		var r := 5.0 if f.strong else 3.0
		var c := Color(1,.83,.53,k)
		draw_line(pos-Vector2(r,0),pos+Vector2(r,0),c,1)
		draw_line(pos-Vector2(0,r),pos+Vector2(0,r),c,1)
	if debug_hitbox and active_window:
		var volume := (player.swing_box.get_node("Shape") as CollisionShape2D).shape as CircleShape2D
		draw_circle(player.swing_box.position,volume.radius,Color(1,.5,.2,.5),false,1)
