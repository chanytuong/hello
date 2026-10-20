# Expressive M1 rebuild — ready for visual review

20 October 2026 · Asia/Saigon · NEVERLOOKBACK

Implemented the **Complete M1 Combat Animation Rebuild** brief, which supersedes the earlier M1-A-only and stationary-punch restrictions. The result is a connected three-strike set: **left drive straight → right body hook → left stepping forearm body blow**. No fourth strike or M2 was produced. Human visual acceptance is pending.

## Review deliverables

- [Normal-speed gameplay, 38.08 s](../artifacts/m1_combat_rebuild/M1_REBUILD_NORMAL.mp4): 2,285 actual Godot captures, native view and nearest 4× inspection view.
- [Selected gameplay at 25% speed, 52.85 s](../artifacts/m1_combat_rebuild/M1_REBUILD_SLOW_25_PERCENT.mp4): source frames held longer; no synthesized inbetweens.
- [Palette-B sprite playback, 8 s](../artifacts/m1_combat_rebuild/M1_B_SPRITE_PLAYBACK.mp4): **art-only**, with virtual advance and the existing flame cels. This does not demonstrate controller input, collisions or the secondary flame spring.
- [Matched old/new contacts](../artifacts/m1_combat_rebuild/MATCHED_B_BODY_COMPARISON_4X.png): old and new Actions rendered through the same camera and palette B, without flame obscuring the comparison.
- [Actual gameplay contact board](../artifacts/m1_combat_rebuild/GAMEPLAY_KEYS_4X.png), [native board](../artifacts/m1_combat_rebuild/NATIVE_GAMEPLAY_KEYS.png), and [actual enemy contacts](../artifacts/m1_combat_rebuild/ACTUAL_CONTACTS.png).
- [Blender working file](../maincharacter/m1_combat_rebuild/IVEN_M1_COMBAT_REBUILD.blend), [authoring/reproduction instructions](../maincharacter/m1_combat_rebuild/README.md), [research and attributed evidence](M1_COMBAT_REBUILD_RESEARCH.md).

Open **`labs/m1_combat_rebuild.tscn`** in Godot and run the current scene. A/D move; LMB or J attacks; Space jumps; Shift rolls; E selects Motion Swap targets, Q/RMB selects self; V toggles the opponent; H toggles the actual contact volume; R retries. Each follow-up needs a fresh press. The ordinary Motion Swap lab also opts into the new driver. `labs/m1_full_combo.tscn` and the original controller remain the rollback comparison.

**Visible limitation:** the preserved approved movement sprites still use the older textured/brown appearance. New attacks use the locked flat palette B. Actual gameplay therefore has a visible material/shape handoff at IDLE/RUN/ROLL/JUMP transitions. No replacement RUN bank was made to hide it. The separate B reel isolates the new attack art. Seamless visual style across locomotion and combat is **not** claimed.

## Final move and control contract

| Strike | Duration / first contact / active end | Chain handoff | Free advance | Damage / free recoil |
|---|---|---|---|---|
| Drive straight L | 0.2333 / 0.0500 / 0.1000 s | 0.1667 s | 5 px | 1 / 60 px/s |
| Turning body hook R | 0.2667 / 0.0667 / 0.1333 s | 0.2000 s | 2 px | 1 / 70 px/s |
| Stepping forearm body blow L | 0.3333 / 0.1000 / 0.1667 s | End → movement | 7 px | 2 / 90 px/s |

The hook uses a bent arm and a lower rotational body shape; the last strike changes direction through a folded arm and downward closed-hand/ulnar-side contact. It is not another straight or a high elbow strike. Actual unscaled enemy hurtboxes exposed the initial high-contact design's misses. Lowering the contacts solved that without changing enemies or adding invisible reach. The contact bones are **L hand, R hand, L hand**; all three contact circles have radius **4.5 px** and follow the evaluated rendered pose.

Godot applies the exported smooth travel curves once through its collision solver. Blender root translation remains neutral. The first two steps settle by 0.10 s; the third advances from 0.07 to 0.20 s, continuing into follow-through. A static/prop obstruction within the combo's 14 px advance, or an already touching character body, selects a **braced** version for that entire combo. Those copies retain the upper-body attacks with stationary feet and zero gameplay advance. Early braced recoil is 25/30 px/s, then 90 for the finish, so a close opponent stays within follow-up reach. These are two support modes for three moves, not RUN-phase or random attack variants.

One accepted press starts one strike. A **0.12 s expiring buffer** can request the next stage; holding LMB never supplies additional presses. Cancellation clears the request. Attack facing stays fixed through contact; a deliberate opposite direction can leave recovery after the active window. Held direction otherwise resumes when recovery ends, with no forced skid or extra entry animation.

Priority is explicit: death, forced motion/stun and Motion Swap selection suppress M1; a valid jump or an available fresh roll interrupts any attack phase, including local hitstop. The existing player gives simultaneous valid jump priority over roll and clears the pending roll. An unavailable roll does not bypass cooldown. Air attacks are not added. Accepted hits use the existing Health/HitBox victim guard, HP deltas, sounds and restrained contact marks. Local hitstop is 1/60 s, or 2/60 for the last strike; it pauses attack playback/advance, not defensive input or the whole game clock.

## Transition matrix and visual examination

| Transition | Implemented / checked behavior |
|---|---|
| IDLE → single M1 → IDLE | Immediate state acceptance, compact gather, deliberate recoil; no automatic follow-up |
| RUN → single M1 → IDLE | Attack takes over horizontal motion directly; no stopping clip or RUN legs during the attack |
| RUN → chain → RUN | 5/2/7 px authored steps; held direction resumes through existing movement logic |
| Strike 1 → 2 → 3 | Shared hip, torso, hand and support endpoint poses; no neutral reset |
| Every strike → ROLL | Same-update cancellation in preparation, contact and recovery, both facings |
| Every strike → JUMP | Same-update valid cancellation in all three phases, both facings; no stale punch afterward |
| Repeated / held / expired input | Three deliberate chain presses, independent singles, held click and expired buffer checked separately |
| Hitstop / direction reversal | Defensive interruption remains live; reversal leaves recovery without flipping a contact pose |
| Close enemy / wall / solid prop | Braced support; wall/prop blocks through-obstacle hits; actual body contacts and damage tested |
| Motion Swap selection | LMB remains target selection; E/Q/RMB roles preserved |

Opened native and enlarged key poses before interpolation, then final contiguous captured sequences in [both](../artifacts/m1_combat_rebuild/COMBO_RIGHT_SEQUENCE.png) [facings](../artifacts/m1_combat_rebuild/COMBO_LEFT_SEQUENCE.png), actual contacts and [movement/defensive handoffs](../artifacts/m1_combat_rebuild/RUN_AND_DEFENSIVE_HANDOFFS.png). The straight, compressed body hook and folded finish have different contact/support shapes. The far folded arm remains compact at this camera and needs human judgment at normal speed. No gross coat explosion, clipped body outline or stuck attack playback was found in the inspected sequences. The movement-cache palette/shape pop remains visible.

All four free/braced chain joins have **0.0 stored pose-channel error**. Continuous native support checks stay within **0.202 px** projected error for free steps and **0.000017 px** forward range for braced support. The actual displayed-cel ankle-point check, including 30/60/120 Hz single-strike cases, has maximum horizontal range **0.795 px** during the declared planted intervals. These are sampled kinematic landmarks, not sole-slip or pressure measurements. Subpixel source results do not mean every raster pixel remains fixed. [Native receipt](../maincharacter/m1_combat_rebuild/FINAL_NATIVE_VALIDATION.json), [capture index and method](../artifacts/m1_combat_rebuild/CAPTURE_REVIEW_INDEX.json).

## Validation and preservation

**New combat tests: 237 checks, 0 failures**, both headless and rendered. The rendered run recorded all 2,285 samples. It covers real accepted damage at 1.0× and 1.5× opponent scale, both facings, close braced targets, duplicate HurtBoxes, walls/props, all stage/phase defensive interruptions, input ownership, hitstop, grounded playback, flame anchors and frame-rate travel. No damage precedes the displayed contact. [Runtime receipt](../artifacts/m1_combat_rebuild/GAMEPLAY_VALIDATION.json), [capture log](../artifacts/m1_combat_rebuild/CAPTURE.log).

Five unchanged regression suites pass **376 assertions**: original M1 101, movement integration 166, foundation repair 34, Motion Swap 43, Motion Swap lab 32. The final real-time chaos regression is **64/65**, with one existing assertion comparing the crate's final Overdrive-adjusted velocity against its raw incoming vector. The same assertion fails with the original M1 driver; final example receives `(0, 362.6667)` and produces `(0, 453.3333)` after the existing 1.25 multiplier. Initial uncapped runs also showed timing-sensitive failures and are retained rather than hidden. A focused companion checks below/above the existing 250 px/s threshold and passes **8/8**. Motion Swap code and the original tests were not modified. [Final legacy log](../artifacts/m1_combat_rebuild/regression/test_m1_combo_motion_regression/final_realtime.log), [old-driver reproduction](../artifacts/m1_combat_rebuild/regression/test_m1_combo_motion_regression/old_driver_baseline.log), [threshold companion](../artifacts/m1_combat_rebuild/OVERDRIVE_CONTRACT.json).

The final working file contains **21 Actions: all 15 originals exact, three new attacks and three braced support copies**. All 184 native 82×82 cells have binary alpha and pass fixed-frame clipping checks. The 1558×984 atlas carries explicit cel start/duration metadata, including semantic contact samples. Original geometry, skin, rest/hierarchy, constraints, materials, palette bands, camera matrix and movement Actions pass exact comparisons. The saved orthographic camera remains `RESEARCH_Y75_P00`, scale 2.2200000286. Rendering follows the approved palette-B Eevee/no-AA setup. No Pixelorama repaint or source-donor curve copying was used.

Checkpoint `99dd6bc` and [rollback copies](../artifacts/m1_combat_rebuild/rollback/) preserve the starting state. The 10,652-file hash audit permits only the player driver-selection/movement hook and the Motion Swap lab opt-in as shared changes; all other protected files must remain exact. [Preservation receipt](../artifacts/m1_combat_rebuild/PROTECTED_VERIFICATION.json). New production, evidence, preview and tests are isolated. Existing RUN and flame artwork remain unchanged.

All three exported videos passed full FFmpeg decode; dimensions, durations and SHA-256 are recorded in [gameplay video validation](../artifacts/m1_combat_rebuild/VIDEO_VALIDATION.json) and [art reel validation](../artifacts/m1_combat_rebuild/SPRITE_PLAYBACK_VALIDATION.json). Videos are silent inspection captures; sound playback is wired to accepted hits, but auditory quality and hardware input latency were not measured. No claim is made about universal Dead Cells cancel windows. Stop here for human review of this M1 set before further combat animation production.
