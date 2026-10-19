extends SceneTree
## Fixed60Hz input replay in the isolated native/nearest4x review scene.
const OUT := "res://artifacts/dodge_roll_v2/demo/"
var scene: Node2D
var player: NLBPlayer
var rows: Array[Dictionary] = []
var events: Array[Dictionary] = []
var case_name := ""
var capture := false

func _init() -> void:
	call_deferred("run")

func observe(n: int) -> void:
	for i in n:
		await physics_frame
		await process_frame
		var vis := player.movement_visual
		rows.append({"index":rows.size(),"case":case_name,"position":[player.position.x,player.position.y],"velocity":[player.velocity.x,player.velocity.y],"roll":player.roll_remaining,"cooldown":player.roll_cooldown_remaining,"ready":player.can_movement_roll(),"clip":str(vis.body.animation),"cel":vis.body.frame,"neck":[vis.neck_local.x,vis.neck_local.y],"flame_angle":vis.flame.rotation,"flame_limited":vis.flame.angle_limited,"hp":player.health.hp,"m1_busy":scene.punch.busy()})
		if capture:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT+"frames/%04d.png"%(rows.size()-1))

func begin(label: String, at: Vector2 = Vector2(200,559)) -> void:
	for a in ["move_left","move_right","dash","jump","attack","swap_select"]:Input.action_release(a)
	scene.punch.reset()
	player.reset_movement(at)
	player.facing=1
	case_name=label
	scene.case_label="ROLL V2 / "+label
	events.append({"case":label,"index":rows.size()})
	await observe(6)

func roll() -> void:
	Input.action_press("dash")
	await observe(1)
	Input.action_release("dash")

func run() -> void:
	root.unfocusable=true
	root.size=Vector2i(1280,720)
	capture="--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	DirAccess.make_dir_recursive_absolute(OUT+"frames")
	scene=load("res://labs/dodge_roll_v2_preview.tscn").instantiate()
	root.add_child(scene)
	player=scene.player
	await begin("RUN > ROLL > RUN")
	Input.action_press("move_right")
	await observe(12)
	await roll()
	await observe(32)
	await begin("ROLL > REVERSE / same-update control")
	await roll()
	await observe(7)
	Input.action_press("move_left")
	await observe(20)
	await begin("ROLL > JUMP / no recovery lock")
	await roll()
	await observe(8)
	Input.action_press("jump")
	await observe(6)
	Input.action_release("jump")
	await observe(25)
	await begin("JUMP > AIR ROLL > AIR CONTROL")
	Input.action_press("jump")
	await observe(7)
	await roll()
	await observe(8)
	Input.action_press("move_left")
	Input.action_release("jump")
	await observe(25)
	await begin("SPAM / fresh press every two ticks / 0.35s after end")
	for i in 150:
		if i%2==0:Input.action_press("dash")
		else:Input.action_release("dash")
		await observe(1)
	await begin("2px WALL / solid capsule unchanged",Vector2(745,559))
	await roll()
	await observe(28)
	for age in [2,8,15]:
		await begin("CANCEL at tick%d / cooldown continues"%age)
		await roll()
		await observe(age-1)
		Input.action_press("move_right")
		await observe(5)
		await roll()
		await observe(24)
	await begin("LEFT RUN > ROLL > RUN",Vector2(600,559))
	Input.action_press("move_left")
	await observe(12)
	await roll()
	await observe(30)
	await begin("Existing M1-A V2 priority / roll wins; no queued punch")
	await roll()
	await observe(6)
	Input.action_press("attack")
	await observe(1)
	Input.action_release("attack")
	await observe(15)
	Input.action_press("attack")
	await observe(1)
	Input.action_release("attack")
	await observe(20)
	var assertions: Array[Dictionary] = []
	assertions.append({"test":"all demonstrated movement bounded","pass":rows.all(func(r):return absf(r.velocity[0])<=player.roll_speed+.01)})
	assertions.append({"test":"no demonstration HP loss","pass":rows.all(func(r):return r.hp==5)})
	var m1_rows := rows.filter(func(r):return r.case.begins_with("Existing M1"))
	assertions.append({"test":"unchanged M1 driver discards attacks during active roll","pass":m1_rows.all(func(r):return not(r.roll>0 and r.m1_busy))})
	assertions.append({"test":"M1 accepts after roll while cooldown remains","pass":m1_rows.any(func(r):return r.m1_busy and r.cooldown>0)})
	var failures := assertions.filter(func(r):return not r.pass).size()
	FileAccess.open(OUT+"trace.json",FileAccess.WRITE).store_string(JSON.stringify({"fps":60,"samples":rows,"events":events,"assertions":assertions,"failures":failures,"captured_frames":rows.size() if capture else 0},"\t"))
	print("DODGE_DEMO: %d frames"%rows.size())
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
