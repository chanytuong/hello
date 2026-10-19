extends Node
## Grounded M1-A V2 lab only. One planted clip, no running-punch variants.
const PIVOT := Vector2(40.499926203, 75.579576591)
const DURATION := 0.20
var player: NLBPlayer
var vis: Node2D
var sprite := Sprite2D.new()
var metadata: Dictionary
var age := -1.0
var requested := false
var accepted := 0
var cancelled := 0
var discarded := 0
var last_cancel := ""
var attack_facing := 1
var current: Dictionary = {}
var active_window := false
var lookup: Dictionary = {}

func _ready() -> void:
	player = get_parent() as NLBPlayer
	vis = player.movement_visual
	metadata = JSON.parse_string(FileAccess.get_file_as_string("res://art/iven/combat_m1a_v2/metadata.json"))
	for row in metadata.records:
		lookup["%s/%d" % [row.direction,row.sample]] = row
	sprite.texture = load("res://art/iven/combat_m1a_v2/body.png")
	sprite.centered = false
	sprite.offset = -PIVOT
	sprite.region_enabled = true
	sprite.z_index = -1
	sprite.hide()
	vis.add_child(sprite)
	player.movement_attack_preview = self

func busy() -> bool:
	return age >= 0.0

func request_attack() -> void:
	requested = true

func reset() -> void:
	age = -1.0
	requested = false
	active_window = false
	current = {}
	sprite.hide()
	vis.body.show()

func before_movement(dt: float, input_dir: float) -> float:
	# Called before the real controller integrates movement. Valid jump wins ties.
	var jump_valid: bool = player._coyote > 0.0 and (Input.is_action_just_pressed("jump") or player._jump_buf > 0.0)
	var roll_requested := Input.is_action_just_pressed("dash")
	var punch_requested := requested or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("swap_select")
	requested = false # never retain a stale attack, including defensive ties
	if jump_valid or roll_requested or not player.is_on_floor() or player.roll_remaining > 0.0:
		if busy():
			cancelled += 1
			last_cancel = "JUMP" if jump_valid else ("ROLL" if roll_requested else "state")
		reset()
		return input_dir
	if busy():
		age += dt
		if age >= DURATION - 0.000001:
			reset()
		elif punch_requested:
			discarded += 1 # no attack queue or automatic combo
	if punch_requested and not busy():
		age = 0.0
		accepted += 1
		attack_facing = player.facing if input_dir == 0.0 else (1 if input_dir > 0.0 else -1)
		vis._skid_left = 0.0
	if busy():
		player.facing = attack_facing
		player.velocity.x = 0.0 # deliberate same-update stop, no lunge/deceleration slide
		return 0.0
	return input_dir

func present() -> void:
	if not busy():
		return
	var sample_index := 0
	for i in metadata.display_starts_s.size():
		if age >= float(metadata.display_starts_s[i]) - 0.000001:
			sample_index = int(metadata.display_indices[i])
	var direction := "right" if attack_facing > 0 else "left"
	current = lookup["%s/%d" % [direction,sample_index]]
	sprite.region_rect = Rect2(sample_index*82,0 if attack_facing>0 else 82,82,82)
	vis.body.hide()
	sprite.show()
	active_window = age >= 0.04 - 0.000001 and age < 0.10 - 0.000001
	vis.neck_local = Vector2(current.neck[0],current.neck[1])-PIVOT
	vis.flame.position = vis.neck_local.round()
	vis.flame.rotation = float(current.angle)
	vis.flame.limit_at_ground(player.global_position.y-vis.flame.global_position.y)
