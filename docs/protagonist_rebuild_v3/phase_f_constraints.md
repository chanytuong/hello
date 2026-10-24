# Phase E — locked Phase F production constraints

Status: LOCKED HANDOFF. Final law: **BRACE, THEN DRIVE**. Phase F has not begun; no canvas or pixels were created. [Final law](final_movement_law.md), [decision matrix](phase_e_decision_matrix.md) and [machine-readable constraints](phase_f_constraints.json) govern the next masters.

## Runtime-compatible geometry

| Property | Locked constraint / meaning |
|---|---|
| Frame | 64×64 RGBA, native raster; BODY/FLAME exports registered to the same canvas. No per-pose trim, resize or scale-to-fit. |
| Anchor | Texture (32,62), offset (−32,−62), centered=false; keep existing sprite origin. |
| Ground | Occupied sole row 62 for grounded support, row 63 transparent. The engine anchor is not changed to conceal a one-pixel coverage difference. Floor contact must be inspected at runtime. |
| Normal visible height | Full actor, including attached flame/void, target 56±1 px in neutral; existing A2 visible bbox y7..62 is the scale baseline. This is not 56 px of physical BODY plus an extra head. |
| Physical BODY height | Neck/collar to sole target 45±1 px in neutral, approximately y18..62. Pose bending/projection changes bounds while volumes/limb lengths stay coherent. |
| Neutral BODY width | About31 px including separated arms/grip in the construction probe; the old22 px bbox is a baseline, not an exact silhouette to copy. Both fit the unchanged64 px canvas/collision contract. |
| Live BODY width | Maximum46 px for the six primary live silhouette families; target idle31/run35/dash44/antic31/contact41/recovery 32. Extra compression/pickup constructions must be reviewed, not auto-scaled into these targets. |
| Collapse BODY width | Maximum58 px, within the same frame; register actual contacts. Corpse cannot disappear or be shrunk to fit. If a reachable collapse cannot fit, resolve it by a documented redraw before expansion, not silent canvas mutation. |
| Composite width | Maximum60 px within columns 2..61. BODY and attached flame share gutter; a separate weapon canvas may extend beyond this BODY canvas without changing player scale/pivot. |
| Gutter | Rows0–1 and63 transparent; columns 0–1 and62–63 transparent. No clipped elbow, toe, flame tip or smear. |
| Scale / filtering | Native1×; rotation0 for body, y scale 1, x facing±1, nearest filtering. No interpolation, blur, fractional resampling, auto shading or blend-generated pixels. |
| Gameplay geometry | Capsule radius 14/height 44, hurtbox, swing geometry, speeds, timings, camera and input remain unchanged. Visual occupancy is not a new collider. |

Actual viewport1280×720, camera zoom1 and floor top600 remain the Phase B context. Build and evaluate at that scale; an enlarged Pixelorama preview alone is insufficient. Normal stance can reach rows 7..62 including flame, but dash/compression bounds are expected to be shorter through articulation. No generated/downloaded/downsampled base or procedural character geometry may become production raster.

## Construction tolerances and identity

Canonical view faces right. RIGHT is the near/grip arm; LEFT is the balancing arm. Neutral landmark targets: pelvis(31,42), rib(33,30), neck(34,20), void center(34,14), shoulders L(28,24)/R(38,22), left wrist(26,40), right grip(48,32), ankles L(25,60)/R(36,60). Joint targets may shift by about 1 px when hand-drawn projection/cluster clarity warrants it; metadata must record actual values. This tolerance is not permission to wobble randomly from frame to frame.

Approximate implied lengths: upper arm10, forearm8, thigh10.5, shin9 px; paired limbs share the same construction. A shortened projected limb needs foreshortening/occlusion, not a missing bone. Working material volumes: ribcage about 13×15, pelvis12×8, arm cloth4–5 px thick, leg cloth5–7 px, compact palm3×4, ordinary shoe7–9 px long and3–4 px high. These are analytical budgets, not geometric shapes to fill mechanically. Draw the clothed person and attached limbs natively.

Spine connects collar, ribcage and pelvis with a mobile shallow curve. Rib/pelvis center separation may project to12–15 px under bend/lean while their masses stay coherent; neither torso mass is a rigid pasted cutout. Right shoulder is about 2 px higher in upright enclosed targets and remains the collar-side shoulder in torso-local construction; do not enforce that numeric screen-y gap on oblique contact or collapse. Left elbow opens a2–3 px by5–8 px wedge. Contact releases the enclosure but preserves anatomical role. Collapse rotates the relationship with the torso rather than retaining a screen-up shrug.

Live six-key rib lead/angle: idle+2 px/~9.5°, run+3/~14°, dash+5/~24.4°, antic0/~0°, contact+6/~24.8°, recovery+2/~9.5°. Void-center lead/pelvis:3/6/12/2/9/2 px respectively. These guide the family, not every drawing. Deep pickup, hurt and terminal collapse require cause-specific bending and are not limited to a25° torso axis; they still obey volume, right-hand ownership and support logic. No state adds a permanent limp, frozen arm, chronic sway or compulsory failed step.

Use plain civilian material masses; avoid copying the reference hoodie, baggy sneaker outfit, proportions or contours. Do not invent cape/armor/scarf ornament to rescue body identity. Wardrobe stays secondary to the selected motion law.

## Native-scale silhouette acceptance

1. BODY-only must identify the same person through compact enclosure, brief support-led opening and retrieval. An unusual flame cannot pass this test for the body.
2. Idle/antic/recovery form a related compact group without becoming duplicate poses; run/contact show opening with different support; dash is a distinct low transit, not the contact lunge held under a rocket head.
3. Preserve the left rib-side wedge and a readable right wrist/grip below the head; never use twin face-height fists. A high-contrast skin pixel cannot replace an attached palm.
4. Account for both anatomical arms and legs. Contact/down/passing/high/opposite contact need identity through occlusion; no mirrored half-cycle that silently swaps limbs.
5. Rising release, unsupported fall and real landing must differ; no seated forward-kick fallback. Do not delay any control to display their preparation.
6. Inspect 1× on the saved game backgrounds and dark/light contrasting fields, then integer enlargement for cluster corrections. Track neck, grip, support points, edge clearance and implied volumes.
7. The final Pixelorama masters must establish this identity visually. Coordinate fit, connected-color statistics and this text do not count as passing native-scale proof.

## Palette roles and budget

Recommended locked starting budget: BODY≤10 opaque colors, FLAME≤5, WEAPON≤4 reused BODY colors; total union≤15, excluding transparent pixels and non-exporting guides. Exact role set below is chosen for F; any later palette correction must be explicit and logged without adding noise/gradients or reflected fire. No color ramp is auto-generated. Raw export counts, not entire-scene/runtime-prototype colors, are checked against this budget.

| ID | Hex / alpha 255 | Material / use |
|---|---|---|
| B0 | #24252B | Deep charcoal: trouser/shoe structural shadow; never the flame void. |
| B1 | #363840 | Charcoal cloth shadow and subdued shoe mass. |
| B2 | #4B4E53 | Dirty gray jacket/body material base or plane shadow. |
| B3 | #686A66 | Dusty gray large jacket lit plane, with quiet interiors. |
| B4 | #5A5B4F | Faded olive secondary cloth material; small deliberate allocation, no pattern. |
| B5 | #82796B | Worn brown-gray shirt/collar material. |
| B6 | #A69B84 | Worn beige selective cuff/sole/shirt accents; highest broad body value. |
| B7 | #77665A | Dull skin shadow in connected hand/wrist shapes. |
| B8 | #A18A74 | Dull skin light in hand/palm; no facial or eye dots. |
| B9 | #747F87 | Restrained blue-gray small material/metal plane; not all-over cool edging. |
| F0 | #09080C | Opaque faceless void, FLAME only; not a universal BODY outline. |
| F1 | #8C2425 | Blood-red attached outer flame mass. |
| F2 | #D0442A | Vermilion principal hot shape. |
| F3 | #EE873F | Orange secondary hot plane/tip. |
| F4 | #F6C394 | Pale hot peach concentrated inner accents, never eye pairs. |

WEAPON reuses B0/B2/B6/B9 for subdued structure/metal and selective light planes. Perception can change silhouette/registration within its existing clock; it does not require new glowing colors. Flame saturation concentrates the self-image; broad BODY masses remain muted charcoal, gray, brown-gray, faded olive, worn beige, dull skin and limited blue-gray. FLAME F0 is opaque black-like material, not a transparent hole or universal body outline. Hot peach is never paired into eyes.

## Maximum detail density

Keep at least about 80% of each major cloth interior in broad unbroken base/shadow planes. Maximum three small authored fold-accent clusters, no more than12 accent pixels total per BODY frame, excluding meaningful material boundaries (shirt/cuff/sole/skin planes) and outer silhouette construction. Each accent must explain a specific bend or plane; do not use the allowance as required decoration.

At most two intentional same-color singleton accents in BODY, each with a documented form purpose; no detached anatomical alpha islands or floating skin pixels. No random distress, lace/sneaker noise, repeated fold wallpaper, dithering, pillow shading, alpha AA, diffuse glow or reflected fire. Alpha of native exports is0/255 only. Do not impose opaque geometric bands just to meet statistics; pixels and quiet planes must explain the actual volume.

## Modular layers and anchors

| Layer | Production rule |
|---|---|
| BODY | One connected physical person; clothes/skin/soles, no flame shading or baked weapon. |
| FLAME | Attached faceless head/self-image, registered neck/void/tips; no eyes, skull, hero hair, aura or autonomous particles. |
| WEAPON | Separate native authored prop; same anatomical right grip; register hilt/tip/orientation for each pose. No added weapon mechanics. |
| FX, if necessary | Only an event-rooted source/path/destination smear; optional, never autonomous decoration or damage. |
| GUIDES | Landmarks, labels and baseline on a non-exporting layer, excluded from all art exports and palette counts. |

Required pose metadata: pose_id, canonical facing, pivot/ground, grip_hand=anatomical_right, right shoulder/elbow/wrist, grip_texture/grip_local, weapon_hilt_offset and tip/angle hint, neck/void/tip landmarks, support_leg/support_points, explicitly occluded limbs, clock meaning and exported layer visibility. Store actual drawn coordinates after correction, not copied proxy numbers.

The legacy rest grip is texture(48,32), local(16,−30). Probe target local grip offsets: run(17,−25), dash(20,−22), antic(13,−30), contact(24,−30), recovery(17,−29). Therefore the fixed old prop offset is inadequate outside rest. F authors compatible metadata; H may adapt presentation lookup only. Do not rewrite weapon state, auto-pickup ranges, five-use break, four-second respawn, damage/reach, input or timers.

Anchor convention uses continuous texture-edge coordinates, matching Sprite2D offset/pivot. Reflect points with world_x=player_x+facing×(u−32); integer bitmap columns separately reflect as63−column. Do not mix those conventions or switch anatomical hands. Sprite flipping around the player origin provides the facing transform; do not generate an opposite-facing skeleton by relabeling limbs. Half-pixel/one-pixel grip coverage still needs actual raster/runtime inspection.

A WEAPON source canvas may have a different size because it is separate; record its own hilt pivot/offset and do not shrink or shift BODY to fit it. Angle hints describe authored orientation; they are not permission to rotate/scale an exported bitmap to manufacture new raster poses. Reuse native material roles while drawing appropriate keyed orientations in Pixelorama. Preserve the existing front-of-player prop draw order initially; any palm/grip occlusion adaptation is presentation-only and must be explicitly reviewed.

## Prop and interrupted-state safeguards

The independent465 ms pickup/perception sequence retains overlap 70 ms, fracture 170 ms, peak 240 ms, snap 285 ms, recoil end345 ms and settle 465 ms. Existing exceptions also remain: a swing resolves pre-snap transformation to285 ms; FREE pickup is blocked during fight freeze; HELD prop transformation has an independent process path. Initial prop lift is26 px and reaches zero at70 ms. A pickup grip must be physically reachable in its drawn bending pose or leave a documented visual issue; never stretch an arm or retime pickup to force registration.

Player BODY/FLAME and hand-anchor lookup hold with skipped visual updates through Blink280 ms, while existing gravity and held-prop clock behavior remain. Preserve the last selected drawing/anchor; do not replay an ended attack or advance a separate flame. Prop-lift mismatch during freeze is a known later QA risk. Existing attack/hurt priority, dash recovery-only cancel, late dash-strike, cooldown/buffer eligibility and hitstop must remain as documented in the final law/matrix.

## Phase F acceptance and scope

Phase F produces the master-key proof in Pixelorama MCP, not a full animation set or Godot integration. Follow its exact master list from the original/current Phase F brief; the construction family here supplies six numeric targets, not a copied six-frame production recipe. The eight-master proof must demonstrate the selected body identity, anatomy, pivot, grip and BODY-only/native-size silhouette before animation expansion. Additional actual-state construction must be resolved before corresponding animations are expanded in G.

Save .pxo source, registered native exports, actual anchor/landmark metadata and native/integer-scale inspection evidence. Use explicit raster pixel batches inside Pixelorama; no PIL/Python drawing, image generation, procedural geometry fills, rigid cutout puppeting, automatically downsampled bases, auto shading or interpolated frames. Analytical centerlines in Phase E are disposable feasibility measurements, never production art.

Each production animation still needs two real MCP correction passes with before/after evidence: first anatomy/support/volume/silhouette/pivot; second clusters/tangents/palette/flame timing/native read. F does not claim those later animation passes are completed. No gameplay integration until H; no runtime-art QA claim until I. Preserve all legacy assets.

Remaining risks: static protected posture could become generic; tiny shoulder/negative-space cues may disappear at1×; foot slide under held distance samples; modular grip and independent prop lift; same-phase hurt/freeze transitions; full collision-reach versus visible contact gap; airborne collapse. Failures must return to authored raster correction, not changes to gameplay or renderer.

PHASE E COMPLETE. NEXT: PHASE F — MASTER KEY POSES IN PIXELORAMA. STOP.
