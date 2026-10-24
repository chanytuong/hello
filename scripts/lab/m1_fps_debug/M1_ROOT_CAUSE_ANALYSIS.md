# M1 Crowbar FPS Drop - Root Cause Analysis

**Project:** NEVERLOOKBACK  
**Scene under test:** `scripts/lab/m1_fps_test.tscn` (isolated flat floor, static camera, one PATROL dummy; five in stress mode)  
**Production path exercised:** `scenes/player.tscn` -> `scripts/combat/m1_crowbar.gd` -> `scripts/combat/slash_shape.gd`  
**Host:** Godot 4.7.2 stable, GL Compatibility, ANGLE / Intel HD Graphics 4600 (D3D11), 1920x1080 display at 75 Hz  
**Measurement modes:** `--mode=bench` (vsync off, precise wall-clock frame times, JSON) and `--mode=record` (vsync on, live HUD, external video)

## 1. Verdict

**Root cause category: A/B - M1 slash-ribbon VFX submission overload.**

The M1 crowbar ribbon was drawn as **one `draw_colored_polygon()` call per triangle**. At the densest authored poses the ribbon contains **253-292 triangles across three layers**, so a single M1 frame queued roughly 250 individual canvas polygons. That produced **146 draw calls at a 255-triangle frame and up to 330 draw calls in the M1 phase** (idle/run baseline: 38-40), with intermittent **200-380 ms frame stalls** on the ANGLE/Intel path.

The stalls are the user-visible problem. The steady-state M1 frame cost was already acceptable: the median M1 frame is ~10 ms both before and after. The old path's **average** was pulled down by a small number of 200-380 ms stalls, which is exactly what "the attack hitches" feels like.

## 2. Evidence

### 2.1 Isolated reproduction

Fixed automated timeline, identical in every run:

```
WARMUP 1.5 s -> IDLE 3.0 s -> RUN 3.0 s -> M1 combo 4.0 s -> DONE 1.0 s
```

The deterministic auto-driver calls the production `combo._start()` and sets `combo.pending` at the authored chain ages, so a stall cannot silently drop a buffered follow-up. Every run recorded 9 strikes (`3/3/3`) and 9 hits on one dummy (15 hits in stress mode), so the before/after load is the same.

### 2.2 A/B switches (lab harness only)

| Run | M1 avg | M1 median | M1 max | Min FPS | Max draws | Peak tris |
|---|---:|---:|---:|---:|---:|---:|
| `base` (all M1 VFX on) | **19.77 ms** | 6.92 ms | **247.45 ms** | **4.0** | **330** | 292 |
| `novfx` (ribbon off) | **7.39 ms** | 7.21 ms | **14.35 ms** | **69.7** | 42 | 0 |
| `nohit` (damage off, ribbon on) | 24.52 ms | 7.20 ms | 275.14 ms | 3.6 | 302 | 264 |
| `noimpact` (impact FX hidden) | 27.01 ms | 7.70 ms | 291.32 ms | 3.4 | 330 | 292 |

`novfx` removes every stall and drops draw calls to the idle baseline. `nohit` and `noimpact` still stall, so hit queries, hitstop and impact particles are **not** causal. This isolates the ribbon itself.

### 2.3 Correlation during M1

Across the M1 phase of the base runs:

| Signal | Pearson r vs frame time |
|---|---:|
| Draw calls | **+0.81 to +0.95** |
| Canvas primitives | +0.73 to +0.88 |
| Ribbon triangles | +0.29 to +0.66 |
| Node count | 0.00 |
| Process / physics time | weak / negative |

The triangle correlation is weaker than the draw-call correlation because a 300 ms stall outlives the frame that queued the triangles: the next sample can show `tris = 0` while the renderer is still catching up. Draw calls track the stall much more tightly.

### 2.4 Code path

`scripts/combat/m1_crowbar.gd::_draw()` (before):

```gdscript
for layer in drawn_layers:
    for triangle in layer.triangles:
        draw_colored_polygon(triangle, layer.color)
```

`scripts/combat/slash_shape.gd::build()` (before) allocated one `PackedVector2Array` per triangle, per layer, every frame. At the densest pose that is 253-292 small arrays and 253-292 canvas polygon submissions per frame, each of which Godot must triangulate and feed to ANGLE.

The ribbon is emitted for samples `[2..7]`, `[4..10]` and `[13..22]` of the three strikes, which is why the stalls cluster around the active slash and disappear between strikes.

### 2.5 Categories ruled out

| Category | Why it is not the cause |
|---|---|
| C - physics / collision | Physics time stays ~2-6 ms; `nohit` still stalls. |
| D - audio / impact feedback | `noimpact` and `nofeedback` still stall; audio voices are bounded at 6. |
| E - shader compilation | No new shader is introduced by M1; stalls repeat on every strike, not only the first. |
| F - scene / node explosion | Lab scene has 48 nodes; node count is flat through the stall. |
| G - garbage collection | Allocations are small per frame; the stall scales with draw submissions, not allocation volume. |
| H - display / vsync | Bench runs use vsync off; the stall is present in uncapped frame times. |

## 3. Why the fix direction is safe

The ribbon's geometric contract is the authored tip/grip samples. The triangles, colours, floor clipping and z-order are unchanged. Only the **submission format** changes: the same triangles are packed into one indexed vertex buffer per layer and submitted with one `RenderingServer.canvas_item_add_triangle_array()` call per layer. This is a pure batching change, so the approved art (RUN animation, palette B, flame-head overlay, camera `RESEARCH_Y75_P00`, rig) is untouched.

See `M1_FIX_APPLIED.md` for the exact diff and `M1_VISUAL_COMPARE.png` for the 0-pixel visual proof.
