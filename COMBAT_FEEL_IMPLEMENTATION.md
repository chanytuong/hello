# Combat Feel Implementation — V02 Jump, V03 Roll, and Crowbar Chaining

**Status:** implemented and verified on 2026-10-25.

**Live scene:** `res://labs/motion_swap_lab.tscn` is the project main scene and the live integration target (`movement_preview = true`, `m1_crowbar_enabled = true`, `M1Combo` mounted on the player). `res://scenes/main.tscn` is the legacy path; it still boots and now uses the same V02 jump and V03 roll sheets through `player._update_sprite()`.

**No Blender assets were re-rendered.** The approved V02/V03 PNG sheets and anchors are loaded as-is. The V03 sheet’s lighter 21-colour B palette is normalised at runtime to the live RUN palette, then the explicit Palette B `modulate` is applied. Source pixels remain untouched.

---

## 1. What changed

| File | Change |
|---|---|
| `scripts/player.gd` | `roll_speed = 400`, `roll_duration = 0.50` (200 px), `attack_cooldown = 0.05` (0.30 s total legacy lockout), full-clip roll commitment, preview `_air_time` / `_jump_land_t` tracking, V02/V03 legacy sprite path. |
| `scripts/iven_movement_visual.gd` | Live preview state machine: V02 `JUMP`/`LAND`, V03 `DODGE_ROLL`/`AIR_ROLL`, runtime sheet loading, merged V02/V03 anchors, RUN-palette-normalised roll sheets, explicit Palette B modulate, hard state-entry frame reset, legacy-body exclusion, roll-family lock, direct roll exit, jump/land foot offset `-77`. |
| `scripts/iven_roll_palette.gd` | Runtime-only palette normaliser: maps the V03 roll sheet’s opaque colours to the live RUN palette before the controller’s `modulate`. No source PNG, anchor, or combat data is changed. |
| `scripts/combat/crowbar_feel_combo.gd` | Chain gates at the first recovery frame: M1 `0.10`, M2 `0.15`; M3 cancel `0.35`; `0.45 s` post-strike window; `0.25 s` full-strike buffer; local hitstop `0.03 / 0.04 / 0.05`. |
| `scripts/combat/m1_crowbar.gd` | Live crowbar playback at `1.0`; stops overridden to `.03 / .04 / .05`; buffer `.25`; contact feedback forwards the accepted damage. |
| `scripts/combat/impact_fx.gd` | Six-layer contact pool: blood/sparks, floating damage numbers, layered hit audio, existing motes. |
| `scripts/combat/crowbar_fx.gd` | Brighter contact cross plus the shared blood/number/audio package. |
| `art/iven/m1_crowbar/attack_metadata.json` | `chain` and `recovery_cancel`: M1 `0.10`; M2 `0.15`; M3 `0.35`; `kb`: `220 / 240 / 260`. The `art/` folder is gitignored, so this file is on disk but not tracked. |
| `scripts/lab/motion_swap_lab.gd` | Connects `contact_feedback`; directional combo camera shake (`4.2 px` base, strike-scaled strength and duration) kept separate from Motion Swap shake. |
| `scripts/lab/lab_enemy_base.gd` | Two-frame white hit flash, `1.22 × 0.82` squash punch, and a one-shot knockback impulse with stagger deceleration. |
| `scripts/lab/roll_test_lab.gd` | 200 px ruler, V03/7F air-roll text, and the same RUN-palette roll normalisation for visual QA. |
| `tests/` | New `test_crowbar_combo_feel.gd` and `test_roll_visual_fixes.gd`; V02/V03 expectations added to movement, roll-visual, replay, Motion Swap, and legacy combo tests. |

---

## 2. Crowbar chaining

### Authored timing

| Strike | Startup | Active end | Contact | Chain gate | Authored end | Recovery cancel | Hitstop | Shake |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| M1 horizontal | 0.050 | 0.100 | 0.0667 | 0.100 | 0.200 | 0.100 | 0.030 | ≈3.9 px |
| M2 overhead | 0.0833 | 0.150 | 0.100 | 0.150 | 0.300 | 0.150 | 0.040 | ≈4.5 px |
| M3 rising | 0.2667 | 0.3333 | 0.2833 | — | 0.650 | 0.350 | 0.050 | ≈5.0 px |

The chain gate is the **first recovery frame**, not a later point in the tail. A press during the active window is buffered to that frame; a press during recovery starts the next authored step on the same update. M1 and M2 therefore never wait for their full `0.20 / 0.30 s` clips before the combo can continue. M3 is the finisher exception: its authored `0.65 s` tail still plays if uninterrupted, but any press is queued and restarts M1 at `0.35 s`, just after the `0.3333 s` active window.

### Input flow

1. **Press before the chain gate:** the press is stored as one bounded follow-up. It survives to the gate instead of expiring on the exact gate tick. The live crowbar buffer is `0.25 s`, enough to cover a full strike from its first frame.
2. **Press at/after the gate:** the next authored strike starts on that update. The branch stays open through the whole authored strike; there is no second gate or closed-branch dead spot.
3. **Branch ends naturally:** M1/M2 arm a `0.45 s` real-time combo window after the authored end. A deliberate click inside that window starts M2/M3, not a fresh M1.
4. **Press after the window:** a fresh opener (M1). Only a pause longer than `0.45 s` after the strike ends resets the combo step.
5. **M3:** no further chain. Any press during the finisher is queued and restarts M1 at the `0.35 s` cancel gate. A press at or after `0.35 s` restarts immediately. There is no `0.60 s` hole.
6. **One press = one strike.** Holding the button does not auto-repeat. A single click produces exactly one authored strike.
7. **Distinct M1/M2/M3 clips remain.** Chaining changes when the next clip starts, not which clip plays.

### Why the animation no longer loops M1

The old live path closed the branch at the chain gate and waited for the authored duration. A press during that recovery was ignored until the final buffer window, and even then only set `restart_pending`, so the next click restarted M1. The new path keeps the branch open through the authored strike, starts `index + 1` at the gate, and only arms the `0.45 s` window after the authored end. A natural ~0.2 s / 0.3 s click cadence therefore reads as M1 → M2 → M3, and a deliberate half-second pause still continues the combo instead of rewinding it.

The animation itself is verified two ways: the sprite sample advances within M1 (not stuck on its first frame), and M1/M2/M3 render distinct authored atlas regions. The live clip is played at `1.0×`; the authored timing is the timing the player sees.

### Defensive priority

- Jump, roll, damage, and Motion Swap still cancel the combo on the same physics update.
- A reversal direction cancel remains immediate at `active_end`.
- A same-direction RUN recovery cancel waits for the authored end (M1/M2) or the `0.35 s` M3 cancel gate, so movement cannot eat a live chain press.
- Motion Swap’s E/LMB/Q/RMB front-end behavior is unchanged and still owns the interruption contract.

---

## 3. Impact feedback

Every accepted crowbar hit fires all six layers on the same contact frame:

| Channel | Implementation |
|---|---|
| Local hitstop | Attacker combo clock pauses for `0.03 / 0.04 / 0.05 s`; victim receives the same local stop and its position is held. The rest of the world keeps moving, so control and readability are preserved. |
| Camera | Directional impulse away from the contact. Base `4.2 px`, strike strength `0.82 + 0.12 * strike` (≈3.9 / 4.5 / 5.0 px), duration `0.13 * (0.90 + 0.10 * strike)` (0.130 / 0.130 / 0.143 s). Uses real time, so hitstop cannot hide it. |
| Blood | 5–10 red particles (7 / 9 / 10 by strike) burst outward in the hit direction, have gravity, and fall. Armored targets throw gold sparks instead. |
| Damage number | A floating `Label` above the contact: 13 px, dark outline, cream for M1/M2 and gold for M3. It pops, rises, and fades over `0.55 s`. |
| Enemy reaction | White body flash for two 60 Hz ticks plus a `1.22 × 0.82` squash that settles back to `1.0` over `0.14 s`. The flash counter decrements during hitstop, so the enemy does not stay a white silhouette for the whole freeze. |
| Knockback | One-shot `220 / 240 / 260 px/s` impulse. The stagger arm decelerates at `900 px/s²`; measured M1 slide is `22.4 px`. The old per-tick re-add was removed because it turned a 220 px/s shove into runaway acceleration. |
| Sound | Layered `hit_1 / hit_2 / hit_3` transient plus `organic` or `metal`, with small deterministic pitch variation; `defeat` adds the kill accent. The existing whoosh remains the wind-up read. |
| Motion Swap separation | Combo shake and Motion Swap shake use separate timers/offsets; neither overwrites the other. |

No global `Engine.time_scale` freeze is used for a normal M1 hit. Motion Swap remains the owner of tactical time. The local stop freezes the attacker clock and victim body, while camera, blood, number, and audio continue to sell the hit.

---

## 4. Movement integration

### Jump V02

- 30-frame approved sheet, loaded into the runtime `SpriteFrames` as `JUMP_right` / `JUMP_left`.
- Airborne drawing: `clampi(3 + int(_air_time * 30.0 + 0.00001), 3, 24)`.
- Landing: frames `25..29` over `5/30 s` (`LAND_right` / `LAND_left`).
- Jump/land foot offset: `-77 px`; ground pivot remains the existing `PIVOT`.
- RUN → JUMP → LAND → RUN:
  - a held run leaves the landing pose after the first touchdown drawing;
  - an idle landing shows the full 25–29 recovery;
  - `_air_time` resets on touchdown, `_jump_land_t` drives the landing window.
- The legacy `scenes/main.tscn` path also selects V02 jump and landing drawings through `player._update_sprite()`.

### Roll V03

| Property | Value |
|---|---:|
| Ground clip | `DODGE_ROLL`, 15 frames at 30 fps = 0.50 s |
| Air clip | `AIR_ROLL`, 7 frames at 30 fps; plays once, then holds the final frame for the remaining physics roll |
| Duration | 0.50 s |
| Speed | 400 px/s |
| Travel | **200 px** |
| Cooldown | 0.35 s, armed on completion or cancellation |
| Color | V03 sheet normalised to the RUN palette, then `Color(0.84, 0.765, 0.739, 1.0)` applied as `modulate` |

- The roll family is chosen once at roll start (`DODGE_ROLL` grounded, `AIR_ROLL` airborne) and held for the whole roll, so landing mid-air-roll cannot pop the clip family.
- The accepted roll plays its full clip. Direction changes, extra dash presses, and movement input no longer cancel it; jump and Motion Swap still interrupt.
- Exit goes directly to RUN / IDLE / JUMP. V03’s final frame is run-ready, so the old V2 entry/exit bridge clips are no longer used.
- Measured on the deterministic replay: `200.00244140625 px`, 30 active physics ticks, `0.50 s` movement, `0.516666666666667 s` including the exit update, 0.35 s cooldown.
- The V03 sheet ships on a lighter grey/cool B palette. A plain warm `modulate` darkened it but did not turn its cloth into RUN’s navy/cloth colours, which is why the live roll still read pale. `iven_roll_palette.gd` now remaps every opaque roll colour to the nearest live RUN colour, pre-divided by the modulate so the final draw lands on the RUN palette. The explicit `modulate` line remains in both controllers.
- State entry is explicit: `body.stop()` clears the previous drawing, the new roll starts on frame 0, the legacy `ColorRect` body is hidden, and nearest filtering is reasserted. The movement path leaves `body.visible` to the movement/combat owner, so an active M1/crowbar overlay is not overridden. Jump→air-roll and land→ground-roll therefore cannot leave a stale jump/land sprite visible.
- `scripts/player.gd` also applies the normalised V03 sheets and the same Palette B modulate on the legacy `scenes/main.tscn` path; `roll_test_lab.gd` uses the same normalisation for visual QA.

---

## 5. Verification

All deterministic checks were run with `--fixed-fps 60`; without it, headless catch-up can execute multiple physics ticks per awaited frame and produce false timing failures.

```powershell
$godot = "C:\Users\Aloha\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
& $godot --headless --fixed-fps 60 --path E:\neverlookback -s res://tests/test_crowbar_combo_feel.gd
```

### Gate results (this pass)

| Test | Result | Evidence / what it proves |
|---|---:|---|
| `test_crowbar_combo_feel.gd` | 43 / 0 | Live M1→M2→M3 chaining, same-update recovery cancel, full-strike buffering, one-click behavior, 0.45 s combo persistence, M3 queued/direct cancel at 0.35 s, advancing/distinct animation regions, hitstop, flash, squash, directional shake, blood, damage number, layered audio, 22.4 px knockback, Motion Swap interruption. |
| `test_foundation_repair.gd` | 38 / 0 | Both `scenes/main.tscn` and `labs/motion_swap_lab.tscn` load; foundation and 200 px roll contracts intact. |
| `test_movement_integration.gd` | 176 / 0, 2032 samples | V02 jump frames 3–24, LAND 25–29, RUN→JUMP→LAND→RUN, 195–205 px roll, wall/cooldown/transition contracts. |
| `test_roll_visual_transitions.gd` | 31 / 0, 457 samples | V03 ground/air clips, Palette B modulate, 0.50 s / 400 px tuning, roll-family lock, full-clip input commitment, left/right, anchors. |
| `test_roll_visual_fixes.gd` | 24 / 0, 66 samples | Live JUMP→AIR_ROLL and LAND→DODGE_ROLL entries: frame 0, exactly one visible body, no stale jump/land clip, nearest filter, exact Palette B modulate, and rendered roll palette matching RUN on both facings. |
| `test_motion_swap_lab.gd` | 32 / 0 | Six-zone lab access/reset and Motion Swap lab contracts. |
| `test_dodge_roll_v2.gd` | 34 / 0 | Roll cooldown, held input, wall stop, air roll, tactical time scale. |
| `final_roll_feel_replay.gd` | 12 / 0 | Measured 200.0024 px / 0.50 s / 0.5167 s including exit; 30 active ticks; jump/air/held-run/repeat cases. |
| `dodge_roll_v2_replay.gd` | 18 / 0, 457 samples | Replayed V03 visual transitions, left/right run stride, no recovery lock. |
| `test_m1_full_combo.gd` | 101 / 0 | Legacy full combo behavior and roll-cooldown interaction. |
| `test_m1_combat_rebuild.gd` | 238 / 0 | Combat rebuild matrix, cancellations, Motion Swap front-end, wall/prop support, anchors. |

Previously verified and not rerun in this pass: `test_m1a_preview.gd` 42 / 0, `test_m1a_v2_preview.gd` 110 / 0, `test_m1_natural_combo.gd` 262 / 0, plus the existing Motion Swap/identity/feel/runtime/arena suites.

### Scene smoke boots

```powershell
& $godot --headless --fixed-fps 60 --path E:\neverlookback --quit-after 30 res://labs/motion_swap_lab.tscn
& $godot --headless --fixed-fps 60 --path E:\neverlookback --quit-after 30 res://scenes/main.tscn
```

Both exited `0` with no script errors.

### Visual evidence

- Roll contact sheet: `artifacts/roll_visual_transition/after/V03_ROLL_CONTACT_SHEET.png`
  - ground roll entry (`DODGE_ROLL` frame 0)
  - ground roll mid (`DODGE_ROLL` frame 7)
  - natural exit (`RUN` restored)
  - air roll entry (`AIR_ROLL` frame 0)
- Roll colour/transition close-ups: `artifacts/roll_visual_fixes/jump_to_air_roll_entry.png` and `land_to_ground_roll_entry.png`, captured non-headless at 4×. The roll frames now use RUN’s navy/cloth palette; no jump/land body is visible after the entry frame.
- Focused results: `artifacts/roll_visual_fixes/results.json`.
- Combo contact sheet: `artifacts/crowbar_combo_feel/capture/M1_M2_M3_CONTACT_SHEET.png`
  - M1 horizontal, M2 overhead, and M3 rising captured at contact with the floating `1 / 1 / 2` damage numbers and blood.
  - The enemy is a simple cyan lab block in this capture; the two-frame white flash is a separate tick and is asserted by the deterministic gate. The capture window favors the pose/number read so the sheet stays legible.
  - Rebuild with `tests/capture_crowbar_juice.gd` (non-headless, `--fixed-fps 60`).
- Raw captured frames: `artifacts/roll_visual_transition/after/frames/` and `artifacts/crowbar_combo_feel/capture/`
- Machine-readable results:
  - `artifacts/crowbar_combo_feel/results.json`
  - `artifacts/roll_visual_transition/after/results.json`
  - `artifacts/movement_integration/runtime_results.json`
  - `artifacts/final_roll_feel/after/results.json`
  - `artifacts/m1_full_combo/GAMEPLAY_VALIDATION.json`
  - `artifacts/m1_combat_rebuild/GAMEPLAY_VALIDATION.json`

---

## 6. Feel explanation

**Snappy chaining.** The combo no longer treats the end of a strike as a dead branch. M1 and M2 open the next step at the first recovery frame, so a press during recovery starts the next authored strike on that same update. A press during late active frames is buffered one or two frames to the gate instead of being swallowed. After the authored end, a `0.45 s` window keeps the sequence alive for a deliberate half-second beat. One-press edge detection and the bounded `0.25 s` buffer keep it from becoming an auto-combo: the player still has to ask for every hit, but the game stops punishing them for asking slightly early or slightly late. M3 keeps its full authored tail for players who let it finish, but any press queues a restart at `0.35 s` instead of waiting out the old `0.60 s` hole.

**Weighty impact.** Contact is sold in six simultaneous layers: a `0.03–0.05 s` local stop, a `3.9–5.0 px` directional camera kick, 5–10 falling blood particles, a floating damage number, a two-frame white flash plus squash on the victim, and a `220–260 px/s` one-shot knockback. A layered `hit_1/2/3 + organic/metal` sound sits on top. The stop is short enough that control returns immediately; the flash decays during the stop, so it reads as a hit rather than a frozen error state. The finisher gets the longest stop, the widest kick, and gold damage text, which makes M3 feel heavier without slowing down M1.

**Roll distance and color sync.** The roll is `400 px/s × 0.50 s = 200 px`, exactly matching the 15-frame V03 ground clip at 30 fps. The same 0.50 s physics budget drives the 7-frame air clip, which holds its last drawing for the remainder of the tumble. The V03 sheet’s lighter B palette is remapped at load time to the live RUN palette, then the explicit `modulate = Color(0.84, 0.765, 0.739, 1.0)` is applied at draw time. The approved source pixels stay untouched, but the rendered roll now uses the same navy/cloth colours as RUN instead of a pale grey. State entry stops the old drawing and starts the new roll at frame 0, so jump→roll and land→roll cannot stack or leak a stale body. V03’s final frame is run-ready, so the roll exits directly into RUN/IDLE without an extra bridge clip or extra travel.

---

## 7. Notes and constraints

- `art/` and `artifacts/` are gitignored. `art/iven/m1_crowbar/attack_metadata.json`, the V02/V03 sheets, and `roll_v03/anchors.json` are present on disk but are not tracked by git. The test JSON/PNG evidence under `artifacts/` is also local to this pass. Include these explicitly in any handoff or commit that needs the full runtime data or evidence.
- Use `--fixed-fps 60` for deterministic replay. Plain headless runs can run multiple physics ticks per awaited frame.
- The live crowbar combo is enabled in `labs/motion_swap_lab.tscn`; `scenes/main.tscn` keeps the legacy attack path but shares the V02/V03 movement visuals.
- Strike damage and health values are unchanged. Crowbar knockback was retuned from the old `35 / 40 / 60` values to `220 / 240 / 260` and changed from a per-tick re-add to a one-shot impulse so the requested 20–30 px slide is real rather than a tiny shove.
- Motion Swap mechanics are preserved: selection, exchange, launch, and interruption behavior were not redesigned.
- Older chaos/preview suites (`test_motion_swap_chaos.gd`, `test_m1_combo_motion_regression.gd`) contain wall-clock/catch-up assumptions. The dedicated deterministic gates above are the authoritative verification for this pass.
