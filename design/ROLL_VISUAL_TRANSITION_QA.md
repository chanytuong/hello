# Roll visual transition repair

> Superseded presentation: [Dodge roll V2 QA](DODGE_ROLL_V2_REDESIGN_QA.md) creates a new compact native Action and phase-specific unfolds, with 0.35 s post-end/cancel cooldown. This report and its media preserve the previous candidate.

2026-10-18 · Godot 4.7.2 stable · Windows / Compatibility / ANGLE.

**Implemented as an animation-integration candidate; human visual approval remains pending.** Entry now uses existing authored bridge poses, return resumes the matched run stride, cancellation unfolds over at most two visual updates, and repeated roll presses no longer rewind the current tumble. Approved gameplay tuning is unchanged. No M1/M2, combat, VFX or map work was added.

## Before / after evidence

- [Synchronized before/after video](../artifacts/roll_visual_transition/BEFORE_AFTER.mp4): 6.75 s, normal 60 fps playback, 2560×720 split view. Both sides use the identical input sequence.
- [Before at full viewport size](../artifacts/roll_visual_transition/BEFORE.mp4), [after at full viewport size](../artifacts/roll_visual_transition/AFTER.mp4), each 1280×720.
- [RUN entry filmstrip](../artifacts/roll_visual_transition/after_00_roll_entry.png), [matched RUN return](../artifacts/roll_visual_transition/after_01_natural_exit.png).
- Tucked jump cancellation: [before frames](../artifacts/roll_visual_transition/before_04_cancel.png), [after frames](../artifacts/roll_visual_transition/after_04_cancel.png).
- [Immediate reversal](../artifacts/roll_visual_transition/after_03_cancel.png), [air-roll cancellation](../artifacts/roll_visual_transition/after_06_cancel.png), [repeated roll](../artifacts/roll_visual_transition/after_repeat.png), [solid wall](../artifacts/roll_visual_transition/after_wall.png).
- [Before trace](../artifacts/roll_visual_transition/before/results.json), [final trace and 30 visual checks](../artifacts/roll_visual_transition/after/results.json), [exact motion comparison](../artifacts/roll_visual_transition/motion_comparison.json).
- [Regression summary](../artifacts/roll_visual_transition/regression_summary.json), [media decode checks](../artifacts/roll_visual_transition/media_verification.json), [delivery receipt and exact file manifest](../artifacts/roll_visual_transition/DELIVERY_RECEIPT.json).

These are real Godot controller/physics runs with actual sprite rendering. The replay uses a **test-only 4× inspection camera**; the shipped camera script, scene and framing are unchanged. Every one of the 405 observed updates per version was saved as a framebuffer, and transition filmstrips and decoded video frames were inspected. The MP4s are encoded from those consecutive framebuffers at 60 fps, without slow motion or interpolated frames. Raw Movie Maker AVIs also remain in the artifact folder; their initial fixture-setup frames are omitted from the comparison. Recording throughput is not a live FPS or hardware-input-latency measurement.

## Actual causes

1. **Existing entry/return art was omitted from runtime integration.** `maincharacter/dodge_roll/body/{right,left}/` already contains `RUN_IN_1/2`, `IDLE_IN_1/2` and three OUT samples, with matching projected neck metadata in `PREVIEW_ANCHORS.json`. The runtime resource contained only the 21 core roll drawings. It therefore jumped directly from running/standing into the crouched `ROLL_01`. [Existing source poses](../artifacts/roll_visual_transition/EXISTING_BRIDGE_POSES.png).
2. **Every RUN return reset to drawing 0.** The source validation explicitly recommends RUN phase 14 on return (zero-based drawing 13). Returning from the last roll drawing into RUN 0 changed the leg/hip silhouette unnecessarily. The existing authored OUT samples already lead into RUN 14.
3. **Arbitrary cancellation had no visual exit.** An inverted core roll drawing could be replaced by the single upright JUMP or IDLE drawing in one update. The tucked jump test changed its pose-local neck height by 53.58 native pixels at once. The controller's physical jump was correct; the pose substitution created the apparent teleport.
4. **Fresh roll presses rewound the displayed roll clock.** Core drawing selection used `roll_duration - roll_remaining`. Repressing roll reset `roll_remaining` even while the same visual state remained active, so the drawing jumped back to 0 during an ongoing tumble.
5. **Attachment orientation also changed abruptly at clip boundaries.** The roll used the measured neck angle, while normal locomotion uses the upright flame basis. The short entry/exit presentation now eases that existing transform together with the body poses. Flame artwork, controller and shader are unchanged.

No shared-origin mismatch or duplicated root motion was found. The original cells are untrimmed 82×82 textures with a common projected pivot `(40.499926203, 75.579576591)`. The roll's authored hip/torso lowering is real pose motion; missing entry art exposed it as a sudden collapse. Runtime code already updated the logical state after the collision solve and only called `play()` when the clip changed. Those mechanisms were retained; there was no evidence of a general per-update animation restart bug outside the roll timer reset.

Inspection included the atlas, frame/anchor metadata, native authoring/validation reports, RUN/IDLE/JUMP playback and the previous two QA reports. No root, ancestor or applicable project `AGENTS.md` was found. Local `agentskill/` packages were enumerated; relevant Godot implementation/animation, Game Feel response/measurement and evidence-gate guidance was read.

## Repair

Only `scripts/iven_movement_visual.gd` changes shipped behavior.

- Reuse **16 existing body PNGs byte-for-byte**, with their existing anchors, in a small companion SpriteFrames resource. The original atlas, SpriteFrames, source PNGs and native rig files are unchanged. Both facings have RUN/IDLE entry samples 1/2 and return samples 1/3; no character drawing or Blender render was generated.
- Use the two entry drawings **inside** the approved roll's existing duration, then sample the core roll through its final drawing. The visual clock remains independent of a repeated gameplay roll press, so an ongoing tumble continues instead of rewinding. When that visual cycle wraps, it reuses the short entry.
- On natural completion, show the two existing return samples while gameplay is already RUN/IDLE/AIR. RUN then resumes at drawing 13, matching the authored return pose, with its ordinary 30 fps stride clock.
- On an early cancel, select at most two existing entry/recovery drawings toward the requested pose. Selection favors vertical neck continuity, rather than skipping the crouch to minimize sideways neck travel around the tumble. This is sprite-pose selection, not skeletal interpolation or a new animation Action.
- Use the **new facing immediately** for every displayed body/bridge drawing. Logical state changes immediately too. Any subsequent action can interrupt the presentation; no physics waits for the bridge to finish.
- Keep the common body offset and per-drawing neck attachment. There is no body recentering, position tween, duplicate sprite, crossfade, scale deformation or root-motion contribution. The only visual position correction remains subpixel-to-pixel snapping.

At normal 60 Hz, each entry/exit uses two displayed updates (33.3 ms total). During tactical slow motion the presentation follows scaled world time, as other animation does. It never gates gameplay input. Mid-roll cancellation does not play the rest of the roll or impose recovery.

## Measured visual change

The following diagnostic measures the largest **pose-local vertical neck landmark change** in the cancellation/return update and the next two updates. Physics translation and camera movement are excluded. It is a useful continuity measure, not a hip-bone measurement or proof of artistic quality.

| Same input event | Before, native px | After, native px |
| --- | ---: | ---: |
| RUN → ROLL entry | 10.30 | 5.69 |
| Natural ROLL → RUN return | 2.65 | 0.40 |
| RUN → ROLL → STOP | 40.67 | 12.80 |
| ROLL → reverse | 47.55 | 15.19 |
| Tucked ROLL → JUMP | 53.58 | 18.62 |
| AIR ROLL → MOVE | 52.12 | 15.73 |
| Movement cancel at ticks 2 / 7 / 11 / 16 | 14.67 / 35.53 / 39.80 / 10.06 | 1.43 / 9.86 / 17.92 / 5.63 |

The close-up frames show the corresponding intermediate silhouettes, correct facing, shared support plane and matched run leg on return. The repeat sequence advances through the tumble instead of returning to drawing 0 on each press. The wall sequence keeps the body root stopped at the solid wall while the roll pose finishes and returns to idle, with HP intact. [Before metrics](../artifacts/roll_visual_transition/before_visual_metrics.json), [after metrics](../artifacts/roll_visual_transition/after_visual_metrics.json).

Feet/root alignment was checked against the common pivot and visible support plane in the frame sequences. No per-frame foot normalization was applied: the source roll legitimately transfers support between boots, hands, back and coat. Exact hip/foot locking for every interrupted pose cannot be established from a neck landmark or sprite silhouettes alone.

## Gameplay and regressions

**All 405 before/after updates have exactly equal player positions, velocities and roll timers (maximum difference 0.0).** `scripts/player.gd` is byte-identical to the accepted tuning. The primary foundation measurement remains approximately 100 px of ground travel at 333.3333333 px/s, with 0.29 s configured duration / 18 active 60 Hz ticks (0.30 s). Run speed/acceleration/friction, jump impulse, capsule, inputs and collision solver are unchanged.

**502 checks pass:** the existing 461-check regression set, the prior 11-check roll-tuning replay, and the new 30-check rendered transition replay. No existing test assertion was relaxed or changed in this pass.

| Suite | Checks / assertions | Result |
| --- | ---: | --- |
| Movement integration, both facings | 166 | Pass |
| Foundation movement/damage | 34 | Pass |
| Motion Swap Chaos | 65 | Pass |
| Lab integration | 32 | Pass |
| Existing Zone F arena | 15 | Pass |
| Motion Swap contract | 43 | Pass |
| Runtime / legacy arena / identity | 7 / 15 / 21 | Pass |
| Weapon / feel / strand | 50 / 10 / 3 | Pass |
| Prior final-roll replay | 11 | Pass |
| New rendered transition replay | 30 | Pass |

Coverage retains immediate activation, all required ground/air cancellation sequences, repeated rolls without velocity accumulation, no extra jump/vertical impulse, wall collision, passive-contact safety, intended Charger attacks, fast bullets, physical impacts, self swap, Overdrive and tactical-time restoration. New checks cover two-update visual settling, immediate displayed facing, matching run return, no tumble rewind, displayed-frame neck attachment and no extra visual root displacement.

Final project import and lab smoke validation pass. The Intel driver warning still selects ANGLE; final runs contain no project script errors. The first transition candidate was visually inspected, then its pose-selection cost was adjusted to prioritize vertical unfolding before the final replay and regressions. Earlier candidate logs remain. Historical fixed-path receipts were preserved, new receipts copied under this pass's artifact directory, and the earlier receipts restored.

## Exact files

Changed/added code and documentation:

- `scripts/iven_movement_visual.gd`.
- `tests/test_roll_visual_transitions.gd` and its generated `.gd.uid` companion.
- `design/ROLL_VISUAL_TRANSITION_QA.md`.
- `design/FINAL_ROLL_FEEL_QA.md`: a notice linking this subsequent visual repair; its physics measurements remain historical evidence.

New runtime companion data under `art/iven/movement/roll_transitions/`: `frames.tres`, `anchors.json`, `provenance.json`, and these exact copied PNGs, each with a generated `.png.import` sidecar:

```text
left_RUN_IN_1.png      left_RUN_IN_2.png
left_RUN_OUT_1.png     left_RUN_OUT_3.png
left_IDLE_IN_1.png     left_IDLE_IN_2.png
left_IDLE_OUT_1.png    left_IDLE_OUT_3.png
right_RUN_IN_1.png     right_RUN_IN_2.png
right_RUN_OUT_1.png    right_RUN_OUT_3.png
right_IDLE_IN_1.png    right_IDLE_IN_2.png
right_IDLE_OUT_1.png   right_IDLE_OUT_3.png
```

[Copy provenance and hashes](../art/iven/movement/roll_transitions/provenance.json), [exact 40-file manifest](../artifacts/roll_visual_transition/changed_files.json). Evidence and source snapshots are under `artifacts/roll_visual_transition/`, with `.gdignore` created before source backups. The manifest compares against this pass's pre-edit workspace, preserving earlier uncommitted foundation work.

[Protected-file verification](../artifacts/roll_visual_transition/protected_verification.json) matched **29,788 pre-existing protected entries, zero differences**, excluding the intentionally edited visual integration script. The 16 byte-identical new runtime copies were checked separately against their existing source PNGs. The approved gameplay, damage, enemies, Motion Swap, scenes, original atlases, anchors, flame source, shaders and camera are preserved. No native rig or source animation was regenerated or edited.

## Human acceptance and limits

Use editor F5 for the existing lab or editor F6 on `scenes/movement_test.tscn`. Test at native size as well as in the close-up comparison: RUN→ROLL→RUN, release during roll, immediate reversal, jump from the tucked phase, jump→air roll→move, repeated presses and wall contact. Shift/L rolls, A/D/arrows move, Space/W/Up jumps. Existing E/LMB/Q/RMB controls and arena reset 1 remain.

The source frames support a clearer short entry and natural return. They cannot provide a continuous skeletal blend from every arbitrary inverted pose into the single held JUMP/IDLE drawing within two updates. The bounded unfold is still fast, especially on a late/inverted jump or reversal. RUN entry uses the existing preview's phase-specific bridge; a different incoming leg phase can still change its silhouette. Source toe rocking/scuff and garment deformation remain. These are concrete human review points, not claims of seamlessness or final animation approval.

Reproduce the close-up visual replay with the local Godot executable:

```powershell
$godotExe = 'C:\Users\Aloha\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --path E:\neverlookback --script res://tests/test_roll_visual_transitions.gd --write-movie E:\neverlookback\artifacts\roll_visual_transition\AFTER.avi -- --capture
& $godotExe --headless --path E:\neverlookback --script res://tests/test_foundation_repair.gd
& $godotExe --headless --path E:\neverlookback --script res://tests/test_motion_swap_chaos.gd
```

The BEFORE footage was recorded before integration changes. A BEFORE label on the current script does not restore the old renderer; its pre-edit copy is retained in the ignored evidence snapshots. No exported-build, physical-keyboard-latency or human normal-speed feel certification is claimed. Stop remains at this repair, pending human gameplay/visual approval.

## Research basis

Motion Twin artist Thomas Vasseur describes timing convincing key poses before adding supporting frames, and adapting animation timing to gameplay. The applicable inference here is to restore the existing entry/return poses and choose readable interrupted silhouettes; no Dead Cells frame counts or transition implementation were assumed. [Vasseur's first-person account](https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i-).

The released Celeste player source separates facing/sprite presentation from collision and movement; its presentation scale is restored after drawing. That supports keeping this repair in the visual layer, without copying its physics or effects. [Celeste developer source](https://github.com/NoelFB/Celeste/blob/master/Source/Player/Player.cs). Godot documents explicit sprite-frame control and distinguishes immediate/synchronized state transitions from waiting for animation end. [2D sprite animation](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html), [animation transitions](https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html). No reference gameplay footage was claimed as viewed; these are primary written/source-code references.
