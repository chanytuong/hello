extends SceneTree
## Actual player physics with the opt-in grounded attack driver. No damage.
const OUT := "res://artifacts/combat_m1a_v2/"
var scene: Node2D
var player: NLBPlayer
var punch: Node
var checks: Array[Dictionary] = []
var samples: Array[Dictionary] = []
var events: Array[Dictionary] = []
var capture := false
var frame_index := 0
var case_name := ""

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String, data: Dictionary = {}) -> void:
	checks.append({"pass":ok,"label":label,"data":data})
	print("%s %s %s" % ["PASS" if ok else "FAIL",label,data])

func step(n: int) -> void:
	for i in n:
		await physics_frame
		await process_frame

func observe(n: int) -> void:
	for i in n:
		await step(1)
		var vis := player.movement_visual
		samples.append({"index":samples.size(),"frame":frame_index if capture else -1,"case":case_name,"age":punch.age,"sample":int(punch.current.get("sample",-1)),"active":punch.active_window,"busy":punch.busy(),"x":player.position.x,"y":player.position.y,"vx":player.velocity.x,"vy":player.velocity.y,"floor":player.is_on_floor(),"roll":player.roll_remaining,"facing":player.facing,"state":vis.state,"anchor_error":vis.flame.position.distance_to(vis.neck_local),"ankles":punch.current.get("ankles",{}),"accepted":punch.accepted,"discarded":punch.discarded})
		if capture:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT+"frames/%04d.png"%frame_index)
			frame_index += 1

func begin(label: String, direction: int, moving: bool) -> void:
	for a in ["move_left","move_right","jump","dash","attack","swap_select"]:
		Input.action_release(a)
	punch.reset()
	player.reset_movement(Vector2(200 if direction>0 else 700,559))
	player.facing = direction
	case_name = ("RIGHT / " if direction>0 else "LEFT / ")+label
	scene.case_label = case_name
	await step(6)
	if moving:
		Input.action_press("move_right" if direction>0 else "move_left")
		await step(12)

func start_attack() -> float:
	var x := player.position.x
	Input.action_press("attack")
	await observe(1)
	Input.action_release("attack")
	check(punch.busy() and punch.age==0.0 and punch.sprite.visible,case_name+": input accepted and first pose displayed on same update")
	check(is_zero_approx(player.velocity.x) and is_equal_approx(x,player.position.x),case_name+": same-update stop with zero post-input displacement")
	events.append({"kind":"attack","sample":samples.size()-1,"case":case_name})
	return x

func run() -> void:
	root.unfocusable = true
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	DirAccess.make_dir_recursive_absolute(OUT+"frames")
	scene = load("res://labs/m1a_v2_preview.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.player
	punch = scene.punch
	await step(5)
	for direction in [1,-1]:
		for family in ["IDLE > M1 > IDLE","RUN > M1 > IDLE","RUN > M1 > RUN"]:
			await begin(family,direction,family.begins_with("RUN"))
			await observe(16)
			var start_index := samples.size()
			var x := await start_attack()
			if family.ends_with("IDLE"):
				Input.action_release("move_right" if direction>0 else "move_left")
			await observe(11)
			var span := samples.slice(start_index)
			check(span.all(func(r):return r.busy and is_zero_approx(r.vx) and is_equal_approx(r.x,x)),case_name+": root fixed throughout planted action")
			check(span.all(func(r):return r.floor and r.state!="SKID_STOP"),case_name+": grounded with no forced skid")
			var active := span.filter(func(r):return r.active)
			check(not active.is_empty() and is_equal_approx(active[0].age,.05) and active[0].sample==2,case_name+": intended .04 contact visible on first eligible 60Hz update")
			await observe(1)
			check(not punch.busy() and not punch.sprite.visible,case_name+": releases at .20s without extra recovery lock")
			if family.ends_with("RUN"):
				check(player.velocity.x*direction>0.0,case_name+": held direction resumes on first recovery-complete update")
			else:
				check(is_zero_approx(player.velocity.x),case_name+": idle remains stationary")
			await observe(22)
		for cancel_action in ["dash","jump"]:
			for phase in [["ANTICIPATION",1],["CONTACT",3],["RECOVERY",8]]:
				await begin("M1 > "+("ROLL" if cancel_action=="dash" else "JUMP")+" / "+phase[0],direction,true)
				await observe(8)
				await start_attack()
				await observe(phase[1])
				Input.action_press(cancel_action)
				await observe(1)
				var acted: bool = player.roll_remaining>0.0 if cancel_action=="dash" else player.velocity.y < -500.0
				check(acted and not punch.busy() and not punch.sprite.visible,case_name+": same-update defensive cancel")
				events.append({"kind":"cancel","sample":samples.size()-1,"case":case_name})
				Input.action_release(cancel_action)
				await observe(24)
		await begin("repeated fresh M1 / busy press discarded",direction,false)
		await observe(8)
		var count: int = punch.accepted
		for j in 3:
			await start_attack()
			await observe(2)
			Input.action_press("attack")
			await observe(1)
			Input.action_release("attack")
			await observe(12)
		check(punch.accepted==count+3,case_name+": exactly three fresh attacks, no busy-input queue")
		await observe(16)
		check(not punch.busy(),case_name+": no delayed surprise attack")
		await begin("simultaneous JUMP + ROLL + M1",direction,true)
		var accepted: int = punch.accepted
		for a in ["jump","dash","attack"]:Input.action_press(a)
		await observe(1)
		check(player.velocity.y < -500.0 and player.roll_remaining==0.0 and punch.accepted==accepted,case_name+": valid jump wins with no queued roll/punch")
		for a in ["jump","dash","attack"]:Input.action_release(a)
		await observe(20)
		await begin("direction changes during brief commitment",direction,true)
		await start_attack()
		await observe(3)
		Input.action_release("move_right" if direction>0 else "move_left")
		Input.action_press("move_left" if direction>0 else "move_right")
		await observe(8)
		check(punch.busy() and player.facing==direction and is_zero_approx(player.velocity.x),case_name+": facing stays coherent while current direction remains readable")
		await observe(1)
		check(not punch.busy() and player.velocity.x*direction<0.0 and player.facing==-direction,case_name+": latest direction resumes at recovery end")
		await observe(16)
		await begin("simultaneous ROLL + M1",direction,true)
		accepted = punch.accepted
		Input.action_press("dash")
		Input.action_press("attack")
		await observe(1)
		check(player.roll_remaining>0.0 and punch.accepted==accepted,case_name+": roll wins without punch queue")
		Input.action_release("dash")
		Input.action_release("attack")
		await observe(23)
		await begin("held M1 does not autorepeat",direction,false)
		accepted = punch.accepted
		Input.action_press("attack")
		await observe(30)
		check(punch.accepted==accepted+1 and not punch.busy(),case_name+": one held press is one attack")
		Input.action_release("attack")
	check(samples.filter(func(r):return r.busy).all(func(r):return r.anchor_error<=.708),"flame root follows displayed pose within nearest-pixel rounding")
	check(is_equal_approx(player.roll_duration,.50) and is_equal_approx(player.roll_speed,400.0),"approved roll tuning preserved")
	var failures := checks.filter(func(r):return not r.pass)
	FileAccess.open(OUT+"GODOT_VALIDATION.json",FileAccess.WRITE).store_string(JSON.stringify({"engine":Engine.get_version_info().string,"checks":checks,"failures":failures.size(),"samples":samples,"events":events,"captured_frames":frame_index,"scope":"Opt-in planted M1-A V2. Same real player physics; no live damage, hitstop or main-scene adoption."},"\t"))
	print("M1A_V2: %d checks / %d failures / %d captured frames" % [checks.size(),failures.size(),frame_index])
	scene.queue_free()
	await process_frame
	quit(1 if failures.size() else 0)
