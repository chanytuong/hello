# Dodge roll V2 — prototype for human review

> Current input contract (2026-10-24): an accepted roll plays its full 18-drawing clip. Direction changes, direction release and extra roll presses are ignored until it ends instead of cancelling it. Jump-cancel and Motion Swap interruption remain, and the 0.35 s cooldown still starts on completion or interruption.

2026-10-19 · Asia/Saigon · `E:\neverlookback` · Godot 4.7.2 / Blender 3.6.23.

The compact native `IVEN_DODGE_ROLL_V2` replaces the prototype's roll presentation, with **0.35 s cooldown after completion or cancellation**. Gameplay retains **0.29 s configured / 99.9978 px measured**, immediate ready activation and immediate movement/jump cancellation. **642 regression checks plus 22 rendered assertions pass. Human visual and gameplay approval remains pending.**

## Prerequisite and boundaries

M1-A V2 was already delivered with its native file, normal/slow recordings, native GIF, key poses and completed validation. All 12 delivery hashes matched before roll work. Its [QA and deliverables](../maincharacter/combat_redesign_m1a/M1_A_V2_QA.md) remain unchanged. No M1-B/M2 or wider combat integration was started.

No applicable `AGENTS.md` was found at root/ancestors or target directories. Enumerated 14 `agentskill` packages; applied relevant Godot implementation/testing/animation, game-feel, animation-systems and Blender animation/rendering/validation guidance. A 28,778-file pre-edit hash baseline and ignored source snapshots preserve the previous work. Existing root untracked work was left alone.

## Reference actually examined

The supplied [Dead Cells video](<C:/Users/Aloha/Downloads/f4112287-1efa-47de-b7ca-044ba2a2f203.mp4>) is 1600×720, 24.83 s, reported average 24.24 fps. Full decode passes. Overview, consecutive selected samples across the recording and the [dense roll excerpt](../artifacts/dodge_roll_v2/reference/ROLL_DETAIL.png) were opened **before authoring**. Approximate labels use average upload rate; they are not an input trace or internal game frame data.

| Approximate time | Observed image sequence | Iven decision |
|---|---|---|
|13.830–13.913 s|Upright; shoulders lower; legs sweep overhead.|Fast coordinated entry, without a gameplay windup.|
|13.954–14.036 s|Changing inverted/back silhouettes, torso near support, then legs unfold.|One readable tumble, earlier knee fold; avoid a held crouch sliding across the floor.|
|14.078–14.119 s|Rise quickly into leftward travel.|Movement-ready exit; no standing recovery lock.|
|14.16–14.78 s; next roll about 14.82–14.99 s|Upright travel visibly separates rolls.|Separate readiness from locomotion. Missing rolls cannot prove rejected input.|
|15.5–16.9 s,20.0–20.4 s,22.8–24.5 s|Further alternating ground and airborne shapes, camera scroll and effects.|Check both facing directions and air control; do not infer world units or exact cancel windows.|

Motion Twin's lead developer describes responsive movement and an invincible dodge in the [2018 development account](https://blog.playstation.com/2018/01/25/rogue-lite-action-platformer-dead-cells-coming-to-ps4-this-year/). The official [Update 19 notes](https://deadcells.com/patchnotes/19) explicitly say Tonic shortens dodge cooldown; [Update 29](https://deadcells.com/patchnotes/29) adds hold-to-roll as an option. These establish mechanics/settings without establishing base numerical timings. **Iven's 0.35 s value comes from this brief.** No Dead Cells cooldown, i-frame or cancel count is invented/copied. Iven gains no immunity or smaller collision capsule. [Detailed reference notes](../maincharacter/dodge_roll_v2/REFERENCE_NOTES.md).

## Diagnosed causes and new poses

The old Action was 21 drawings at 30 fps / 0.667 s between endpoints, compressed into 18 gameplay updates plus runtime entry/return patches. Its extended dive, long leg shapes and only 28% middle tuck spent too much of that short playback outside a compact silhouette. The old patch selected two existing unroll drawings from neck distance; it could not improve the underlying anatomy. Fresh presses restarted the controller timer indefinitely even though the visual clock avoided rewinding.

The common origin, world trajectory and solid solver were already correct. There was no duplicate root displacement. The flame was position-attached; the existing floor limiter adjusts its angle near the support plane. Camera/facing/pivot were verified rather than retuned.

V2 authors new keys on the original bones: earlier additional 43% ankle-toward-hip fold at peak, 24% wrist retraction toward shoulders, a shorter extended-dive section, and a grounded rise toward the existing RUN 14 support shape. The existing coordinated full-body inversion is anatomical scaffolding; this is a new pose adaptation rather than another animation-speed-only change. No extra turn/spin, new bones, weights, mesh, materials or rig repair.

[Body-only old/new key poses](../artifacts/dodge_roll_v2/OLD_VS_NEW_POSES.png) compare both facings; actual engine comparisons are linked below. The editable native source is [IVEN_DODGE_ROLL_V2.blend](../maincharacter/dodge_roll_v2/IVEN_DODGE_ROLL_V2.blend); the old `maincharacter/dodge_roll/` is retained.

## Timing and input contract

| Measurement | Before | V2 |
|---|---:|---:|
|Configured roll|0.29 s|0.29 s|
|Speed|333.3333333 px/s|333.3333333 px/s|
|Measured empty-ground travel|99.9978 px|99.9978 px|
|Active ticks/time at 60 Hz|18 / 0.3000 s|18 / 0.3000 s|
|Including inactive exit update|0.316667 s|0.316667 s|
|Post-end/cancel cooldown|None|0.35 s / 21 game-physics ticks|
|Rapid presses within 120 ticks|Could extend continuously|3 separate accepted rolls|

`roll_cooldown_remaining` ticks once at the start of player physics using game-time `delta`, including forced-motion updates. `_end_movement_roll()` arms it only when ending an active roll. Natural completion, fresh direction/release, valid jump and actual Motion Swap interruption use that route. Rejected presses cannot extend, reset or queue another roll. Explicit test-room retry clears it with the other reset state.

RUN, reversal, release, valid JUMP and air control apply on their accepting update during cooldown. A fresh roll starts immediately when ready; already-held/rejected input does not auto-fire later. No jump budget, gravity, vertical impulse, run acceleration/friction, capsule, collision solver or damage rule changes. Simultaneous valid jump wins. Existing M1-A V2 priority remains jump > fresh roll > M1; M1 during active roll is discarded, and M1 can start after roll ends during cooldown. No new roll-to-attack override was added to the unchanged punch driver.

Cooldown shares tactical game time: at 0.12 time scale it advances 0.002 s per physics tick, rather than using a second real-time timer. Motion Swap's existing real-time selection deadline remains separate and unchanged.

Continuous RUN between ready rolls can still provide a small travel advantage: nominally about 304.6 px/s versus 280 px/s RUN under earliest legal repetition. Cooldown removes indefinite continuous roll movement; it does not impose a speed penalty on RUN. This tradeoff remains for human feel review within the requested starting ranges.

## Sprite and native validation

Source Action 1–19 at 60 fps, 0.30 s between endpoints. The 18 displayed samples are source 1–18; the final ready endpoint supports the return. Separate resources contain **372 untrimmed 82×82 cells / 116 clips**, with a 1476×1722 atlas, common pivot `(40.499926203,75.579576591)`, scale 1 and actual left/right model orientation. There are 36 main cells, 12 entry cells and 324 cancel cells. [Sprite metadata](../maincharacter/dodge_roll_v2/SPRITE_METADATA.json), [atlas validation](../maincharacter/dodge_roll_v2/SPRITE_VALIDATION.json).

Two entry samples from IDLE, RUN or the existing AIR pose fit inside the roll duration. Cancellation uses two native skeletal blends at 40% and 75%, followed by the **exact existing RUN 14, IDLE or AIR target cel**, over at most 0.05 s; control is already live. A second intent immediately interrupts that presentation. RUN returns at the matched stride rather than frame 0 or a restarted loop. AIR's raised-foot pose is preserved rather than lowered to the floor. All 108 final target copies are byte-identical to their sources, with zero endpoint neck/angle error. [Target provenance](../maincharacter/dodge_roll_v2/EXACT_TARGET_PROVENANCE.json), [handoff verification](../artifacts/dodge_roll_v2/HANDOFF_VALIDATION.json).

Godot owns all world displacement; sprites add only existing subpixel rounding. Neck positions are evaluated from each displayed native pose. Its attachment axis follows the roll and blends toward the existing locomotion screen-up basis with the body pose. Existing red flame cels, shader, spring response and floor constraint remain unchanged. No dust/trail/VFX was added.

A fresh native open checks 1,153 subframe evaluations at 1/64-frame spacing: **zero penetration samples**, minimum visible support clearance 0.136 mm, maximum gap 2.232 mm (about 0.082 native pixels), root translation 0, finite geometry, seek-back errors 0. All original Actions, rig/rest/hierarchy/weights/mesh/packed materials and the saved locked camera matrix/orthographic scale match exactly. Contact translation is baked at 1/32-frame; no handlers. [Native validation](../maincharacter/dodge_roll_v2/NATIVE_VALIDATION.json), [authoring](../maincharacter/dodge_roll_v2/AUTHORING.json). Support bounds do not prove every surface is collision-free or every pose has plausible weight bearing. The runtime export is sprites/metadata, so a GLB round-trip is not applicable.

## Engine, media and preservation

| Real Godot suite group | Checks / assertions | Result |
| --- | ---: | --- |
| Original 12 foundation, arena, Motion Swap, movement and combat regressions | 461 | Pass |
| Previous final-roll replay | 11 | Pass |
| Roll visual transitions | 30 | Pass |
| Existing M1-A V2 preview | 110 | Pass |
| New roll V2 controls | 30 | Pass |
| **16-suite regression total** | **642** | **Zero failures or script errors** |
| Captured before/after scenario assertions | 18 | Pass |
| Captured isolated gameplay assertions | 4 | Pass |

[Suite summary](../artifacts/dodge_roll_v2/REGRESSION_SUMMARY.json), [raw logs and receipts](../artifacts/dodge_roll_v2/regression/), [control measurements](../artifacts/dodge_roll_v2/control_results.json), [captured scenario results](../artifacts/dodge_roll_v2/after/results.json), [gameplay trace](../artifacts/dodge_roll_v2/demo/trace.json).

Coverage includes same-update activation, cooldown after natural exit and early/middle/late cancel, rejected-input suppression, no queue, movement/jump during cooldown, air jump budget, bounded velocity, a 2 px wall, forced-motion/tactical timing, no ordinary-contact damage, legitimate Charger attacks and high-speed impacts, Motion Swap, slow motion and existing M1 behavior. The [motion comparison](../artifacts/dodge_roll_v2/MOTION_COMPARISON.json) matches 364 before/after samples outside the repeated-input case with **zero position or velocity difference**.

Project import and isolated headless smoke pass in the [final validator receipt](../artifacts/dodge_roll_v2/validation_final/20261019T011548346Z-fcfc5ce5/receipt.json). That CLI receipt records L1 only; the rendered input replays are separate evidence above. No exported build was tested. Final capture processes exit 0 without project script errors. The known Intel OpenGL warning triggers ANGLE fallback.

Initial missing-import runs, the older fixture that retried during the newly required cooldown, and intermediate AIR-handoff captures remain in the evidence folder. Final receipts identify passing reruns. Visual review caught an approximately 8 px AIR endpoint drop in an intermediate blend; preserving AIR height and using exact target cels corrected it before the final captures.

Actual recordings:

- [Old versus new, normal speed](../artifacts/dodge_roll_v2/OLD_VS_NEW.mp4): 6.75 s, matching real-scene input replays, old left / V2 right, both using the evidence-only 4× inspection view.
- [Gameplay demonstration](../artifacts/dodge_roll_v2/GAMEPLAY.mp4): 10.02 s, native world travel alongside nearest-neighbor 4× inspection. Includes run, reverse, jump, air roll, spam, wall, early/middle/late cancels and M1 input priority.
- [Close-up comparison, four times slower](../artifacts/dodge_roll_v2/CLOSEUP_SLOW_4X.mp4): inspection footage retimed without generated intermediate images, approximately 15 fps over 26.93 s.
- [Repeated-input cooldown test](../artifacts/dodge_roll_v2/COOLDOWN_SPAM.mp4): 2.60 s including reset frames, with fresh roll input every two ticks.
- [Before separately](../artifacts/dodge_roll_v2/BEFORE.mp4), [after separately](../artifacts/dodge_roll_v2/AFTER.mp4).

All six MP4s pass full FFmpeg decode. Normal recordings are 60 fps. Captures use fixed 60 Hz game time; recording throughput is not a live FPS benchmark. Selected decoded normal/slow/cancel frames were opened and inspected; this is not manual viewing of every frame or physical-keyboard playtesting. [Media verification](../artifacts/dodge_roll_v2/MEDIA_VALIDATION.json), [decoded review indices](../artifacts/dodge_roll_v2/DECODED_REVIEW.json).

The [protected-file verification](../artifacts/dodge_roll_v2/PROTECTED_VERIFICATION.json) covers **28,778 baseline entries: 28,769 unchanged, nine authorized changes, zero unexpected changes or missing files**. It also verifies 111 M1 V2 entries unchanged and all 12 M1 delivery hashes. Source rigs, old atlases, flame source and game cameras remain unchanged. Existing player/visual M1 hooks predated this pass; the [player diff](../artifacts/dodge_roll_v2/player_THIS_PASS.diff) and [visual diff](../artifacts/dodge_roll_v2/iven_movement_visual_THIS_PASS.diff) isolate this task from the already dirty checkout.

## Exact changed files

Nine existing files changed:

- `scripts/player.gd`: the single cooldown authority and shared roll-end cleanup.
- `scripts/iven_movement_visual.gd`: separate V2 resources, entry/cancel sampling, matched return and neck basis.
- `tests/test_foundation_repair.gd`, `tests/test_movement_integration.gd`, `tests/test_roll_visual_transitions.gd`, `tests/final_roll_feel_replay.gd`: approved cooldown, terminal-sample and transition expectations/fixtures only.
- `design/MOVEMENT_COMBAT_FOUNDATION_QA.md`, `design/FINAL_ROLL_FEEL_QA.md`, `design/ROLL_VISUAL_TRANSITION_QA.md`: supersession notices.

New files: this report; `labs/dodge_roll_v2_preview.tscn`; `scripts/previews/dodge_roll_v2_preview.gd` and UID; `tests/test_dodge_roll_v2.gd`, `tests/dodge_roll_v2_replay.gd`, `tests/dodge_roll_v2_demo.gd` and their UIDs; five resources in `art/iven/movement/roll_v2/`; native Action/renders/authoring tools in `maincharacter/dodge_roll_v2/`; and evidence/capture/verification tools in `artifacts/dodge_roll_v2/`. `artifacts/.gdignore` prevents evidence images from becoming game imports. Unrelated pre-existing untracked files are excluded.

The [exact path/size/SHA256 manifest](../artifacts/dodge_roll_v2/changed_files.json) enumerates these files, including native renders, raw captures and intermediate evidence. The [delivery receipt](../artifacts/dodge_roll_v2/DELIVERY_RECEIPT.json) hashes the review deliverables and records final checks.

## Review and remaining limits

Open `labs/dodge_roll_v2_preview.tscn` and use editor F6: native world travel at left and nearest-neighbor 4× inspection at right. A/D move, Shift/L roll, Space/W/Up jump, J/LMB existing M1-A V2, R explicit retry. Existing main/F5 lab and cameras are unchanged.

Judge compactness, support, flame overlap, rapid reversal and early/mid/late unfolds at native size and normal speed. The source costume's coat/sash compression and toe scuff remain; there is no exhaustive cloth/self-intersection proof. The existing flame floor limiter redirects the inverted flame and can cause body overlap. The three-cel unfold is deliberately short and can still be perceptually abrupt from full inversion. The single existing AIR/IDLE pose limits continuous arbitrary-pose transitions. No physical-keyboard latency, live FPS benchmark, exported-build certification or human fun/feel approval is claimed.

The unchanged isolated M1-A V2 driver gives any fresh roll press defensive cancel priority, even if cooldown prevents a new roll: it can exit the planted attack into locomotion without starting a dodge. There is no queued punch or roll. This inherited input-priority edge remains for human combat review; this pass does not edit the punch driver or its assets.

**Stopped at this roll prototype and QA for human approval.** No JUMP redesign, M1-B/M2, enemies, abilities, VFX or new game map.


Reproduce the focused checks and open the isolated scene:

```powershell
$godotExe = 'C:\Users\Aloha\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --path E:\neverlookback --script res://tests/test_dodge_roll_v2.gd
& $godotExe --headless --path E:\neverlookback --script res://tests/test_foundation_repair.gd
& $godotExe --headless --path E:\neverlookback --script res://tests/test_motion_swap_chaos.gd
& $godotExe --path E:\neverlookback res://labs/dodge_roll_v2_preview.tscn
```

`artifacts/dodge_roll_v2/run_regressions.py` runs all 16 suites while retaining the older reports' fixed-output evidence. BEFORE was captured before edits; current code cannot recreate it without the preserved source state.
