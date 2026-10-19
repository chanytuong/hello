# NEVERLOOKBACK — CANONICAL 3D-TO-2D CHARACTER PIPELINE
Date: 2026-10-14
Status: Current agreed workflow; supersedes earlier fixed-angle RUN and previous flame-head-as-3D assumptions.

## Narrative & identity
- Use NEVERLOOKBACK V2: THE THINGS WE BURY as narrative basis: Iven, an ordinary former maintenance worker in Veyr; his sister Mara, Continuance, personal guilt and responsibility, unreliable interpretations; Ember symbolizes his defensive self-image. Do not invent religion/supernatural flame power.
- Approved visual direction: B4 from The Unfinished Repair concept, but optimize model for animated 2D sprites. Avoid dark fantasy/edgy tropes, overly complex garments, folds, straps and extra accessories. Silhouette and action readability at approximately 50–60 pixel gameplay height dominate.
- Body 3D, Ember head flame 2D: no baked-in fire on 3D body. May use a temporary hidden placeholder head for rigging and a neck/head anchor. Final body frames exclude placeholder head. Ember 2D animation separately authored and synchronized to movement/contact/timing.

## Master pipeline
1. SOURCE: Meshy Azure Wayfarer FBX with texture, located in `E:\neverlookback\maincharacter\Meshy_AI_The_Azure_Wayfarer_1014044525_texture_fbx` (verify exact filesystem path locally). Meshy has better form than Tripo; Tripo source suffers geometric artifacts. Original Meshy ~141,728 triangle faces reported; confirm actual numbers. Preserve original files byte-for-byte.
2. SKILLS: Local coding/design agents must enumerate `E:\neverlookback\agentskill\`, read `AGENTS.md` and task-relevant skills deeply, before any edit. Only local agents with E: filesystem access should claim to have read these files. Read applicable project-specific docs instead of overwriting them with generic advice.
3. BLENDER IMPORT/AUDIT: Check hierarchy, mesh-part density, UV/textures, material paths, disconnected/intersecting/hidden surfaces and deformation-sensitive joints; save visual evidence front/side/back/wireframe. Distinguish source triangle vs quad counts.
4. CLEANUP/OPTIMIZATION: Work only on a separate copy. Eliminate needless detail, garment folds, hidden parts and geometry. Trial selective decimation and local manual retopo where appropriate. No blind fixed polygon budget; compare silhouette, textures and shoulder/elbow/wrist/hip/knee deformation. Lower triangles do not inherently give better rig topology. Avoid local AI rebuilding full character mesh procedurally from scratch (previous failed and wasted many hours).
5. AUTO-RIG: Mixamo or AccuRIG may be used strictly to generate a humanoid skeleton/skin weights, **not** to choose character animation. Rigify/Blender for further controls if necessary; verify basic joint bends before proceeding. No forced dependence on Cascadeur.
6. CAMERA/VIEW: Old near-front yaw ~20° from front was chosen for earlier artwork and is NOT locked for B4. Old side-biased/profiling experiments also cannot be accepted automatically. Test strict side and several near-side orthographic camera positions with idle+run+attack test poses. Define precise yaw conventions, use consistent camera/scale/foot-ground alignment and compare silhouette at actual 2D display size. Lock camera only after visual side-by-side and user approval. Do not copy old RUN animation unchanged because view/form has changed.
7. CUSTOM ANIMATION: User-authored design principles and existing RUN/motion/keypose experiments are references, not necessarily valid motion assets for new angle/model. Explicitly no Mixamo animation presets. Pose and timing designed for NEVERLOOKBACK: hesitant awkward idle versus reckless and excessive Ember combat; agile responsive locomotion with clear anticipation, contacts, overshoot, recovery, weight shifts, foot plant, no unintended airborne hits. Retarget/rebuild only as required for new rig/camera. Blender works; Cascadeur is optional pose/physics aid if actual benefit demonstrated. Test short two-pose/run/contact first rather than mass-producing animation.
8. 3D TO 2D EXPORT: Render authored 3D frames using consistent orthographic view, palette/materials, silhouette lighting. Export PNG with transparent background, fixed cell/pivot/alignment. The Dead Cells artist Thomas Vasseur described exporting each animated 3D frame to .png together with its normal map and using a toon shader; additional blend passes can add graphic effects. **Test** optional per-frame normal maps and toon shader when they improve sprites; not mandatory. Avoid anti-alias/shimmer mismatches and texture microdetail. Render at gameplay-appropriate pixels, test pixel quantization/nearest filtering and controlled cleanup, not high-res cinematic art.
9. EMBER 2D: Draw/animate flame head as independent 2D component, tied to skeleton-derived neck/head anchor exported or tracked per frame. No literal human skull or supernatural 3D fire. Make it readable and expressive at small scale, with stable clusters and no unintentional flicker.
10. GODOT INTEGRATION: Import final body sprite sequences (+ optional normal maps), compose Ember 2D with stable anchor, setup animation states/timings, attack windows, hitboxes/hurtboxes, cancel/recovery rules and Blink behavior. Validate original game feel in actual gameplay, not just Blender viewer.

## Quality gates
A. Geometry/rig feasibility — actual mesh stats and bend tests; stop if unfixable.
B. Static silhouette/image test — camera comparisons with body in idle and attack, at native gameplay scale; choose and lock viewpoint.
C. Motion test — short RUN/contact and attack in Godot (frame timing, foot slip, angle, readability); stop/revise before full suite.
D. Production/export — only after gates A–C visually accepted; render all actions, add Ember and normal-map effects if beneficial.

## Constraints
- Never overwrite approved originals. Save working .blend and evidence versions separately.
- Never silently return to old yaw or previous sprite/animation as authoritative.
- Never recommend prepackaged Mixamo run/attack motion as final animation.
- Never embed Ember flame in 3D mesh for final art.
- Never treat a technical unit test passing as proof the animation looks good.
- Never start multi-hour procedural modeling/rebuilding without bounded test and proof.
- Source: Thomas Vasseur, 'Art Design Deep Dive: Using a 3D pipeline for 2D animation in Dead Cells' (2018), https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i-

## Next action
Review local Meshy audit/optimization report and saved outputs, not another concept image. Check optimized mesh, bending, and viable rig export first. Then run a controlled view-angle test before custom RUN motion production.
