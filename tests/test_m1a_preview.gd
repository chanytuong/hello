extends SceneTree
## Real unchanged player controller + isolated visual overlay. No live combat damage.
var scene: Node2D
var player: NLBPlayer
var punch: Node2D
var rows: Array[Dictionary] = []
var checks: Array[Dictionary] = []
var case_name: String = ""
var capture: bool = false
var frame_index: int = 0
var events: Array[Dictionary] = []
const OUT := "res://artifacts/combat_m1a/"

func _init() -> void:
	call_deferred("run")

func check(ok: bool, what: String, values: Dictionary = {}) -> void:
	checks.append({"pass":ok,"test":what,"values":values})
	print("%s: %s %s" % ["PASS" if ok else "FAIL",what,values])

func step(n: int) -> void:
	for i in n:
		await physics_frame
		await process_frame

func run() -> void:
	root.unfocusable = true
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute(OUT+"distance_phase/frames")
	scene = load("res://labs/m1a_preview.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.player
	punch = scene.punch
	await step(5)
	# Exact physics equivalence under the same input replay, overlay on versus off.
	var trajectories: Array = []
	for enabled in [false,true]:
		await begin("physics reference",1,true)
		punch.enabled = enabled
		if enabled:
			punch.request_attack()
		var trace: Array = []
		for i in 16:
			await step(1)
			trace.append([player.global_position.x,player.global_position.y,player.velocity.x,player.velocity.y])
		trajectories.append(trace)
	check(trajectories[0]==trajectories[1],"M1-A overlay adds zero player position/velocity difference over the same RUN input")
	punch.enabled = true
	for direction in [1,-1]:
		for family in ["IDLE","RUN","FIXED CLOCK COMPARISON","PLANTED COUNTEREXAMPLE"]:
			await begin(("RIGHT" if direction>0 else "LEFT")+" / "+family+" > M1-A > "+("IDLE" if family=="IDLE" else "RUN"),direction,family!="IDLE")
			punch.planted_demo = family=="PLANTED COUNTEREXAMPLE"
			punch.distance_phase = family!="FIXED CLOCK COMPARISON"
			await observe(18)
			var x := player.position.x
			punch.request_attack()
			await observe(1)
			var accepted: Dictionary = rows.back()
			check(accepted.age==0.0 and accepted.sample==1,"%s: accepting update displays gathered hand immediately" % case_name)
			events.append({"kind":"accept","index":rows.size()-1,"case":case_name})
			await observe(12)
			var span := rows.slice(rows.size()-13)
			var active := span.filter(func(r):return r.active)
			check(not active.is_empty() and is_equal_approx(active[0].age,0.05) and active[0].sample==2,
				case_name+": .04s contact threshold and matching drawing reached on first eligible 60Hz update",{"first_contact_age":active[0].age if not active.is_empty() else -1})
			check(punch.age<0.0 and not punch.sprite.visible and player.movement_visual.body.visible,case_name+": clean .20s overlay release")
			if family=="IDLE":
				check(is_equal_approx(player.position.x,x),case_name+": standing root remains fixed")
			else:
				check(is_equal_approx(player.velocity.x,280.0*direction),case_name+": full RUN speed retained throughout")
				if family=="RUN":
					var last: Dictionary = span[11]
					var after: Dictionary = span[12]
					check(posmod(int(after.run_phase)-int(last.render_phase),18)<=1,case_name+": return continues current stride without restarting RUN")
			await observe(18)
		for cancel_action in ["dash","jump"]:
			await begin(("RIGHT" if direction>0 else "LEFT")+" / M1-A > "+("ROLL" if cancel_action=="dash" else "JUMP"),direction,true)
			await observe(12)
			punch.request_attack()
			await observe(4)
			Input.action_press(cancel_action)
			await observe(1)
			var good := player.roll_remaining>0.0 if cancel_action=="dash" else player.velocity.y < -600.0
			check(good and punch.age<0.0 and not punch.sprite.visible,case_name+": movement and punch cancel on the same accepting physics update")
			events.append({"kind":"cancel","index":rows.size()-1,"case":case_name})
			Input.action_release(cancel_action)
			await observe(18)
	check(is_equal_approx(player.roll_duration,.29) and is_equal_approx(player.roll_speed,333.3333333),"approved roll tuning unchanged")
	check(rows.all(func(r):return r.anchor_error<=0.708),"flame root within nearest-pixel rounding distance of the displayed pose neck")
	check(rows.filter(func(r):return r.active).all(func(r):return r.sample in [2,3]),"all intended active updates display the authored contact/recoil-contact poses")
	var failed := checks.filter(func(r):return not r.pass)
	FileAccess.open(OUT+"GODOT_VALIDATION.json",FileAccess.WRITE).store_string(JSON.stringify({"engine":Engine.get_version_info().string,"checks":checks,"failures":failed.size(),"samples":rows,"events":events,"captured_frames":frame_index,"capture_frame_dir":"distance_phase/frames","scope":"Isolated M1-A visual/contact-guide preview, no damage/hitbox framework; actual shared player/visual/flame scripts unchanged."},"\t"))
	print("M1A_PREVIEW: %d checks / %d failures / %d captured frames" % [checks.size(),failed.size(),frame_index])
	scene.queue_free()
	await process_frame
	quit(1 if failed.size() else 0)

func begin(label: String,direction: int,moving: bool) -> void:
	for a in ["move_left","move_right","jump","dash","attack","swap_select"]:
		Input.action_release(a)
	punch.reset()
	punch.planted_demo = false
	punch.distance_phase = true
	player.reset_movement(Vector2(180 if direction>0 else 700,559))
	player.facing = direction
	case_name = label
	scene.case_label = label
	await step(6)
	if moving:
		Input.action_press("move_right" if direction>0 else "move_left")
		await step(12)

func observe(n: int) -> void:
	for i in n:
		await step(1)
		var vis := player.movement_visual
		var ankle_world: Dictionary = {}
		var sole_z: Dictionary = {}
		var source_family: String = str(punch.current.get("family","none"))
		if not punch.current.is_empty():
			for side in ["L","R"]:
				var p: Vector2 = player.global_position + vis.position + Vector2(punch.current.ankles[side][0],punch.current.ankles[side][1])-punch.PIVOT
				ankle_world[side] = [p.x,p.y]
			sole_z = punch.metadata.base_details[source_family].sole_world_z
		var record := {"index":rows.size(),"frame":frame_index if capture else -1,"case":case_name,
			"age":punch.age,"active":punch.active_window,"sample":int(punch.current.get("sample",-1)),
			"family":str(punch.current.get("family","none")),"root":[player.position.x,player.position.y],
			"velocity":[player.velocity.x,player.velocity.y],"floor":player.is_on_floor(),"roll":player.roll_remaining,
			"facing":player.facing,"run_phase":vis.body.frame,"state":vis.state,
			"visual_offset":[vis.position.x,vis.position.y],"anchor_error":vis.flame.position.distance_to(vis.neck_local),
			"render_phase":int(source_family.trim_prefix("RUN_")) if source_family.begins_with("RUN_") else -1,
			"ankles_world":ankle_world,"source_sole_z_m":sole_z,"run_clock":vis.state_time}
		rows.append(record)
		if capture:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT+"distance_phase/frames/%04d.png"%frame_index)
			frame_index += 1
