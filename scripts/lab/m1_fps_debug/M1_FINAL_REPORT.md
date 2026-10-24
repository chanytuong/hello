# M1 Crowbar FPS Drop - Final Report

**Project:** NEVERLOOKBACK  
**Scene:** `scripts/lab/m1_fps_test.tscn` (isolated flat floor, static camera, 1 PATROL dummy; 5 in stress mode)  
**Production path:** `scenes/player.tscn` -> `scripts/combat/m1_crowbar.gd` -> `scripts/combat/slash_shape.gd`  
**Host:** Godot 4.7.2 stable, GL Compatibility, ANGLE / Intel HD Graphics 4600 (D3D11), 1920x1080 @ 75 Hz  
**Status:** Fix implemented and measured. Stopping for human review; no commits made.

## 1. Verdict

**Root cause: category A/B - M1 slash-ribbon VFX submission overload.**

The ribbon was submitted as **one `draw_colored_polygon()` per triangle**. At the densest authored poses that is **253-292 triangles across three layers**, so a single M1 frame queued roughly 250 individual canvas polygons. On this ANGLE/Intel path that produced **146 draw calls at a 255-triangle frame, up to 330 draw calls across the M1 phase** (idle/run baseline: 38-40), with intermittent **200-380 ms stalls**.

The fix batches each ribbon layer into **one indexed triangle-array submission**. In the controlled 1-enemy A/B it reduced M1 average frame time by **66.3%**, p95 by **90.0%**, and maximum frame time by **91.0%**, with **0 differing pixels** at the two compared authored poses.

The median M1 frame is essentially unchanged (10.32 ms legacy vs 10.99 ms batched). The bug was **tail latency**, not steady-state throughput: a few 200-380 ms stalls dragged the average down and produced the visible attack hitch.

## 2. What changed

Two production scripts:

- `scripts/combat/slash_shape.gd` - builds one flat, indexed mesh per ribbon layer (shared boundary vertices, explicit triangle indices, per-vertex colour array) instead of one 3-point array per triangle.
- `scripts/combat/m1_crowbar.gd` - `_draw()` submits each layer with one `RenderingServer.canvas_item_add_triangle_array()` call. The legacy per-triangle loop is retained behind `batched_draw` for A/B and rollback.

Unchanged: authored tip/grip samples, width table, taper, pixel rounding, colours, floor clipping, layer order, `z_index = -2`, hitboxes, damage, hitstop, audio, impact FX, camera `RESEARCH_Y75_P00`, RUN animation, palette B, flame-head overlay and rig. See `M1_FIX_APPLIED.md` for the exact diff and rollback.

## 3. Test setup

Fixed timeline, identical for every run:

```
WARMUP 1.5 s -> IDLE 3.0 s -> RUN 3.0 s -> M1 combo 4.0 s -> DONE 1.0 s
```

- `--mode=bench`: vsync off, precise wall-clock frame times, JSON output.
- `--mode=record`: vsync on, live HUD, external desktop capture.
- `--mode=stress`: five stationary melee dummies, 15 hits per run, vsync off, JSON output.
- `--mode=snap`: physics frozen, damage and impact FX disabled, production `present()` stepped through authored samples for pixel comparison.
- The deterministic auto-driver calls the production `combo._start()` and sets `combo.pending` at the authored chain ages. Every measured run recorded **9 strikes (3/3/3)** and **9 hits** (15 hits in stress), so before/after load is the same.
- Controlled A/B toggles are lab-only: `--ab=legacy` selects the per-triangle path; the batched path is the production default.

The primary proof is the **controlled A/B in the same build**, alternating legacy and batched three times each. Historical loaded before/after runs are supporting worst-case evidence, not a controlled comparison.

## 4. Results

### 4.1 Controlled 1-enemy A/B

| Run | M1 avg | M1 median | M1 p95 | M1 max | Max draws | Peak tris | Hits |
|---|---:|---:|---:|---:|---:|---:|---:|
| batch r1 | 10.88 ms | 10.24 ms | 17.80 ms | 29.72 ms | 47 | 292 | 9 |
| batch r2 | 12.37 ms | 11.82 ms | 22.40 ms | 30.97 ms | 47 | 292 | 9 |
| batch r3 | 11.47 ms | 10.99 ms | 18.72 ms | 36.19 ms | 47 | 292 | 9 |
| **batch median of runs** | **11.47 ms (87.2 fps)** | **10.99 ms** | **18.72 ms** | **30.97 ms** | **47** | **292** | **9** |
| legacy r1 | 34.06 ms | 10.32 ms | 164.32 ms | 331.94 ms | 310 | 270 | 9 |
| legacy r2 | 32.71 ms | 10.12 ms | 186.32 ms | 383.19 ms | 330 | 290 | 9 |
| legacy r3 | 42.92 ms | 10.91 ms | 223.90 ms | 344.19 ms | 330 | 290 | 9 |
| **legacy median of runs** | **34.06 ms (29.4 fps)** | **10.32 ms** | **186.32 ms** | **344.19 ms** | **330** | **290** | **9** |

Change (median of runs): **-66.3% average**, **-90.0% p95**, **-91.0% maximum**, **-85% draw calls**. Median frame time is flat, confirming the fix removes stalls rather than changing normal rendering cost.

Source: `bench_ab_batch_r1..3.json`, `bench_ab_legacy_r1..3.json`.

### 4.2 Controlled 5-enemy stress A/B

| Run | M1 avg | M1 median | M1 p95 | M1 max | Max draws | Peak tris | Hits |
|---|---:|---:|---:|---:|---:|---:|---:|
| batch r1 | 12.28 ms | 11.72 ms | 21.40 ms | 32.38 ms | 50 | 292 | 15 |
| batch r2 | 12.58 ms | 11.61 ms | 22.49 ms | 42.92 ms | 50 | 292 | 15 |
| batch r3 | 13.93 ms | 12.82 ms | 25.19 ms | 40.50 ms | 50 | 292 | 15 |
| **batch median of runs** | **12.58 ms (79.5 fps)** | **11.72 ms** | **22.49 ms** | **40.50 ms** | **50** | **292** | **15** |
| legacy r1 | 40.74 ms | 11.04 ms | 229.44 ms | 359.80 ms | 324 | 284 | 15 |
| legacy r2 | 39.23 ms | 10.11 ms | 223.09 ms | 347.20 ms | 312 | 272 | 15 |
| legacy r3 | 47.18 ms | 12.50 ms | 281.31 ms | 360.11 ms | 297 | 255 | 15 |
| **legacy median of runs** | **40.74 ms (24.5 fps)** | **11.04 ms** | **229.44 ms** | **359.80 ms** | **324** | **284** | **15** |

Change (median of runs): **-69.1% average**, **-90.2% p95**, **-88.7% maximum**, **-85% draw calls**. All three controlled stress runs average **71.8-81.4 fps**, comfortably above the 40 fps gate.

Source: `stress_stress_ab_batch_r1..3.json`, `stress_stress_ab_legacy_r1..3.json`.

### 4.3 Historical loaded before/after

These runs compare the original code against the final code in the loaded production-like lab, but were taken at different times, so host load is not controlled. They are supporting worst-case evidence.

| Run | M1 avg | M1 median | M1 p95 | M1 max | Max draws | Hits |
|---|---:|---:|---:|---:|---:|---:|
| before r1 | 101.75 ms | 16.67 ms | 545.25 ms | 859.64 ms | 332 | 9 |
| before r2 | 99.98 ms | 17.40 ms | 570.34 ms | 688.03 ms | 330 | 9 |
| before r3 | 98.03 ms | 17.51 ms | 552.98 ms | 727.90 ms | 312 | 9 |
| **before median** | **99.98 ms** | **17.40 ms** | **552.98 ms** | **727.90 ms** | **330** | **9** |
| after r1 | 19.98 ms | 16.97 ms | 40.37 ms | 50.08 ms | 47 | 9 |
| after r2 | 23.95 ms | 18.87 ms | 49.81 ms | 67.25 ms | 47 | 9 |
| after r3 | 20.52 ms | 17.46 ms | 41.76 ms | 54.73 ms | 47 | 9 |
| **after median** | **20.52 ms** | **17.46 ms** | **41.76 ms** | **54.73 ms** | **47** | **9** |

Change (median): **-79.5% average**, **-92.4% p95**, **-92.5% maximum**, draw calls 330 -> 47. Again the median is flat (17.40 -> 17.46 ms); the 700+ ms tail is gone.

Source: `bench_before_r1..3.json`, `bench_after2_r1..3.json`.

### 4.4 Clean-host profile

`bench_profile_r1.json` (profile instrumentation on, cleaner host):

- M1 average **9.83 ms / 101.7 fps**, median 8.79 ms, p95 16.85 ms, max **21.47 ms**.
- 200+ triangle frames: average **13.42 ms**, max 19.11 ms.
- Ribbon `build_ms` at 200+ triangles: **0.665 ms average** (1.118 ms max).
- Ribbon `draw_ms` at 200+ triangles: **0.653 ms average** (1.311 ms max).
- M1 draw calls: **40-47**; IDLE median 7.63 ms.

The remaining cost at high triangle counts is small and split roughly evenly between mesh build and submission; it is no longer a stall source.

### 4.5 Visible HUD evidence

| Screenshot | Peak frame | M1 tris | Draw calls | Process |
|---|---:|---:|---:|---:|
| `M1_MONITOR_BEFORE.png` (controlled legacy) | **215.0 ms** | 255 | **235** | 40.36 ms |
| `M1_MONITOR_AFTER.png` (fixed) | **23.2 ms** | 193 | **45** | 18.24 ms |

The screenshots were taken at slightly different ribbon densities (255 vs 193 triangles), so they are illustrative HUD evidence, not a controlled timing comparison. The controlled A/B tables above are the primary metric.

### 4.6 Pixel equivalence

| Pose | Triangles | Differing pixels (RGB + alpha, 1280x720) |
|---|---:|---:|
| Strike 2 | 253 | **0** |
| Strike 3 | 278 | **0** |

`M1_VISUAL_COMPARE.png` shows the four panels and the diff result. The snapshots use the same authored pose and production geometry, with physics frozen and damage/impact FX disabled, so only `batched_draw` differs.

## 5. Stop-condition checklist

| Condition | Result | Evidence |
|---|---|---|
| Improvement < 10% -> stop | **Pass** | 66.3% lower average and 90.0% lower p95 in the controlled 1-enemy A/B |
| Stress FPS < 40 -> stop | **Pass with one caveat** | Controlled stress: 71.8-81.4 fps average. One loaded-host repeat averaged 39.1 fps (see caveat below) |
| Art breaks -> stop | **Pass** | 0 differing pixels at two poses; no approved asset or camera/rig/animation file modified |
| Root cause unknown -> stop | **Pass** | `novfx` removes the stalls; `nohit`/`noimpact` still stall; draw-call correlation +0.81 to +0.95; code path isolated to per-triangle ribbon submission |

### Stress caveat

A separate loaded-host stress repeat (`stress_stress_final_r1..3.json`) averaged **47.3 / 39.1 / 60.2 fps**. The 39.1 fps run is marginally below the literal 40 fps gate. Its M1 max was 71.29 ms with only **50 draw calls**, and its IDLE was also degraded by concurrent host load; the ribbon was no longer the bottleneck. I am reporting this rather than hiding it. The controlled stress A/B, which alternates legacy and batched in the same build, is the fair comparison and is comfortably above 40 fps. If the gate is meant literally for every run on a loaded host, this is the one item that needs your acceptance.

## 6. Caveats

- The host is shared and noisy. IDLE ranged from ~7.6 ms (clean) to ~20 ms (loaded). The controlled alternating A/B is the primary proof; absolute numbers will vary on other machines.
- The historical loaded before/after runs were not interleaved, so they support the direction and magnitude but are not the controlled proof.
- The desktop recordings are real-time gdigrab captures at 60 Hz and encode at roughly 22-27 fps. Use the JSON and HUD for timing; use the video for qualitative smoothness and the visible stall.
- `M1_FPS_BEFORE.mp4` is the controlled legacy capture (same per-triangle path, same geometry). The original loaded capture is preserved as `M1_FPS_BEFORE_LOADED.mp4`.
- No commits were made. Production scripts are modified in the working tree; the M1 combat/lab files are untracked.

## 7. Deliverables

All in `E:\neverlookback\scripts\lab\m1_fps_debug\`:

| File | Description |
|---|---|
| `M1_FPS_BEFORE.mp4` | Controlled legacy capture, 10.7 s, 9 hits |
| `M1_MONITOR_BEFORE.png` | Legacy HUD: peak 215.0 ms, 255 tris, 235 draws |
| `M1_ROOT_CAUSE_ANALYSIS.md` | Root-cause evidence and category ruling |
| `M1_FIX_APPLIED.md` | Diff, art-safety argument, rollback |
| `M1_FPS_AFTER.mp4` | Fixed capture, 10.0 s, 9 hits |
| `M1_VISUAL_COMPARE.png` | Strike 2 / strike 3 side-by-side, 0-pixel diff |
| `M1_FPS_STRESS.mp4` | Five dummies, 15 hits, fixed build |
| `M1_FINAL_REPORT.md` | This report |
| `M1_REPRODUCTION.md` | Exact commands and analyzer usage |

Supporting evidence: `bench_ab_batch_r1..3.json`, `bench_ab_legacy_r1..3.json`, `stress_stress_ab_batch_r1..3.json`, `stress_stress_ab_legacy_r1..3.json`, `bench_before_r1..3.json`, `bench_after2_r1..3.json`, `bench_profile_r1.json`, `record_before_controlled.json`, `record_after.json`, `stress_stress.json`, `M1_MONITOR_COMPARE.png`.

## 8. Recommendation

Accept the batched submission as the production path. It removes the 200-380 ms M1 stalls, preserves the approved art at pixel level, and leaves the normal-frame median unchanged. If desired, run one confirmation pass on an otherwise idle host before merging; the expected result is an M1 average near 10-12 ms and a max below ~40 ms with one enemy.

No further changes are proposed in this task. Human review is the next step.
