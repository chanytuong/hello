extends "res://scripts/combat/m1_rebuild.gd"
## Three horizontal strikes. A chain decision and a complete stop continuation
## share one authored Action per strike; a committed stop never rewinds to chain.
var branch_closed := false
var restart_pending := 0.0

func _ready() -> void:
	super._ready()
	metadata=JSON.parse_string(FileAccess.get_file_as_string("res://art/experiments/m1_natural_combo/metadata.json"))
	free_lookup.clear()
	braced_lookup.clear()
	for row in metadata.records:
		var key: String="%d/%s/%d"%[row.strike,row.direction,row.sample]
		if row.get("support","free")=="braced":braced_lookup[key]=row
		else:free_lookup[key]=row
	lookup=free_lookup
	sprite.texture=load("res://art/experiments/m1_natural_combo/body.png")
	buffer_seconds=.22

func reset() -> void:
	super.reset()
	branch_closed=false
	restart_pending=0.0

func _start(strike: int,direction: int) -> void:
	super._start(strike,direction)
	if strike==0 and not braced_support:
		# Conservative support choice: a nearby solid character may not recoil
		# enough to clear all three steps. Do not slide planted feet into its body.
		var body_shape:=player.get_node("CollisionShape2D") as CollisionShape2D
		var query:=PhysicsShapeQueryParameters2D.new()
		query.shape=body_shape.shape
		query.transform=body_shape.global_transform
		var distance:=0.0
		for cfg in metadata.configs:distance+=float(cfg.travel_px)
		query.motion=Vector2(direction*distance,0)
		query.collision_mask=4
		query.exclude=[player.get_rid()]
		var fractions:=player.get_world_2d().direct_space_state.cast_motion(query)
		if fractions[0]<.999:braced_support=true
	lookup=braced_lookup if braced_support else free_lookup
	if braced_support:player.swing_box.knockback.x=direction*float(_config().braced_kb)
	branch_closed=false
	restart_pending=0.0

func before_movement(dt: float,input_dir: float) -> float:
	motion_step=0.0
	var press:=Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("swap_select")
	var jump_valid:=player._coyote>0.0 and (Input.is_action_just_pressed("jump") or player._jump_buf>0.0)
	var roll_valid:=Input.is_action_just_pressed("dash") and player.can_movement_roll()
	if _selection_blocks() or player.swap_override_t>0.0 or player.motion_stun_t>0.0 or player.health.hp<=0:
		cancel_for("motion_swap_or_unavailable")
		return input_dir
	if jump_valid or roll_valid or not player.is_on_floor() or player.roll_remaining>0.0:
		cancel_for("jump" if jump_valid else ("roll" if roll_valid else "air_or_roll"))
		return input_dir
	if busy():
		if input_dir*attack_facing<0.0 and age>=float(_config().active_end):
			cancel_for("recovery_direction_change")
			return input_dir
		pending=maxf(0,pending-dt)
		restart_pending=maxf(0,restart_pending-dt)
		if stop_left>0.000001:stop_left=maxf(0,stop_left-dt)
		else:age+=dt
		var cfg:=_config()
		var next_distance:=_distance(age)
		motion_step=maxf(0,next_distance-planned_travel)
		planned_travel=next_distance
		if press:
			if index<2 and not branch_closed and age<=float(cfg.chain)+.000001:pending=buffer_seconds
			elif age>=float(cfg.duration)-buffer_seconds:restart_pending=buffer_seconds
		if index<2 and not branch_closed and age>=float(cfg.chain)-.000001:
			if pending>.000001:_start(index+1,attack_facing)
			else:
				branch_closed=true
				pending=0.0
				events.append({"event":"stop_branch","index":index,"age":age,"frame":Engine.get_physics_frames()})
		elif age>=float(cfg.duration)-.000001:
			var restart:=restart_pending>.000001
			reset()
			if restart or press:_start(0,player.facing if input_dir==0 else (1 if input_dir>0 else -1))
	elif press:_start(0,player.facing if input_dir==0 else (1 if input_dir>0 else -1))
	if busy():
		player.facing=attack_facing
		return 0.0
	return input_dir

func _resolve_hits() -> void:
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=(player.swing_box.get_node("Shape") as CollisionShape2D).shape
	query.transform=player.swing_box.global_transform
	query.collision_mask=32
	query.collide_with_areas=true
	query.collide_with_bodies=false
	for found in player.get_world_2d().direct_space_state.intersect_shape(query,64):
		var hb:=found.collider as NLBHurtBox
		if hb==null:continue
		var h:=hb.health_node()
		if h==null:continue
		# Test each victim, not merely the circle center: the circle edge may
		# overlap a victim behind a thin barrier while its center stays in front.
		var origin:=player.global_position+Vector2(0,player.swing_box.position.y)
		var sight:=PhysicsRayQueryParameters2D.create(origin,hb.global_position,player.collision_mask & ~6,[player.get_rid()])
		if not player.get_world_2d().direct_space_state.intersect_ray(sight).is_empty():continue
		var before:=h.hp
		var context: Dictionary={"kind":"m1","attack_instance_id":attack_instance_id,"strike":index+1,"attack_age":age,"contact_time":float(_config().startup),"fist":player.swing_box.global_position,"sprite_sample":current.sample}
		player.swing_box._try_hit(hb,context)
		if h.hp<before:
			var event:=context.duplicate()
			event.merge({"hp_before":before,"hp_after":h.hp,"damage":before-h.hp,"victim":str(h.get_parent().get_path()),"frame":Engine.get_physics_frames(),"position":player.swing_box.global_position})
			events.append(event)
			player.landed_hit.emit()
			hit_confirmed.emit(event)
			if feedback_enabled:_feedback(event,h.get_parent())
