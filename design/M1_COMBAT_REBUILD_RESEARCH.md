# Expressive M1 rebuild — evidence and production decisions

2026-10-19 · NEVERLOOKBACK · research completed before new animation authoring

The latest supplied brief replaces the stationary-punch and running-punch requirements. The initial three-move hypothesis was an advancing left straight, turning right hook and short stepping left elbow. Three different paths are sufficient; a fourth has no demonstrated purpose. These are authored Iven proposals, not attacks traced from sword footage. Palette B and the redesigned model are locked by this brief. Old M1 remains available for comparison and rollback. Production refinements after testing are recorded at the end.

## Preparation and preservation

Read the two earlier combat studies, M1/full-combo and movement QA, the pixel pipeline master guide/quickstart, and relevant Blender animation, Godot animation, pixel-art, combat-design and game-feel skills. Enumerated 14 packages / 447 skills; no applicable AGENTS.md was found. [Inventory](../artifacts/m1_combat_rebuild/SKILL_INVENTORY.txt).

Checkpoint `99dd6bc` preserves the existing state. A fresh 10,652-file hash baseline protects approved assets, previous combat, controllers and previous visual-refinement work. [Baseline](../artifacts/m1_combat_rebuild/PROTECTED_BEFORE.json). Read-only opening of `IVEN_COLOR_REFINED.blend` confirms 101 bones, 15 existing Actions, the seven REFINE_B material assignments, and the exact saved camera. [Audit](../artifacts/m1_combat_rebuild/TARGET_READ_ONLY_AUDIT.json). The current authority is the approved **Eevee, 82×82, one sample, Standard / None / exposure 0** pipeline, not the obsolete Workbench setup in the earlier research.

## User video: actual examination

The supplied `36bf9305-e30d-4e9a-8e22-36fa9bf5c3a6.mp4` contains 835 video frames across 34.462 seconds, variable timestamps, 1280×576. Full decoding succeeded. Three overview boards cover the entire clip; four dense sequences contain 67, 56, 47 and 115 consecutive original frames. All dense boards were opened. Frame numbers below are zero-based and follow original presentation timestamps, not a presumed game animation rate. [Metadata, hash and every frame timestamp](../artifacts/m1_combat_rebuild/research/USER_VIDEO_SOURCE.json), [dense indices/crops](../artifacts/m1_combat_rebuild/research/USER_DENSE_INDEX.json).

![Timestamped original-frame study](../artifacts/m1_combat_rebuild/research/USER_ANNOTATED_STORYBOARD.png)

| Examined interval | Observed | Consequence for Iven |
|---|---|---|
| 0–2.75 s, opening near Chopping block | At f2 / 0.083 s blade lowers and the spare arm separates. f4 / 0.166 s has a low arc; f7 / 0.291 s carries the blade above the shoulder. f11 / 0.455 s gathers, then f13 / 0.537 s makes a more compact low shape. f16 / 0.661 s returns upright. The clip starts after a ready pose, not at an authenticated input. | Vary direction, elbow angle and torso height. Let the preceding recoil prepare the next action. Do not identify all opening gestures as confirmed hits or one measured combo. |
| 14.35–16.65 s | Running approach becomes raised preparation at f376 / 15.521 s. Victim blood and displayed 26 appear at f379 / 15.644 s. f382 / 15.768 s changes body/weapon direction with another reaction; f390 / 16.097 s has a much larger arc. | Give each contact a recognizable pose and direction. Contact feedback should agree with that pose; movement-to-attack must respond without a long cosmetic bridge. |
| 17.6–19.55 s | Left-facing close exchanges alternate gathered, inclined and broader shapes. Crowd/effect overlap hides portions of the arm. An enemy's red attack arc must not be assigned to the player. By 19.397–19.521 s the player recovers and moves low away. | Inspect both facings. Succession into low travel establishes visible continuity, not a proven roll-cancel window. |
| 29.7–34.462 s | Shield enemy blocks/attacks, followed by a red hurt screen around 30.42 s. Player recovers, approaches again, passes low across the enemy at 32.2–32.8 s, then attacks around 32.94 s and makes a broad arc near 33.35 s. | Separate damage/hurt pauses from attack feedback. A low traversal pose is not another fist strike. |

The supplied sword is not identified reliably by its icon alone. Screen panning, slope/platform changes and occlusion prevent deriving exact world displacement or planted-foot error from raw screen coordinates. Feet, knees and body inclination visibly change; ground force is an inference. Repeated drawings can be animation holds, hitstop, video sampling or combinations of these. No input trace, internal hitboxes, cancel timing, hardware latency or exact combo count was measured. Sound was not audited.

## Additional Dead Cells weapon families

Downloaded ordinary accessible gameplay excerpts, retained URL/title/uploader/section/hash metadata and examined actual gear menus plus footage. No access restriction or authentication was bypassed. These are different captured runs/builds, not a controlled current-version input experiment. Original footage remains attributed research evidence outside the game build.

| Firsthand gameplay source | Examined evidence | Observed contrast / limits |
|---|---|---|
| Modesto, [Balanced Blade Showcase (Season 2)](https://www.youtube.com/watch?v=Ye9CBFcrybM) | 0–90 s overview; gear name visible around 54 s. Dense 70.4–72.0 s, 97 consecutive source frames. [Cropped landmarks](../artifacts/m1_combat_rebuild/research/weapons/balanced_CROPPED_LANDMARKS.png). | Around 71.1–71.6 s compact high/low sweeps and inclined torso shapes succeed one another against close opponents. The earlier roll/door burst is excluded as blade contact. Crowd and effects obscure exact hand paths. |
| Modesto, [Twin Daggers Showcase (5BC)](https://www.youtube.com/watch?v=zGDEChmcLKI) | 0–90 s overview; gear name visible around 72 s. Dense 58.8–60.6 s, 109 consecutive frames. [Landmarks](../artifacts/m1_combat_rebuild/research/weapons/twin_daggers_CROPPED_LANDMARKS.png). | Ledge/door action precedes close low-to-rising attacks around 59.7–60.3 s. Compact lowered support and a rising arc contrast with broader follow-through. Door destruction and crossing effects cannot establish weapon damage attribution for every burst. |
| Modesto, [Broadsword Showcase (Season 2)](https://www.youtube.com/watch?v=eW8-2W1NobE) | 0–90 s overview plus 90–135 s continuation; gear name visible 75–78 s. Dense 116–118 s, 121 source frames including the endpoint. [Landmarks](../artifacts/m1_combat_rebuild/research/weapons/broadsword_CROPPED_LANDMARKS.png). | Larger gathered arm/blade positions, substantial body bending, and a very broad sweep near 117.4 s. The white-caped player must be distinguished from the magenta enemy. Stronger silhouette contrast than the compact blade exchanges; overlapping effects and slowed status prevent a clean speed comparison. |

[Source receipts and decoded clips](../artifacts/m1_combat_rebuild/research/weapons/). This study does not claim to have examined Swift Sword or Assassin's Dagger, nor that all weapons share combo length or cancel policy.

### Developer documentation and movement/cancellation boundary

Thomas Vasseur describes establishing convincing, timed key poses before interpolation, rendering a small 3D character without antialiasing, and using pose-to-pose attacks with effects to clarify movement. We adopt that production order, not weapon reach or anatomy. [Motion Twin production account, 25 January 2018](https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i-).

Motion Twin's lead designer describes fast, fluid controls and equipment supporting different play styles. This states a design goal, not measured cancel windows. [Developer article](https://blog.playstation.com/2018/01/25/rogue-lite-action-platformer-dead-cells-coming-to-ps4-this-year/).

Official Update 24 notes reduced forward movement for Katana's basic attack while leaving its charged attack unchanged, alongside weapon-specific adjustments. Thus attack travel and commitment are explicitly weapon- and version-dependent. [Official patch notes](https://deadcells.com/patchnotes/24).

The inspected footage shows attacks followed by travel/low movement, but cannot determine when held direction becomes accepted or whether a roll interrupts recovery. No universal Dead Cells cancellation rule is established here. Hitstop is a short contact-related pause; an attack movement restriction is a separate controller policy and may occur even on a whiff. Iven's proposed policy is explicit below, rather than inferred from repeated video frames.

## Unarmed mechanics and limits

Reopened the prior study's actual Gal, MRB and Misako consecutive boards. Reuse their documented source receipts rather than repeating the search. [Earlier research](COMBAT_ANIMATION_REFERENCE_RESEARCH.md).

- [Gal training, WahnTawns](https://www.youtube.com/watch?v=yAPt0wCTfU4), 33.00–33.38 s: compact extensions/retractions, separated spare arm and shoulder/profile change over nearly fixed support. Subsequent kicks are excluded. Useful for the first short straight and deliberate recoil.
- [MRB developer trailer](https://www.youtube.com/watch?v=uxYtskZkyK4), 37.20–37.77 s: green-shorts fighter's short grounded unarmed strikes coincide with victim head/shoulder recoil; bent-knee support and modest torso commitment. Alpha footage. Useful for contact alignment and weight, not exact hitstop.
- [WayForward Misako spotlight](https://www.youtube.com/watch?v=SA5vCVBf6s8), 26.0–26.8 s: compact exchanges are partly obscured. Larger downward ground attacks at 36.4–37.9 s demonstrate shape contrast, not a neutral hook. Kyoko's later throw is excluded as punch anatomy.

These excerpts do not cleanly establish an elbow technique or every anatomical hand identity. The proposed bent-arm hook and folded-arm elbow are new authored choices to be judged through Iven's actual rig, not claims of traced game moves. Boxing/ShadowBoxing remain motion references; no donor curves will be copied. Their unresolved license provenance is unchanged.

## Implementation hypothesis

| Stage | Construction / timing hypothesis | Travel hypothesis | Connection |
|---|---|---|---|
| 1: drive straight L | Short step, shoulder-led soft-elbow extension; 0.2333 s, contact 0.05 s | 5 px, synchronized with lead-foot step | Recoil holds coordinated support/turn for stage 2, chain at 0.1667 s |
| 2: turning hook R | Bent elbow, curved lower fist path, opposite chest/hip turn; 0.2667 s, contact 0.0667 s | 2 px, pressure transfer rather than another dash | Return across the body prepares folded L arm; chain at 0.20 s |
| 3: stepping short elbow L | Folded forearm and projected elbow, trailing foot catches the advancing body; 0.3333 s, contact 0.10 s | 7 px, stronger but short step | Controlled recoil and foot catch return to existing IDLE/RUN |

Numbers are prototype budgets to verify, not reference-game measurements. Author anticipation/contact/follow-through/recovery poses first, render both actual orientations through the saved camera, then refine. No phase-indexed running attacks. Root remains neutral in exported sprites; authored support is measured against a virtual travel curve applied once by Godot. Collision-limited travel must be tested separately from unobstructed support.

Current code uses `NLBM1Combo`, the player's existing swing HitBox, HurtBox/Health victim guard, pose-derived flame anchors, per-strike contact times and local hitstop. The old controller suppresses horizontal movement and uses three similar straights. Preserve it as a rollback fixture; add a new M1 driver and a small optional post-jump movement hook in the player. Keep normal movement, defensive physics, health and Motion Swap architecture intact.

Proposed priority: Motion Swap/death/forced state suppress combat; fresh eligible ROLL or valid JUMP interrupts any M1 phase immediately; attack advance otherwise owns horizontal motion for its brief clip. Held direction resumes at recovery end. A reversal can leave late recovery without flipping the contact pose. One fresh press starts one attack; a short expiring buffer advances only one stage. Cancellation clears it. No auto-chain from a held click. Contact volumes follow the evaluated fist for stages 1/2 and elbow for stage 3, with one victim guard per attack instance. Local hitstop pauses only accepted-hit attack playback/travel, never defensive input.

Required QA: singles and full chain in both facings; IDLE/RUN entry and return; interruptions in preparation/contact/recovery and hitstop; short/expired/held inputs; wall and multiple-HurtBox cases; Motion Swap LMB selection; 30/60/120 Hz displacement and damage. Preserve all approved source files and existing movement sprites. Report any remaining movement-to-palette mismatch honestly rather than replacing RUN artwork.

Research is complete; production and actual gameplay verification follow. This report is not a visual acceptance claim.

## Production refinement after research, 20 October

Native testing confirmed the value of a projected straight, bent rotational follow-up and a folded-arm finish. Testing the game's actual unscaled graybox enemies exposed a reach/height problem hidden by the character-height comparison fixture: high fist/elbow contacts passed above their smaller hurtboxes. Production therefore lowers the straight and body hook, and uses a compact downward **forearm/closed-hand body blow** for stage 3. This is an authored refinement, not a newly verified elbow technique in the reference footage. Gameplay volumes remain attached to evaluated hands rather than being extended invisibly toward targets.

The third advance is delayed into contact/follow-through so the supporting step can follow accepted target recoil. Static walls/props choose braced copies of the same upper-body attacks, keeping the feet planted when advance is obstructed. This is one deterministic support choice, not a RUN-phase bank or procedural combo generator. Final pose, contact and input results belong to the production QA report.
