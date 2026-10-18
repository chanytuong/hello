# Combat animation redesign — design approval required

2026-10-18–19 · Asia/Saigon · NEVERLOOKBACK · research and proposed poses only

**Recommendation:** build the new M1-A from the anatomical **left straight in `Boxing_mixamo.fbx`, frames 135–143**. Use the opposite-arm Boxing strike for M1-B and a reduced ShadowBoxing cross for M2. Preserve their coordinated support–hip–shoulder sequence, then adapt timing and projection for Iven. Do not reuse the rejected prototype's keys.

**No new Iven Action or retarget has been created.** The images below show the supplied source mannequin, not a repaired Iven. M1-B and M2 remain designs. Source licensing is **UNVERIFIED**; filename suffixes do not establish ownership.

## Preparation and evidence

No applicable `AGENTS.md` was found at the project root, its ancestors or the output paths. Enumerated **14 skill packages / 447 `SKILL.md` files**. Read/reused the relevant Blender animation/rendering, animation systems, sprite review, game-feel, combat design and Godot animation guidance; no unrelated rig-repair workflow was started. [Skill inventory](../artifacts/combat_redesign_research/SKILL_INVENTORY.txt).

Git checkpoint **`870d256`**, `checkpoint: preserve rejected M1-A before reference-led redesign`, preserves the previous prototype and its preview/test code. The rejected folder is retained intact. A **641-file hash baseline** covers supplied Combat assets, the previous prototype, approved source assets, tracked controllers, labs, tests and existing design reports. [Baseline](../artifacts/combat_redesign_research/PROTECTED_BEFORE.json).

**Observed** below means evaluated source frames or decoded images actually examined. **Documented** means the identified author's account. **Proposed** means an Iven design that still needs retargeting and visual testing. Foot positions are kinematics, not force-plate measurements. A maximum fist extension is a contact-shape candidate, not proof of hitting an opponent.

## 1. Supplied assets: actual contents and motion

The directory contains **eleven files, all inside `maincharacter/Combat/Combat/`**. Binary headers identify **FBX 7500**. Every file imports successfully in Blender **3.6.23** and contains one **52-bone humanoid**, two untextured mannequin meshes (774 vertices total), and animation. There are no supplied preview movies, texture images, weapon meshes or cameras.

Each import creates one main skeletal take plus auxiliary/end-node object Actions: **14 datablocks do not mean 14 attacks**. The skeletal take starts with a T-pose. FBX time mode and import both indicate **24 fps**. Durations below are `(last frame − first frame) / 24`; encoded clips include the final sampled frame. The global FBX time-span placeholder is not the actual take length. [Inventory](../artifacts/combat_redesign_research/SOURCE_INVENTORY.json), [embedded metadata](../artifacts/combat_redesign_research/FBX_EMBEDDED_METADATA.json).

All eleven contain nonzero Hips translation. The largest full-take horizontal component ranges are RoundHouseKick's **3.15 / 3.07 m**; Boxing's are **1.15 / 1.69 m**. These include repositioning and departure, not just attack advance. Per-file XYZ ranges are in the inventory. Rest axes are Z-up / facing −Y, but performers turn during the takes. None should be treated as an aligned in-place attack without selecting and normalizing an excerpt.

| Actual filename, all `.fbx` | Main take / duration | Examined motion and useful landmarks | Decision / trim |
|---|---:|---|---|
| `BigFrontKick_mixamo.fbx` | 1–260 / 10.792 s | Relaxed setup; leg gathers, lifts and extends forward around f92–108; arms counterbalance over one supporting leg; then lowers and walks out. | Front kick, unsuitable for punch anatomy. Remove entire clip from punch production. |
| `Boxing_mixamo.fbx` | 1–430 / 17.875 s | Guard, short strikes, dips and repositioning. L straight at f59 and repeated more cleanly at **f139**; R extension at **f243**. Opposite hand retracts as shoulder turns. Later relaxation/walk-out. | **Primary punch donor.** Isolate one strike, exclude T-pose, setup, bobbing, adjacent attacks and departure. |
| `FightingIdle_mixamo.fbx` | 1–1259 / 52.417 s | Long guard variations, knee flexion, weight shifts and hand feints; inspected f223/297/593/667 among overview samples. | Support/guard reference only. Not a concise attack or a replacement IDLE. |
| `KnifeFight_mixamo.fbx` | 1–550 / 22.875 s | Guard, short forward hand thrusts and wider elbow-led gestures with stance changes; f259 and f356–421 illustrate differing paths. No knife geometry. | Weapon-oriented classification is an inference from name/path. Do not treat thrusts as ready-made bare-fist punches. |
| `KnockOut_Loser_mixamo.fbx` | 1–493 / 20.500 s | Standing exchange/reaction, then loss of balance and a ground fall around f290–346; later sits and stands. | Knockdown/reaction, not M1/M2. No death/fall production authorized. |
| `KnockOut_Winner_mixamo.fbx` | 1–482 / 20.042 s | Brief R forward extension near f77 from a relatively relaxed upright base; later holds, relaxes and departs. | Name alone does not make this a heavy punch. Less useful body coordination than Boxing/ShadowBoxing; reject as M2 donor. |
| `RoundHouseKick_mixamo.fbx` | 1–276 / 11.458 s | Guard, large turn, leg lift/sweep around f179–211, landing and exit. Large world travel. | Kick and spin; inappropriate for restrained punches. |
| `ShadowBoxing_mixamo.fbx` | 1–747 / 31.083 s | Repeated guard/straights, slips, broader torso turns and knee compression. L crosses at f152, **f267**, f472; later relaxation and walk-out. | **M2 mechanics donor**, especially f263–273. Reduce turn, dip and trailing-hand drop; do not import the full combination. |
| `SwordFight_mixamo.fbx` | 1–712 / 29.625 s | Repeated R arm reach/sweeps, wider stances and later overhead preparation; f126–336 and f419 are useful classification samples. No sword geometry. | Weapon-like reach/arc, inferred from motion/name. Reject for short fists. |
| `SwordIdleLight_mixamo.fbx` | 1–1550 / 64.542 s | Small stance sway, changing hand support/guard; f639 shows the held forward-hand relationship. | Long weapon-ready idle reference, no useful punch payoff. |
| `SwordIdleMedium_mixamo.fbx` | 1–1354 / 56.375 s | Restrained stance changes, arm repositioning and raised/forward-hand holds, including f876. | Not a punch donor; do not create another combat idle. |

All eleven full source-rig sequences were generated at their source rate and passed complete FFmpeg decode. Their navigation sheets were opened; candidate punches received denser adjacent-frame examination. Actual skinned source-mesh samples from **every file** were rendered and opened in both diagnostic and locked-camera views. This is not a claim of manually viewing every mesh frame.

**Original perspective limitation:** none of the FBXs contains an authored camera. The left view is explicitly a diagnostic 3/4 view of the supplied motion, not a recovered original camera. Full-take skeleton videos retain original world travel at left; the right navigation view recenters hip XY each frame and **cannot establish foot sliding**. The selected mesh storyboards instead use **one constant source normalization per excerpt**, retaining relative pelvis and foot motion. All normalization matrices are recorded. [Mesh review](../artifacts/combat_redesign_research/SOURCE_MESH_REVIEW.png), [render receipt](../artifacts/combat_redesign_research/SOURCE_RENDER_RECEIPT.json).

Per-file motion, hierarchy and evidence are indexed in [the research evidence folder](../artifacts/combat_redesign_research/README.md). Original FBXs remain untouched.

### Provenance and license

Embedded metadata says **“Rokoko FBX Export” / author “Rokoko”**. The Mixamo-named skeleton is not evidence that Adobe supplied or licensed these particular motions. Rokoko supports export skeleton presets including Mixamo, and its Motion Library contains assets from different publishers, including free and purchased material. [Rokoko export options](https://www.rokoko.com/pricing), [Rokoko Motion Library documentation](https://support.rokoko.com/hc/en-us/articles/4410021327121-Getting-Started-Rokoko-Studio-Motion-Library).

There is no publisher, original listing, purchase/license receipt or entitlement sidecar with these files. Their technical inspection is complete; **commercial-use permission is not established**. Adobe's general Mixamo allowance does not clear a Rokoko-origin file. [Adobe Mixamo FAQ](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html). Retain the original asset listing and applicable license before production adoption; do not redistribute these donor FBXs as game content.

## 2. Practical research and design consequences

### Mandatory Dead Cells production account

**Documented:** Thomas Vasseur describes a simple 3D model/rig exported through FBX, rendered at very small size without antialiasing. He establishes convincing, timed key poses before adding interpolation around those poses; attacks use pose-to-pose construction and VFX for motion/impact. [Vasseur, Motion Twin, 25 January 2018](https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i-).

The direct article page returned HTTP 403; its indexed primary text was readable. Two linked original GIFs were independently downloaded and decoded: **45-frame gameplay attack** and **134-frame authoring/retiming demonstration**. Both decoded boards were opened. The former visibly contrasts gathered, extended and low follow-through shapes; the latter shows substantial whole-body shape changes around the hammer motion. These are weapon examples, not punch anatomy or measured game input timings. [Gameplay frames](../artifacts/combat_redesign_research/primary_media/DEAD_CELLS_ATTACK_DECODED.png), [authoring frames](../artifacts/combat_redesign_research/primary_media/DEAD_CELLS_RETIME_DECODED.png), [media URLs/hashes](../artifacts/combat_redesign_research/primary_media/MEDIA_RECEIPT.json).

**Iven proposal:** approve three strong whole-body landmarks at native size before refining transitions. Do not smooth away the contact shape or add weapon-sized VFX to disguise an unreadable fist.

### Attack construction and responsive controls

| Primary resource | Documented principle | Application proposed for Iven |
|---|---|---|
| Eric Williams, [Attack Animations, Part 1](https://www.derekdaniels.com/attack-animations-part-1) | Establish anticipation, connection and follow-through; the connection must unmistakably communicate contact. Give the animator useful acted/video references and explicit foot/movement context. | Use donor body mechanics, then judge three distinct silhouettes. Keep the connection readable without importing the article's exaggerated weapon poses. |
| Williams, [Part 2](https://www.derekdaniels.com/attack-animations-part-2) | Define timing sections and acceleration/deceleration rather than uniformly stretching a clip; movement and foot treatment must agree. | Compress the donor preparation/recoil selectively. Make fist spacing accelerate into contact; maintain support or continuing gait, with no automatic lunge. |
| Williams, [Part 3](https://www.derekdaniels.com/attack-animations-part-3) | Victim reactions should agree with direction and impact; their timing/spacing affects the perceived result. | Future reaction, sound and small contact effect begin at accepted hit time. Pose quality must already work without them. No new reaction system in this phase. |
| Williams, [Combat Cancelled](https://www.derekdaniels.com/combat-cancelled) | Buffering stores a command for a valid window; an instant cancel executes when input and eligibility coincide. Cancel rules must be designed explicitly. | Preserve the project's immediate roll/jump priority. Do not wait for attack playback completion or replay a stale queued punch after a defensive input. |
| Norm Nazarof, [Dealing With Designer Input Latency](https://www.gamedeveloper.com/design/opinion-dealing-with-designer-input-latency) | Delayed acceptance, buffering and interruption affect perceived response. | Show a visible response immediately, keep locomotion live, and distinguish animation recovery from an input lock. This does not establish an exact latency threshold for Iven. |

The Williams articles are the author's work rehosted with permission on Derek Daniels' site. Their God of War examples inform construction, not Iven's movement or cancel rules.

### Verified gameplay references, reused without repeating the earlier search

The [previous study](COMBAT_ANIMATION_REFERENCE_RESEARCH.md) contains source metadata, exact frame indices and the six decoded videos. Gal, MRB and DC consecutive boards were reopened in this review. Other findings below reuse that documented visual examination; no new input trace or play session is claimed.

| Reference and examined interval | Verified observation / limit | Use in this redesign |
|---|---|---|
| [Fight'N Rage — Gal training, WahnTawns](https://www.youtube.com/watch?v=yAPt0wCTfU4), 33.00–33.38 s | Short arm extensions, shoulder/profile changes, contact bursts and recoil over a nearly fixed support base. The following string includes kicks. Exact anatomical arm ownership/cancel windows are not resolved. [Frames](../artifacts/combat_reference_research/GAL_PUNCH_NATIVE_A.png). | Compact anticipation→contact→recoil rhythm; the feet need not perform a new step for every punch. |
| WayForward's [Misako spotlight](https://www.youtube.com/watch?v=SA5vCVBf6s8), 26.0–26.8 and 36.4–37.9 s; [Kyoko spotlight](https://www.youtube.com/watch?v=vtIwzRqq7bA), 25.0–27.3 and 37.7–38.9 s | Compact exchanges contrast with broader ground strikes/throws. Overlap obscures some fist ownership. Kyoko's later move is a throw, not a verified heavy punch; mapped Light/Heavy inputs remain unknown. | M2 needs a larger gather and more decisive alignment than M1, without copying throws, finishers or recovery length. |
| [Mother Russia Bleeds developer trailer](https://www.youtube.com/watch?v=uxYtskZkyK4), 37.20–37.77 s | Green-shorts fighter makes short grounded punches with modest torso commitment and victim recoil. Trailer is labelled alpha. Exact hitstop is unknown. [Frames](../artifacts/combat_reference_research/MRB_CONTACT_NATIVE.png). | Put coordinated torso/fist alignment and the future victim's first response at one clear event. |
| [Dead Cells, Motion Twin](https://www.youtube.com/watch?v=ReZCldo7HdM), 24.79–26.9 s | Weapon contact is followed by a low travelling shape in one shot. A later cut prevents proving attack→jump; succession does not prove an attack cancel. [Frames](../artifacts/combat_reference_research/DC_CONTACT_NATIVE.png). | Keep a recognizable body axis and a short route back into movement. Do not copy sword reach. |
| [Katana ZERO, Studio 51 weaponless run, Stuf Lane](https://www.youtube.com/watch?v=zAomU01utGU), 26.97–27.60 s | Door strike, separate bottle-like throw and crossing gunfire; no standard bare-fist combo verified. Tutorial/planning freezes are not hitstop. [Door frames](../artifacts/combat_reference_research/KZ_DOOR_NATIVE.png). | Brief causal events and quick movement succession, not punch anatomy or a measured cancel specification. |

**Timing evidence boundary:** upload frame rate, repeated images and contact effects do not reveal internal attack windows, buffer lengths or measured latency. Hitstop should be judged separately from a held drawing. Sound was not audited. Jump/air attacks are future integration cases, not permission to add airborne attack variants now.

## 3. Why the rejected M1-A failed

Opened the actual [rejected native-derived pose board](../maincharacter/combat_m1a/BODY_KEYS_4X.png) and inspected its authoring code. The standing pelvis/root/feet are held exactly; only a **3.5° Spine02 turn** accompanies the arm solve. Moving samples inherit RUN legs while applying the arm target independently. This preserves source assets but leaves preparation and recoil dominated by the hands. Technical validation did not establish convincing force.

The replacement should transmit the change through the chain, rather than making every joint move more:

| Chain | Donor evidence | New design rule |
|---|---|---|
| Supporting foot → pelvis | Boxing f135→139: R ankle changes only ~2.3 mm while pelvis shifts ~25 mm horizontally. | Standing: quiet support with a small pressure shift and natural heel response. Running: retain the current gait support, never paste a planted stance over travel. Pressure is inferred, not measured. |
| Hip → torso | Same interval: hip line turns ~19°, shoulder line ~32°. | Preserve coordinated relative turn at a reduced amplitude; do not freeze the hip or rotate the entire actor to fake torso participation. |
| Shoulder → elbow → fist | L elbow reaches ~161° at f139, with fist clearly beyond the torso; it retracts by f143. | Shoulder carries the punch; elbow stays soft. Short direct fist arc, then an equally deliberate recoil. No arm scaling or hyperextension. |
| Opposite arm | Donor R hand stays withdrawn while L extends. | A distinct spare hand/counterarm shape, constrained by Iven's coat and 75° projection. |
| Recoil → movement | Donors return through active support, then add unrelated dips/combination motion. | Keep only the useful recoil. Blend toward current RUN phase or existing IDLE, without a mandatory extra guard beat. |

These are donor joint-line angles, not target Euler commands. [Exact source measurements](../artifacts/combat_redesign_research/SELECTED_SOURCE_MECHANICS.json). M1 target trials should begin around **6–10° hip / 12–20° shoulder change**, with small pelvis compensation; M2 may use roughly **12–18° / 20–30°**. These are proposed test bounds, not accepted poses. Reduce them if the costume fails; do not return to a motionless lower chain.

## 4. Proposed key poses and timing

![Source-based anticipation, contact and recovery storyboards; these are original donor meshes, not new Iven poses](../artifacts/combat_redesign_research/COMBAT_SOURCE_STORYBOARDS.png)

Yellow lines mark shoulders, magenta hips, green dots ankle landmarks; these dots are not assertions that both feet are planted. Cyan/orange distinguish anatomical L/R hands. The board deliberately exposes imperfect donor poses so the proposed corrections remain reviewable. Final Iven/native-scale appearance is **UNTESTED** until an approved retarget exists.

The same nine source poses were also rendered directly at **82×82 with AA off** and opened at native size and nearest 4×. The straight's extension remains distinguishable, but the very thin donor mannequin loses body/limb pixels; it cannot predict readability through Iven's costume. [Native source study](../artifacts/combat_redesign_research/SOURCE_KEYS_NATIVE.png). No source ground-penetration or target deformation pass is inferred from ankle dots or these stills.

| Design | Chosen source, 24 fps | Anticipation | Contact | Recovery / transitions |
|---|---|---|---|---|
| **M1-A, L straight** | Boxing **f135 / 139 / 143**, 5.583 / 5.750 / 5.917 s | Short gathered hand, soft knees, small hip preparation over current support; no visible step or reverse lunge. | Hip begins the turn, chest/shoulder finish it; L fist projects clearly past chest, R hand withdrawn. Reduce donor turn/travel. | Arrest turn and retract along a short path. IDLE settles onto its existing base. RUN keeps advancing phase and velocity. |
| **M1-B, R straight** | Boxing **f239 / 243 / 247**, 9.917 / 10.083 / 10.250 s | Start from M1-A's recoil; prepare R without a neutral reset. | Opposite shoulder leads. Donor elbow is only ~136°: straighten the intended fist path modestly while keeping a soft elbow and visible L guard. | Withdraw R while unwinding the smaller hip turn. Same IDLE/RUN contract; no compulsory third hit. |
| **M2, L cross** | ShadowBoxing **f263 / 267 / 273**, 10.917 / 11.083 / 11.333 s | Broader gather and leg contribution, without a deep squat or extra step. | Coordinated leg–hip–chest–shoulder commitment. Donor pelvis drops ~53 mm and shoulder line turns ~54° from prep: reduce both substantially; keep spare hand higher. | One controlled follow-through, stop rotation early, compact recoil toward IDLE or ongoing RUN. No spin, jump or prolonged balance performance. |

Choosing L for M1-A is deliberate: this supplied straight has the cleanest full extension and body-chain evidence. M1-B uses anatomical R, regardless of screen facing. It is not a mirrored copy of old M1-A. The earliest Boxing R short extension around f45 was examined but rejected as the primary straight: its elbow remains markedly bent and its fist path reads less clearly.

**Provisional budgets:** M1-A/B **0.20 s** (startup 0.04, active 0.06, recovery 0.10); M2 **0.34 s** (0.10 / 0.08 / 0.16). Retiming the selected M1 span is about 1.67×; the selected M2 span about 1.23×, before endpoint/transition refinement. Keep acceleration, contact and recoil landmarks; do not uniformly speed the complete takes. No evidence yet justifies a gameplay timing change.

At 30 fps, a 0.04 s event falls between regular render samples. After approval, render the semantic contact pose explicitly and give cels exact durations in metadata. The **first contact cel, active window and evaluated fist location must agree**; rounding to the nearest frame silently would change the attack. A short contact hold can supply readability, but cannot postpone accepted input or defensive cancellation.

## 5. Retarget feasibility and smallest movement solution

Read-only target inspection confirms **101 AccuRIG bones** and the existing movement Actions. All **52 donor bones have named target counterparts**, including fingers, but the hierarchy, rest lengths and bone axes differ. This is feasible with calibrated retargeting, **not a tested successful retarget**. [Mapping and read-only receipt](../artifacts/combat_redesign_research/RETARGET_FEASIBILITY.json).

| Donor | Existing target | Required treatment after approval |
|---|---|---|
| Hips | CC_Base_Hip, existing pelvis/root hierarchy | Separate global travel from small pose compensation. Keep Godot horizontal motion authoritative; retain useful hip rotation and support-related vertical change. |
| Spine / Spine1 / Spine2 | Waist / Spine01 / Spine02 | Rest-space calibrated distribution of turn; preserve the donor chain's timing rather than assigning one chest angle. |
| Shoulder / Arm / ForeArm / Hand | Clavicle / Upperarm / Forearm / Hand | Calibrate axes and lengths; retain Iven proportions. Check elbow pole, wrist and native twist bones. |
| Neck / Head | Existing neck-twist chain / Head | Distribute through the existing chain; retain pose-derived flame attachment metadata. |
| UpLeg / Leg / Foot / ToeBase | Thigh / Calf / Foot / ToeBase | Standing support cleanup; running support trajectories follow the approved gait. No new bones, constraints, weights or rig repair. |
| Five finger chains | Existing Thumb / Index / Mid / Ring / Pinky chains | Map Middle→Mid explicitly; ensure readable fists without changing hand scale. |

The donor lacks Iven's extra twist/helper structure; do not copy indices, collapse the skeleton or transfer weights. Remove the initial T-pose and unrelated setup. Apply one facing alignment to the character/source, leaving the camera fixed. Avoid frame-by-frame hip recentering as a substitute for contact cleanup.

**Full-body sprite limitation:** a single planted punch sprite translated at RUN speed skates. The current pipeline already supports phase-indexed full-body attack renders; use that small existing mechanism, but replace its absolute arm-only overlay with the **new coordinated hip/spine/clavicle/arm motion expressed relative to continuing RUN**. Preserve RUN leg timing and correct the new attack copy's support trajectory after the hip adjustment. No new upper/lower runtime renderer is needed.

First test standing and two contrasting RUN phases, not a large bank of variants. If the shoulder/hip contribution still disappears, or feet cannot retain convincing travel, reject the motion before expanding phase coverage. Do not solve it by locking movement, slowing physics, restarting RUN or lengthening a cosmetic entry bridge past contact. The existing RUN's stride/playback mismatch must remain distinguishable from new attack-induced skating; no RUN/controller retuning is authorized here.

## 6. Production plan, only after design approval

1. Work in a new **`maincharacter/combat_redesign_m1a/`** folder, opening the original movement library. Keep `combat_m1a/` as the rejected comparison. Create only **`IVEN_M1_A_V2`**, from the selected supplied Boxing excerpt; preserve original imported source separately. Do not create M1-B or M2 Actions.
2. Retarget the coordinated chain, remove donor travel, reduce turn and refine three landmarks through the exact saved camera. Verify IDLE entry/recoil and the two RUN support phases before interpolation. Use pose-relative arm motion and animation-side contact correction, without changing rig/skin or approved Actions.
3. Render 82×82, native + nearest 4×, both actual facing orientations. Preserve pivot, scale, materials and red flame assets; export evaluated neck and **L fist** positions, contact/active times, cel durations and RUN phase metadata. Do not reuse the old R-fist metadata blindly.
4. Demonstrate IDLE→M1→IDLE and moving RUN→M1→RUN with visible ground travel. Compare new vs rejected at matching speed/framing. Include normal-speed and slow decoded footage; check outline bounds, coat, hand gap, wrist/elbow, support-foot displacement and movement return.
5. In the existing isolated Godot preview if available, verify immediate input, direction change, jump/roll cancellation before/at/after contact and interruption of any visual bridge. Keep health, damage, Motion Swap and locomotion unchanged. Future hitboxes follow evaluated contact and accepted damage events; do not add damage/VFX machinery as part of pose approval.
6. Stop for **M1-A visual review**. Only an accepted M1-A permits a separate decision to author M1-B/M2. Air attacks, new abilities, maps and other combat production remain outside this pass.

## Validation, limits and approval gate

- All eleven supplied FBXs imported and their full source-rig videos decoded without errors. Actual source-mesh review, detailed source skeleton sequences, mandatory article GIFs and the source storyboards were opened.
- The copied **RESEARCH_Y75_P00** camera is orthographic, scale **2.2200000286**. Its actual matrix matches the saved lock with **maximum element error 0.0**, both in source render copies and the read-only Iven inspection. No Euler reconstruction or camera research was performed.
- The target pipeline remains Workbench, 82×82, Standard / Medium High Contrast, exposure +0.45, gamma 1. Source mannequins use neutral diagnostic shading because they contain no Iven materials; they are not production sprite renders.
- **641 protected files: 0 changed, 0 missing.** This research adds only the report and isolated evidence. No Iven Actions, gameplay edits, rig/weight changes or new combat integration. No gameplay-suite rerun is claimed for this documentation-only phase. [Validation receipt](../artifacts/combat_redesign_research/RESEARCH_VALIDATION.json).
- Retargeted costume deformation, both-facing Iven contact silhouettes and final native readability remain untested. Existing garment limits are not resolved by donor selection. License/provenance remains missing.

**Approval requested:** adopt these source-based designs—Boxing L straight for M1-A, Boxing R continuation for M1-B, reduced ShadowBoxing cross for M2—and proceed with **M1-A V2 only**. This is the design gate required by the new brief, replacing the earlier Option C approval. No animation production will continue before that approval.
