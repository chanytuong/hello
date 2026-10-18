# Final roll feel tuning

> Subsequent visual repair: [Roll visual transition QA](ROLL_VISUAL_TRANSITION_QA.md) replaces the transition presentation described here. The approved 0.29 s / approximately 100 px controller tuning is preserved.

2026-10-18 · `E:\neverlookback` · Godot 4.7.2 stable · Windows / Compatibility / ANGLE.

**The final roll measures 100 px with 0.29 s configured duration.** Ground/air use and immediate input cancellation remain. Human gameplay and visual approval are pending. This pass stops at roll tuning; M1/M2 production has not started.

## Before / after

The same scripted inputs were recorded in the real lab before and after editing the controller, without tuning overrides. The baseline matched all 30 source hashes from the foundation delivery. Source snapshots are saved under `artifacts/final_roll_feel/source_before/` and excluded from Godot scanning with `.gdignore`.

- [Short before/after gameplay recording](../artifacts/final_roll_feel/BEFORE_AFTER.mp4), 6.37 s, native 1280×720 at 60 fps.
- [Before separately](../artifacts/final_roll_feel/BEFORE.mp4), [after separately](../artifacts/final_roll_feel/AFTER.mp4).
- [Baseline measurements and samples](../artifacts/final_roll_feel/before/results.json), [final measurements and 11 rendered checks](../artifacts/final_roll_feel/after/results.json).
- [Regression summary](../artifacts/final_roll_feel/regression_verified_summary.json), [media decode verification](../artifacts/final_roll_feel/media_verification.json), [delivery receipt](../artifacts/final_roll_feel/DELIVERY_RECEIPT.json).

| Measurement | Foundation baseline | Final tuning |
| --- | ---: | ---: |
| Configured duration | 0.24 s | **0.29 s** |
| Controller roll speed | 320 px/s | **333.3333333 px/s** |
| Measured ground travel | 79.9988 px | **99.9978 px** |
| Active movement ticks at 60 Hz | 15 | 18 |
| Active movement time | 0.2500 s | **0.3000 s** |
| Time including the inactive exit update | 0.2667 s | 0.3167 s |
| First accepting update | Moving at 320 px/s | Moving at 333.33 px/s |
| Reverse cancellation | −280 px/s, RUN | −280 px/s, RUN |
| Movement release during roll | 0 px/s, decorative SKID_STOP | **0 px/s, immediate IDLE** |
| Held RUN at natural roll exit | 280 px/s, RUN | 280 px/s, RUN |
| Air roll | Available | Available, gravity/jump budget preserved |

The 60 Hz controller quantizes 0.29 s to 18 active movement ticks. Speed and duration were tuned together to produce 100 px across those ticks. The inactive exit update is reported separately; it has no roll movement or recovery lock. Movie Maker uses fixed 60 Hz game time. Recording throughput does not measure normal gameplay FPS or physical keyboard/display latency.

## Localized changes

`scripts/player.gd` has three small changes:

1. Set `roll_duration` from **0.24→0.29** and `roll_speed` from **320→333.3333333**. This changes actual controller displacement and animation timing together.
2. At natural roll completion, immediately use the current directional input's normal run speed, or zero for idle. With the slightly faster new roll, this prevents a residual overspeed tick while acceleration approaches RUN speed. There is no stop between held RUN and RUN.
3. Suppress decorative release-skid requests when the previous update was rolling. A release cancellation previously stopped motion immediately but selected SKID_STOP; it now selects IDLE immediately. Ordinary run-release skid remains.

No run tuning was changed: `run_speed=280`, `acceleration=2600`, `reverse_accel=4200`, `friction=3200`, `air_control_mult=0.7`. Fresh direction cancellation already assigns the intended run velocity on the accepting update, so a global acceleration/deceleration adjustment was unnecessary.

`scripts/iven_movement_visual.gd` was inspected and remains byte-identical. It already derives roll drawing from the gameplay timer, prioritizes rolling in air and leaves the roll pose as soon as gameplay cancels it. Correcting the controller's skid request is sufficient. The final replay reaches drawing 20, then exits without a frozen end pose. The atlas has 21 drawings; at 60 Hz some intermediate drawings are skipped during the shorter-than-source playback, as before. No root motion is added.

Jump physics, the physical capsule, collision solver, camera, source rig, Blender files, atlas, anchors, flame and shaders were not changed. Damage, enemy AI, Motion Swap and arena source files were not changed.

## Responsiveness verified

The rendered replay checks RUN→ROLL→RUN, ROLL→REVERSE, ROLL→RELEASE, ROLL→JUMP, JUMP→AIR ROLL→AIR CONTROL and five rapid repeated rolls. It records the first accepting update and visual state for every cancellation.

- Natural completion with held direction selects RUN at exactly 280 px/s; idle-origin completion selects IDLE at zero horizontal speed.
- Reverse input selects RUN and −280 px/s immediately. Release selects IDLE and zero horizontal speed immediately, with no decorative skid.
- A valid grounded jump cancels immediately to JUMP with the unchanged −613.33 px/s first-update vertical velocity.
- Air roll leaves gravity active: vertical velocity changes from −480 to −453.33 px/s under normal gravity; it does not receive an upward impulse. The existing air budget remains 1→1. Fresh left input then restores JUMP/air control at −280 px/s immediately.
- All five fresh roll presses activate. Peak horizontal speed is 333.33334 px/s, the configured speed rounded to the engine float, with no accumulation or cooldown.
- The existing foundation tests retain solid-wall checks, including an airborne roll into a 2 px wall, ordinary contact without damage/forced motion, legitimate Charger attack damage and high-speed physical impact regressions.

No input lock, new cooldown, immunity, movement mechanic or cinematic recovery was introduced. The separate legacy combat dash remains unchanged.

## Automated results

**All 461 existing checks/assertions pass across 12 suites**, plus **11/11 rendered roll checks** (472 total). No final project script errors.

| Suite | Checks / assertions | Final result |
| --- | ---: | --- |
| `test_motion_swap_chaos` | 65 | Pass |
| `test_weapon` | 50 | Pass |
| `test_movement_integration` | 166 | Pass |
| `test_foundation_repair` | 34 | Pass |
| `test_motion_swap_lab` | 32 | Pass |
| `test_foundation_arena` | 15 | Pass |
| `test_motion_swap` | 43 | Pass |
| `test_runtime` | 7 | Pass |
| `test_arena` | 15 | Pass |
| `test_identity` | 21 | Pass |
| `test_feel` | 10 | Pass |
| `test_strand` | 3 | Pass |
| Rendered final-roll replay | 11 | Pass |

The final import and smoke logs are [project import](../artifacts/final_roll_feel/project_import_verified.log) and [lab smoke launch](../artifacts/final_roll_feel/headless_smoke_verified.log). The three MP4 files encode and fully decode without errors; source framebuffers and decoded frames were inspected.

Initial concurrent runs had timing-sensitive failures in crate exchange, legacy weapon wall-clock timing and movement sampling. Their logs remain under `artifacts/final_roll_feel/`. An initial editor import also found a duplicate `NLBPlayer`: the source backup had been placed inside the project without an ignore marker. Adding the evidence folder's `.gdignore` and refreshing the original script registration fixed the artifact setup. The final summary uses isolated reruns after hashing/import activity ended; unrelated test assertions were not relaxed.

Earlier suites write receipts to fixed historical paths. Their previous receipts were saved, the new results copied into `artifacts/final_roll_feel/regression_receipts/`, and the historical receipt files restored. The earlier 80 px foundation recording and measurements remain intact.

## Exact source files modified in this pass

| File | Purpose |
| --- | --- |
| `scripts/player.gd` | Roll duration/speed, immediate normal-speed exit, omit skid on roll cancellation. |
| `tests/test_foundation_repair.gd` | New 95–105 px / 0.29 s acceptance; speed checks use the roll setting. The separate 0.24 s self-swap setup is unchanged. |
| `tests/test_motion_swap_lab.gd` | Replace the previous 60–90 px roll expectation with 95–105 px. |
| `tests/test_movement_integration.gd` | Replace the previous 60–90 px trajectory expectation with 95–105 px. |
| `tests/final_roll_feel_replay.gd` | New identical before/after input replay, measurements, cancellation-pose assertions and recording. |
| `tests/final_roll_feel_replay.gd.uid` | Generated Godot script UID. |
| `design/FINAL_ROLL_FEEL_QA.md` | This report. |
| `design/MOVEMENT_COMBAT_FOUNDATION_QA.md` | Add a notice linking this later roll tuning; historical measurements retained. |

[Exact manifest and source hashes](../artifacts/final_roll_feel/DELIVERY_RECEIPT.json). Evidence, snapshots, logs, `.gdignore` and videos are confined to `artifacts/final_roll_feel/`. No scene, map, enemy, VFX, rig or atlas source was modified. Protected asset verification is recorded [here](../artifacts/final_roll_feel/protected_verification.json).

## Human review and remaining limits

Use editor F5 to run the lab, then in-game F7 for the existing arena. A/D or arrows move; Shift/L rolls; Space/W/Up jumps. Use the open lane to try held RUN→ROLL→RUN, release during a roll, rapid reversal, valid jump cancels and repeated air rolls. E/LMB/Q/RMB retain their Motion Swap controls; 1 resets the arena. Alternatively run `scenes/movement_test.tscn` with editor F6 for isolated review.

The longer roll travels about 25% farther, with no added startup or recovery. Tests establish controller/pose timing, not subjective feel. Native-size animation readability, controller comfort and gameplay approval still require a human. Some source drawings are necessarily skipped at 60 Hz; no source animation was regenerated. There is no exported-build or hardware-latency certification in this pass.

Reproduce the focused recording and primary regressions from PowerShell:

```powershell
$godotExe = 'C:\Users\Aloha\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --path E:\neverlookback --script res://tests/final_roll_feel_replay.gd --write-movie E:\neverlookback\artifacts\final_roll_feel\AFTER.avi
& $godotExe --headless --path E:\neverlookback --script res://tests/test_foundation_repair.gd
& $godotExe --headless --path E:\neverlookback --script res://tests/test_motion_swap_chaos.gd
& $godotExe --headless --path E:\neverlookback --script res://tests/test_movement_integration.gd
```

The BEFORE clip uses the pre-edit controller saved in `source_before/`; rerunning the current controller with a BEFORE label would not reproduce that old tuning. Treat the earlier foundation report as the historical 80 px baseline and this report as the current roll specification.

Inspection found no root, ancestor or applicable project `AGENTS.md`. The local `agentskill/` packages were enumerated; the relevant Game Feel response-tuning and Godot movement/animation guidance was read. Dead Cells supplies the requested responsiveness reference; no exact frame data or additional mechanic was copied.
