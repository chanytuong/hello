extends "res://scripts/combat/m1_combo.gd"
## Isolated PixelLab rebuild. Existing Health/HitBox remains the damage authority.
const MANIFEST := "res://art/iven/m1_crowbar/attack_metadata.json"
var pivot := Vector2(79.499926203, 114.579576591)
var cell := Vector2(160,160)
var branch_closed := false
var restart_pending := 0.0
var weapon_visible := false
var previous_points: Array = []
var previous_age := -1.0
var manifest_valid := false

func _ready() -> void:
	super._ready()
	if not FileAccess.file_exists(MANIFEST):
		push_error("PixelLab rebuild manifest missing: "+MANIFEST)
		return
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not parsed is Dictionary:
		push_error("PixelLab rebuild manifest is not a JSON object")
		return
	metadata=parsed
	if metadata.get("configs",[]).size()!=3 or metadata.get("records",[]).is_empty():
		push_error("PixelLab rebuild manifest needs three configs and frame records")
		return
	var origin: Array=metadata.get("pivot",[79.499926203,114.579576591])
	pivot=Vector2(origin[0],origin[1])
	var dims: Array=metadata.get("cell",[160,160])
	cell=Vector2(dims[0],dims[1])
	lookup.clear()
	for row in metadata.records:
		lookup["%d/%s/%d"%[row.strike,row.direction,row.sample]]=row
	var texture_path: String=metadata.get("texture","res://art/iven/m1_crowbar/attack_body.png")
	# Direct PNG reading also works in a fresh CLI run before editor import.
	var atlas:=Image.load_from_file(ProjectSettings.globalize_path(texture_path))
	if atlas==null or atlas.is_empty():
		push_error("PixelLab rebuild atlas missing or unreadable: "+texture_path)
		return
	sprite.texture=ImageTexture.create_from_image(atlas)
	sprite.offset=-pivot
	buffer_seconds=.22
	manifest_valid=sprite.texture!=null

func reset() -> void:
	super.reset()
	branch_closed=false
	restart_pending=0.0
	weapon_visible=false
	previous_points.clear()
	previous_age=-1.0

func _start(strike: int,direction: int) -> void:
	super._start(strike,direction)
	branch_closed=false
	restart_pending=0.0
	previous_points.clear()
	previous_age=-1.0

func before_movement(dt: float,input_dir: float) -> float:
	if not manifest_valid:return input_dir
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
		var chain: float=float(cfg.chain)
		if press:
			if index<2 and not branch_closed and age<=chain+.000001:pending=buffer_seconds
			elif age>=float(cfg.duration)-buffer_seconds:restart_pending=buffer_seconds
		if index<2 and not branch_closed and age>=chain-.000001:
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
		player.velocity.x=0.0
		return 0.0
	return input_dir

func apply_attack_motion(_dt: float) -> void:
	# Grounded in-place strikes. Existing gravity, jump, roll and carriers own Y.
	if busy() and not player._movement_jumped and player.roll_remaining<=0.0:
		player.velocity.x=0.0

func present() -> void:
	if not busy():
		weapon_visible=false
		return
	var cfg:=_config()
	var sample:=0
	for i in cfg.times.size():
		if age>=float(cfg.times[i])-.000001:sample=i
	var key: String="%d/%s/%d"%[index,"right" if attack_facing>0 else "left",sample]
	if not lookup.has(key):
		push_error("Missing PixelLab cel "+key)
		cancel_for("missing_frame")
		return
	current=lookup[key]
	var rect: Array=current.get("rect",[sample*cell.x,(index*2+(0 if attack_facing>0 else 1))*cell.y,cell.x,cell.y])
	sprite.region_rect=Rect2(rect[0],rect[1],rect[2],rect[3])
	vis.body.hide()
	sprite.show()
	vis.neck_local=Vector2(current.neck[0],current.neck[1])-pivot
	vis.flame.position=vis.neck_local.round()
	vis.flame.rotation=float(current.angle)
	vis.flame.limit_at_ground(player.global_position.y-vis.flame.global_position.y)
	var grip: Array=current.get("grip",current.get("fist",[pivot.x,pivot.y-35]))
	player.swing_box.position=Vector2(grip[0],grip[1])-pivot
	weapon_visible=bool(current.get("weapon_visible",true))
	active_window=weapon_visible and age>=float(cfg.startup)-.000001 and age<float(cfg.active_end)-.000001
	if active_window and damage_enabled:
		if not box_open:
			player.swing_box.begin()
			box_open=true
		_resolve_hits()
	elif box_open:
		player.swing_box.end()
		box_open=false
	previous_points=current.get("weapon_points",[]).duplicate(true)
	previous_age=age

func weapon_segments() -> Array:
	var result: Array=[]
	if not busy() or not weapon_visible:return result
	var points: Array=current.get("weapon_points",[])
	for i in range(points.size()-1):
		result.append([Vector2(points[i][0],points[i][1])-pivot,Vector2(points[i+1][0],points[i+1][1])-pivot])
	return result

func _resolve_hits() -> void:
	var segments:=weapon_segments()
	var points: Array=current.get("weapon_points",[])
	# Endpoint sweeps fill a single physics tick of actual visible weapon motion.
	# They never bridge strike changes, rewinds, pauses or cancellations.
	if previous_points.size()==points.size() and previous_age>=0 and age>previous_age and age-previous_age<.04:
		for i in points.size():
			segments.append([Vector2(previous_points[i][0],previous_points[i][1])-pivot,Vector2(points[i][0],points[i][1])-pivot])
	var checked: Dictionary={}
	for j in segments.size():
		var a: Vector2=segments[j][0]
		var b: Vector2=segments[j][1]
		var capsule:=CapsuleShape2D.new()
		capsule.radius=float(_config().get("weapon_radius_px",2.0))
		capsule.height=maxf(capsule.radius*2,(b-a).length()+capsule.radius*2)
		var query:=PhysicsShapeQueryParameters2D.new()
		query.shape=capsule
		query.transform=Transform2D((b-a).angle()-PI*.5,player.global_position+(a+b)*.5)
		query.collision_mask=32
		query.collide_with_areas=true
		query.collide_with_bodies=false
		for found in player.get_world_2d().direct_space_state.intersect_shape(query,64):
			var hb:=found.collider as NLBHurtBox
			if hb==null:continue
			var health_node:=hb.health_node()
			if health_node==null or checked.has(health_node.get_instance_id()):continue
			checked[health_node.get_instance_id()]=true
			var origin:=player.global_position+Vector2(0,(a.y+b.y)*.5)
			var sight:=PhysicsRayQueryParameters2D.create(origin,hb.global_position,player.collision_mask & ~6,[player.get_rid()])
			if not player.get_world_2d().direct_space_state.intersect_ray(sight).is_empty():continue
			var contact:=player.global_position+Geometry2D.get_closest_point_to_segment(hb.global_position-player.global_position,a,b)
			var before:=health_node.hp
			var context: Dictionary={"kind":"m1","weapon":"pixellab_crowbar","attack_instance_id":attack_instance_id,"strike":index+1,"attack_age":age,"contact_time":float(_config().startup),"fist":contact,"sprite_sample":current.sample,"weapon_segment":j,"knockback":player.swing_box.knockback}
			player.swing_box._try_hit(hb,context)
			if health_node.hp<before:
				var event:=context.duplicate()
				event.merge({"hp_before":before,"hp_after":health_node.hp,"damage":before-health_node.hp,"victim":str(health_node.get_parent().get_path()),"frame":Engine.get_physics_frames(),"position":contact})
				events.append(event)
				player.landed_hit.emit()
				hit_confirmed.emit(event)
				if feedback_enabled:_feedback(event,health_node.get_parent())

func _draw() -> void:
	for mark in fx:
		var pos: Vector2=player.to_local(mark.position)
		var radius:=5.0 if mark.strong else 3.0
		var color:=Color(1,.83,.53,mark.t/.075)
		draw_line(pos-Vector2(radius,0),pos+Vector2(radius,0),color,1)
		draw_line(pos-Vector2(0,radius),pos+Vector2(0,radius),color,1)
	if debug_hitbox and active_window:
		for segment in weapon_segments():draw_line(segment[0],segment[1],Color(1,.5,.2,.8),float(_config().get("weapon_radius_px",2))*2)
