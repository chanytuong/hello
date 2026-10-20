# Natural M1 combo — candidate visual review

20 October 2026 · NEVERLOOKBACK · Straight → Hook → Forearm.

The candidate now has **horizontal upper-body attacks and complete authored exits after one, two or three hits**. The first two stop tails share their starting recoil with the next attack, so a timely follow-up skips the stop tail. Late input cannot rewind a stop already underway. Human visual acceptance remains pending; passing tests is not an animation approval.

## Five actual Godot recordings

| Required demonstration | Normal speed | 25% inspection copy |
|---|---|---|
| One strike: IDLE and RUN entry/return, both facings | [Video 1](../artifacts/m1_natural_combo/VIDEO1_ONE_HIT_NORMAL.mp4) | [Slow](../artifacts/m1_natural_combo/VIDEO1_ONE_HIT_SLOW_25_PERCENT.mp4) |
| Straight → hook → complete recovery, both facings | [Video 2](../artifacts/m1_natural_combo/VIDEO2_TWO_HITS_NORMAL.mp4) | [Slow](../artifacts/m1_natural_combo/VIDEO2_TWO_HITS_SLOW_25_PERCENT.mp4) |
| Straight → hook → forearm → complete recovery, both facings | [Video 3](../artifacts/m1_natural_combo/VIDEO3_THREE_HITS_NORMAL.mp4) | [Slow](../artifacts/m1_natural_combo/VIDEO3_THREE_HITS_SLOW_25_PERCENT.mp4) |
| Every strike interrupted in preparation/contact/recovery, reversal, wall adjacency | [Video 4](../artifacts/m1_natural_combo/VIDEO4_RESPONSIVENESS_NORMAL.mp4) | [Slow](../artifacts/m1_natural_combo/VIDEO4_RESPONSIVENESS_SLOW_25_PERCENT.mp4) |
| Same attacks against 60/64 px diagnostic bodies, actual contact/hurtbox outlines | [Video 5](../artifacts/m1_natural_combo/VIDEO5_TARGET_HEIGHT_NORMAL.mp4) | [Slow](../artifacts/m1_natural_combo/VIDEO5_TARGET_HEIGHT_SLOW_25_PERCENT.mp4) |

These are real Godot viewport captures driven through engine input/physics and Health/HitBox contact. They are not Blender-only or reconstructed sprite gameplay. Normal category fixtures run at 60 Hz. Slow copies hold source frames longer, with no generated inbetweens. Separate 30/60/120 Hz stress cases remain in the raw capture/test evidence. RUN demonstrations end while direction remains held; the subsequent ten-frame test release into the unrelated preserved SKID clip is outside Videos 1–3 and remains in the raw PNGs. Recordings are silent; auditory quality and hardware latency were not measured.

The final preview draws contact evidence on a separate foreground node. Encoded-frame inspection caught the first enlarged debug outlines being covered by the inspection background and target. That preview-only layering error was corrected, and the complete capture was regenerated into a fresh folder; the earlier raw captures are archived under `preview_debug_before/`. No native pose or gameplay rule changed for this correction.

Open [the candidate scene](../labs/m1_natural_combo.tscn) and run the current scene: A/D move, LMB/J attack, Space jump, Shift roll, E target selection, Q/RMB self, H contact debug, V opponent toggle, R retry. [Native Blender file](../maincharacter/m1_natural_combo/IVEN_M1_NATURAL_COMBO.blend), [key poses at native size](../maincharacter/m1_natural_combo/KEYS_NATIVE.png), [nearest enlarged keys](../maincharacter/m1_natural_combo/KEYS_3X.png), [reproduction workflow](../maincharacter/M1_NATURAL_COMBO_WORKFLOW.md).

## Animation and branching result

| Stage | First contact / active end | Continue at | Complete standalone stop | Free movement |
|---|---|---|---|---|
| L straight | .050 / .100 s | .1667 s | .300 s | 5 px |
| R hook | .0667 / .1333 s | .200 s | .3333 s | 2 px |
| L forearm | .100 / .1667 s | End | .400 s | 7 px |

The straight uses a calibrated soft **154.95° contact elbow**. The hook keeps a bent arm and travels around the body with the opposite hip/chest turn. The finisher folds the arm into a horizontal forearm sweep with the stronger short step. Hip/shoulder rotation and supporting/catching feet contribute; no arm/hand scaling, spin, leap or downward target solve was added.

The former first/two-hit tails lasted only .0667 s and lowered the body toward short targets. New stop tails are .1333 / .1333 / .1600 s after the shared recoil/settle landmark. Each catches one trailing foot while the other supports. Hand recovery follows a solved short path toward rest: the first quaternion-only draft opened the elbows into an unwanted intermediate extension and was revised before final production. All four free/braced chain joins have **0.0 stored channel error**. Final native endpoints return to the existing IDLE pose, without a mandatory extra guard beat.

One fresh press starts one strike. The **.22 s request** supports a fast deliberate double tap and the short hit pause. At the chain decision, either consume one live request or commit to the stop continuation. Later input may request a new opener after complete recovery; it cannot jump backward into the hook. Held click does not auto-chain. Death/forced motion/selection/valid defence clears both request types. Direction reversal can leave recovery after active contact; facing stays fixed through the damaging portion. Valid jump wins simultaneous jump/roll as in the existing player. Available roll and valid jump interrupt preparation, contact, recovery and accepted-hit pauses immediately in the tested physics update.

Godot applies the exported 5/2/7 px curves once. Native root translation is zero and no upward velocity is added. The 1/2/3-hit no-target stops measure approximately **5 / 7 / 14 px**, with single-strike travel also checked at 30/60/120 Hz. A predicted solid wall/prop or nearby solid character body chooses braced support once for the combo, with zero advance. This resolved a measured 2.6 px finisher slip when an advancing copy ran into a dummy. It does not require RUN-phase variants or a procedural upper/lower-body renderer.

## Contact height, targets and feedback

Active contact height is approximately **1.348–1.380 m above the native floor**, close to standing shoulder/chest level. The wrist/forearm is no longer .25–.32 m below the shoulder. Contacts are L hand, R hand and a point **55% from L forearm head toward L hand head**. The legacy metadata field `fist` stores that evaluated point; the third attack does not use the hand as an elbow substitute. Debug circles are 4 px radius, aligned with the displayed cel and its active window.

Only diagnostic instances change dimensions: 60/64 px standing body, 20 px width, chest hurtbox 20×22 px centered 42/44 px above ground. The green outlines use actual shapes in both inspection views. Original enemy scenes, art, scales, body shapes and hurtboxes remain unchanged. All three attacks apply accepted damage against both diagnostic sizes in both facings. Duplicate HurtBoxes sharing Health still receive one hit per strike.

Damage is **1 / 1 / 2**, with free recoil **45 / 50 / 80 px/s** and smaller early braced recoil **25 / 30 / 80 px/s**. Existing accepted-hit sounds, small marks and local hitstop remain: 1/60 s for the first two and 2/60 s for the last. Per-victim wall visibility is checked before the existing damage route. The first implementation checked only the impact circle center; its edge could overlap a victim across a thin barrier. The final actual wall-contact test confirms no through-wall damage.

Future enemy recommendation: the current Patrol's roughly 40 px visible/collision height is about two-thirds of Iven's approximately 60 px body. Correct each enemy's intended height, width, floor pivot and chest/hurtbox placement together in a separate task. Do not globally multiply all enemy scales by 1.5, and do not bend Iven downward or stretch his hitbox to conceal the mismatch. No enemy production was started here.

## Validation and preservation

**262 checks / 0 failures**, both headless and rendered; **2,895 actual captured frames**. Coverage includes all 1/2/3-hit stop branches from IDLE/RUN and both facings, fast/held/late input, deliberately buffered interruption, every stage/phase roll and jump, accepted-hitstop defence, reversal, wall support/occlusion, diagnostic damage, duplicate HurtBoxes, E/LMB/Q/RMB ownership and frame-rate travel. Every busy attack sample is grounded; accepted damage never precedes displayed contact. [Runtime receipt](../artifacts/m1_natural_combo/GAMEPLAY_VALIDATION.json), [capture log](../artifacts/m1_natural_combo/CAPTURE.log).

Native support checks at subframes show maximum projected planted-point drift about **.459 px** and minimum sole height about **−.289 mm**. Actual displayed-cel support, including frame-rate stress and collision cases, stays within **.762 px** horizontal range; braced dummy support is effectively stationary. These are kinematic landmark ranges, not force-plate or sole-slip measurements. [Native receipt](../maincharacter/m1_natural_combo/FINAL_NATIVE_VALIDATION.json), [runtime support method/results](../artifacts/m1_natural_combo/RUNTIME_SUPPORT.json).

The final library contains **21 Actions**: all 15 originals exact, three new attacks and three braced support copies. All **200** native cells pass fixed-frame bounds, binary alpha and the pixel skill's antialiasing/orphan/palette/grid checks. There is no camera refit, frame crop, weight/rig repair or material redesign. [Pixel audit](../artifacts/m1_natural_combo/PIXEL_AUDIT.json).

Visual examination opened the 36 native/enlarged semantic keys, contiguous capture boards covering both-facing complete [one-hit](../artifacts/m1_natural_combo/VIDEO1_DENSE_NATIVE.png), [two-hit](../artifacts/m1_natural_combo/VIDEO2_DENSE_NATIVE.png) and [three-hit](../artifacts/m1_natural_combo/VIDEO3_DENSE_NATIVE.png) stops, [target contacts](../artifacts/m1_natural_combo/VIDEO5_DENSE_NATIVE.png), and representative [five-frame defensive interruptions](../artifacts/m1_natural_combo/DEFENSIVE_INTERRUPTION_NATIVE.png). All ten delivery MP4s passed full decode and SHA verification; [decoded video samples](../artifacts/m1_natural_combo/encoded_checks/DECODED_VIDEO_SAMPLES.png) and the full target/debug frame were opened. [Collated final receipt](../artifacts/m1_natural_combo/FINAL_VALIDATION.json). This is frame examination and timing validation, not a claim of manually watching every frame or measuring hardware input latency.

Both-facing RUN entry/return sequences were also opened for [one hit](../artifacts/m1_natural_combo/VIDEO1_RUN_TRANSITIONS_NATIVE.png), [two hits](../artifacts/m1_natural_combo/VIDEO2_RUN_TRANSITIONS_NATIVE.png) and [three hits](../artifacts/m1_natural_combo/VIDEO3_RUN_TRANSITIONS_NATIVE.png). These use direct cel changes between the existing stride and the grounded attack, with no extra stopping clip or phase-indexed attack bank. The leg-spacing change at that boundary and the compact far-facing forearm need human judgment at normal speed; the numerical support checks do not establish that those cuts feel smooth.

Checkpoint `9288642` and the fresh **11,118-file baseline** protect the previous implementation and source data. Only `scripts/player.gd` changes among protected files: it adds a default-false candidate selector. The main scene, active production art, approved RUN, flame and Motion Swap code remain unchanged. [Preservation receipt](../artifacts/m1_natural_combo/PROTECTED_VALIDATION.json). Fresh relevant original-suite regressions pass **299 assertions / 0 failures**: M1 101, movement integration 166 and Motion Swap lab 32. [Regression validation](../artifacts/m1_natural_combo/REGRESSION_VALIDATION.json) uses redirected copies so historical receipts stay intact.

New deliverables are confined to `maincharacter/m1_natural_combo/`, `art/experiments/m1_natural_combo/`, `artifacts/m1_natural_combo/`, the candidate driver/preview scripts and their UIDs, `labs/m1_natural_combo.tscn`, `tests/test_m1_natural_combo.gd` and UID, these three natural-combo design reports and `maincharacter/M1_NATURAL_COMBO_WORKFLOW.md`. `artifacts/m1_natural_combo/CANDIDATE_FILE_MANIFEST.json` enumerates their exact paths and critical native/atlas/metadata hashes. No active production replacement or M2 was made.

For consistent one/two/three-hit review, the isolated scene uses **40 byte-copied existing B IDLE/RUN previews** in an instance-only duplicated SpriteFrames resource. It preserves movement timing and the RUN repeat endpoint. Existing skid/roll/jump textures retain their older appearance; the defensive video and raw captures show that handoff honestly. [Copy hashes](../artifacts/m1_natural_combo/REVIEW_MOVEMENT_COPIES.json). Main production resources are not silently converted.

The required online sources and verified frame observations are in [research](M1_NATURAL_COMBO_RESEARCH.md). Luke/Ed video retrieval remained unavailable; only Capcom's readable developer account is used as documentation, with no invented footage analysis. Human review should judge the complete one/two/three-hit rhythm, stop tails and far-arm forearm silhouette at normal speed before adoption. No test count establishes that subjective acceptance.
