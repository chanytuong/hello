extends SceneTree
const OUT := "res://artifacts/m1_full_combo/"
var scene: Node2D
var player: NLBPlayer
var combo: NLBM1Combo
var checks: Array[Dictionary]=[]
var samples: Array[Dictionary]=[]
var case_name := ""
var capture := false
var frame_index := 0
var stages: Array[Dictionary]=[]
var hit_events: Array[Dictionary]=[]

func _init() -> void:call_deferred("run")

func check(ok: bool,label: String,data: Dictionary={}) -> void:
	checks.append({"pass":ok,"label":label,"data":data})
	print("%s %s %s"%["PASS" if ok else "FAIL",label,data])

func step(n: int) -> void:
	for i in n:
		await physics_frame
		await process_frame

func observe(n: int) -> void:
	for i in n:
		await step(1)
		var vis:=player.movement_visual
		samples.append({"frame":frame_index,"case":case_name,"state":combo.state,"age":combo.age,"active":combo.active_window,"id":combo.attack_instance_id,"cel":combo.current.get("sample",-1),"x":player.position.x,"y":player.position.y,"vx":player.velocity.x,"vy":player.velocity.y,"floor":player.is_on_floor(),"roll":player.roll_remaining,"cooldown":player.roll_cooldown_remaining,"pending":combo.pending,"hp":scene.enemy.health.hp if is_instance_valid(scene.enemy) else 0,"hits":scene.hit_count,"anchor_error":vis.flame.position.distance_to(vis.neck_local)})
		if capture:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT+"frames/%04d.png"%frame_index)
		frame_index+=1

func release_all() -> void:
	for a in ["move_left","move_right","jump","dash","attack","swap_select","swap_activate","swap_self"]:Input.action_release(a)

func begin(label: String,dir: int=1,only_animation: bool=false,moving: bool=false) -> void:
	release_all()
	scene.reset(dir,only_animation)
	case_name=label+(" / RIGHT" if dir>0 else " / LEFT")
	scene.case_label=case_name
	stages.append({"label":case_name,"start":frame_index,"animation_only":only_animation})
	await step(5)
	if moving:
		scene.enemy.position=player.position+Vector2(dir*82,0)
		Input.action_press("move_right" if dir>0 else "move_left")
		await observe(12)

func click() -> void:
	Input.action_press("attack")
	await observe(1)
	Input.action_release("attack")

func full_chain() -> void:
	await click()
	await observe(3)
	await click() # one deliberately buffered follow-up
	while combo.index==0:await observe(1)
	await observe(3)
	await click()
	while combo.busy():await observe(1)

func input_action(action: String,pressed: bool) -> void:
	var event:=InputEventAction.new()
	event.action=action
	event.pressed=pressed
	Input.parse_input_event(event)

func mouse(pressed: bool,at: Vector2,button: MouseButton=MOUSE_BUTTON_LEFT) -> void:
	var event:=InputEventMouseButton.new()
	event.button_index=button
	event.position=at
	event.pressed=pressed
	Input.parse_input_event(event)

func start_n(index: int) -> void:
	await click()
	for i in index:
		await observe(3)
		await click()
		while combo.index==i:await observe(1)

func run() -> void:
	root.unfocusable=true
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i(1280,720)
	capture="--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	DirAccess.make_dir_recursive_absolute(OUT+"frames")
	scene=load("res://labs/m1_full_combo.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	player=scene.player
	combo=scene.combo
	combo.hit_confirmed.connect(func(event: Dictionary):
		var row:=event.duplicate()
		row.capture_frame=frame_index
		row.case=case_name
		hit_events.append(row))
	await step(8)
	for dir in [1,-1]:
		await begin("ANIMATION ONLY / IDLE > THREE HITS > IDLE",dir,true)
		await observe(24)
		check(absf(player.position.x-(260 if dir>0 else 650))<.01,"animation-only idle has no hidden-opponent contact motion")
		var before:=combo.accepted
		await full_chain()
		check(combo.accepted==before+3,"three fresh clicks create three strikes / "+str(dir))
		check(scene.hit_count==0,"animation-only has no damage/effects")
		await observe(25)
		await full_chain()
		await observe(30)
	for dir in [1,-1]:
		await begin("GAMEPLAY / RUN IN > STOP > THREE HITS > RUN OUT",dir,false,true)
		var begin_events:=hit_events.size()
		var x:=player.position.x
		await click()
		check(is_zero_approx(player.velocity.x) and is_equal_approx(player.position.x,x),"same-update stop without displacement / "+str(dir))
		await observe(3)
		await click()
		while combo.index==0:await observe(1)
		await observe(3)
		await click()
		while combo.index==1:await observe(1)
		await observe(10)
		# Resume away from the solid opponent; do not imply running through bodies.
		Input.action_release("move_right" if dir>0 else "move_left")
		Input.action_press("move_left" if dir>0 else "move_right")
		while combo.busy():await observe(1)
		var hits:=hit_events.slice(begin_events)
		check(hits.size()==3,"three accepted enemy hits / "+str(dir),{"hits":hits})
		check(scene.enemy.health.hp==8,"HP12 > 11 > 10 > 8 / "+str(dir))
		check(hits.size()==3 and hits[0].strike==1 and hits[1].strike==2 and hits[2].strike==3,"ordered contacts")
		check(hits.size()==3 and hits[0].attack_instance_id!=hits[1].attack_instance_id and hits[1].attack_instance_id!=hits[2].attack_instance_id,"unique strike instances")
		check(player.velocity.x*(-dir)>0,"latest held RUN resumes on recovery update")
		await observe(25)
		Input.action_release("move_left" if dir>0 else "move_right")
		await observe(15)
		for kind in ["dash","jump"]:
			await begin("GAMEPLAY / "+("STRIKE 1 > ROLL" if kind=="dash" else "STRIKE 2 > JUMP"),dir,false,false)
			await observe(12)
			await start_n(0 if kind=="dash" else 1)
			await observe(4)
			check(is_instance_valid(scene.enemy) and scene.enemy.health.hp<12,"real opponent remains present before defensive interrupt / "+kind)
			await click() # queue next, then clear through defensive intent
			Input.action_press(kind)
			await observe(1)
			Input.action_release(kind)
			check(not combo.busy() and combo.pending==0,"defence clears pending chain / "+kind)
			check(player.roll_remaining>0 if kind=="dash" else player.velocity.y<0,"defence executes immediately / "+kind)
			await observe(40)
	# One held click and one released click each produce exactly one strike.
	for held in [false,true]:
		await begin("ONE HELD CLICK" if held else "ONE CLICK",1,true)
		var before:=combo.accepted
		Input.action_press("attack")
		await observe(1)
		if not held:Input.action_release("attack")
		await observe(45)
		check(combo.accepted==before+1 and not combo.busy(),"held/released single click does not auto-chain")
		Input.action_release("attack")
	# All strike phases, both defensive inputs. No queued punches survive.
	for strike in 3:
		for phase in [["anticipation",1],["contact",5 if strike==2 else 3],["recovery",10 if strike==2 else 7]]:
			for action in ["dash","jump"]:
				await begin("CANCEL M1-%d %s %s"%[strike+1,phase[0],action],1,true)
				await start_n(strike)
				await observe(phase[1])
				var accepts:=combo.accepted
				Input.action_press(action)
				await observe(1)
				Input.action_release(action)
				check(not combo.busy() and not combo.sprite.visible and combo.pending==0,"cancel phase / "+case_name)
				check(player.roll_remaining>0 if action=="dash" else player.velocity.y<0,"same-update action / "+case_name)
				await observe(18)
				check(combo.accepted==accepts,"no stale attack / "+case_name)
	# Shared Health dedup across two overlapping HurtBoxes.
	await begin("MULTI-HURTBOX DEDUP",1,false)
	var duplicate: Node=scene.enemy.get_node("HurtBox").duplicate()
	scene.enemy.add_child(duplicate)
	await step(2)
	var hits_before:=hit_events.size()
	await click()
	await observe(13)
	check(hit_events.size()==hits_before+1 and scene.enemy.health.hp==11,"two HurtBoxes sharing Health receive one strike")
	duplicate.queue_free()
	await step(2)
	# Cooldown cannot be bypassed by a blocked defensive roll during a punch.
	await begin("ROLL COOLDOWN PRESERVED",1,true)
	Input.action_press("dash")
	await observe(1)
	Input.action_release("dash")
	Input.action_press("move_right")
	await observe(1)
	Input.action_release("move_right")
	await observe(1)
	check(player.roll_cooldown_remaining>0,"cancelled roll arms existing cooldown")
	await click()
	var old_id:=combo.attack_instance_id
	Input.action_press("dash")
	await observe(1)
	Input.action_release("dash")
	check(combo.busy() and combo.attack_instance_id==old_id and player.roll_remaining==0,"unavailable roll neither cancels attack nor bypasses cooldown")
	await observe(35)
	check(not combo.busy() and player.roll_remaining==0,"no stale roll or M1 after cooldown")
	# Actual E/LMB/Q and RMB front-end events, with all attack input suppressed.
	await begin("MOTION SWAP / E THEN LMB TARGET / Q SELF",1,false)
	await click()
	await observe(2)
	await click() # buffered second strike
	var before_select:=combo.accepted
	input_action("swap_activate",true)
	await observe(1)
	input_action("swap_activate",false)
	check(scene.controller.is_selecting() and not combo.busy() and combo.pending==0,"E interrupts and clears combo")
	mouse(true,scene.enemy.swap_target.anchor_world())
	await observe(1)
	mouse(false,scene.enemy.swap_target.anchor_world())
	check(scene.controller.target_a==scene.enemy.swap_target and combo.accepted==before_select,"LMB selects A without attacking",{"phase":scene.controller.phase,"feedback":scene.controller.last_feedback,"a":str(scene.controller.target_a),"expected":str(scene.enemy.swap_target),"accepted":combo.accepted,"before":before_select})
	input_action("swap_self",true)
	await observe(1)
	input_action("swap_self",false)
	check(not scene.controller.is_selecting() and not scene.controller.last_exchange.is_empty(),"Q completes existing Motion Swap exchange")
	await observe(20)
	check(not combo.busy() and combo.accepted==before_select,"no stale punch after completed exchange")
	await begin("MOTION SWAP / RMB SELF",1,false)
	input_action("swap_activate",true)
	await observe(1)
	input_action("swap_activate",false)
	mouse(true,player.position,MOUSE_BUTTON_RIGHT)
	await observe(1)
	mouse(false,player.position,MOUSE_BUTTON_RIGHT)
	check(scene.controller.target_a==player.swap_target and not combo.busy(),"RMB selects Iven without melee")
	scene.controller.cancel_selection()
	await observe(15)
	# Press too early expires, final-strike presses never queue another combo.
	await begin("BUFFER EXPIRY / NO FINAL QUEUE",1,true)
	await click()
	await click()
	var before_expire:=combo.accepted
	await observe(25)
	check(combo.accepted==before_expire and not combo.busy(),"early follow-up expires instead of surprising delayed strike")
	await full_chain()
	await observe(2)
	check(not combo.busy(),"full chain ends without forced follow-up")
	check(samples.all(func(s):return not s.active or s.state!=NLBM1Combo.State.READY),"no active frames in READY")
	check(samples.filter(func(s):return s.state!=0).all(func(s):return s.floor and absf(s.vx)<.001),"all attack samples grounded and stationary")
	check(samples.filter(func(s):return s.state!=0).all(func(s):return s.anchor_error<=.708),"flame root follows pose within pixel rounding")
	check(hit_events.all(func(e):return e.attack_age>=e.contact_time-.000001),"accepted damage never precedes contact")
	release_all()
	Engine.time_scale=1
	var failures:=checks.filter(func(c):return not c.pass).size()
	FileAccess.open(OUT+"GAMEPLAY_VALIDATION.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"samples":samples,"hits":hit_events,"events":combo.events,"stages":stages,"captured":frame_index if capture else 0},"\t"))
	print("FULL_M1: %d checks / %d failures / %d frames"%[checks.size(),failures,frame_index])
	quit(1 if failures else 0)
