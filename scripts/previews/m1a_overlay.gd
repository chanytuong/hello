extends Node2D
## Isolated M1-A visual prototype. Never writes player movement or shared art.
const PIVOT := Vector2(40.499926203, 75.579576591)
var player: NLBPlayer
var vis: Node2D
var image: Texture2D
var metadata: Dictionary
var lookup: Dictionary = {}
var sprite := Sprite2D.new()
var age: float = -1.0
var active_window: bool = false
var requested: bool = false
var planted_demo: bool = false
var distance_phase: bool = true
var enabled: bool = true
var accepted: int = 0
var cancelled: int = 0
var current: Dictionary = {}
var last_cancel: String = ""

func _ready() -> void:
	player = get_parent() as NLBPlayer
	vis = player.movement_visual
	metadata = JSON.parse_string(FileAccess.get_file_as_string("res://art/iven/combat_m1a/m1a_metadata.json"))
	image = load("res://art/iven/combat_m1a/m1a_body.png")
	for row in metadata.records:
		lookup["%s/%s/%d" % [row.direction, row.family, row.sample]] = row
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.offset = -PIVOT
	sprite.texture = image
	sprite.region_enabled = true
	sprite.z_index = -1
	sprite.hide()
	vis.add_child(sprite)
	# The unchanged controller updates its visual first; this child runs after it.
	process_physics_priority = 10

func request_attack() -> void:
	requested = true

func reset() -> void:
	age = -1.0
	active_window = false
	requested = false
	current = {}
	sprite.hide()
	vis.body.show()

func _physics_process(dt: float) -> void:
	var defensively_cancelled := Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("dash")
	var compatible: bool = player.is_on_floor() and player.roll_remaining <= 0.0 and vis.state in ["RUN", "IDLE"]
	if not enabled or defensively_cancelled or not compatible:
		if age >= 0.0:
			cancelled += 1
			last_cancel = "jump/roll" if defensively_cancelled else "movement state"
		reset()
		return
	var started := false
	if requested or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("swap_select"):
		requested = false
		if age < 0.0:
			age = 0.0
			accepted += 1
			started = true
	if age < 0.0:
		return
	if not started:
		age += dt
	if age >= 0.2 - 0.000001:
		reset()
		return
	active_window = age >= 0.04 - 0.000001 and age < 0.10 - 0.000001
	# Review-only animation-side clock matching. The source RUN and controller
	# are unchanged. Carry the current phase through return; never restart it.
	if vis.state == "RUN" and distance_phase and not planted_demo and not started:
		var reference_speed: float = metadata.run_phase_reference_speed_px_s
		vis.state_time = maxf(0.0,vis.state_time + dt*(absf(player.get_real_velocity().x)/reference_speed - 1.0))
	var sample_index := 1
	for i in metadata.display_start_times_s.size():
		if age + 0.000001 >= float(metadata.display_start_times_s[i]):
			sample_index = int(metadata.display_sample_indices[i])
	var direction := "right" if player.facing > 0 else "left"
	var family := "IDLE"
	var row_index := 0
	if vis.state == "RUN" and not planted_demo:
		var phase: int = posmod(int(vis.state_time*30.0+0.00001),18) if distance_phase else vis.body.frame
		family = "RUN_%02d" % phase
		row_index = phase + 1
	if direction == "left":
		row_index += 19
	sprite.region_rect = Rect2(sample_index*82, row_index*82, 82, 82)
	current = lookup["%s/%s/%d" % [direction, family, sample_index]]
	vis.body.hide()
	sprite.show()
	vis.neck_local = Vector2(current.neck[0], current.neck[1]) - PIVOT
	vis.flame.position = vis.neck_local.round()
	vis.flame.rotation = float(current.angle)
	vis.flame.limit_at_ground(player.global_position.y - vis.flame.global_position.y)
