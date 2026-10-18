# M1-A prototype — ready for human review

2026-10-18 · approved Option C, **M1-A only** · pre-edit checkpoint `5180f58`.

Delivered one **IVEN_M1_A** Action: compact gather, closed right fist, clear straight contact, restrained 3.5° upper-spine turn and fast recoil. Root and pelvis remain fixed in the standing Action. IDLE uses the existing held SKID STOP endpoint; no new idle Action was added. Existing rig, weights, proportions, costume, materials, camera, flame assets and movement Actions are preserved. **Visual acceptance and production adoption remain pending.**

## Review outputs

- [Normal speed](../maincharacter/combat_m1a/M1_A_PREVIEW.mp4): real Godot framebuffer, 1280×720, 60 fps, **532 frames / 8.87 s**. Both facings: IDLE→M1→IDLE, RUN→M1→RUN, fixed-clock/planted comparisons, M1→ROLL and M1→JUMP.
- [Quarter-speed inspection](../maincharacter/combat_m1a/M1_A_SLOW_4X.mp4): 35.45 s. [Native video](../maincharacter/combat_m1a/M1_A_NATIVE.mp4), [native GIF](../maincharacter/combat_m1a/M1_A_60PX.gif), [native keys](../maincharacter/combat_m1a/M1_A_NATIVE_KEYS.png), [4× key sheet](../maincharacter/combat_m1a/M1_A_KEY_POSES.png).
- [Editable Blender file](../maincharacter/combat_m1a/IVEN_M1_A.blend), [transparent individual frames](../maincharacter/combat_m1a/frames/), [atlas](../maincharacter/combat_m1a/sprites/M1_A_BODY.png), [metadata](../maincharacter/combat_m1a/sprites/M1_A_METADATA.json).
- [Isolated Godot scene](../labs/m1a_preview.tscn), [controls/reproduction](../maincharacter/combat_m1a/README.md).

The native body spans **50–61 px** across the standing/RUN combinations. Draw scale is 1 px per Godot unit; the labeled inspection panel is 4× nearest. All three MP4s fully decode. The GIF's 471 coalesced frames decode, totaling 8.87 s. Actual decoded normal/slow frames and the GIF were opened: [normal review](../maincharacter/combat_m1a/ACTUAL_MP4_REVIEW.png), [slow review](../maincharacter/combat_m1a/ACTUAL_SLOW_REVIEW.png), [GIF review](../maincharacter/combat_m1a/ACTUAL_GIF_REVIEW.png). No claim of manually playing the game or measuring live hardware latency/FPS is made.

## Timing and contact

Nominal startup **0.04 s**, active **0.06 s**, recovery **0.10 s**, total **0.20 s**. The sparse sprite player shows the gathered hand immediately on acceptance. Contact is authored at Blender **frame2.2** and displayed for the explicit **[0.04, 0.10) s** window; on the tested 60 Hz clock, first eligible contact is **0.05 s**, with contact sample2 displayed. Sample3 continues contact until 0.10 s. Source/endpoint samples are handoff references, not extra clip holds.

Metadata exports the actual projected right knuckle, wrist, elbow, neck, neck angle, ankles, common pivot and camera. H in the preview shows a **2.5 px contact landmark guide**. Future melee must use this displayed-pose landmark and the same age clock. **No live hitbox/damage, health UI, combo buffering or M1-B/M2 is implemented.**

## Running attacks and foot sliding

A translated standing punch visibly skates: its planted feet travel **51 px** across the displayed 0–0.183 s interval. The smallest animation-side solution implemented here combines the same saved M1-A upper body with all **18 existing RUN phases**, preserving their leg/root poses. The **304 untrimmed 82×82 frames** include both facings and exact base endpoints; the atlas is 656×3116, about 625 KB.

The original RUN reference projects to approximately **187.76 px/s**, while the current controller runs at **280 px/s**. The isolated preview therefore advances the existing RUN phase by travelled distance **during M1-A**, then resumes at that phase. It does not change velocity, root displacement, RUN drawings or outside-attack playback. Fixed-clock and planted cases remain available for comparison. [Actual comparison sheet](../maincharacter/combat_m1a/FOOT_SLIDING_COMPARISON_3X.png).

Residual limit: foot stepping/slip is reduced, not eliminated. A near-floor **ankle tracking diagnostic**, including foot roll and pixel/drawing quantization, records net **4.50 px over six qualifying updates** for the distance-matched example versus **14.81 px over seven** with the fixed RUN clock; left/right magnitudes agree. These are different support intervals and **not** exact contact-patch friction measurements or a percentage improvement claim. [Samples and method](../maincharacter/combat_m1a/FOOT_MOTION_DIAGNOSTIC.json). Outside-attack RUN retains its existing timing. Broader locomotion retiming is outside this prototype.

## Validation and visual findings

| Check | Result |
|---|---|
| Native reopen | Blender 3.6.23; saved Action hash and all **11 original Actions** match; native asset signature exact; no frame handlers |
| Camera | Actual `RESEARCH_Y75_P00`, ORTHO scale2.2200000286; matrix error **0.0**, unchanged framing/material/render pipeline |
| Root / legs | Standing hip displacement **0.0 m**, root location **0.0**; sampled lower-body channel error **0.0**; boot vertex error at contact **0.0 m** versus each base |
| Contact support | Minimum sampled base boot clearance **0.209 mm**; no new penetration seen in inspected native/detail outputs; existing RUN flight shapes retained |
| Sprite bounds | All 304 body alpha bounds contained; reopened standing pixels match reused original PNGs exactly |
| Gameplay response | **42/42 preview checks**: same position/velocity with overlay on/off, full RUN speed, no phase restart on return, same-update roll/jump cancellation both ways |
| Flame | Existing art/shader/controller unchanged; displayed-pose neck anchor updated; maximum root rounding error **0.680 px** |
| Existing roll | **30/30 regression checks**, 405 samples; original test reused with a new receipt directory |
| Preservation | **92 protected files**, zero changed/missing; no tracked pre-existing gameplay edits |

Opened full-size standing/RUN contact probes, native sheets, actual contact/recovery/cancel frames and encoded-media review sheets. The fist and forearm remain distinguishable from the torso in both facings; moving legs keep their stride. The far-arm left-facing punch has less separation, and contrast is weaker when the RUN arm was already forward. Existing coat/sash deformation limits remain. These are review limits, not repaired-rig claims.

New engine files are only [the review scene](../labs/m1a_preview.tscn), [review manager](../scripts/previews/m1a_preview.gd), [visual overlay](../scripts/previews/m1a_overlay.gd), [preview replay](../tests/test_m1a_preview.gd), [regression wrapper](../tests/test_m1a_regression.gd), and new `art/iven/combat_m1a/` exports. F5, shared player/visual/flame code, Motion Swap controls and damage systems are unchanged. The preview is grounded M1-A only; jump/roll cancel it immediately.

[Native validation](../maincharacter/combat_m1a/NATIVE_VALIDATION.json) · [Godot replay](../artifacts/combat_m1a/GODOT_VALIDATION.json) · [regression](../artifacts/combat_m1a/regression/results.json) · [media](../maincharacter/combat_m1a/MEDIA_VALIDATION.json) · [hash/preservation receipt](../maincharacter/combat_m1a/DELIVERY_VALIDATION.json).

**STOP. Review M1-A before any M1-B, M2 or production integration.**
