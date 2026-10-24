extends RefCounted
## Solid variable-area ribbons, not widened lines. Actual tip/grip samples are
## the geometric contract. Every vertex is quantized to the native pixel grid.
##
## Geometry is emitted as one flat triangle soup per layer so the whole ribbon
## can be submitted with a single canvas draw command instead of one command
## (and one polygon triangulation) per triangle.
const WIDTHS := [Vector3(7,9,12),Vector3(11,14,17),Vector3(15,18,22)]
const EDGE := Color("18212c")
const BODY := Color("7c9198")
const LIGHT := Color("e8aa70")

static func build(points: Array, strike: int, strength: int, shrink := 1.0) -> Array:
	if points.size() < 2 or shrink <= 0: return []
	var samples: Array = []
	var total := 0.0
	for i in range(1,points.size()): total += points[i].tip.distance_to(points[i-1].tip)
	if total < 2: return []
	var walked := 0.0
	for i in range(1,points.size()):
		var a: Dictionary = points[i-1]
		var b: Dictionary = points[i]
		var distance: float = a.tip.distance_to(b.tip)
		var steps := maxi(2,ceili(distance/3.0))
		for j in range(steps):
			var t := float(j)/steps
			var tip: Vector2 = a.tip.lerp(b.tip,t)
			var grip: Vector2 = a.grip.lerp(b.grip,t)
			var previous_tip: Vector2 = points[i-2].tip if i > 1 else a.tip
			var next_tip: Vector2 = points[i+1].tip if i+1 < points.size() else b.tip
			var tangent_a: Vector2 = (b.tip-previous_tip).normalized()
			var tangent_b: Vector2 = (next_tip-a.tip).normalized()
			var tangent: Vector2 = tangent_a.lerp(tangent_b,t).normalized()
			var normal := tangent.orthogonal()
			if normal.dot(grip-tip) < 0: normal = -normal
			var u := (walked+distance*t)/total
			var taper := pow(maxf(0,sin(PI*u)),0.80)
			var width: float = WIDTHS[clampi(strength,0,2)][clampi(strike,0,2)]*taper*shrink
			# An asymmetric inner boundary makes a compact swept wedge/crescent.
			# Keep a native-pixel gap from the current steel silhouette. The fill
			# reads as a swept shape outside the hook path, not a luminous blade.
			samples.append({"outer":tip-normal*(width+1.5),"normal":normal,"width":width,"u":u})
		walked += distance
	samples.append({"outer":points[-1].tip,"normal":Vector2.ZERO,"width":0.0,"u":1.0})
	var layers: Array = []
	for layer in 3:
		var polygon := PackedVector2Array()
		for p in samples:
			var offset: float = -1.0 if layer == 0 else 0.0
			polygon.append((p.outer+p.normal*offset).round())
		for i in range(samples.size()-1,-1,-1):
			var p: Dictionary = samples[i]
			var width: float = p.width+(1.0 if layer == 0 else 0.0)
			if layer == 2: width *= 0.28
			polygon.append((p.outer+p.normal*width).round())
		# Indexed strip mesh: reuse the polygon's 2N boundary points instead of
		# duplicating 3 vertices per triangle. The triangle list (and therefore
		# the rasterized pixels) is identical; only the vertex buffer shrinks.
		var vertices := polygon.duplicate()
		var indices := PackedInt32Array()
		var count := samples.size()
		var last := polygon.size()-1
		for i in range(count-1):
			var a := polygon[i]
			var b := polygon[i+1]
			var c := polygon[last-1-i]
			var d := polygon[last-i]
			if absf((b-a).cross(d-a)) > .01:
				indices.append(i)
				indices.append(i+1)
				indices.append(last-i)
			if absf((c-b).cross(d-b)) > .01:
				indices.append(i+1)
				indices.append(last-1-i)
				indices.append(last-i)
		var color: Color = [EDGE,BODY,LIGHT][layer]
		var colors := PackedColorArray()
		colors.resize(vertices.size())
		colors.fill(color)
		layers.append({
			"polygon":polygon,
			"vertices":vertices,
			"indices":indices,
			"colors":colors,
			"tri_count":indices.size()/3,
			"color":color,
		})
	return layers
