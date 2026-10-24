# Phase C — reference sprite audit

Status: COMPLETE. Analysis only. No research, protagonist design, new sprites, animation, production canvas, or integration was started.

## File identity and inspection evidence

The reference was located by enumerating `E:/neverlookback/refs/`. That directory contains one PNG and its Godot `.import` sidecar. The actual audited PNG is:

**`E:\neverlookback\refs\Bảng sprite nhân vật đầu lửa pixel art.png`**

- Dimensions: **1536 × 1024**. Format: PNG; mode: RGBA; size: 2,124,079 bytes; no embedded metadata keys found.
- SHA-256: `fe48d42836313d2ec7b8191e943d7b49d85fb00dbd5baee11eb7e1af8980db9d`.
- The supplied Downloads copy has the identical SHA-256. This establishes file identity, not authorship provenance.
- Transparency is real but unsuitable as a binary production-alpha source: 254 distinct values, min 0, max 253; 689,731 fully transparent pixels, 883,133 partially transparent pixels, **zero alpha-255 pixels**.
- RGB still contains the brown/red presentation backdrop in transparent areas. The alpha mask removes much of that backdrop. A viewer showing RGB without correct compositing can make the source look like a fully painted board; raw color sampling there would be misleading. Both alpha and the actual alpha composite on #0D0F17 were inspected.
- There are 141,054 distinct whole-board RGB colors. This includes backdrop/labels/soft edges and **does not describe the character's production palette**.

The complete board was inspected at its stored 1× dimensions, and all 16 regions were inspected at 4× nearest-neighbor enlargement. `reference_inspection/` contains unchanged-pixel native crops and integer enlargements. Alpha/composite diagnostics and the seven-swatch column are supplementary views. `reference_inspection.py` performs only image inspection/cropping/compositing and writes only documentary files under docs. It neither extracts reusable sprites nor draws production art.

Only the board's stored raster scale is known. The larger upper figures and smaller animation samples have different display scales; no source pixel grid, common frame canvas, root registration, or original sprite resolution is supplied. The small idle bodies are roughly 75–80 stored pixels from collar region to shoe baseline, depending on the chosen landmark; this is a visual estimate, not an alpha-bounded production measurement. Phase B's current visible body height is 56 pixels. No downsampled reference was created or accepted as a game asset. Exact gameplay-size readability must be established on new native art later.

## Visible inventory

There are **14 motion/effect groups, 75 visible samples**, plus **2 static groups, 10 visible samples**. The visible counts are samples on a still illustration, not verified animation lengths or exposures. Ellipses do not count as frames.

| Visible section | Samples | Evidence type |
| --- | ---: | --- |
| Unlabeled large character views | 4 | Static views, not a registered orthographic turnaround |
| SILHOUETTE | 6 | Two rows of three faint, head-inclusive silhouettes |
| HEAD VARIATION (IDLE) | 10 | Two rows of five; may be alternatives rather than ordered frames |
| HEAD DURING ACTION | 4 | Unattached directional studies |
| IDLE | 5 | Body poses; ellipsis follows |
| WALK | 5 | Body poses; ellipsis follows |
| RUN | 6 | Body poses; ellipsis follows |
| JUMP | 6 | Standing/airborne/landing-related poses |
| FALL | 5 | Crouched and seated airborne/low poses |
| DASH | 4 | Low body poses with increasing flame stretch |
| ATTACK 1 (QUICK) | 6 | Guard-like poses, reach, raised gesture, leaning end |
| ATTACK 2 (HEAVY) | 4 | Low stance, head arc/stretch, partial return |
| ATTACK 3 (UP) | 5 | Low/rising/overhead/sweeping/leaning poses |
| HURT | 4 | Guard/lean variations and a lifted-leg reaction |
| DEATH | 5 | Four body-collapse poses, then one ember-only sample; ellipsis follows |
| EXTRA / EFFECT (OPTIONAL) | 6 | Separate blob, tall flare, small hook, crescent, long streak, open U-curl |

The seven unlabeled color swatches are palette presentation, not an animation group. Every visible group, including the two static groups, is covered in `reference_animation_audit.md` and its JSON companion.

## Pixel construction

**Clusters and masses.** At board scale, the small poses use broad jacket/trouser masses with tiny cuff, hand, and shoe accents. Many major clusters span several stored pixels; fine marks occupy about one or two pixels, while fabric patches are wider. The large views contain much larger patches plus mottled transitions. These are descriptive scale observations, not a reusable pixel-grid recipe. Soft edge colors, partial alpha, and fine speckling prevent treating every apparent cluster as a deliberate native pixel decision.

**Outlines.** Dark, interrupted contour segments often mark elbows, hems, cuffs, knees, and shoe boundaries. Internal shadow shares much of the trouser/jacket mass. This can reduce contour clutter. Some perimeter marks behave like isolated dark dashes; other boundaries are soft and multi-valued. Uniform black edging, broken dashes without form purpose, and the black head void used as a universal outline should not be inherited.

**Values and palette hierarchy.** Trousers are the lowest broad body mass, jacket occupies muted middle values, and exposed shirt/cuffs/soles create lighter breaks. Flame has the strongest red/orange/peach contrast against a dark center. The quiet-body/hot-head hierarchy is useful. Bright shoes, warm skin and shirt accents can compete with that focus; their exact hues and allocations are not a new palette specification. No hex palette was designed in this phase. Warm RGB backdrop haze is not evidence of a permitted glow or reflected fire treatment.

**Shading and fabric.** Large sleeves, trouser tubes, compressed knee folds, and a few cuff/hem breaks explain the wardrobe before texture does. This simplification is useful. Mottled shirt/jacket surfaces and busy sneakers add many micro-contrasts that contribute little in the small rows. Thin fold marks sometimes divide volume; elsewhere they read as wallpaper texture. Shading density must not be copied as automatic noise or downsampled detail.

**Hands and feet.** Hands are compact warm masses with occasional dark notches; shoes have readable soles and larger toe blocks. Large views suggest fingers, but small poses repeatedly blur fist size and hand ownership. Sneaker laces/color patches are denser than the torso and can distract from support. A readable sole is a useful principle; exact hand/foot forms, oversized shoes, or noisy trim are not.

**Negative space.** Wide leg gaps and selected arm-to-torso gaps help separate masses. Closed hand/hip and knee/shoe tangencies recur in compressed poses. The head's dark void is painted dark material/shape, not necessarily a transparent hole: sampled void pixels retain high partial alpha. The faint silhouette panel includes the flame, so it does not demonstrate an independently distinctive body with the head hidden.

**Detail distribution.** Cuffs, hems, soles, and the head receive more contrast than broad fabric. That uneven focus appears useful. Texture is also dispersed through many surfaces, and the sheet alone cannot prove that each mark was intentional. Keep the principle of uneven attention; reject indiscriminate micro-detail.

## Body-language observations

Idle favors low shoulders, relaxed arms, baggy legs and a wide base, with a modest slouch. Much of the body identity comes from wardrobe and the unusual head. The final idle study changes toward frontal orientation instead of proving a closed breathing loop. Large views suggest uneven support, but static views cannot establish the timing of weight transfer.

Walk/run share a forward lean, arm pumping and split legs. Shoulders and pelvis often travel as one wedge; the cloth obscures an independent ribcage/pelvis rhythm. Walk lacks an unambiguous passing pose. Run shows apparent support/flight differences but does not reliably identify both halves of an alternating cycle. These rows are recognizable locomotion illustrations with generic athletic gestures, not evidence of the required original whole-body law.

Jump supplies useful upright/tucked/low contrast. Fall and late hurt reuse seated or folded leg arrangements that can also read as kicking or hopping. Compression closes limb gaps and sometimes obscures whether a foot belongs to the near or far leg. Crouching is not itself evidence of stable bone lengths. Death has the clearest progressive loss of support through its four body poses, but the fifth removes body mass entirely.

Common illustrated floor lines are useful references for support; they are not registered world-space roots. Montage x/y gaps do not encode distance traveled, vertical velocity, support pinning, or center-of-mass trajectories. No exact anatomical grip hand can be traced reliably across the board. The current game's separate weapon and fixed legacy grip therefore cannot be validated from these poses.

## Flame-language observations

Idle flame uses unequal tips, a hot inner envelope and dark void. Variation is more interesting than a symmetric flame emblem. However, repeated paired bright holes/dots strongly read as glowing eyes or a skull face. That conflicts with the rebuild's no-eyes/no-skull constraint and must be rejected even where the surrounding flame is appealing.

Locomotion tips often lean backward/upward while the body aims forward. This suggests directional lag, but a still sheet cannot demonstrate a delayed phase relative to a planted foot, shoulder initiation, or pelvis release. Jump/fall heads mostly change tilt and vertical tips; a deliberate ascent/fall phase difference is not established.

Dash/heavy/up exaggerate flame into broad strokes, which are legible as solid masses. Long leading voids also read as meteors/fire attacks; overhead arcs can read as spell VFX. Their root/body relationship becomes less clear as size grows. The saturation hierarchy and connected stroke concept may inform later research. Exact silhouettes, eye points, giant head volume, detached red fragments, aura-like curls, and flame presented as the damage source must not be copied.

Death pairs body lowering with a smaller flame, a useful concept of consequence. The ember-only end does not establish continuity of the body's disappearance. Flame structure loss does not authorize particles, dissolution, new physics, or a new death lock.

## Motion-language observations

Anticipation is clearest in the low-to-rising upward row; quick/heavy poses often begin already loaded or repeated in similar guards. Contact is usually implied by maximum reach or largest flame, rather than a consistent hand or weapon surface. Recovery often ends in another lean or an unresolved compressed state. Overshoot is suggested in raised quick-attack gestures and elongated head forms, but restoration is weak.

Smears are most readable when hot shapes remain connected as a broad stroke. A large streak alone does not prove a valid smear: it needs a registered source, a parent/body root, a reachable destination, and a restored shape. Head-action and optional effects omit those relationships. Dash increases stretch without showing a contracted exit. Repeated drawings may imply holds, but no exposures exist to confirm that. The board's spacing is layout, and no FPS, timed playback, loop seam, contact hold, or three-cycle consistency was supplied or fabricated.

The actual game has one melee action (50 ms startup, 120 ms active, 80 ms recovery), a 150 ms dash, a 120 ms nonfatal hurt visual clock, and a 1.2 s death reload. The reference's heavy/up rows do not authorize new attacks; its walk row does not authorize a new walk-speed mode. This phase identifies incompatibilities and leaves new movement design to Phase E.

## Authorship and anti-AI assessment

The purposeful cues are broad value separation, selected silhouette changes, unequal tips, cuffs/soles that explain contact, and a collapse that visibly loses support. Roughness is useful where broken contour or compressed fabric explains form, rather than merely adding texture. These are perceptual judgments, not claims about how the file was created.

Weak cues include ambiguous limb ownership, near-duplicate stride poses without an evident full support cycle, familiar combat guards, drastic void/head size changes, unstable hand prominence, missing returns, soft alpha edges, and noisy local finishing. These can feel generic or AI-like, but resizing, compositing, removal of a background, or manual editing could also produce some symptoms. Creation provenance is **unknown**. The audit rejects visible weaknesses without inventing an AI-generation diagnosis.

## Keep, adapt, reject

**KEEP AS PRINCIPLE**

- Muted broad body masses against a concentrated saturated head.
- Large connected deformation shapes with an intelligible direction.
- Unequal tips, selective negative space, and uneven detail attention.
- Clear support loss/compression as an expression of consequence.

**FIX / ADAPT**

- Head variability: preserve the idea of instability while rejecting face/eye shapes and unstable attachment.
- Directional lag: establish actual body-relative phase and restoration later; the sheet only suggests it.
- Tuck/landing and collapse contrast: resolve paired limbs, stable mass, contact, and the missing release/rest state.
- Quiet idle/support and hurt imbalance: distinguish received impact from generic guard gestures.

**REJECT**

- Exact character, outfit, proportions, poses, flame contours, board layout and frame sequences.
- Glowing eyes/skull face, hero sprint/guards, meteor head, magic/aura/projectile readings and floating effect fragments.
- Incomplete/ambiguous gait cycles, unclear striking-hand ownership, flame masking contact, and unresolved recovery.
- Unexplained body disappearance, forced heavy/up/walk mechanics, soft production alpha, copied noise or palette.

## Decisions and remaining uncertainty

Motion/effect groups: **0 PASS, 6 FIX, 8 REPLACE**. Static groups: **0 PASS, 1 FIX, 1 REPLACE**. Total classified: **16 groups; 0 PASS, 7 FIX, 9 REPLACE**. FIX preserves useful principles only; all future raster art must be original. PASS would require no identified major visual/gameplay-fit flaw within the evidence's limits; no group meets that bar here. Unknown timing is recorded separately rather than treated as invented failure evidence.

Unresolved: source pixel grid/resolution, whether head studies are alternatives, exact sample ordering, durations/holds, root registration, loop seams, anatomical limb/grip identity, creation provenance, and final game-size readability. These limit what can be concluded from the supplied file but do not prevent completion of its visual audit. No extra files or user approval are required to finish Phase C.

Phase C stops here. **Next: Phase D — external research + synthesis.** No Phase D work was performed.
