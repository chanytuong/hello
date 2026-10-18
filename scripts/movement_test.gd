extends Node2D
## Small fixed-view movement room; no combat, enemies or gameplay systems.
@onready var player: NLBPlayer = $Player
var status := Label.new()

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("202832"))
	_solid("LeftBoundary", Rect2(-30, 0, 30, 720))
	_solid("Runway", Rect2(0, 600, 760, 120))
	_solid("GapExit", Rect2(850, 600, 430, 120))
	_solid("RollWall", Rect2(1230, 410, 30, 190))
	_solid("LowPlatform", Rect2(450, 490, 120, 16))
	_solid("HighPlatform", Rect2(650, 390, 100, 16))
	_solid("Ledge", Rect2(920, 480, 140, 16))
	var layer := CanvasLayer.new()
	add_child(layer)
	var instructions := Label.new()
	instructions.position = Vector2(24, 18)
	instructions.text = "IVEN / MOVEMENT TEST\nA D or arrows: move    Space / W / Up: jump    Shift / L: roll    R: reset\nTemporary IDLE / JUMP / ROLL / FLAME assets - human visual review pending"
	instructions.add_theme_font_size_override("font_size", 18)
	layer.add_child(instructions)
	status.position = Vector2(24, 98)
	status.add_theme_font_size_override("font_size", 17)
	layer.add_child(status)
	for item in [[Vector2(180, 635), "RUN / RELEASE / REVERSE"], [Vector2(758, 635), "GAP"], [Vector2(1100, 635), "ROLL WALL"]]:
		var label := Label.new()
		label.position = item[0]
		label.text = item[1]
		layer.add_child(label)

func _solid(label: String, rect: Rect2) -> void:
	var solid := StaticBody2D.new()
	solid.name = label
	solid.z_index = -1 # do not let terrain conceal sprite/flame intersections
	solid.position = rect.position
	solid.collision_layer = 1
	solid.collision_mask = 2
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.size / 2.0
	solid.add_child(shape)
	var art := ColorRect.new()
	art.size = rect.size
	art.color = Color("414e5b")
	solid.add_child(art)
	var edge := ColorRect.new()
	edge.size = Vector2(rect.size.x, 2)
	edge.color = Color("91a0a9")
	solid.add_child(edge)
	add_child(solid)

func _physics_process(_dt: float) -> void:
	if Input.is_action_just_pressed("restart") or player.position.y > 780.0:
		player.reset_movement(Vector2(180, 599))
	status.text = "%s   |   %s" % [player.movement_visual.state, "RIGHT" if player.facing > 0 else "LEFT"]
