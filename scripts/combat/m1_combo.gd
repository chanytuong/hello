extends Node2D
class_name NLBM1Combo
## One grounded attack clock drives sprite, active hitbox and chain decisions.
signal strike_started(index: int, instance_id: String)
signal hit_confirmed(event: Dictionary)
signal interrupted(reason: String)
enum State { READY, M1_1, M1_2, M1_3 }
const PIVOT := Vector2(40.499926203,75.579576591)
@export var buffer_seconds := 0.12
@export var hitstop_enabled := true
@export var hitstop_seconds := 1.0/60.0
@export var finisher_hitstop_seconds := 2.0/60.0
@export var damage_enabled := true
var state: State = State.READY
var age := -1.0
var index := -1
var attack_facing := 1
var pending := 0.0
var instance_serial := 0
var attack_instance_id := ""
var accepted := 0
var cancelled := 0
var active_window := false
var current: Dictionary = {}
var metadata: Dictionary
var player: NLBPlayer
var vis: Node2D
var sprite := Sprite2D.new()
var lookup: Dictionary = {}
var stop_left := 0.0
var box_open := false
var selector: NLBMotionSwapController
var selection_frame := -100
var selection_click_held := false
var events: Array[Dictionary] = []
var audio := AudioStreamPlayer.new()
var fx: Array[Dictionary] = []
var feedback_enabled := true
var debug_hitbox := false
var sounds: Array[AudioStream] = []

func _ready() -> void:
	player = get_parent() as NLBPlayer
	vis = player.movement_visual
	metadata = JSON.parse_string(FileAccess.get_file_as_string("res://art/iven/m1_combo/metadata.json"))
	for row in metadata.records:
		lookup["%d/%s/%d"%[row.strike,row.direction,row.sample]] = row
	sprite.texture = load("res://art/iven/m1_combo/body.png")
	sprite.centered = false
	sprite.offset = -PIVOT
	sprite.region_enabled = true
	sprite.z_index = -1
	sprite.hide()
	vis.add_child(sprite)
	player.movement_attack_preview = self
	# The existing box, HurtBox and Health remain the damage authority.
	player.swing_box.manual_contact_only = true
	player.swing_box.damage_kind = &"m1"
	player.swing_box.end()
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	(player.swing_box.get_node("Shape") as CollisionShape2D).shape = shape
	if player.swing_box.landed.is_connected(player._on_swing_landed):
		player.swing_box.landed.disconnect(player._on_swing_landed)
	add_child(audio)
	audio.volume_db = -9.0
	for i in 3:sounds.append(load("res://art/iven/m1_combo/hit_%d.wav"%(i+1)))
	process_physics_priority = 10

func busy() -> bool:
	return state != State.READY

func _config() -> Dictionary:
	return metadata.configs[index]

func reset() -> void:
	state = State.READY
	index = -1
	age = -1.0
	pending = 0.0
	stop_left = 0.0
	active_window = false
	current = {}
	box_open = false
	player.swing_box.end()
	sprite.hide()
	vis.body.show()

func cancel_for(reason: String) -> void:
	if busy():
		cancelled += 1
		events.append({"event":"cancel","reason":reason,"index":index,"age":age,"frame":Engine.get_physics_frames()})
		interrupted.emit(reason)
	reset()

func _selection_changed(_phase: int) -> void:
	selection_frame = Engine.get_physics_frames()
	selection_click_held = Input.is_action_pressed("swap_select")
	cancel_for("motion_swap")

func _selection_blocks() -> bool:
	if not is_instance_valid(selector):
		selector = get_tree().get_first_node_in_group("motion_swap_controller") as NLBMotionSwapController
		if selector != null and not selector.phase_changed.is_connected(_selection_changed):
			selector.phase_changed.connect(_selection_changed)
	if not Input.is_action_pressed("swap_select"):selection_click_held = false
	return Input.is_action_just_pressed("swap_activate") or (selector != null and selector.is_selecting()) or selection_click_held or Engine.get_physics_frames() <= selection_frame+1

func _start(strike: int, direction: int) -> void:
	player.swing_box.end()
	box_open = false
	index = strike
	state = strike+1
	age = 0.0
	pending = 0.0
	active_window = false
	stop_left = 0.0
	instance_serial += 1
	attack_instance_id = "%d:%d"%[player.get_instance_id(),instance_serial]
	attack_facing = direction
	accepted += 1
	vis._skid_left = 0.0
	# Old decorative roll handoffs cannot cover a newly accepted contact pose.
	vis._exit_poses.clear()
	var cfg := _config()
	player.swing_box.damage = int(cfg.damage)
	player.swing_box.knockback = Vector2(float(attack_facing)*float(cfg.kb),0)
	events.append({"event":"start","index":index,"id":attack_instance_id,"frame":Engine.get_physics_frames()})
	strike_started.emit(index,attack_instance_id)
	player.swung.emit()

func before_movement(dt: float, input_dir: float) -> float:
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
		pending = maxf(0.0,pending-dt)
		# Defence is checked above hitstop; local impact hold never delays a cancel.
		if stop_left>0.000001:
			stop_left = maxf(0.0,stop_left-dt)
		else:
			age += dt
		if press and index<2:pending = buffer_seconds
		var cfg := _config()
		if index<2 and age>=float(cfg.chain)-0.000001 and pending>0.000001:
			_start(index+1,attack_facing)
		elif age>=float(cfg.duration)-0.000001:
			reset() # no inactivity queue survives the short recovery
			# A genuinely new press on this exact READY tick may begin a new combo.
			if press:_start(0,player.facing if input_dir==0 else (1 if input_dir>0 else -1))
	elif press:
		_start(0,player.facing if input_dir==0 else (1 if input_dir>0 else -1))
	if busy():
		player.facing = attack_facing
		player.velocity.x = 0.0
		return 0.0
	return input_dir

func present() -> void:
	if not busy():return
	var cfg := _config()
	var sample := 0
	for i in cfg.times.size():
		if age>=float(cfg.times[i])-0.000001:sample=i
	var direction := "right" if attack_facing>0 else "left"
	current = lookup["%d/%s/%d"%[index,direction,sample]]
	sprite.region_rect = Rect2(sample*82,(index*2+(0 if attack_facing>0 else 1))*82,82,82)
	vis.body.hide()
	sprite.show()
	vis.neck_local = Vector2(current.neck[0],current.neck[1])-PIVOT
	vis.flame.position = vis.neck_local.round()
	vis.flame.rotation = float(current.angle)
	vis.flame.limit_at_ground(player.global_position.y-vis.flame.global_position.y)
	active_window = age>=float(cfg.startup)-0.000001 and age<float(cfg.active_end)-0.000001
	player.swing_box.position = Vector2(current.fist[0],current.fist[1])-PIVOT
	if active_window and damage_enabled:
		if not box_open:
			player.swing_box.begin()
			box_open = true
		_resolve_hits()
	elif box_open:
		player.swing_box.end()
		box_open = false

func _resolve_hits() -> void:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = (player.swing_box.get_node("Shape") as CollisionShape2D).shape
	query.transform = player.swing_box.global_transform
	query.collision_mask = 32
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for found in player.get_world_2d().direct_space_state.intersect_shape(query,64):
		var hb := found.collider as NLBHurtBox
		if hb==null:continue
		var h := hb.health_node()
		if h==null:continue
		var before := h.hp
		var context := {"kind":"m1","attack_instance_id":attack_instance_id,"strike":index+1,"attack_age":age,"contact_time":float(_config().startup),"fist":player.swing_box.global_position,"sprite_sample":current.sample}
		player.swing_box._try_hit(hb,context)
		if h.hp<before:
			var event := context.duplicate()
			event.merge({"hp_before":before,"hp_after":h.hp,"damage":before-h.hp,"victim":str(h.get_parent().get_path()),"frame":Engine.get_physics_frames(),"position":player.swing_box.global_position})
			events.append(event)
			player.landed_hit.emit()
			hit_confirmed.emit(event)
			if feedback_enabled:_feedback(event,h.get_parent())

func _feedback(event: Dictionary, victim: Node) -> void:
	var pause := finisher_hitstop_seconds if index==2 else hitstop_seconds
	if hitstop_enabled:
		stop_left = maxf(stop_left,pause)
		if victim.has_method("apply_combat_hitstop"):victim.apply_combat_hitstop(pause)
	fx.append({"position":event.position,"t":.075,"strong":index==2})
	audio.stream = sounds[index]
	audio.play()

func _process(dt: float) -> void:
	for f in fx:f.t-=dt
	fx = fx.filter(func(f):return f.t>0.0)
	queue_redraw()

func _draw() -> void:
	for f in fx:
		var pos: Vector2 = player.to_local(f.position)
		var k: float = f.t/.075
		var r := 5.0 if f.strong else 3.0
		var c := Color(1,.83,.53,k)
		draw_line(pos-Vector2(r,0),pos+Vector2(r,0),c,1)
		draw_line(pos-Vector2(0,r),pos+Vector2(0,r),c,1)
	if debug_hitbox and active_window:draw_circle(player.swing_box.position,7,Color(1,.5,.2,.5),false,1)
