# Full M1 three-hit combo — human review candidate

2026-10-19 · Asia/Saigon · Blender3.6.23 / Godot4.7.2. The full-combo brief supersedes the isolated M1-A gate and historical simultaneous running-punch proposal. Checkpoint `7218014` preserves M1-A V2 and the latest roll/cooldown work.

Three source-derived Actions on the existing101-bone AccuRIG candidate: **`IVEN_M1_1` / `IVEN_M1_2` / `IVEN_M1_3`**. No M2, new rig, weights, costume or locomotion edits. [Editable source and previews](../maincharacter/m1_full_combo/README.md), [research completed before editing](../maincharacter/m1_full_combo/RESEARCH_AND_DESIGN.md).

## Motion and timing

| Strike | Donor / anatomical arm | Startup | Active interval | Recovery ends | Earliest next strike | Damage | Horizontal knockback |
|---|---|---:|---|---:|---:|---:|---:|
|M1-1|Boxing135–143 / L|.040s|[.040,.100)|.200s|.150s|1HP|60px/s|
|M1-2|Boxing239–247 / R|.040s|[.040,.100)|.200s|.150s|1HP|70px/s|
|M1-3|ShadowBoxing263–273 / L|.066667s|[.066667,.133333)|.280s|none|2HP|90px/s|

These are Iven prototype values, not reference-game frame counts. Contact first appears on the eligible60Hz update: age.050/.050/.066667, cel2 for each. The same clock selects the sprite and enables damage. First two late-recovery branches feed exact source poses into the next Action; their unchained tails return toward existing IDLE. At earliest branching the nominal sequence is.58s before sampling/hitstop, rather than the sum of three independent full recoveries.

The recorded connected sequence measures **.650s** from first acceptance to release in both facings, including local hitstop. Its horizontal root range is **0px**, all attack samples are grounded, and there is no READY/neutral interval between linked strikes. [Measured sequence](../maincharacter/m1_full_combo/COMBO_METRICS.json).

Rest-calibrated donor support/hip/spine/shoulder motion is restrained for Iven. Native-length arm solves retain soft elbows, hand opposition and counterarm shape. Initial renders exposed a bent/upward right contact and finisher; local animation-side fist paths and hand axes were corrected, then rerendered in both facings. The source T-pose, long setup, unrelated dips and departure are excluded. This is not the rejected arm-only prototype with new labels.

## Controls and damage authority

- On grounded M1 acceptance: first gathered pose and velocity.x0 on the same update, with no post-input horizontal step, lunge, forced SKID or pre-stop animation. No RUN-leg attack variants. Facing remains coherent until release; current direction is read throughout and resumes at recovery end.
- One fresh press per strike. One pending follow-up lasts at most.12s and may branch from.15s in strikes1/2. Too-early presses expire; excess presses cannot stack; holding does not repeat. The chain resets on completion or interruption. No stale third/fresh combo is queued during the finisher.
- Priority: **valid JUMP > available fresh ROLL > M1 > direction**. Both defensive actions interrupt anticipation/contact/recovery, including local hitstop. An unavailable roll cannot bypass the existing.35s cooldown or queue itself. Damage, E selection, actual Motion Swap, forced motion and loss of ground clear attack/pending state.
- Existing `NLBHitBox → NLBHurtBox → NLBHealth` owns all damage. One Health guard per strike epoch prevents duplicate damage across overlapping HurtBoxes. Each strike gets a new attacker/serial ID. The reused box is queried synchronously at the evaluated striking-fist landmark with7px radius; it is off outside the active interval. No contact damage or competing HP system is introduced.
- M1 uses.06s victim immunity so separate strikes can connect; other damage retains its existing iframe rule. Accepted damage is measured as HP-before minus HP-after, including lethal clamps. The demonstrated12HP target follows12→11→10→8.
- Feedback: existing immediate enemy flash/stagger/knockback, a small contact cross, three original short dry impact WAVs; finisher has larger5px flash versus3px and longer/deeper sound. Configurable local attack/victim hold is1/60s for strikes1/2 and2/60s for3. Global time scale, gravity and world simulation keep their existing authority. Hitstop holds the contact drawing; it is separate from the brief grounded attack commitment.

Implementation is a small component used by the existing player controller. `m1_combo_enabled` opts the main Motion Swap lab and new isolated review lab in. Existing legacy combat and movement-only test scenes keep their previous path. Enemy presentation rectangles ignore mouse events so real LMB can reach the existing E selector. Q/RMB roles remain intact.

## Native and preservation proof

[Fresh Blender receipt](../maincharacter/m1_full_combo/NATIVE_VALIDATION.json):329 subframe evaluations, finite geometry; original mesh/topology/UV/skin/rest/hierarchy/material/packed-image signatures and all original Action curves match. Latest roll V2 Action is also copied unchanged into the editable library. Exact saved camera matrix error0, ortho scale2.2200000286. No Euler reconstruction, reframing, root travel or frame handlers.

Minimum sampled sole clearance.219mm; maximum support gap.251mm; maximum ankle XY drift.0472mm (below.002 native pixels). Full-mesh chain endpoint errors are.000200mm and.000415mm; seek-back error0. Positive quaternion hemispheres preserve editable interpolation. These checks establish sampled continuity/support, not exhaustive self-collision freedom.

The render pipeline remains Workbench,82×82, AA-off; Standard/Medium High Contrast, exposure+.45, gamma1, fixed pivot(40.499926203,75.579576591). All54 native cells are contained in the738×492 atlas. Both facings rotate the character; the camera stays fixed. Existing red flame assets/controller/shader are unchanged; each cel exports evaluated neck/axis and L/R fist metadata.

## Validation and visual review

**101/101 focused checks pass in the actual1,595-frame rendered replay. All16 existing regression suites pass (642 existing checks).** [Input/damage/capture receipt](../artifacts/m1_full_combo/GAMEPLAY_VALIDATION.json), [regression summary and final raw-log references](../artifacts/m1_full_combo/regression/SUMMARY.json). The replay exercises actual player physics, collision queries, health acceptance and rendered viewport output, not damage calls pasted into a video. Core scenarios are enemy-free full chains; RUN→STOP→three accepted hits→RUN; first-strike roll and second-strike jump; both facings; one click/hold; eighteen strike/phase defensive cancels; duplicate HurtBoxes; roll cooldown; E/LMB/Q/RMB selection; buffer expiry and no stale attacks.

Two legacy suites use wall-clock targeting deadlines and require normal real-time execution, rather than accelerated fixed-fps headless mode. Their final original-suite runs pass65/0 and32/0. A transient exact RigidBody velocity-read assertion also passed a clean unchanged-suite rerun; earlier failing logs are retained. No legacy assertion or physics rule was weakened to obtain passing results.

Delivered media: animation-only **302frames /5.033s**, actual gameplay **1,595frames /26.583s**, slow inspection **6,379frames /106.317s**. All are1280×720,60fps,H.264/yuv420p and pass full FFmpeg decode; gameplay includes event-synchronised AAC sound. The native/nearest4× GIF decodes to105 merged frames over5.030s. Body sprites span60–64px. Opened all16 final decoded review boards (190 selected source frames), six clean contact views, decoded GIF samples and eight slow-video samples. This is selected-frame inspection, not a claim of manually watching every frame or measuring live rendering throughput. [Media receipt](../maincharacter/m1_full_combo/MEDIA_VALIDATION.json).

**6,919 protected files verified:6,914 unchanged, five authorised shared-code changes, zero missing/unexpected.** Those changes are player opt-in/cancel hooks, M1-specific health immunity, existing enemy local-hitstop/mouse presentation, controller discovery group and main-lab opt-in. Old prototypes, donor FBXs, approved movement/flame/body assets and original native files remain unchanged. [Preservation receipt](../maincharacter/m1_full_combo/PROTECTED_VERIFICATION.json). Final native metadata-only knockback changes were independently reopened with identical asset and Action-curve hashes: [reopen proof](../maincharacter/m1_full_combo/FINAL_METADATA_REOPEN.json).

The isolated encounter reuses PATROL with12HP, speed0 and1.5× instance scale (about57px body above its origin) to match Iven's native height. Retry uses a fresh instance and briefly warms mutual solid contact against the floor; HurtBox damage and input remain live. This avoids physics-derived velocity from a test-room teleport. It changes no production collision/impact thresholds. Hidden animation-only opponents have physics disabled. Intermediate captures exposed this fixture defect; only the final passing capture is delivered. The gameplay demonstration resumes RUN away from the solid opponent through explicit directional input; it does not imply that a roll or RUN can pass through an enemy.

## Acceptance limits

- Human review must judge overall punch rhythm, right-hand/contact shape and fast RUN replant/return. Fixed-pivot support does not guarantee every pose change feels fluid. No long cosmetic bridge or movement lock hides the joins.
- The7px fist volume intentionally follows the visible high straight. Short original graybox enemies can fall below it; the scaled review fixture does not establish universal height coverage. No automatic vertical aim, enlarged invisible reach, crouch attack or enemy redesign is delivered.
- Existing coat/sash and rig-candidate acceptance limits remain. No arbitrary future-motion or all-surface collision guarantee.
- Donors have Rokoko export metadata without a source listing/entitlement. **Commercial-use licensing remains unverified.** Local review is not commercial clearance; donor FBXs are not packaged as game content.
- Input replay proves simulation-update response and cancellation. Hardware input/display latency, device audio quality, exported builds and human playtesting are not measured. Normal video uses the same authored WAVs mixed at accepted engine-event timestamps; slow and animation-only footage are silent.

**Stop for human visual/gameplay approval of the complete M1 combo. No M2 or unrelated animation production follows this delivery.**
