extends Node2D
var player: NLBPlayer
var punch: Node
var review := Node2D.new()
var review_body := Sprite2D.new()
var review_neck := Node2D.new()
var review_flame := Sprite2D.new()
var title := Label.new()
var detail := Label.new()
var case_label := "M1-A V2 / planted Boxing left straight"

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("222a30"))
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(3000,80)
	shape.shape = box
	floor_body.position = Vector2(640,600)
	floor_body.add_child(shape)
	add_child(floor_body)
	player = preload("res://scenes/player.tscn").instantiate()
	player.movement_preview = true
	player.position = Vector2(240,559)
	add_child(player)
	punch = preload("res://scripts/previews/m1a_v2_driver.gd").new()
	player.add_child(punch)
	add_child(review)
	review.position = Vector2(1035,555)
	review.scale = Vector2(4,4)
	review_body.centered = false
	review_body.offset = -punch.PIVOT
	review.add_child(review_body)
	review.add_child(review_neck)
	review_flame.centered = false
	review_flame.offset = Vector2(-18,-31)
	review_flame.region_enabled = true
	review_neck.add_child(review_flame)
	for l in [title,detail]:
		l.add_theme_color_override("font_color",Color("e6ebe8"))
		add_child(l)
	title.position = Vector2(24,20)
	title.add_theme_font_size_override("font_size",24)
	detail.position = Vector2(24,625)
	detail.add_theme_font_size_override("font_size",17)
	process_physics_priority = 20

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		punch.reset()
		player.reset_movement(Vector2(240,559))

func _physics_process(_dt: float) -> void:
	var vis := player.movement_visual
	if punch.sprite.visible:
		review_body.texture = punch.sprite.texture
		review_body.region_enabled = true
		review_body.region_rect = punch.sprite.region_rect
	else:
		review_body.texture = vis.body.sprite_frames.get_frame_texture(vis.body.animation,vis.body.frame)
		review_body.region_enabled = false
	review_neck.position = vis.flame.position
	review_neck.rotation = vis.flame.rotation
	review_flame.texture = vis.flame.sprite.texture
	review_flame.material = vis.flame.sprite.material
	review_flame.region_rect = vis.flame.sprite.region_rect
	title.text = case_label
	detail.text = "A/D move | LMB or J punch | Space jump | Shift roll | R reset | Native left / nearest 4x right\n"+"age %.3f | active %s | vx %.1f | Same-update stop; no attack queue; jump > roll > M1" % [punch.age,punch.active_window,player.velocity.x]
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(820,175,440,420),Color("1a2229"))
	draw_line(Vector2(16,560),Vector2(790,560),Color("929d95"))
	for x in range(20,790,10):
		draw_line(Vector2(x,561),Vector2(x,566 if x%50==0 else 563),Color("596b6d"))
