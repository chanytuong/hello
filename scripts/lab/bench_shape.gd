extends SceneTree
## Micro-benchmark for the ribbon geometry builder (CPU only, headless).

const SHAPE = preload("res://scripts/combat/slash_shape.gd")

func _init() -> void:
	var points: Array = []
	for i in 8:
		points.append({
			"tip": Vector2(0, -i * 12),
			"grip": Vector2(12, -i * 12),
		})
	for i in 200:
		SHAPE.build(points, 1, 1, 1.0)
	var t0 := Time.get_ticks_usec()
	for i in 3000:
		SHAPE.build(points, 1, 1, 1.0)
	var dt := Time.get_ticks_usec() - t0
	var layers: Array = SHAPE.build(points, 1, 1, 1.0)
	var tris := 0
	for layer in layers:
		tris += int(layer.tri_count)
	print("[SHAPEBENCH] build_avg_us=%.2f layers=%d tris=%d verts0=%d idx0=%d" % [
		dt / 3000.0, layers.size(), tris, layers[0].vertices.size(), layers[0].indices.size()])
	quit()
