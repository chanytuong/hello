extends Node2D
var player: NLBPlayer
var combo: NLBM1Combo
var enemy: LabPatrolEnemy
var controller: NLBMotionSwapController
var animation_only := false
var case_label := "Crowbar M1 | Sweep > Reverse > Drive | Diagnostic 60px dummy"
var review := Node2D.new()
var review_body := Sprite2D.new()
var review_neck := Node2D.new()
var review_flame := Sprite2D.new()
var review_enemy := ColorRect.new()
var contact_debug := Node2D.new()
var title := Label.new()
var info := Label.new()
var hp_label := Label.new()
var hit_count := 0
var last_hit := ""

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("222a30"))
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var ground := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(3000,80)
	shape.shape=box
	ground.position=Vector2(640,600)
	ground.add_child(shape)
	add_child(ground)
	player=preload("res://scenes/player.tscn").instantiate()
	player.movement_preview=true
	player.m1_crowbar_enabled=true
	player.position=Vector2(240,559)
	add_child(player)
	player.enable_motion_swap()
	combo=player.movement_attack_preview
	combo.hit_confirmed.connect(func(event: Dictionary):
		hit_count+=1
		last_hit="M1-%d | HP %d > %d"%[event.strike,event.hp_before,event.hp_after])
	_spawn_enemy()
	controller=NLBMotionSwapController.new()
	controller.name="Controller"
	add_child(controller)
	_setup_review()

func _spawn_enemy(at: Vector2=Vector2(420,559)) -> void:
	enemy=preload("res://labs/enemies/patrol.tscn").instantiate()
	enemy.name="Diagnostic_60px_Dummy"
	enemy.hp=30
	enemy.speed=0
	enemy.position=at
	enemy.scale=Vector2.ONE
	# Only this diagnostic instance changes. Existing enemy scenes/resources stay exact.
	var capsule:=CapsuleShape2D.new()
	capsule.radius=10
	capsule.height=60
	enemy.get_node("CollisionShape2D").shape=capsule
	enemy.get_node("CollisionShape2D").position=Vector2(0,-30)
	var chest:=RectangleShape2D.new()
	chest.size=Vector2(20,22)
	enemy.get_node("HurtBox/Shape").shape=chest
	enemy.get_node("HurtBox").position=Vector2(0,-42)
	var visual:=enemy.get_node("Body") as ColorRect
	visual.offset_left=-10;visual.offset_right=10
	visual.offset_top=-60;visual.offset_bottom=0
	add_child(enemy)
	enemy.configure_patrol(0,1280)

func _setup_review() -> void:
	add_child(review)
	review.position=Vector2(1000,555)
	review.scale=Vector2(4,4)
	review_body.centered=false
	var review_pivot: Vector2 = combo.get("pivot")
	review_body.offset=-review_pivot
	review.add_child(review_body)
	review.add_child(review_neck)
	review_flame.centered=false
	review_flame.offset=Vector2(-18,-31)
	review_flame.region_enabled=true
	review_neck.add_child(review_flame)
	review_enemy.offset_left=-10
	review_enemy.offset_right=10
	review_enemy.offset_top=-60
	review_enemy.offset_bottom=0
	review_enemy.mouse_filter=Control.MOUSE_FILTER_IGNORE
	review.add_child(review_enemy)
	for label in [title,info,hp_label]:
		label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_color",Color("e6ebe8"))
		add_child(label)
	# Draw contact evidence after the background, target and sprite children.
	contact_debug.z_index=10
	contact_debug.draw.connect(draw_target_bounds)
	add_child(contact_debug)
	title.position=Vector2(24,20)
	title.add_theme_font_size_override("font_size",24)
	info.position=Vector2(24,625)
	info.add_theme_font_size_override("font_size",17)
	process_physics_priority=20

func reset(direction: int, only_animation: bool=false) -> void:
	controller.reset_state()
	animation_only=only_animation
	player.reset_movement(Vector2(260 if direction>0 else 650,559))
	player.facing=direction
	combo.damage_enabled=not only_animation
	combo.feedback_enabled=not only_animation
	combo.hitstop_enabled=not only_animation
	# A fresh existing-type body avoids teleport-derived contact velocity during
	# review retries. No production collision or impact thresholds are changed.
	if is_instance_valid(enemy):
		remove_child(enemy)
		enemy.queue_free()
	_spawn_enemy(player.position+Vector2(direction*48,0))
	enemy.visible=not only_animation
	enemy.set_physics_process(not only_animation)
	(enemy.get_node("HurtBox/Shape") as CollisionShape2D).set_deferred("disabled",only_animation)
	# Keep ground collision enabled even when the opponent is hidden.
	# CharacterBody contact velocity can include a retry teleport for one update.
	# Warm the two bodies against the floor before restoring their mutual solid
	# contact. HurtBox/damage and player input are never delayed by this fixture.
	enemy.collision_layer=0
	enemy.collision_mask=1
	_restore_retry_contacts(enemy,not only_animation)
	hit_count=0
	last_hit=""

func _restore_retry_contacts(body: LabPatrolEnemy,enabled: bool) -> void:
	for i in 3:await get_tree().physics_frame
	if is_instance_valid(body) and body==enemy and enabled:
		body.collision_mask=775
		body.collision_layer=4

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_R:reset(player.facing,animation_only)
		if event.physical_keycode==KEY_V:reset(player.facing,not animation_only)
		if event.physical_keycode==KEY_H:combo.debug_hitbox=not combo.debug_hitbox

func _physics_process(_dt: float) -> void:
	var vis:=player.movement_visual
	if combo.sprite.visible:
		review_body.texture=combo.sprite.texture
		review_body.region_enabled=true
		review_body.region_rect=combo.sprite.region_rect
	else:
		review_body.texture=vis.body.sprite_frames.get_frame_texture(vis.body.animation,vis.body.frame)
		review_body.region_enabled=false
	review_neck.position=vis.flame.position
	review_neck.rotation=vis.flame.rotation
	review_flame.texture=vis.flame.sprite.texture
	review_flame.material=vis.flame.sprite.material
	review_flame.region_rect=vis.flame.sprite.region_rect
	title.text=case_label
	info.text="A/D move | LMB / J strike (1 / 2 / 3 fresh presses) | Space jump | Shift roll | E target / Q,RMB self | V no-enemy view | R retry\n%s | age %.3f | active %s | pending %.3f | hits %d | %s"%[NLBM1Combo.State.keys()[combo.state],combo.age,combo.active_window,combo.pending,hit_count,last_hit]
	if not is_instance_valid(enemy):
		review_enemy.hide()
		hp_label.hide()
		return
	review_enemy.size=enemy.body_vis.size
	review_enemy.position=enemy.body_vis.global_position-player.global_position
	review_enemy.color=enemy.body_vis.color
	review_enemy.scale=enemy.scale
	review_enemy.visible=enemy.visible
	hp_label.position=enemy.position+Vector2(-32,-68)
	hp_label.text="%d / %d"%[enemy.health.hp,enemy.health.max_hp]
	hp_label.visible=enemy.visible
	info.text+=" | crowbar "+str(combo.get("weapon_visible"))
	queue_redraw()
	contact_debug.queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(820,175,440,420),Color("1a2229"))
	draw_line(Vector2(830,556),Vector2(1250,556),Color("596b6d"))
	draw_line(Vector2(16,560),Vector2(790,560),Color("929d95"))
	for x in range(20,790,10):draw_line(Vector2(x,561),Vector2(x,566 if x%50==0 else 563),Color("596b6d"))


func draw_target_bounds() -> void:
	if not is_instance_valid(enemy) or not enemy.visible:return
	var volume:=enemy.get_node("HurtBox/Shape") as CollisionShape2D
	var chest: Rect2=volume.shape.get_rect()
	chest.position+=volume.global_position
	contact_debug.draw_rect(chest,Color(.8,1,.5,.8),false,1)
	var height: float=enemy.body_vis.size.y
	contact_debug.draw_line(enemy.position+Vector2(-15,-height),enemy.position+Vector2(15,-height),Color(.8,1,.5))
	var inspection: Vector2=review.position+(chest.position-player.position)*4
	contact_debug.draw_rect(Rect2(inspection,chest.size*4),Color(.8,1,.5,.8),false,1)
	if combo.debug_hitbox and combo.active_window:
		for segment in combo.weapon_segments():
			var a: Vector2=segment[0]
			var b: Vector2=segment[1]
			var radius: float=float(combo._config().weapon_radius_px)
			for origin in [player.position,review.position]:
				var factor:=1.0 if origin==player.position else 4.0
				contact_debug.draw_line(origin+a*factor,origin+b*factor,Color(1,.5,.2,.9),radius*2*factor)
				contact_debug.draw_circle(origin+a*factor,radius*factor,Color(1,.65,.2),false,1)
				contact_debug.draw_circle(origin+b*factor,radius*factor,Color(1,.65,.2),false,1)
