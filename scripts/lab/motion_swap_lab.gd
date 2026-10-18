extends Node2D
class_name NLBMotionSwapLab
## MOTION SWAP TEST LAB — one industrial facility, six connected zones.
##
##   A  bullet to enemy     fast gunner shots, patrol, impact wall
##   B  charger to crate    committed runs and physical crate chains
##   C  human projectile    Iven launch, normal target, cannon and crash wall
##   D  projectile to Iven  leftward cannon, two belts and a lift
##   E  plate & gate        LIFT + BELT + crate: make the plate open the gate
##   F  mixed encounter     everything at once, ending at the finish line
##
## Design rules the lab itself obeys:
##   * Ground is continuous and every gap is jumpable (jump h = 128 px, air
##     travel ~196 px), so no zone can strand the player.
##   * Every zone has a checkpoint: dying or falling rescues to the LAST cleared
##     checkpoint, never to the start of the lab.
##   * Three explicit reset tools (1 / 2 / 3) plus a full restart (R): a lab
##     that can be broken is a lab that cannot be tested.
##   * Machines keep what they were handed. Nothing here silently puts it back.
##
## The scene is deliberately thin: the player/scene/controller live in
## motion_swap_lab.tscn, and everything in between is built by these functions
## so the layout is readable, greppable and resettable zone by zone.

const WORLD_WIDTH := 7840.0
const FLOOR_Y := 600.0
const FALL_KILL_Y := 830.0
const RESPAWN_GRACE := 2.5
const SCAN_INTERVAL := 0.4
const PLAYER_MASK_ADD := 256 | 512  # prop + machine: crates, belts, lifts, gate

const CRATE_SCENE: PackedScene = preload("res://labs/objects/lab_crate.tscn")
const CONVEYOR_SCENE: PackedScene = preload("res://labs/objects/conveyor.tscn")
const PLATFORM_SCENE: PackedScene = preload("res://labs/objects/moving_platform.tscn")
const PLATE_SCENE: PackedScene = preload("res://labs/objects/pressure_plate.tscn")
const GATE_SCENE: PackedScene = preload("res://labs/objects/gate.tscn")
const CANNON_SCENE: PackedScene = preload("res://labs/objects/lab_cannon.tscn")
const PATROL_SCENE: PackedScene = preload("res://labs/enemies/patrol.tscn")
const GUNNER_SCENE: PackedScene = preload("res://labs/enemies/gunner.tscn")
const CHARGER_SCENE: PackedScene = preload("res://labs/enemies/charger.tscn")

const GROUND_FILL := Color("3a4551")
const GROUND_EDGE := Color("8fa1ad")
const ROCK_FILL := Color("333c47")
const LABEL_COLOR := Color("bfe6ff")
const CARD_COLOR := Color("9fb4c4")

var player: NLBPlayer = null
var controller: NLBMotionSwapController = null
var overlay: LabDebugOverlay = null

var completed: bool = false
var checkpoint_title: String = "ZONE A"
var checkpoint_pos: Vector2 = Vector2(650, 599)

var _zones: Array[Node2D] = []
var _enemy_entries: Array[Dictionary] = []
var _pending_spawns: Array[Dictionary] = []
var _plate_bindings: Array[Dictionary] = []
var _scan_t: float = 0.0
var _msg: String = ""
var motion_feedback: LabMotionFeedback
@export_group("Impact feedback")
@export var hitstop_enabled: bool = true
@export var hitstop_real_seconds: float = 0.028
@export var camera_shake_pixels: float = 1.8
@export var trace_impacts: bool = false
var _hitstop_deadline: int = 0
var _shake_left: float = 0.0
var _last_real_tick: int = 0
const ZONE_SPAWNS: Array[Vector2] = [Vector2(650, 599), Vector2(1800, 599), Vector2(3000, 599), Vector2(4200, 599), Vector2(5500, 599), Vector2(7080, 599)]

func _ready() -> void:
	Engine.time_scale = 1.0
	_stamp_helper_classes()
	_build_world()
	_setup_player()
	_setup_camera()
	_setup_controller()
	_setup_overlay()
	motion_feedback = LabMotionFeedback.new()
	motion_feedback.name = "MotionFeedback"
	motion_feedback.z_index = 6
	add_child(motion_feedback)
	_last_real_tick = Time.get_ticks_usec()

## Touching the class names here documents which helper scripts this scene
## depends on and makes a missing file a load error, not a subtle silent skip.
func _stamp_helper_classes() -> void:
	var _a := LabConveyor.new()
	var _b := LabMovingPlatform.new()
	var _c := LabPressurePlate.new()
	var _d := LabGate.new()
	var _e := LabCannon.new()
	_a.free()
	_b.free()
	_c.free()
	_d.free()
	_e.free()

# --------------------------------------------------------------------- setup

func _setup_player() -> void:
	player = $Player as NLBPlayer
	# The lab is the one place crates and machines must be solid for Iven:
	# standing on a lift, being carried by a belt, pushing a crate.
	player.collision_mask |= PLAYER_MASK_ADD
	player.enable_motion_swap()
	if player.health != null:
		player.health.died.connect(_on_player_died)

func _setup_camera() -> void:
	# The lab is WORLD_WIDTH wide, so most of it would render off-screen without
	# a camera. Iven carries it; the limits frame the full 720 px world height
	# (a fixed, honest view) and stop the scroll at the built world's edges.
	var cam := Camera2D.new()
	cam.name = "LabCamera"
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	cam.limit_left = 0
	cam.limit_right = int(WORLD_WIDTH)
	cam.limit_top = 0
	cam.limit_bottom = int(FLOOR_Y + 120.0)
	player.add_child(cam)
	cam.make_current()

func _setup_controller() -> void:
	controller = $Controller as NLBMotionSwapController
	controller.swap_executed.connect(_on_swap_executed)
	controller.feedback.connect(func(text: String, _ok: bool) -> void: _say(text))

func _on_swap_executed(_a: NLBMotionSwapTarget, _b: NLBMotionSwapTarget) -> void:
	_hitstop_deadline = 0
	_shake_left = 0.06

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func show_motion_impact(point: Vector2, normal: Vector2, speed: float) -> void:
	if motion_feedback != null:
		motion_feedback.impact_at(point, normal, speed)
	_shake_left = 0.09
	if hitstop_enabled and speed >= 430.0 and controller != null and not controller.is_selecting():
		_hitstop_deadline = Time.get_ticks_usec() + int(hitstop_real_seconds * 1000000.0)
		Engine.time_scale = 0.04

func visit_zone(index: int) -> void:
	if index < 0 or index >= _zones.size():
		return
	controller.reset_state()
	_hitstop_deadline = 0
	Engine.time_scale = 1.0
	checkpoint_title = "ZONE " + String.chr(65 + index)
	checkpoint_pos = ZONE_SPAWNS[index]
	place_player(checkpoint_pos)
	reset_zone()
	var cam := player.get_node_or_null("LabCamera") as Camera2D
	if cam != null:
		cam.reset_smoothing()

func _setup_overlay() -> void:
	overlay = $HUD as LabDebugOverlay
	overlay.lab = self
	overlay.controller = controller
	overlay.player = player
	_say("MOTION SWAP LAB · F4: Human Projectile · F1: details")

func _say(text: String) -> void:
	_msg = text
	if overlay != null:
		overlay.set_message(text)

# --------------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	for i in 6:
		if event.is_action_pressed("lab_zone_" + String.chr(97 + i)):
			visit_zone(i)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("lab_overdrive_toggle"):
		controller.overdrive_enabled = not controller.overdrive_enabled
		_say("OVERDRIVE " + ("ON" if controller.overdrive_enabled else "OFF"))
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("lab_debug_toggle"):
		if overlay != null:
			overlay.debug_expanded = not overlay.debug_expanded
			controller.debug_values = overlay.debug_expanded
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("lab_reset_zone"):
		reset_zone()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("lab_reset_targets"):
		reset_targets()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("lab_respawn_enemies"):
		respawn_enemies()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart"):
		controller.reset_state()
		_hitstop_deadline = 0
		Engine.time_scale = 1.0
		get_viewport().set_input_as_handled()
		get_tree().reload_current_scene()

# --------------------------------------------------------------- reset tools

## 1 — everything in the zone the player is standing in goes back to its
## authored state: positions, machine speeds, plates, gates, dead enemies.
func reset_zone() -> void:
	controller.reset_state()
	_hitstop_deadline = 0
	Engine.time_scale = 1.0
	var zone := current_zone()
	if zone == null:
		_say("RESET ZONE: no zone found")
		return
	var before := _selection_text()
	for child in zone.get_children():
		_reset_subtree(child)
	for entry in _enemy_entries:
		if entry.zone == zone and not is_instance_valid(entry.node):
			_spawn_enemy_entry(entry, true)
	_pending_spawns = _pending_spawns.filter(func(p: Dictionary) -> bool: return p.entry.zone != zone)
	for p in get_tree().get_nodes_in_group("lab_projectiles"):
		p.retire_now()
	var index := _zones.find(zone)
	if index >= 0:
		place_player(ZONE_SPAWNS[index])
	player.health.reset()
	if controller != null:
		controller.cancel_selection()
	print("[LAB] reset zone %s" % zone.name)
	_say("RESET %s — %s" % [zone.get_meta("title", zone.name), before])

## 2 — clears every EXCHANGED motion without moving anything: machines return
## to their authored speeds, characters and crates drop the received motion in
## place, and live shots are retired. Nothing teleports.
func reset_targets() -> void:
	controller.reset_state()
	_hitstop_deadline = 0
	Engine.time_scale = 1.0
	player.reset_movement(player.global_position)
	for n in get_tree().get_nodes_in_group("lab_machines"):
		if n.has_method("reset_motion"):
			n.reset_motion()
	for n in get_tree().get_nodes_in_group("lab_enemies"):
		if n.has_method("reset_motion"):
			n.reset_motion()
	for n in get_tree().get_nodes_in_group("crates"):
		if n.has_method("reset_motion"):
			n.reset_motion()
	for n in get_tree().get_nodes_in_group("lab_projectiles"):
		var p := n as LabProjectile
		if p != null:
			p.retire_now()
	if controller != null:
		controller.cancel_selection()
	_say("TARGETS RESET — all exchanged motion cleared in place (machines back to authored speeds).")

## 3 — every enemy back to its spawn point, alive, full hp.
func respawn_enemies() -> void:
	controller.reset_state()
	_hitstop_deadline = 0
	Engine.time_scale = 1.0
	var n := 0
	for entry in _enemy_entries:
		if is_instance_valid(entry.node):
			entry.node.reset_state()
		else:
			_spawn_enemy_entry(entry, true)
		n += 1
	_pending_spawns.clear()
	_say("ENEMIES RESPAWNED (%d)." % n)

func _reset_subtree(n: Node) -> void:
	if n.has_method("reset_state"):
		n.call("reset_state")
	for c in n.get_children():
		_reset_subtree(c)

func _selection_text() -> String:
	if controller == null:
		return "selection cleared"
	return "selection cleared" if controller.target_a == null else "A was selected, now cleared"

# ------------------------------------------------------------ runtime upkeep

func _process(delta: float) -> void:
	var now := Time.get_ticks_usec()
	var real_delta := float(now - _last_real_tick) / 1000000.0
	_last_real_tick = now
	_shake_left = maxf(_shake_left - real_delta, 0.0)
	var cam := player.get_node_or_null("LabCamera") as Camera2D
	if cam != null:
		cam.offset = Vector2(sin(float(now) * 0.00019), cos(float(now) * 0.00023)) * camera_shake_pixels * minf(_shake_left / 0.09, 1.0)
	if _hitstop_deadline > 0:
		if controller.is_selecting():
			_hitstop_deadline = 0 # tactical controller now owns the clock
		elif now >= _hitstop_deadline:
			_hitstop_deadline = 0
			Engine.time_scale = 1.0
	_tick_pending(delta)
	_scan_t -= delta
	if _scan_t > 0.0:
		return
	_scan_t = SCAN_INTERVAL
	_scan_world()

func _tick_pending(delta: float) -> void:
	for i in range(_pending_spawns.size() - 1, -1, -1):
		var p: Dictionary = _pending_spawns[i]
		p.t -= delta
		if p.t <= 0.0:
			_pending_spawns.remove_at(i)
			_spawn_enemy_entry(p.entry, true)

func _scan_world() -> void:
	# Fallen enemies are retired and given a grace period, not left as a body
	# stuck somewhere unreachable.
	for n in get_tree().get_nodes_in_group("lab_enemies"):
		var e := n as LabEnemy
		if e != null and e.global_position.y > FALL_KILL_Y:
			_schedule_respawn_for(e)
	# Fallen crates go home: a lost crate must never become a missing tool.
	for n in get_tree().get_nodes_in_group("crates"):
		var c := n as LabCrate
		if c != null and c.global_position.y > FALL_KILL_Y:
			c.reset_state()
			_say("CRATE RECOVERED to its spawn.")
	# And the player is always rescued to the last checkpoint.
	if player != null and player.global_position.y > FALL_KILL_Y:
		_respawn_player("FELL OUT OF THE WORLD")

func _schedule_respawn_for(e: LabEnemy) -> void:
	for entry in _enemy_entries:
		if entry.node == e:
			entry.node = null
			_pending_spawns.append({"entry": entry, "t": RESPAWN_GRACE})
			_say("%s fell out — respawning shortly." % entry.label)
			break
	e.retire()

func _on_player_died() -> void:
	_respawn_player("KNOWN DOWN")

func _respawn_player(reason: String) -> void:
	if player == null:
		return
	_hitstop_deadline = 0
	Engine.time_scale = 1.0
	place_player(checkpoint_pos)
	if player.health != null:
		player.health.reset()
	if controller != null:
		controller.cancel_selection()
	_say("%s — back at CHECKPOINT %s." % [reason, checkpoint_title])

## Teleport Iven somewhere without becoming a weapon. A raw position set that
## lands him inside a resting crate makes the physics engine eject the CRATE at
## several hundred px/s (measured: 763 px/s from one 24 px overlap), which would
## let a checkpoint respawn solve zone E by accident. So on overlap the PLAYER
## steps aside and the crate keeps its own motion — the same rule the legacy
## arena used for arena changes.
func place_player(at: Vector2) -> void:
	if player == null:
		return
	player.reset_movement(at)
	var shape := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null or shape.shape == null:
		return
	for _i in 4:
		var q := PhysicsShapeQueryParameters2D.new()
		q.shape = shape.shape
		q.transform = Transform2D(0.0, player.global_position + shape.position)
		q.collide_with_bodies = true
		q.collide_with_areas = false
		q.collision_mask = 256  # prop only: crates. Never machines, never enemies.
		var hits := player.get_world_2d().direct_space_state.intersect_shape(q, 4)
		if hits.is_empty():
			return
		var moved := false
		for hit in hits:
			var body := hit.get("collider") as Node2D
			if body == null or body == player:
				continue
			var dir := 1.0 if player.global_position.x >= body.global_position.x else -1.0
			player.global_position.x = body.global_position.x + dir * 40.0
			moved = true
		if not moved:
			return
	player.velocity = Vector2.ZERO

func _on_enemy_impact(strength: float, enemy: LabEnemy) -> void:
	_say("%s IMPACT" % enemy.type_label())
	if trace_impacts:
		print("IMPACT %s %.0f px/s" % [enemy.type_label(), strength])

func _on_enemy_down(label: String) -> void:
	_say("%s DOWN" % label)

func _on_plate_changed(pressed_now: bool, latched: bool, plate: LabPressurePlate) -> void:
	for b in _plate_bindings:
		if b.plate == plate:
			var gate := b.gate as LabGate
			gate.set_open(latched)
	if pressed_now:
		_say("PLATE DOWN — gate opened (latched)." if latched else "PLATE DOWN — gate held open.")

func _on_finish_body_entered(body: Node2D) -> void:
	if body != player or completed:
		return
	completed = true
	_say("LAB COMPLETE — free play. Finish tool: R restarts the lab.")

func current_zone() -> Node2D:
	if player == null:
		return null
	var x := player.global_position.x
	for z in _zones:
		if x >= z.get_meta("x_start", 0.0) and x <= z.get_meta("x_end", 0.0):
			return z
	return null

func lab_status_line() -> String:
	var zone := current_zone()
	return "LAB  %s   checkpoint %s   %s" % [
		zone.get_meta("title", "?") if zone != null else "—",
		checkpoint_title,
		"COMPLETE" if completed else "in progress"]

# ------------------------------------------------------------------- builders

func _build_world() -> void:
	var world := $World as Node2D
	_build_zone_a(world)
	_build_zone_b(world)
	_build_zone_c(world)
	_build_zone_d(world)
	_build_zone_e(world)
	_build_zone_f(world)
	# Outer shell: the lab is a closed box, so nothing can walk off the ends.
	_solid(world, "LeftWall", Rect2(-40, -240, 40, 960), ROCK_FILL)

func _zone_node(world: Node2D, id: String, title: String, x_start: float, x_end: float) -> Node2D:
	var z := Node2D.new()
	z.name = "Zone" + id
	z.set_meta("x_start", x_start)
	z.set_meta("x_end", x_end)
	z.set_meta("title", "ZONE %s · %s" % [id, title])
	world.add_child(z)
	_zones.append(z)
	return z

func _solid(parent: Node2D, label: String, rect: Rect2, fill: Color = GROUND_FILL, edge: Color = GROUND_EDGE) -> StaticBody2D:
	var solid := StaticBody2D.new()
	solid.name = label
	solid.z_index = -1
	solid.position = rect.position
	solid.collision_layer = 1
	solid.collision_mask = 2 | 4 | 256 | 512
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.size * 0.5
	solid.add_child(shape)
	var art := ColorRect.new()
	art.name = "Fill"
	art.size = rect.size
	art.color = fill
	solid.add_child(art)
	var top := ColorRect.new()
	top.name = "Edge"
	top.size = Vector2(rect.size.x, 2)
	top.color = edge
	solid.add_child(top)
	parent.add_child(solid)
	return solid

func _zone_card(zone: Node2D, pos: Vector2, title: String, lines: Array[String]) -> void:
	var t := Label.new()
	t.name = "Title"
	t.position = pos
	t.text = title
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", LABEL_COLOR)
	zone.add_child(t)
	var body := Label.new()
	body.name = "Card"
	body.position = pos + Vector2(2, 42)
	body.text = "\n".join(lines)
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", CARD_COLOR)
	zone.add_child(body)

func _checkpoint(zone: Node2D, x: float, title: String, respawn: Vector2) -> void:
	var area := Area2D.new()
	area.name = "Checkpoint"
	area.position = Vector2(x, FLOOR_Y - 300.0)
	area.collision_layer = 0
	area.collision_mask = 2  # player
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(12, 600)
	shape.shape = box
	area.add_child(shape)
	area.body_entered.connect(_on_checkpoint.bind(title, respawn))
	zone.add_child(area)
	var post := ColorRect.new()
	post.name = "CheckpointPost"
	post.position = Vector2(x - 3, FLOOR_Y - 90.0)
	post.size = Vector2(6, 90)
	post.color = Color(0.45, 0.85, 1.0, 0.5)
	zone.add_child(post)

func _on_checkpoint(body: Node2D, title: String, respawn: Vector2) -> void:
	if body != player:
		return
	if checkpoint_title == title:
		return
	checkpoint_title = title
	checkpoint_pos = respawn
	_say("CHECKPOINT %s" % title)

func _crate(parent: Node2D, pos: Vector2) -> LabCrate:
	var c := CRATE_SCENE.instantiate() as LabCrate
	c.position = pos
	parent.add_child(c)
	return c

func _enemy(scene: PackedScene, zone: Node2D, pos: Vector2, label: String, config: Callable = Callable()) -> LabEnemy:
	var e := scene.instantiate() as LabEnemy
	e.position = pos
	e.set_spawn(pos)
	zone.add_child(e)
	if config.is_valid():
		config.call(e)
	e.impact.connect(_on_enemy_impact.bind(e))
	e.died.connect(_on_enemy_down.bind(label))
	_enemy_entries.append({
		"scene": scene, "pos": pos, "zone": zone, "node": e,
		"config": config, "label": label,
	})
	return e

func _spawn_enemy_entry(entry: Dictionary, announce: bool) -> void:
	var e := (entry.scene as PackedScene).instantiate() as LabEnemy
	e.position = entry.pos
	e.set_spawn(entry.pos)
	(entry.zone as Node2D).add_child(e)
	var cfg := entry.config as Callable
	if cfg.is_valid():
		cfg.call(e)
	e.impact.connect(_on_enemy_impact.bind(e))
	e.died.connect(_on_enemy_down.bind(String(entry.label)))
	entry.node = e
	if announce:
		_say("%s respawned." % entry.label)

func _hazard(zone: Node2D, rect: Rect2) -> NLBHazard:
	var h := NLBHazard.new()
	h.name = "Spikes"
	h.position = rect.position + rect.size * 0.5
	var hit := NLBHitBox.new()
	hit.name = "HitBox"
	hit.collision_layer = 64
	hit.collision_mask = 128  # player hurtbox only
	hit.damage = 1
	hit.knockback = Vector2(0, -260)
	hit.continuous = true
	hit.tick = 0.2
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	hit.add_child(shape)
	h.add_child(hit)
	var vis := ColorRect.new()
	vis.name = "Visual"
	vis.position = -rect.size * 0.5
	vis.size = rect.size
	h.add_child(vis)
	zone.add_child(h)
	return h

func _conveyor(zone: Node2D, x_top_left: float, speed: float, length: float, tag: String = "") -> LabConveyor:
	var c := CONVEYOR_SCENE.instantiate() as LabConveyor
	c.name = "Belt" + tag if not tag.is_empty() else "Belt"
	c.surface_speed = speed
	c.belt_length = length
	c.position = Vector2(x_top_left, FLOOR_Y)
	zone.add_child(c)
	_solid(zone, "Belt%sBase" % tag, Rect2(x_top_left, FLOOR_Y + c.thickness, length, 100), ROCK_FILL)
	return c

func _platform(zone: Node2D, origin: Vector2, axis: Vector2, path_len: float, speed: float,
		size: Vector2, label: String) -> LabMovingPlatform:
	var p := PLATFORM_SCENE.instantiate() as LabMovingPlatform
	p.axis = axis
	p.path_length = path_len
	p.travel_speed = speed
	p.platform_size = size
	p.label_text = label
	p.position = origin
	zone.add_child(p)
	return p

func _plate(zone: Node2D, pos: Vector2, gate: LabGate, label: String = "PLATE") -> LabPressurePlate:
	var p := PLATE_SCENE.instantiate() as LabPressurePlate
	p.position = pos
	p.label_text = label
	zone.add_child(p)
	p.state_changed.connect(_on_plate_changed.bind(p))
	_plate_bindings.append({"plate": p, "gate": gate})
	return p

func _gate(zone: Node2D, pos: Vector2, size: Vector2) -> LabGate:
	var g := GATE_SCENE.instantiate() as LabGate
	g.gate_size = size
	g.position = pos
	zone.add_child(g)
	return g

func _cannon(zone: Node2D, pos: Vector2, dir: Vector2, speed: float) -> LabCannon:
	var c := CANNON_SCENE.instantiate() as LabCannon
	c.position = pos
	c.direction = dir
	c.speed = speed
	zone.add_child(c)
	return c

# ------------------------------------------------------------------ zone A

func _build_zone_a(world: Node2D) -> void:
	var z := _zone_node(world, "A", "BULLET TO ENEMY", 0.0, 1200.0)
	_solid(z, "Ground", Rect2(0, FLOOR_Y, 1200, 120))
	_solid(z, "LowWall", Rect2(1090, FLOOR_Y - 100, 20, 100), ROCK_FILL)
	_zone_card(z, Vector2(70, 330), "A · BULLET TO ENEMY", [
		"E slows the world. Click a fast SHOT, then the PATROL.",
		"Its received direction is exact. The wall supplies the damage.",
		"Q / RMB chooses Iven in either slot. E / Esc cancels.",
		"F2–F7 jump to tests · 1 retry · F1 details · F8 Overdrive A/B",
	])
	_checkpoint(z, 70, "ZONE A", Vector2(650, 599))
	_enemy(GUNNER_SCENE, z, Vector2(350, 599), "GUNNER A")
	_enemy(PATROL_SCENE, z, Vector2(830, 599), "PATROL A", func(e: LabEnemy) -> void:
		(e as LabPatrolEnemy).configure_patrol(780.0, 940.0))
	_crate(z, Vector2(180, 580))
	_crate(z, Vector2(240, 580))

# ------------------------------------------------------------------ zone B

func _build_zone_b(world: Node2D) -> void:
	var z := _zone_node(world, "B", "CHARGER TO CRATE", 1200.0, 2500.0)
	_solid(z, "Ground", Rect2(1200, FLOOR_Y, 1300, 120))
	_solid(z, "Perch", Rect2(2370, FLOOR_Y - 100, 20, 100), ROCK_FILL)
	_zone_card(z, Vector2(1240, 340), "B · CHARGER TO CRATE", [
		"Let the CHARGER rush. E · Charger · CRATE.",
		"The charge stops. The crate hits the gunner or another crate.",
		"A wall, a body, or a pressure plate can end the chain. 1 retries.",
	])
	_checkpoint(z, 1250, "ZONE B", Vector2(1800, 599))
	_enemy(CHARGER_SCENE, z, Vector2(1500, 599), "CHARGER B")
	_enemy(GUNNER_SCENE, z, Vector2(2230, 599), "GUNNER B")
	_crate(z, Vector2(1980, 580))
	_crate(z, Vector2(2120, 580))

# ------------------------------------------------------------------ zone C

func _build_zone_c(world: Node2D) -> void:
	var z := _zone_node(world, "C", "HUMAN PROJECTILE", 2500.0, 3700.0)
	_solid(z, "Ground", Rect2(2500, FLOOR_Y, 1200, 120))
	_solid(z, "ChargeStop", Rect2(3480, FLOOR_Y - 100, 20, 100), ROCK_FILL)
	_zone_card(z, Vector2(2540, 340), "C · HUMAN PROJECTILE", [
		"Let the CHARGER rush RIGHT. E · click Charger · Q.",
		"Hit the patrol at speed. Near the wall, take a RIGHT shot with Q.",
		"The open lane to the left is safe for recovery. 1 resets this zone.",
	])
	_checkpoint(z, 2550, "ZONE C", Vector2(3000, 599))
	_enemy(CHARGER_SCENE, z, Vector2(2860, 599), "CHARGER C")
	_enemy(PATROL_SCENE, z, Vector2(3100, 599), "PATROL C", func(e: LabEnemy) -> void:
		(e as LabPatrolEnemy).configure_patrol(3090.0, 3120.0)
		(e as LabPatrolEnemy).speed = 35.0)
	_crate(z, Vector2(3300, 580))
	_cannon(z, Vector2(3340, 560), Vector2.RIGHT, 1200.0)

# ------------------------------------------------------------------ zone D

func _build_zone_d(world: Node2D) -> void:
	var z := _zone_node(world, "D", "PROJECTILE TO IVEN / MACHINERY", 3700.0, 5150.0)
	_solid(z, "GroundWest", Rect2(3700, FLOOR_Y, 300, 120))
	_conveyor(z, 4000.0, 120.0, 300.0, "A")
	_solid(z, "GroundMid", Rect2(4300, FLOOR_Y, 200, 120))
	_conveyor(z, 4500.0, -120.0, 300.0, "B")
	_solid(z, "GroundEast", Rect2(4800, FLOOR_Y, 200, 120))
	_solid(z, "LiftLedge", Rect2(5000, 400, 300, 16), ROCK_FILL)
	_zone_card(z, Vector2(3740, 330), "D · PROJECTILE TO IVEN", [
		"The test cannon fires LEFT at 1200 px/s. E · SHOT · Q.",
		"Iven launches LEFT. Order never changes the direction.",
		"Belt / lift commands swap with machines and persist until reset.",
	])
	_checkpoint(z, 3750, "ZONE D", Vector2(4200, 599))
	_cannon(z, Vector2(4520, 560), Vector2.LEFT, 1200.0)
	_crate(z, Vector2(4370, 580))
	_crate(z, Vector2(4700, 580))
	var lift := _platform(z, Vector2(4860, 560), Vector2(0, -1), 160.0, 80.0,
		Vector2(140, 16), "LIFT")
	lift.name = "Lift"
	_crate(z, Vector2(5080, 380))

# ------------------------------------------------------------------ zone E

func _build_zone_e(world: Node2D) -> void:
	var z := _zone_node(world, "E", "PLATE & GATE", 5150.0, 6400.0)
	_solid(z, "GroundWest", Rect2(5150, FLOOR_Y, 470, 120))
	_solid(z, "PitFloor", Rect2(5620, FLOOR_Y + 60, 180, 60), ROCK_FILL)
	# The east floor IS the belt: whatever the lift delivers lands on it, and
	# the belt is what carries the crate the rest of the way to the plate.
	_conveyor(z, 5800.0, 120.0, 280.0, "E")
	_solid(z, "GroundGate", Rect2(6080, FLOOR_Y, 320, 120))
	_solid(z, "CorridorCeiling", Rect2(6240, 320, 220, 160), ROCK_FILL)
	var gate := _gate(z, Vector2(6300, FLOOR_Y - 120), Vector2(20, 120))
	gate.name = "ZoneEGate"
	_zone_card(z, Vector2(5190, 300), "ZONE E · PLATE & GATE", [
		"A crate is parked on the LIFT. The belt is stopped. The plate latches.",
		"1. Swap the BELT speed (+120) into the LIFT: the crate rides across.",
		"2. Swap them again: the belt drives the crate onto the plate.",
		"Linear things (crate vs lift) are REFUSED with a reason — channels.",
		"The plate latches, so the gate can never close behind you;",
		"standing on the plate yourself also opens it.",
	])
	_checkpoint(z, 5200, "ZONE E", Vector2(5250, 599))
	# The crossing lift: parked at its left bound, flush with the west floor.
	var lift := _platform(z, Vector2(5620, FLOOR_Y), Vector2.RIGHT, 80.0, 0.0,
		Vector2(100, 16), "E-LIFT")
	lift.name = "CrossingLift"
	# Loaded at the lift's far edge, so the crossing delivers the crate onto the
	# belt instead of stopping an arm's length short of it.
	_crate(z, Vector2(5700, 580))
	_plate(z, Vector2(6080, FLOOR_Y - 12), gate, "PLATE")

# ------------------------------------------------------------------ zone F

func _build_zone_f(world: Node2D) -> void:
	var z := _zone_node(world, "F", "MIXED ENCOUNTER", 6400.0, 7840.0)
	_solid(z, "Ground", Rect2(6400, FLOOR_Y, 1440, 120))
	_solid(z, "Perch", Rect2(6700, 420, 200, 16), ROCK_FILL)
	_solid(z, "RightWall", Rect2(7800, -240, 40, 960), ROCK_FILL)
	_hazard(z, Rect2(7300, FLOOR_Y - 12, 120, 12))
	_conveyor(z, 7560.0, -100.0, 200.0, "F")
	_zone_card(z, Vector2(6450, 330), "ZONE F · MIXED ENCOUNTER", [
		"Everything at once: the turret aims, the patrol walks, the charger commits,",
		"the belt runs against you. Swap, dodge, and reach the far wall.",
	])
	_checkpoint(z, 6450, "ZONE F", Vector2(6500, 599))
	_enemy(GUNNER_SCENE, z, Vector2(6790, 419), "GUNNER F")
	_enemy(PATROL_SCENE, z, Vector2(7000, 599), "PATROL F", func(e: LabEnemy) -> void:
		(e as LabPatrolEnemy).configure_patrol(6880.0, 7150.0))
	_enemy(CHARGER_SCENE, z, Vector2(7520, 599), "CHARGER F")
	_crate(z, Vector2(6600, 580))
	_crate(z, Vector2(7420, 580))
	var finish := Area2D.new()
	finish.name = "FinishLine"
	finish.position = Vector2(7774, FLOOR_Y - 150)
	finish.collision_layer = 0
	finish.collision_mask = 2
	var fshape := CollisionShape2D.new()
	var fbox := RectangleShape2D.new()
	fbox.size = Vector2(20, 300)
	fshape.shape = fbox
	finish.add_child(fshape)
	finish.body_entered.connect(_on_finish_body_entered)
	z.add_child(finish)
	var board := Label.new()
	board.position = Vector2(7620, 400)
	board.text = "FINISH"
	board.add_theme_font_size_override("font_size", 26)
	board.add_theme_color_override("font_color", Color("e8d27a"))
	z.add_child(board)
