extends SceneTree
const OUT := "res://artifacts/m1_combat_rebuild/"
var scene: Node2D
var player: NLBPlayer
var combo: NLBM1Combo
var checks: Array[Dictionary] = []
var samples: Array[Dictionary] = []
var stages: Array[Dictionary] = []
var hits: Array[Dictionary] = []
var label := ""
var frame_index := 0
var capture := false
func _init() -> void:call_deferred("run")
func check(ok: bool, name: String, data: Dictionary={}) -> void:
	checks.append({"pass":ok,"label":name,"data":data})
	print("%s %s %s"%["PASS" if ok else "FAIL",name,data])
func release_all() -> void:
	for a in ["attack","swap_select","swap_activate","swap_self","move_left","move_right","jump","dash"]:Input.action_release(a)
func step(n: int) -> void:
	for j in n:
		await physics_frame
		await process_frame
func observe(n: int) -> void:
	for j in n:
		await step(1)
		samples.append({"frame":frame_index,"case":label,"index":combo.index,"age":combo.age,"active":combo.active_window,"sample":combo.current.get("sample",-1),"x":player.position.x,"y":player.position.y,"vx":player.velocity.x,"floor":player.is_on_floor(),"pending":combo.pending,"stop":combo.stop_left,"support":combo.current.get("support","free"),"anchor_error":player.movement_visual.flame.position.distance_to(player.movement_visual.neck_local)})
		if capture:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT+"frames/%04d.png"%frame_index)
		frame_index+=1
func begin(name: String, dir: int=1, only_animation: bool=true) -> void:
	release_all()
	scene.reset(dir,only_animation)
	label=name+(" / RIGHT" if dir>0 else " / LEFT")
	scene.case_label=label
	stages.append({"name":label,"start":frame_index})
	await step(6)
func click() -> void:
	Input.action_press("attack")
	await observe(1)
	Input.action_release("attack")
func finish() -> void:
	var guard:=0
	while combo.busy() and guard<100:
		await observe(1)
		guard+=1
	check(guard<100,"attack always returns READY / "+label)
func start_n(n: int) -> void:
	await click()
	for j in n:
		await observe(5)
		await click()
		var guard:=0
		while combo.index==j and guard<40:
			await observe(1)
			guard+=1
		check(combo.index==j+1,"intentional chain / "+label)
func full_chain() -> void:
	await start_n(2)
	await finish()
func input_event(action: String, pressed: bool) -> void:
	var e:=InputEventAction.new()
	e.action=action
	e.pressed=pressed
	Input.parse_input_event(e)
func mouse(pressed: bool, at: Vector2, button: MouseButton=MOUSE_BUTTON_LEFT) -> void:
	var e:=InputEventMouseButton.new()
	e.button_index=button
	e.position=at
	e.pressed=pressed
	Input.parse_input_event(e)
func run() -> void:
	root.unfocusable=true
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i(1280,720)
	capture="--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	DirAccess.make_dir_recursive_absolute(OUT+"frames")
	scene=load("res://labs/m1_combat_rebuild.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	player=scene.player
	combo=scene.combo
	combo.hit_confirmed.connect(func(e: Dictionary):
		var row:=e.duplicate()
		row.case=label
		row.capture_frame=frame_index
		hits.append(row))
	await step(8)
	for dir in [1,-1]:
		await begin("NO EFFECTS / IDLE > STRAIGHT > HOOK > FOREARM > IDLE",dir)
		await observe(18)
		var x:=player.position.x
		var accepted:=combo.accepted
		await full_chain()
		check(combo.accepted==accepted+3,"three presses, three distinct stages")
		check(absf((player.position.x-x)*dir-14.0)<.05,"authored 5 + 2 + 7 px applied once",{"distance":(player.position.x-x)*dir})
		await observe(18)
		await begin("RUN IN > MOVING COMBO > RUN OUT",dir)
		Input.action_press("move_right" if dir>0 else "move_left")
		await observe(14)
		await full_chain()
		await observe(14)
		check(player.velocity.x*dir>0,"held direction resumes after recoil")
		Input.action_release("move_right" if dir>0 else "move_left")
		await observe(18)
		await begin("RUN IN > ONE STRIKE > IDLE",dir)
		Input.action_press("move_right" if dir>0 else "move_left")
		await observe(12)
		await click()
		Input.action_release("move_right" if dir>0 else "move_left")
		await finish()
		await observe(18)
		check(absf(player.velocity.x)<.01,"single strike returns IDLE")
		await begin("REAL ENEMY / CONTACTS AND RECOIL",dir,false)
		# Existing solid opponent, no fake hit events. Close enough for unarmed reach.
		scene.enemy.position=player.position+Vector2(dir*30,0)
		await step(4)
		var before_hits:=hits.size()
		await full_chain()
		await observe(20)
		check(hits.size()>before_hits,"real accepted damage / "+str(dir))
		var chain_hits:=hits.slice(before_hits)
		check(chain_hits.size()==3 and chain_hits[0].strike==1 and chain_hits[1].strike==2 and chain_hits[2].strike==3,"all three visible strikes connect at close range / "+str(dir),{"strikes":chain_hits.map(func(e):return e.strike)})
		check(hits.slice(before_hits).all(func(e):return e.damage==e.hp_before-e.hp_after),"feedback uses accepted HP delta")
	for dir in [1,-1]:
		await begin("UNSCALED GAME ENEMY / ACTUAL HURTBOX HEIGHT",dir,false)
		scene.enemy.scale=Vector2.ONE
		scene.enemy.position=player.position+Vector2(dir*32,0)
		await step(5)
		var before_native:=hits.size()
		await full_chain()
		var native_hits:=hits.slice(before_native)
		check(native_hits.size()==3 and native_hits[0].strike==1 and native_hits[1].strike==2 and native_hits[2].strike==3,"three contacts on unscaled game enemy / "+str(dir),{"strikes":native_hits.map(func(e):return e.strike)})
		await observe(18)
	for dir in [1,-1]:
		await begin("CLOSE ENEMY / BRACED COMBO",dir,false)
		scene.enemy.scale=Vector2.ONE
		scene.enemy.position=player.position+Vector2(dir*29,0)
		await step(6)
		var close_hits_before:=hits.size()
		var close_x:=player.position.x
		await full_chain()
		var close_hits:=hits.slice(close_hits_before)
		check(close_hits.size()==3,"braced close combo connects all three / "+str(dir),{"strikes":close_hits.map(func(e):return e.strike)})
		check(absf(player.position.x-close_x)<.1,"body contact uses planted support without skating advance")
		await observe(16)
	for held in [false,true]:
		await begin("ONE HELD CLICK" if held else "ONE CLICK")
		var count:=combo.accepted
		Input.action_press("attack")
		await observe(1)
		if not held:Input.action_release("attack")
		await observe(30)
		check(combo.accepted==count+1 and not combo.busy(),"one press never auto-combos")
	await begin("REPEATED INDEPENDENT M1 / NO AUTOMATIC FOLLOW-UP")
	var repeated_count:=combo.accepted
	for j in 3:
		await click()
		check(combo.index==0,"fresh combo starts with straight")
		await finish()
		await observe(5)
	check(combo.accepted==repeated_count+3,"three separated clicks are three singles")
	await begin("ROLL COOLDOWN CANNOT BE BYPASSED")
	Input.action_press("dash")
	await observe(1)
	Input.action_release("dash")
	Input.action_press("move_right")
	await observe(1)
	Input.action_release("move_right")
	await observe(1)
	await click()
	var cooldown_id:=combo.attack_instance_id
	Input.action_press("dash")
	await observe(1)
	Input.action_release("dash")
	check(combo.busy() and combo.attack_instance_id==cooldown_id and player.roll_remaining==0,"unavailable roll preserves attack and existing cooldown")
	await finish()
	# Explicit preparation/contact/recoil interruptions, every stage, both directions.
	for dir in [1,-1]:
		for strike in 3:
			for phase in ["preparation","contact","recoil"]:
				for action in ["dash","jump"]:
					await begin("CANCEL %d %s > %s"%[strike+1,phase,action],dir)
					await start_n(strike)
					var target_age:=.016 if phase=="preparation" else float(combo._config().startup if phase=="contact" else combo._config().active_end)+.001
					while combo.age<target_age:await observe(1)
					var count:=combo.accepted
					Input.action_press(action)
					await observe(1)
					Input.action_release(action)
					check(not combo.busy() and combo.pending==0 and not combo.sprite.visible,"same-update cancel / "+label)
					check(player.roll_remaining>0 if action=="dash" else player.velocity.y<0,"defence executes / "+label)
					await observe(12)
					check(combo.accepted==count,"no stale queued attack")
	await begin("EARLY BUFFER EXPIRES")
	await click()
	await click()
	var count:=combo.accepted
	await observe(25)
	check(combo.accepted==count and not combo.busy(),"expired follow-up never fires")
	await begin("RECOVERY REVERSAL")
	await click()
	await observe(7)
	Input.action_press("move_left")
	await observe(1)
	check(not combo.busy() and player.velocity.x<0,"recoil reversal leaves safely for RUN")
	await observe(10)
	await begin("SHARED HEALTH / TWO HURTBOXES",1,false)
	scene.enemy.position=player.position+Vector2(30,0)
	var duplicate: Node=scene.enemy.get_node("HurtBox").duplicate()
	scene.enemy.add_child(duplicate)
	await step(4)
	var old_hits:=hits.size()
	await click()
	await finish()
	check(hits.size()==old_hits+1 and scene.enemy.health.hp==11,"once per strike across two HurtBoxes")
	duplicate.queue_free()
	await begin("DEFENCE DURING LOCAL HITSTOP",1,false)
	scene.enemy.position=player.position+Vector2(30,0)
	await step(4)
	await click()
	var wait_frames:=0
	while combo.stop_left<=0 and combo.busy() and wait_frames<20:
		await observe(1)
		wait_frames+=1
	check(combo.stop_left>0,"real hit enables local hitstop")
	Input.action_press("jump")
	await observe(1)
	Input.action_release("jump")
	check(not combo.busy() and player.velocity.y<0,"hitstop never delays valid JUMP")
	await observe(20)
	# Real Motion Swap front-end: E/LMB/Q and RMB retain their roles.
	await begin("MOTION SWAP E / LMB / Q",1,false)
	await click()
	input_event("swap_activate",true)
	await observe(1)
	input_event("swap_activate",false)
	var before_select:=combo.accepted
	check(scene.controller.is_selecting() and not combo.busy(),"E cancels melee")
	mouse(true,scene.enemy.swap_target.anchor_world())
	await observe(1)
	mouse(false,scene.enemy.swap_target.anchor_world())
	check(scene.controller.target_a==scene.enemy.swap_target and combo.accepted==before_select,"LMB selection cannot trigger M1")
	input_event("swap_self",true)
	await observe(1)
	input_event("swap_self",false)
	check(not scene.controller.is_selecting() and not scene.controller.last_exchange.is_empty(),"Q exchange preserved")
	await observe(12)
	await begin("MOTION SWAP RMB SELF",1,false)
	input_event("swap_activate",true)
	await observe(1)
	input_event("swap_activate",false)
	mouse(true,player.position,MOUSE_BUTTON_RIGHT)
	await observe(1)
	mouse(false,player.position,MOUSE_BUTTON_RIGHT)
	check(scene.controller.target_a==player.swap_target and not combo.busy(),"RMB self selection preserved")
	scene.controller.cancel_selection()
	# Fixed rate changes exercise the actual collision-driven actor, not a curve-only test.
	for rate in [30,60,120]:
		Engine.physics_ticks_per_second=rate
		await begin("PHYSICS %d HZ / SINGLE ADVANCE"%rate)
		var x:=player.position.x
		await click()
		await finish()
		check(absf(player.position.x-x-5)<.05,"single advance consistent at %d Hz"%rate,{"px":player.position.x-x})
	Engine.physics_ticks_per_second=60
	await begin("WALL COLLISION / NO THROUGH-WALL HIT",1,false)
	var wall:=StaticBody2D.new()
	var cs:=CollisionShape2D.new()
	var rect:=RectangleShape2D.new()
	rect.size=Vector2(8,120)
	cs.shape=rect
	wall.add_child(cs)
	var wall_art:=ColorRect.new()
	wall_art.position=Vector2(-4,-60)
	wall_art.size=Vector2(8,120)
	wall_art.color=Color("657480")
	wall_art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	wall.add_child(wall_art)
	wall.position=player.position+Vector2(18,-50)
	scene.add_child(wall)
	scene.enemy.position=player.position+Vector2(36,0)
	await step(4)
	var x:=player.position.x
	old_hits=hits.size()
	await full_chain()
	check(player.position.x-x<8,"wall limits authored advance",{"px":player.position.x-x})
	check(hits.size()==old_hits,"solid wall blocks contact volume")
	check(samples.any(func(s):return s.case.begins_with("WALL COLLISION") and s.index>=0 and s.support=="braced"),"wall uses braced support throughout attack")
	await observe(16)
	wall.collision_layer=256 # existing solid-prop layer, same physical fixture
	await begin("SOLID PROP / BRACED SUPPORT",1,false)
	scene.enemy.position=player.position+Vector2(36,0)
	await step(4)
	old_hits=hits.size()
	await full_chain()
	check(hits.size()==old_hits,"solid prop also blocks contact volume")
	check(samples.any(func(s):return s.case.begins_with("SOLID PROP") and s.index>=0 and s.support=="braced"),"solid prop uses braced support")
	await observe(12)
	wall.queue_free()
	check(samples.filter(func(s):return s.index>=0).all(func(s):return s.floor),"all attack playback stays grounded")
	check(samples.filter(func(s):return s.index>=0).all(func(s):return s.anchor_error<=.708),"flame anchor follows evaluated pose within rounding")
	check(hits.all(func(e):return e.attack_age>=e.contact_time-.000001),"accepted hit never precedes visible contact")
	release_all()
	Engine.time_scale=1
	var failures:=checks.filter(func(c):return not c.pass).size()
	FileAccess.open(OUT+"GAMEPLAY_VALIDATION.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"samples":samples,"stages":stages,"hits":hits,"events":combo.events,"captured":frame_index if capture else 0},"\t"))
	print("M1_REBUILD: %d checks / %d failures / %d frames"%[checks.size(),failures,frame_index])
	quit(1 if failures else 0)
