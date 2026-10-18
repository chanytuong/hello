extends Node2D
## Port of existing V3 spring controller. Same 12 authored cels and durations.
const HOLDS := [0.08, 0.07, 0.07, 0.06, 0.07, 0.08, 0.09, 0.08, 0.07, 0.06, 0.07, 0.08]
var sprite := Sprite2D.new()
var clock: float = 0.0
var bend: float = 0.0
var bend_velocity: float = 0.0
var vertical: float = 0.0
var vertical_velocity: float = 0.0
var branch: float = 0.0
var branch_velocity: float = 0.0
var cel: int = 0
var _material := ShaderMaterial.new()
var _sources: Array[PackedByteArray] = []
var ground_extent: float = 0.0
var angle_limited: bool = false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = preload("res://art/iven/movement/flame_atlas.png")
	var atlas := sprite.texture.get_image()
	atlas.convert(Image.FORMAT_RGBA8)
	for i in 12:
		_sources.append(atlas.get_region(Rect2i((i%6)*36, (i/6)*36, 36, 36)).get_data())
	sprite.centered = false
	sprite.offset = Vector2(-18, -31)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, 36, 36)
	_material.shader = preload("res://shaders/iven_flame.gdshader")
	sprite.material = _material
	add_child(sprite)

func step(velocity: Vector2, acceleration: Vector2, dt: float) -> void:
	# Convert world drag into the neck basis during the roll. Root never deforms.
	var v := velocity.rotated(-rotation)
	var a := acceleration.rotated(-rotation)
	var tx := clampf(-v.x / 65.0 - a.x / 400.0, -6.0, 6.0)
	var ty := clampf(-v.y / 250.0 - a.y / 4000.0, -3.0, 3.0)
	var n := maxi(1, ceili(dt * 240.0))
	var h := dt / float(n)
	var w := TAU * 4.2
	var wy := TAU * 5.0
	var wb := TAU * 3.3
	for i in n:
		bend_velocity += (w*w*(tx-bend) - 2.0*0.57*w*bend_velocity)*h
		bend += bend_velocity*h
		vertical_velocity += (wy*wy*(ty-vertical) - 2.0*0.68*wy*vertical_velocity)*h
		vertical += vertical_velocity*h
		branch_velocity += (wb*wb*(bend-branch) - 2.0*0.66*wb*branch_velocity)*h
		branch += branch_velocity*h
	clock += dt * (1.0 + 0.12*clampf(absf(v.x)/200.0, 0.0, 1.0))
	var t := fmod(clock, 0.88)
	cel = 0
	while cel < 11 and t >= HOLDS[cel]:
		t -= HOLDS[cel]
		cel += 1
	var origin := Vector2((cel % 6)*36, (cel / 6)*36)
	sprite.region_rect = Rect2(origin, Vector2(36, 36))
	_material.set_shader_parameter("cel_origin", origin)
	_material.set_shader_parameter("bend", clampf(bend, -6.4, 6.4))
	_material.set_shader_parameter("vertical", clampf(vertical, -3.2, 3.2))
	_material.set_shader_parameter("branch", clampf(branch, -6.4, 6.4))

func limit_at_ground(clearance: float) -> void:
	# Minimal attachment constraint: keep existing flame pixels above the support
	# plane while the neck root stays fixed. Upper art/controller stays unchanged.
	var points := PackedVector2Array()
	var b0 := clampf(bend, -6.4, 6.4)
	var br := clampf(branch, -6.4, 6.4)
	var v := clampf(vertical, -3.2, 3.2)
	for y in 36:
		var sy := y if y >= 28 else int(floor((y - 28.0*v/18.0)/(1.0-v/18.0) + 0.5))
		if sy < 0 or sy >= 36:
			continue
		var height := clampf((28.0 - sy)/18.0, 0.0, 1.0)
		for x in 36:
			var b := 0.65*b0 + 0.35*br if x > 19 else b0
			var sx := x - int(floor(b*pow(height, 1.22) + 0.5))
			if sx >= 0 and sx < 36 and _sources[cel][(sy*36+sx)*4+3] > 0:
				points.append(Vector2(x-18+0.5, y-31+0.5))
	var target := wrapf(rotation, -PI, PI)
	angle_limited = _extent(points, target) > clearance - 1.0
	if angle_limited:
		var low := 0.0
		var high := 1.0
		for i in 12:
			var mid := (low + high)*0.5
			if _extent(points, target*mid) <= clearance - 1.0:
				low = mid
			else:
				high = mid
		rotation = target*low
	ground_extent = _extent(points, rotation)

func _extent(points: PackedVector2Array, angle: float) -> float:
	var result := -100.0
	var sn := sin(angle)
	var cs := cos(angle)
	for p in points:
		result = maxf(result, p.x*sn + p.y*cs)
	return result
