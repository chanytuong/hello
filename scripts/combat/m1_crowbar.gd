extends "res://scripts/combat/crowbar_feel_combo.gd"
const SHAPE = preload("res://scripts/combat/slash_shape.gd")
var vfx_enabled := true
var vfx_strength := 1 # A=0 restrained, B=1 selected medium, C=2 strong.
var ribbon_points: Array = []
var ribbon_last_sample := -1
var ribbon_last_clock := -1.0
var drawn_layers: Array = []
var last_ribbon_area := 0.0
var impact_vfx: Node2D
var batched_draw := true # Lab A/B toggle; production always uses the batched path.
var profile := false # Lab-only timing hook; off in production.
var build_us := 0
var draw_us := 0

func _ready() -> void:
	super._ready()
	metadata = JSON.parse_string(FileAccess.get_file_as_string("res://art/iven/m1_crowbar/attack_metadata.json"))
	lookup.clear()
	for row in metadata.records: lookup["%d/%s/%d"%[row.strike,row.direction,row.sample]] = row
	sprite.texture = ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(metadata.texture)))
	playback_rate = 1.0 # Retime is authored into this export's per-phase samples.
	trails_enabled = false # The rejected line trail is never drawn or emitted.
	stops = Vector3(.03,.04,.05)
	# One full strike of intent: covers M2's 0.20 s gate from its first frame.
	buffer_seconds = .25
	bounded_buffer = true
	# Fill is behind body and actual weapon, so it cannot turn the crowbar into
	# a luminous sword or hide its hook. Enemy telegraphs remain in front.
	z_index = -2
	impact_vfx = preload("res://scripts/combat/crowbar_fx.gd").new()
	impact_vfx.name = "CrowbarFX"
	impact_vfx.top_level = true
	player.add_child(impact_vfx)
	contact_feedback.connect(_on_contact_feedback)
	whoosh.connect(_on_whoosh)

func reset() -> void:
	ribbon_points.clear()
	drawn_layers.clear()
	ribbon_last_sample = -1
	ribbon_last_clock = -1
	last_ribbon_area = 0
	super.reset()

func _start(strike: int, direction: int) -> void:
	ribbon_points.clear()
	drawn_layers.clear()
	ribbon_last_sample = -1
	ribbon_last_clock = -1
	super._start(strike,direction)

func present() -> void:
	# Snap the effect transform, not the physical character. Local integer
	# vertices then stay on the same native grid as the approved body sprite.
	position = player.global_position.round()-player.global_position
	super.present()
	if not busy() or not vfx_enabled:
		drawn_layers.clear()
		return
	var emit_start: int = [2,4,13][index]
	var emit_end: int = [7,10,22][index]
	var sample := int(current.get("sample",-1))
	if sample >= emit_start and sample <= emit_end and sample != ribbon_last_sample:
		var tip_data: Array = current.tip
		var grip_data: Array = current.grip
		var tip: Vector2 = player.global_position.round()+sprite.position+Vector2(tip_data[0],tip_data[1])-pivot
		var grip: Vector2 = player.global_position.round()+sprite.position+Vector2(grip_data[0],grip_data[1])-pivot
		ribbon_points.append({"tip":tip.round(),"grip":grip.round(),"clock":age})
		ribbon_last_sample = sample
		ribbon_last_clock = age
	# Motion follows the source clock, including local contact stop. Dissolve by
	# discrete shape erosion; opaque clusters, no blurred translucent smear.
	var tail := maxf(0,age-float(emit_end)/60.0)
	var shrink := 1.0
	if tail > 2.0/60.0: shrink = 0.60
	if tail > 3.0/60.0: shrink = 0.28
	if tail > 4.0/60.0: shrink = 0.0
	var recent: Array = []
	for point in ribbon_points:
		if age-point.clock <= .14: recent.append({"tip":to_local(point.tip),"grip":to_local(point.grip)})
	if index == 0:
		# Suppress the rearward preparation streak. Clip the already-travelled
		# trajectory at Iven's shoulder plane, so the broad mass reads forward.
		var forward: Array = []
		for i in recent.size():
			var point: Dictionary = recent[i]
			if point.tip.x*attack_facing >= -5:
				if i > 0 and recent[i-1].tip.x*attack_facing < -5:
					var previous: Dictionary = recent[i-1]
					var t: float = (-5.0-previous.tip.x*attack_facing)/((point.tip.x-previous.tip.x)*attack_facing)
					forward.append({"tip":previous.tip.lerp(point.tip,t),"grip":previous.grip.lerp(point.grip,t)})
				forward.append(point)
		recent = forward
	var _build_start := Time.get_ticks_usec() if profile else 0
	drawn_layers = SHAPE.build(recent,index,vfx_strength,shrink)
	if profile:
		build_us = Time.get_ticks_usec()-_build_start
	# The grounded stroke may touch the floor; its visual mass must not draw
	# through it. This clips only VFX triangles, never hitboxes or movement.
	for layer in drawn_layers:
		var verts: PackedVector2Array = layer.vertices
		for i in verts.size():
			var vertex := verts[i]
			vertex.y = minf(0,vertex.y)
			verts[i] = vertex
		layer.vertices = verts
	last_ribbon_area = 0
	if not drawn_layers.is_empty():
		var poly: PackedVector2Array = drawn_layers[1].polygon
		for i in poly.size(): last_ribbon_area += poly[i].cross(poly[(i+1)%poly.size()])
		last_ribbon_area = absf(last_ribbon_area)*.5
	queue_redraw()

func _draw() -> void:
	if not vfx_enabled or not busy(): return
	var _draw_start := Time.get_ticks_usec() if profile else 0
	for layer in drawn_layers:
		# A projected stroke can double back. Filled strip triangles avoid an
		# invalid self-intersecting polygon without replacing the real trajectory.
		var verts: PackedVector2Array = layer.vertices
		if verts.is_empty(): continue
		if batched_draw:
			# One batched triangle-array command per layer instead of one per triangle.
			RenderingServer.canvas_item_add_triangle_array(
				get_canvas_item(),layer.indices,verts,layer.colors)
		else:
			# Legacy lab reference path: identical triangles, one polygon each.
			var color: Color = layer.color
			var idx: PackedInt32Array = layer.indices
			var i := 0
			while i + 2 < idx.size():
				draw_colored_polygon(
					PackedVector2Array([verts[idx[i]],verts[idx[i+1]],verts[idx[i+2]]]),color)
				i += 3
	if profile:
		draw_us = Time.get_ticks_usec()-_draw_start

func _on_whoosh(strike: int) -> void:
	if is_instance_valid(impact_vfx):
		impact_vfx.sound("whoosh_%d" % (strike + 1))

func _on_contact_feedback(event: Dictionary, victim: Node) -> void:
	if not is_instance_valid(impact_vfx):
		return
	var metal := false
	if victim != null:
		var armor: Variant = victim.get("armor")
		metal = armor != null and bool(armor)
	impact_vfx.burst(event.position, attack_facing, int(event.strike), metal, int(event.hp_after) <= 0, int(event.damage))
