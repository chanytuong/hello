# M1 Crowbar FPS Drop - Fix Applied

**Project:** NEVERLOOKBACK  
**Fix scope:** M1 slash-ribbon rendering submission only  
**Files changed:** `scripts/combat/slash_shape.gd`, `scripts/combat/m1_crowbar.gd`  
**Production default:** batched path (`batched_draw = true`)  
**Rollback:** set `batched_draw = false` on the M1 combo node, or use `--ab=legacy` in the lab harness

## 1. One-line summary

The ribbon used to submit **one `draw_colored_polygon()` per triangle** - 253-292 polygons per dense frame, across three layers. It now packs the same triangles into **one indexed vertex/index buffer per layer** and submits each layer with **one `RenderingServer.canvas_item_add_triangle_array()` call**. Geometry, colours, floor clipping, layer order and z-order are unchanged; only the submission format changed.

## 2. Before / after

### 2.1 `scripts/combat/slash_shape.gd`

**Before (behaviour):** `build()` returned three layer dictionaries whose `triangles` entry was an `Array` of `PackedVector2Array`, one 3-point array per triangle. Every frame allocated a new array for every triangle, and every triangle became a separate canvas polygon.

**After:** each layer carries a flat, indexed mesh:

```gdscript
var vertices := polygon.duplicate()   # 2N boundary points, shared
var indices := PackedInt32Array()     # 6 indices per quad -> 2 triangles
var colors := PackedColorArray()
colors.resize(vertices.size())
colors.fill(color)
layers.append({
    "polygon": polygon,
    "vertices": vertices,
    "indices": indices,
    "colors": colors,
    "tri_count": indices.size() / 3,
    "color": color,
})
```

The index list is built from the same quad split that the old per-triangle loop used:

```gdscript
for i in range(count-1):
    var a := polygon[i]
    var b := polygon[i+1]
    var c := polygon[last-1-i]
    var d := polygon[last-i]
    if absf((b-a).cross(d-a)) > .01:
        indices.append(i); indices.append(i+1); indices.append(last-i)
    if absf((c-b).cross(d-b)) > .01:
        indices.append(i+1); indices.append(last-1-i); indices.append(last-i)
```

Degenerate triangles are skipped with the same area test as before. The polygon boundary, taper, width table, native-pixel rounding and layer colours are untouched.

### 2.2 `scripts/combat/m1_crowbar.gd`

**Before (behaviour):**

```gdscript
for layer in drawn_layers:
    for triangle in layer.triangles:
        draw_colored_polygon(triangle, layer.color)
```

**After:**

```gdscript
for layer in drawn_layers:
    var verts: PackedVector2Array = layer.vertices
    if verts.is_empty(): continue
    if batched_draw:
        # One batched triangle-array command per layer instead of one per triangle.
        RenderingServer.canvas_item_add_triangle_array(
            get_canvas_item(), layer.indices, verts, layer.colors)
    else:
        # Legacy lab reference path: identical triangles, one polygon each.
        var color: Color = layer.color
        var idx: PackedInt32Array = layer.indices
        var i := 0
        while i + 2 < idx.size():
            draw_colored_polygon(
                PackedVector2Array([verts[idx[i]],verts[idx[i+1]],verts[idx[i+2]]]),color)
            i += 3
```

The legacy branch is retained deliberately. It is the controlled A/B reference and the rollback path; production never selects it unless `batched_draw` is explicitly set to `false`.

Floor clipping in `present()` now edits the shared vertex array:

```gdscript
for layer in drawn_layers:
    var verts: PackedVector2Array = layer.vertices
    for i in verts.size():
        var vertex := verts[i]
        vertex.y = minf(0,vertex.y)
        verts[i] = vertex
    layer.vertices = verts
```

Because the vertices are shared by the triangles that use them, clipping the shared array produces the same clipped triangles as clipping each duplicated triangle independently.

## 3. Why the art is untouched

The authored contract is the tip/grip sample stream, not the submission primitive. The following are byte-for-byte or value-for-value unchanged:

| Element | Status |
|---|---|
| `art/iven/m1_crowbar/attack_metadata.json` | Unchanged |
| Crowbar texture / sprite frames | Unchanged |
| Tip and grip samples, sample ages, combo gates | Unchanged |
| `WIDTHS`, `EDGE`, `BODY`, `LIGHT` | Unchanged |
| Taper (`pow(sin(pi*u), 0.80)`), width scaling, `.round()` pixel quantisation | Unchanged |
| Floor clip (`y = min(0, y)`) | Unchanged |
| Layer order (edge, body, light) and `z_index = -2` | Unchanged |
| Camera `RESEARCH_Y75_P00`, RUN animation, palette B, flame-head overlay, rig | Unchanged |
| Hitboxes, damage, hitstop, knockback, audio, impact FX | Unchanged |

No sprite was downscaled, no VFX was removed, and no approved asset file was edited.

## 4. Why this removes the stalls

`draw_colored_polygon()` accepts an arbitrary polygon, so every call enters Godot's polygon submission path (including triangulation and feeding the renderer) instead of reusing a prepared index buffer. The old path therefore made roughly 250 polygon submissions per dense frame. On this host (Godot 4.7.2 GL Compatibility via ANGLE on Intel HD Graphics 4600 / D3D11) that produced **146 draw calls at a 255-triangle frame, up to 330 draw calls in the M1 phase**, and intermittent **200-380 ms stalls**.

The batched path:

1. builds the ribbon **triangle index list once**, in `slash_shape.build()`, reusing the polygon boundary vertices;
2. uploads **one vertex array + one index array + one colour array per layer**;
3. submits **three canvas commands per frame** instead of 250-292.

Measured effect in the controlled 1-enemy A/B (three alternating runs):

| Metric | Legacy | Batched | Change |
|---|---:|---:|---:|
| M1 average frame time (median of runs) | 34.06 ms | 11.47 ms | **-66.3%** |
| M1 p95 (median of runs) | 186.32 ms | 18.72 ms | **-90.0%** |
| M1 max (median of runs) | 344.19 ms | 30.97 ms | **-91.0%** |
| M1 draw calls | 310-330 | 47 | **-85%** |
| M1 ribbon triangles | 290-292 | 292 | unchanged |

The median frame is essentially unchanged (10.32 ms legacy vs 10.99 ms batched); the fix removes the **tail**, which is what the player perceives as the attack hitching.

## 5. Visual equivalence proof

Two authored poses were stepped through the production `present()`/`_draw()` path with physics frozen and damage disabled:

- `SNAP_strike2_legacy.png` vs `SNAP_strike2_batch.png` (253 triangles)
- `SNAP_strike3_legacy.png` vs `SNAP_strike3_batch.png` (278 triangles)

Both pairs are **0 differing pixels at 1280x720**, comparing RGB and alpha. `M1_VISUAL_COMPARE.png` shows the side-by-side composition and the diff result.

The comparison uses the same authored pose, same frame, same production geometry, and only toggles `batched_draw`. The impact FX and dummy knockback are disabled in snap mode so that only the ribbon draw path can differ.

## 6. Rollback

### Lab

```powershell
& $godot --path "E:\neverlookback" --resolution 1280x720 --position 40,40 `
  res://scripts/lab/m1_fps_test.tscn -- --mode=bench --tag=legacy --ab=legacy
```

`--ab=legacy` sets `combo.batched_draw = false` and uses the retained per-triangle path.

### Production

Set `batched_draw = false` on the `M1Combo` node before its first draw, or change the default in `m1_crowbar.gd`:

```gdscript
var batched_draw := false
```

No save data, resource format or scene serialization depends on this flag. Reverting the two scripts restores the exact pre-fix behaviour.

## 7. Verification performed

- [x] Controlled A/B in the same build: 3 alternating legacy/batched runs, 1 enemy.
- [x] Controlled stress A/B: 3 alternating legacy/batched runs, 5 enemies, 15 hits each.
- [x] Historical loaded before/after runs: 3 each, 9 hits each.
- [x] Pixel diff: 0 pixels at strike 2 and strike 3.
- [x] Production path exercised: `scenes/player.tscn` with `m1_crowbar_enabled = true`.
- [x] No approved art, animation, camera or rig file modified.
- [x] No commits made.

See `M1_FINAL_REPORT.md` for the full results and `M1_REPRODUCTION.md` for the exact commands.
