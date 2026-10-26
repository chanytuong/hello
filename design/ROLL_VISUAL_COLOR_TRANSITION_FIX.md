# Roll colour and transition fix

2026-10-25 · Godot 4.7.2 · live `motion_swap_lab.tscn` and legacy `scenes/main.tscn`

## Symptoms

- The live roll looked pale/grey against the dark RUN/IDLE character.
- Jump → roll and land → roll could show a stale jump/land pose or a body overlap on entry.

## Actual causes

1. **The V03 sheet is a different, lighter palette.** It ships with 21 opaque colours that are lighter and cooler than the RUN atlas. The explicit `modulate = Color(0.84, 0.765, 0.739, 1.0)` was already present in `iven_movement_visual.gd`, but multiplying the grey/cool sheet by a warm tint only produced a darker grey. The roll still did not share RUN’s navy/cloth palette.
2. **State entry did not explicitly reset the drawing.** The live preview has one `AnimatedSprite2D`, not separate jump/roll sprites, so it could not stack two authored frames, but the previous drawing was not explicitly stopped before the new clip. The legacy `ColorRect` body also had to be kept hidden on every path.

## Fix

- Added `scripts/iven_roll_palette.gd`. At load time it collects the live RUN palette and remaps every opaque V03 roll colour to the nearest RUN colour. The target is pre-divided by `ROLL_MODULATE`, so the controller’s explicit Palette B modulate lands on the RUN colour at draw time. Source PNGs, anchors and frame counts are untouched.
- Applied the normalisation in:
  - `scripts/iven_movement_visual.gd` (live preview; ground/air, right/left);
  - `scripts/player.gd` (legacy `main.tscn` sprite path);
  - `scripts/lab/roll_test_lab.gd` (visual QA consistency).
- Kept the explicit `body.modulate = Color(0.84, 0.765, 0.739, 1.0)` on roll frames and `sprite.modulate = ROLL_MODULATE` on the legacy path.
- Hardened state entry in `iven_movement_visual.gd`: `_enter_state()` stops the old drawing, clears to frame 0, hides the legacy `ColorRect`, and the normal sampler applies the new clip in the same physics tick. `body.texture_filter` is explicitly `TEXTURE_FILTER_NEAREST`; the legacy sprite is also reasserted visible/nearest-filtered and the old body hidden each update. The movement path does not force `body.visible` while an M1/crowbar overlay is hiding it, so combat presentation is untouched.
- No movement tuning, combat logic, damage, hitstop, knockback, or roll distance changed. `roll_speed = 400`, `roll_duration = 0.50`, and the ~200 px travel remain.

## Verification

```powershell
$godot = "C:\Users\Aloha\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
& $godot --headless --fixed-fps 60 --path E:\neverlookback -s res://tests/test_roll_visual_fixes.gd
& $godot --headless --fixed-fps 60 --path E:\neverlookback -s res://tests/test_roll_visual_transitions.gd
& $godot --headless --fixed-fps 60 --path E:\neverlookback -s res://tests/test_movement_integration.gd
& $godot --headless --fixed-fps 60 --path E:\neverlookback -s res://tests/test_foundation_repair.gd
& $godot --headless --fixed-fps 60 --path E:\neverlookback -s res://tests/test_crowbar_combo_feel.gd
```

| Gate | Result |
|---|---:|
| `test_roll_visual_fixes.gd` | **24 / 0**, 66 samples |
| `test_roll_visual_transitions.gd` | **31 / 0**, 457 samples |
| `test_movement_integration.gd` | **176 / 0**, 2032 samples |
| `test_foundation_repair.gd` | **38 / 0** |
| `test_crowbar_combo_feel.gd` | **43 / 0** |
| `labs/motion_swap_lab.tscn` smoke | exit 0, no script errors |
| `scenes/main.tscn` smoke | exit 0, no script errors |
| `scripts/lab/roll_test_scene.tscn` smoke | exit 0, no script errors |

The focused gate proves, on both jump→air-roll and land→ground-roll:

- the entry update is already the matching roll clip;
- the active drawing is frame 0;
- exactly one body is visible;
- no jump/land clip leaks into the roll;
- every sampled frame is nearest-filtered;
- every roll frame keeps the explicit Palette B modulate;
- the rendered roll palette is within highlight-clipping tolerance of the live RUN palette, on both facings.

The legacy path was also sampled directly: its 15 ground + 7 air frames match the legacy RUN palette within **0.89/255** after the modulate.

## Evidence

- `artifacts/roll_visual_fixes/jump_to_air_roll_entry.png` — frames 10–16 around air-roll entry.
- `artifacts/roll_visual_fixes/land_to_ground_roll_entry.png` — frames 50–56 around land-to-ground-roll entry.
- `artifacts/roll_visual_fixes/results.json` — focused samples and assertions.
- `artifacts/roll_visual_transition/after/frames/` — 457 captured transition frames from the existing 4× replay.

Non-headless capture uses `--capture`; deterministic gates use `--headless --fixed-fps 60`.
