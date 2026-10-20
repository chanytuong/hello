extends SceneTree
const OUT := "res://artifacts/m1_natural_combo/"
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
		samples.append({"frame":frame_index,"case":label,"index":combo.index,"age":combo.age,"active":combo.active_window,"sample":combo.current.get("sample",-1),"x":player.position.x,"y":player.position.y,"vx":player.velocity.x,"floor":player.is_on_floor(),"pending":combo.pending,"stop":combo.stop_left,"support":combo.current.get("support","free"),"branch_closed":combo.branch_closed,"restart_pending":combo.restart_pending,"anchor_error":player.movement_visual.flame.position.distance_to(player.movement_visual.neck_local)})
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
	scene=load("res://labs/m1_natural_combo.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	player=scene.player
	combo=scene.combo
	combo.hit_confirmed.connect(func(e: Dictionary):
		var row:=e.duplicate()
		row.case=label;row.capture_frame=frame_index;hits.append(row))
	await step(8)
	# Every stop length from standing and running, in both actual facings.
	for n in [1,2,3]:
		for dir in [1,-1]:
			for running in [false,true]:
				await begin("VIDEO%d / %d HIT%s > COMPLETE RECOVERY > %s"%[n,n,"S" if n>1 else "","RUN" if running else "IDLE"],dir)
				await observe(15)
				var action: String="move_right" if dir>0 else "move_left"
				if running:
					Input.action_press(action)
					await observe(14)
				var before:=combo.accepted
				var start_x:=player.position.x
				await start_n(n-1)
				await finish()
				var expected: float=[5.0,7.0,14.0][n-1]
				check(combo.accepted==before+n,"exactly %d fresh presses, %d strikes"%[n,n])
				if not running:check(absf((player.position.x-start_x)*dir-expected)<.05,"measured travel for %d-hit stop"%n,{"actual":(player.position.x-start_x)*dir,"expected":expected})
				await observe(14)
				check(player.velocity.x*dir>0 if running else absf(player.velocity.x)<.01,"complete recovery returns intended locomotion")
				Input.action_release(action)
				await observe(10)
	# Real diagnostic bodies, same animation at the intended standing target height.
	for height in [60,64]:
		for dir in [1,-1]:
			await begin("VIDEO5 / %d PX STANDING DUMMY / CONTACT AND HURTBOX"%height,dir,false)
			scene.enemy.position=player.position+Vector2(dir*31,0)
			if height==64:
				scene.enemy.get_node("CollisionShape2D").shape.height=64
				scene.enemy.get_node("CollisionShape2D").position.y=-32
				scene.enemy.body_vis.offset_top=-64
				scene.enemy.get_node("HurtBox").position.y=-44
			combo.debug_hitbox=true
			await step(6)
			await observe(16)
			var before_hits:=hits.size()
			await full_chain()
			var local_hits:=hits.slice(before_hits)
			check(local_hits.size()==3 and local_hits[0].strike==1 and local_hits[1].strike==2 and local_hits[2].strike==3,"three real upper-body contacts / %d px / %d"%[height,dir],{"hits":local_hits})
			check(local_hits.all(func(e):return e.damage==e.hp_before-e.hp_after),"damage feedback uses accepted HP deltas")
			await observe(20)
			combo.debug_hitbox=false
	# All stages and all phases, with both directions and both defensive inputs.
	for dir in [1,-1]:
		for strike in 3:
			for phase in ["preparation","contact","recovery"]:
				for action in ["dash","jump"]:
					await begin("VIDEO4 / STRIKE %d %s > %s"%[strike+1,phase,action],dir)
					await start_n(strike)
					var target_age: float=.016 if phase=="preparation" else float(combo._config().startup if phase=="contact" else combo._config().active_end)+.001
					while combo.age<target_age:await observe(1)
					var count:=combo.accepted
					Input.action_press(action)
					await observe(1)
					Input.action_release(action)
					check(not combo.busy() and combo.pending==0 and combo.restart_pending==0 and not combo.sprite.visible,"same-update defensive cancellation / "+label)
					check(player.roll_remaining>0 if action=="dash" else player.velocity.y<0,"defence executes / "+label)
					await observe(12)
					check(combo.accepted==count,"no stale follow-up after cancellation")
	await begin("VIDEO4 / STOP TAIL > JUMP")
	await click();await observe(12)
	check(combo.branch_closed,"single attack selected complete stop continuation")
	Input.action_press("jump");await observe(1);Input.action_release("jump")
	check(not combo.busy() and player.velocity.y<0,"authored stop continuation remains interruptible")
	await observe(16)
	await begin("VIDEO4 / RECOVERY FACING REVERSAL")
	await click();await observe(7)
	Input.action_press("move_left");await observe(1)
	check(not combo.busy() and player.velocity.x<0,"reversal leaves recoil without flipping contact pose")
	await observe(18)
	for dir in [1,-1]:
		await begin("VIDEO4 / WALL ADJACENT BRACED COMBO",dir)
		var wall:=StaticBody2D.new()
		var shape:=CollisionShape2D.new();var box:=RectangleShape2D.new();box.size=Vector2(8,120);shape.shape=box;wall.add_child(shape)
		wall.position=player.position+Vector2(dir*24,-45);scene.add_child(wall)
		var rect:=ColorRect.new();rect.position=Vector2(-4,-60);rect.size=Vector2(8,120);rect.color=Color(.4,.5,.55);wall.add_child(rect)
		await step(4)
		var x:=player.position.x
		await full_chain()
		check(absf(player.position.x-x)<.1,"wall chooses planted support with no duplicate advance")
		check(samples.any(func(r):return r.case==label and r.support=="braced"),"braced drawings used at wall")
		await observe(18);wall.queue_free();await step(3)
	# Input contracts not dependent on a subjective visual score.
	await begin("CHECK / ONE HELD CLICK")
	var count:=combo.accepted
	Input.action_press("attack");await observe(45);Input.action_release("attack")
	check(combo.accepted==count+1 and not combo.busy(),"held click is one complete strike")
	await begin("CHECK / FAST DELIBERATE DOUBLE TAP")
	count=combo.accepted
	await click();await click();await observe(40)
	check(combo.accepted==count+2 and not combo.busy(),"two fast fresh clicks produce two complete strikes")
	await begin("CHECK / QUEUED FOLLOWUP CANCELLED")
	await click();await observe(2);await click();count=combo.accepted
	check(combo.pending>0,"fresh follow-up is buffered")
	Input.action_press("jump");await observe(1);Input.action_release("jump");await observe(25)
	check(combo.accepted==count and combo.pending==0 and combo.restart_pending==0,"defence discards the deliberately buffered follow-up")
	await begin("CHECK / LATE CLICK CANNOT REWIND STOP BRANCH")
	await click();await observe(12)
	check(combo.branch_closed and combo.index==0,"stop decision is committed")
	await click()
	check(combo.index==0 and combo.branch_closed,"late press does not teleport into hook")
	await observe(5)
	check(combo.index==0 and not combo.branch_closed,"bounded late press starts a fresh opener after full recovery")
	await finish()
	await begin("CHECK / DUPLICATE HURTBOX",1,false)
	scene.enemy.position=player.position+Vector2(30,0)
	var duplicate: Node=scene.enemy.get_node("HurtBox").duplicate();scene.enemy.add_child(duplicate);await step(5)
	var old_hits:=hits.size();await click();await finish()
	check(hits.size()==old_hits+1 and scene.enemy.health.hp==29,"one victim guard spans duplicate hurtboxes")
	duplicate.queue_free()
	await begin("CHECK / ACCEPTED HITSTOP DEFENCE",1,false)
	scene.enemy.position=player.position+Vector2(30,0);await step(5);await click()
	var guard:=0
	while combo.busy() and combo.stop_left<=0 and guard<20:await observe(1);guard+=1
	check(combo.stop_left>0,"real hit enables local hitstop")
	Input.action_press("jump");await observe(1);Input.action_release("jump")
	check(not combo.busy() and player.velocity.y<0,"local hitstop cannot delay valid jump")
	await observe(15)
	await begin("CHECK / ACCEPTED HITSTOP ROLL",1,false)
	scene.enemy.position=player.position+Vector2(30,0);await step(5);await click()
	guard=0
	while combo.busy() and combo.stop_left<=0 and guard<20:await observe(1);guard+=1
	check(combo.stop_left>0,"real hit enables roll-cancel test")
	Input.action_press("dash");await observe(1);Input.action_release("dash")
	check(not combo.busy() and player.roll_remaining>0,"local hitstop cannot delay available roll")
	await observe(20)
	await begin("CHECK / MOTION SWAP E LMB Q",1,false)
	await click();input_event("swap_activate",true);await observe(1);input_event("swap_activate",false)
	var selected_count:=combo.accepted
	check(scene.controller.is_selecting() and not combo.busy(),"E suppresses melee")
	mouse(true,scene.enemy.swap_target.anchor_world());await observe(1);mouse(false,scene.enemy.swap_target.anchor_world())
	check(scene.controller.target_a==scene.enemy.swap_target and combo.accepted==selected_count,"selection click cannot trigger M1")
	input_event("swap_self",true);await observe(1);input_event("swap_self",false)
	check(not scene.controller.is_selecting() and not scene.controller.last_exchange.is_empty(),"Q exchange remains functional")
	await observe(12)
	await begin("CHECK / MOTION SWAP RMB SELF",1,false)
	input_event("swap_activate",true);await observe(1);input_event("swap_activate",false)
	mouse(true,player.position,MOUSE_BUTTON_RIGHT);await observe(1);mouse(false,player.position,MOUSE_BUTTON_RIGHT)
	check(scene.controller.target_a==player.swap_target and not combo.busy(),"RMB self selection preserves input ownership")
	scene.controller.cancel_selection()
	await begin("VIDEO4 / WALL OCCLUDES REAL CONTACT",1,false)
	scene.enemy.position=player.position+Vector2(31,0)
	var barrier:=StaticBody2D.new();var barrier_shape:=CollisionShape2D.new();var barrier_rect:=RectangleShape2D.new()
	barrier_rect.size=Vector2(2,120);barrier_shape.shape=barrier_rect;barrier.add_child(barrier_shape);barrier.position=player.position+Vector2(19.5,-45);scene.add_child(barrier)
	var barrier_vis:=ColorRect.new();barrier_vis.position=Vector2(-1,-60);barrier_vis.size=Vector2(2,120);barrier_vis.color=Color(.4,.5,.55);barrier.add_child(barrier_vis)
	await step(5)
	var occluded_before:=hits.size();await full_chain()
	check(hits.size()==occluded_before and scene.enemy.health.hp==30,"solid barrier blocks actual damage, not only actor movement")
	await observe(16);barrier.queue_free();await step(3)
	for rate in [30,60,120]:
		Engine.physics_ticks_per_second=rate
		await begin("CHECK / PHYSICS %d HZ"%rate)
		var x:=player.position.x;await click();await finish()
		check(absf(player.position.x-x-5)<.05,"single travel through actual solver / %d Hz"%rate,{"px":player.position.x-x})
	Engine.physics_ticks_per_second=60
	check(samples.all(func(r):return r.index<0 or r.floor),"all active attack samples remain grounded")
	check(samples.all(func(r):return r.index<0 or r.anchor_error<.71),"flame follows evaluated pose within pixel rounding")
	check(hits.all(func(h):return h.attack_age+.000001>=h.contact_time),"accepted damage never precedes displayed contact")
	release_all()
	var failures:=checks.filter(func(r):return not r.pass).size()
	FileAccess.open(OUT+"GAMEPLAY_VALIDATION.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"samples":samples,"stages":stages,"hits":hits,"events":combo.events,"captured":frame_index if capture else 0},"\t"))
	print("M1_NATURAL: %d checks / %d failures / %d frames"%[checks.size(),failures,frame_index])
	quit(1 if failures else 0)
