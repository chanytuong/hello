# M1 Crowbar FPS Drop - Reproduction Guide

**Project:** `E:\neverlookback`  
**Test scene:** `res://scripts/lab/m1_fps_test.tscn`  
**Harness:** `scripts/lab/m1_fps_test.gd`  
**Output directory:** `scripts/lab/m1_fps_debug/`

This guide reproduces the controlled A/B, the stress run, the pose snapshots, the recordings and the analysis. Run one Godot instance at a time; close browsers/editors that compete for CPU/GPU if you want clean absolute numbers.

## 1. Environment

| Item | Value used |
|---|---|
| Godot | `C:\Users\Aloha\AppData\Local\Temp\opencode\godot\Godot_v4.7.2-stable_win64_console.exe` |
| Renderer | GL Compatibility, ANGLE fallback on Intel HD Graphics 4600 / D3D11 |
| Display | 1920x1080 @ 75 Hz |
| Game window | 1280x720 client area at screen position `(40,40)` |
| Window title | `NEVERLOOKBACK (DEBUG)` |
| Python | Pillow + `imageio_ffmpeg` installed |
| ffmpeg | `python -c "import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())"` |

The ANGLE fallback warning (`Your video card drivers are known to have low quality OpenGL 3.3 support, switching to ANGLE`) is expected on this host.

## 2. Fixed timeline

Every non-snap run uses the same automated sequence:

```
WARMUP 1.5 s -> IDLE 3.0 s -> RUN 3.0 s -> M1 combo 4.0 s -> DONE 1.0 s
```

- `WARMUP`: scene settles, no recording.
- `IDLE`: one dummy active, player idle; recording starts.
- `RUN`: dummy hidden, player shuttles left/right inside the static frame.
- `M1`: dummy active, player faces right, three fresh M1 combos are started at 0.0 / 1.30 / 2.60 s. The auto-driver calls the production `combo._start()` and sets `combo.pending` at the authored follow-up ages, so a stall cannot silently drop the chain.
- `DONE`: recording stops; JSON is written; the process quits (bench/stress) or quits after the DONE second (record).

A valid run records **9 strikes (3/3/3)** and **9 hits**; stress records **15 hits**. Check `hits` and `strikes` in the JSON before trusting the timing.

## 3. Bench commands

Set these once in PowerShell:

```powershell
$godot = "C:\Users\Aloha\AppData\Local\Temp\opencode\godot\Godot_v4.7.2-stable_win64_console.exe"
$scene = "res://scripts/lab/m1_fps_test.tscn"
$common = @("--path", "E:\neverlookback", "--resolution", "1280x720", "--position", "40,40", $scene, "--")
```

`--mode=bench` disables vsync, records precise wall-clock frame times and writes `bench_<tag>.json`.

### 3.1 Controlled 1-enemy A/B (alternating)

```powershell
for ($i = 1; $i -le 3; $i++) {
  & $godot @common "--mode=bench" "--tag=ab_batch_r$i"
  & $godot @common "--mode=bench" "--tag=ab_legacy_r$i" "--ab=legacy"
}
```

- Batched is the production default; no `--ab` flag is needed.
- `--ab=legacy` sets `combo.batched_draw = false` and uses the retained per-triangle path.
- Alternating the order in the same session is what makes the comparison fair on a noisy host.

### 3.2 Controlled 5-enemy stress A/B

```powershell
for ($i = 1; $i -le 3; $i++) {
  & $godot @common "--mode=stress" "--tag=stress_ab_batch_r$i"
  & $godot @common "--mode=stress" "--tag=stress_ab_legacy_r$i" "--ab=legacy"
}
```

`--mode=stress` forces five dummies and 15 hits, and writes `stress_<tag>.json`. The player's HP is raised so the run completes.

### 3.3 Profile instrumentation

```powershell
& $godot @common "--mode=bench" "--tag=profile_r1" "--profile=1"
```

Adds `build_ms` and `draw_ms` for the ribbon to each row. Production leaves `profile = false`.

### 3.4 Other lab A/B switches

These exist only for diagnosis; they are not part of the fix:

```powershell
& $godot @common "--mode=bench" "--tag=novfx" "--ab=novfx"
& $godot @common "--mode=bench" "--tag=nohit" "--ab=nohit"
& $godot @common "--mode=bench" "--tag=noimpact" "--ab=noimpact"
& $godot @common "--mode=bench" "--tag=nofeedback" "--ab=nofeedback"
```

- `novfx`: ribbon disabled.
- `nohit`: damage disabled, ribbon still drawn.
- `noimpact`: impact FX hidden.
- `nofeedback`: contact feedback and impact FX disabled.

## 4. Pose snapshots (pixel proof)

`--mode=snap` freezes physics, disables damage and impact FX, then steps the production `present()` through authored samples for strike 2 and strike 3. It saves PNGs named `SNAP_strike2_<tag>.png` and `SNAP_strike3_<tag>.png`.

```powershell
& $godot @common "--mode=snap" "--tag=legacy" "--ab=legacy"
& $godot @common "--mode=snap" "--tag=batch"
```

Compare with Pillow, including alpha:

```python
from PIL import Image, ImageChops

base = r"E:\neverlookback\scripts\lab\m1_fps_debug"
for pose in ("strike2", "strike3"):
    a = Image.open(fr"{base}\SNAP_{pose}_legacy.png").convert("RGBA")
    b = Image.open(fr"{base}\SNAP_{pose}_batch.png").convert("RGBA")
    diff = ImageChops.difference(a, b)
    print(pose, "size", a.size, "diff bbox", diff.getbbox())
```

Expected:

```
strike2 size (1280, 720) diff bbox None
strike3 size (1280, 720) diff bbox None
```

`None` means zero differing pixels. `M1_VISUAL_COMPARE.png` is the side-by-side composition of these four images.

## 5. Video and HUD capture

`capture_video.ps1` starts the game, waits for the exact window title, pins the window topmost at `(40,40)` size `1280x720`, minimizes any top-level window covering `(100,100)`, records the desktop rectangle with gdigrab, restores the occluder, then trims the raw capture to the IDLE->DONE sequence using the JSON timestamps.

**Warning:** the script kills existing `Godot_v4.7.2-stable_win64*` processes at start. Do not run it while the editor has unsaved work.

### 5.1 Fixed-build capture (after)

```powershell
powershell -ExecutionPolicy Bypass -File `
  "E:\neverlookback\scripts\lab\m1_fps_debug\capture_video.ps1" `
  -Tag after -Mode record -CaptureSeconds 26 -Fps 60 -Source desktop
```

Produces:

- `M1_FPS_AFTER.mp4` (trimmed, ~10 s)
- `M1_MONITOR_AFTER.png` (saved at peak ribbon density or the 3.5 s fallback)
- `after_capture.json`, `record_after.json`, `after_raw.mp4`, `after_ffmpeg.log`

### 5.2 Legacy capture (before)

```powershell
powershell -ExecutionPolicy Bypass -File `
  "E:\neverlookback\scripts\lab\m1_fps_debug\capture_video.ps1" `
  -Tag before_controlled -Mode record -Ab legacy -CaptureSeconds 26 -Fps 60 -Source desktop
```

Produces `M1_FPS_BEFORE_CONTROLLED.mp4` and `M1_MONITOR_BEFORE_CONTROLLED.png`. The deliverable names were produced by copying:

```powershell
Copy-Item .\M1_FPS_BEFORE_CONTROLLED.mp4 .\M1_FPS_BEFORE.mp4 -Force
Copy-Item .\M1_MONITOR_BEFORE_CONTROLLED.png .\M1_MONITOR_BEFORE.png -Force
```

The original loaded capture from the pre-fix build is preserved as `M1_FPS_BEFORE_LOADED.mp4` / `M1_MONITOR_BEFORE_LOADED.png`.

### 5.3 Stress capture

```powershell
powershell -ExecutionPolicy Bypass -File `
  "E:\neverlookback\scripts\lab\m1_fps_debug\capture_video.ps1" `
  -Tag stress -Mode stress -CaptureSeconds 26 -Fps 60 -Source desktop
```

`-Mode stress` is passed through as `--mode=stress` (five dummies, 15 hits, vsync off). Produces `M1_FPS_STRESS.mp4` and `stress_capture.json`.

### 5.4 Capture notes

- `-Source desktop` is required for the HUD to show real frame times; Movie Maker mode would not.
- `-Source title` is available, but the desktop crop is more reliable when another window overlaps the title bar.
- The video encoder runs at 60 Hz input but the delivered files encode at roughly 22-27 fps due to desktop capture duplication/drops. Use the JSON/HUD for timing, not the container fps.
- If the window is not found, verify the project title is still `NEVERLOOKBACK (DEBUG)` and that the process name matches.
- If the capture is black, check DPI scaling and the `(40,40)` window origin; adjust `-OffsetX/-OffsetY` if Windows scales the window.

## 6. Analysis

`analyze.py` prints phase statistics, the top 15 spikes, Pearson correlations during M1, and frame time by ribbon-triangle bucket.

```powershell
python "E:\neverlookback\scripts\lab\m1_fps_debug\analyze.py" `
  "E:\neverlookback\scripts\lab\m1_fps_debug\bench_ab_batch_r1.json"
```

Example output (batch r1):

```
M1     n= 369 avg=  10.88ms ( 91.9 fps) med=  10.24 p95=  17.80 p99=  21.79 max=   29.72 min_fps= 33.6
...
M1 correlations (Pearson):
  dt_ms vs ribbon_tris    = +0.494
  dt_ms vs draws          = +0.531
...
M1 frame time by ribbon triangle bucket:
  tris 0        n= 246 avg=   9.37ms max=   29.72
  tris 200+     n=  44 avg=  14.03ms max=   25.38
```

For the legacy run, the same analyzer shows the tail:

```
M1     n= 150 avg=  34.06ms ( 29.4 fps) med=  10.32 p95= 164.32 p99= 320.15 max=  331.94 min_fps=  3.0
```

### 6.1 Reading the numbers

- **Average** is dominated by a handful of stalls; **median** shows normal-frame cost.
- **p95/max** are the player-visible hitch metric. The fix is successful when median stays flat and p95/max collapse.
- **Draw calls** should be ~40-50 in M1 on the batched path; the legacy path reaches ~300-330.
- **`ribbon_tris`** is the sum of `tri_count` across the three layers. It should be identical between legacy and batched at the same pose.
- Discard a run if `hits` is not 9 (or 15 in stress), or `strikes` is not `{1:3, 2:3, 3:3}`.
- On a loaded host, IDLE itself can exceed 15 ms. Compare alternating A/B runs from the same session rather than absolute numbers from different days.

## 7. One-command sanity check

```powershell
$godot = "C:\Users\Aloha\AppData\Local\Temp\opencode\godot\Godot_v4.7.2-stable_win64_console.exe"
& $godot --path "E:\neverlookback" --resolution 1280x720 --position 40,40 `
  res://scripts/lab/m1_fps_test.tscn -- --mode=bench --tag=sanity
python "E:\neverlookback\scripts\lab\m1_fps_debug\analyze.py" `
  "E:\neverlookback\scripts\lab\m1_fps_debug\bench_sanity.json"
```

Expected on a reasonably idle host: M1 average ~10-12 ms, max < 40 ms, draw calls 40-50, 9 hits.

## 8. Troubleshooting

| Symptom | Check |
|---|---|
| `bench_<tag>.json` missing | The run did not reach DONE, or the process was killed. Check the console log for `SEQUENCE END`. |
| Hits not 9 / 15 | The combo chain was dropped or the dummy moved. Re-run; do not compare that sample. |
| Legacy and batched show the same draw calls | `--ab=legacy` was not passed, or `batched_draw` was changed in the scene. |
| Snap diff is not zero | Confirm `--tag=legacy --ab=legacy` vs `--tag=batch`, and that no other code changed the ribbon geometry. |
| Video has no HUD | `-Source title` or Movie Maker mode was used; use `-Source desktop`. |
| Video is black/occluded | Another window covers `(40,40)`; the script minimizes the window at `(100,100)`, but a different occluder may need manual handling. |
| Godot process lingers | The capture script kills `Godot_v4.7.2-stable_win64*` at start; close it manually if needed. |

## 9. Artifacts produced by these commands

| Command | JSON | Video/PNG |
|---|---|---|
| `--mode=bench --tag=ab_batch_r1` | `bench_ab_batch_r1.json` | - |
| `--mode=bench --tag=ab_legacy_r1 --ab=legacy` | `bench_ab_legacy_r1.json` | - |
| `--mode=stress --tag=stress_ab_batch_r1` | `stress_stress_ab_batch_r1.json` | - |
| `--mode=stress --tag=stress_ab_legacy_r1 --ab=legacy` | `stress_stress_ab_legacy_r1.json` | - |
| `--mode=bench --tag=profile_r1 --profile=1` | `bench_profile_r1.json` | - |
| `--mode=snap --tag=legacy --ab=legacy` | - | `SNAP_strike2_legacy.png`, `SNAP_strike3_legacy.png` |
| `--mode=snap --tag=batch` | - | `SNAP_strike2_batch.png`, `SNAP_strike3_batch.png` |
| `capture_video.ps1 -Tag after -Mode record` | `record_after.json` | `M1_FPS_AFTER.mp4`, `M1_MONITOR_AFTER.png` |
| `capture_video.ps1 -Tag before_controlled -Mode record -Ab legacy` | `record_before_controlled.json` | `M1_FPS_BEFORE_CONTROLLED.mp4`, `M1_MONITOR_BEFORE_CONTROLLED.png` |
| `capture_video.ps1 -Tag stress -Mode stress` | `stress_stress.json` | `M1_FPS_STRESS.mp4` |
