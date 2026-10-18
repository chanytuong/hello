# Combat animation reference research — direction approval required

2026-10-18 · NEVERLOOKBACK · research only

**Recommend Option C: Hybrid.** Use Gal's compact punch rhythm and stable support, with a clearly projected fist/contact pose and a short, controlled M2 weight transfer. Borrow impact clarity from Mother Russia Bleeds and movement continuity from Dead Cells and Katana ZERO. Do not import their finishers, sword reach or movement rules.

**No M1-A, M1-B or M2 animation has been produced. No gameplay, rig, camera or approved movement asset has been edited.** The next authorized step is human approval of this direction, followed by the M1-A prototype only. M1-B and M2 below are storyboards.

## Method and evidence standard

- **Observed:** decoded gameplay frames actually opened and examined. All six downloaded videos passed full decode; overview sheets were inspected, followed by selected contiguous source-frame sequences. This is frame examination, not a claim of playing the games or watching every video frame.
- **Documentation:** an identified developer's published description. This establishes stated intent or a documented mechanic, not a measured input-to-display delay.
- **Inference / proposal:** the interpretation or design suggested for Iven. These require prototype testing.
- **UNVERIFIED:** unavailable footage or a claim that the available images cannot resolve. No cancel-window, internal animation-frame-count or input-latency measurements are inferred from upload frame rate.

Evidence lives in [the local research folder](../artifacts/combat_reference_research/). Each `*_SOURCE.json` records URL, exact title, uploader, source-video rate, duration and SHA-256. Segment `INDEX.json` files map extracted images to source-video frames and crop rectangles. Navigation sheets sample approximately 10 times per second; the `*_NATIVE*.png` contact boards show consecutive source-video frames. Neither is an original game sprite sheet. Some exploratory filenames describe a search hypothesis; the classifications below supersede those names.

The excerpts are attributed study evidence, excluded from the game build. Their availability does not confer a license to redistribute the footage or reuse the games' artwork. No reference sprite, sound or animation data is imported into Iven.

Project preparation: enumerated 14 `agentskill/` packages containing 447 `SKILL.md` files; read the relevant game-feel, animation, Blender animation/rendering and small-sprite review guidance. [Inventory](../artifacts/combat_reference_research/SKILL_INVENTORY.txt). Pre-research checkpoint: `0196380` (`checkpoint: movement and Motion Swap foundation before combat reference research`), preserving the pre-existing foundation work.

## 1. Fight'N Rage — Gal: primary M1 reference

**Video:** [FIGHT N RAGE - Gal Black Belt - Training Mode](https://www.youtube.com/watch?v=yAPt0wCTfU4), WahnTawns, 69.35 seconds, 720p/60 fps.

**Observed:** the character selection at **00:06.7–00:07.3** explicitly identifies **GAL**. At **00:32.3–00:32.9**, she settles into a compact ready shape. **00:33.00–00:33.38** shows successive short arm extensions, shoulder/profile changes, contact bursts and recoil, with the shoes and broad support base staying nearly fixed. The yellow impact burst provides a clear contact event while the torso remains legible. The subsequent sequence develops into kicks/juggling; it is not all punches.

[Character identity](../artifacts/combat_reference_research/GAL_SELECTION_CHECK.png) · [Sequence context, 31–34 s](../artifacts/combat_reference_research/gal_chain_SEQUENCE.png) · [Consecutive frames, 33.00–33.18 s](../artifacts/combat_reference_research/GAL_PUNCH_NATIVE_A.png) · [Consecutive frames, 33.20–33.38 s](../artifacts/combat_reference_research/GAL_PUNCH_NATIVE_B.png).

![Gal: consecutive source-video frames showing compact extension and contact; WahnTawns / Fight'N Rage](../artifacts/combat_reference_research/GAL_PUNCH_NATIVE_A.png)

**Documentation:** the [official developer store page](https://store.steampowered.com/app/674520/FightN_Rage/) characterizes Gal by speed and short reach, describes the simplified controls, and documents cancelling normal attacks into specials. This does not establish arbitrary jump/roll cancels or their timing.

**Transfer:** build a compact guard → extension → recoil vocabulary. A modest shoulder lead and withdrawn spare hand can make repeated punches readable without moving the pelvis through a large arc. M1-B should use the opposite anatomical arm, but the footage does not establish anatomical left/right bone identities for every overlap. That alternation is our proposed construction, not a traced bone analysis.

**Do not copy:** long expert strings, launchers, kicks, airborne juggling, CRT distortion or a brawler's depth-lane movement. A return toward a ready shape is visible; the exact moment movement input becomes accepted is **UNVERIFIED**.

## 2. River City Girls — Misako and Kyoko: strength contrast, with limits

**Videos:** WayForward's official [River City Girls Character Spotlight: Misako](https://www.youtube.com/watch?v=SA5vCVBf6s8), 66.814 s, 720p/60 fps; and [River City Girls Character Spotlight - Kyoko](https://www.youtube.com/watch?v=vtIwzRqq7bA), 65.894 s, 720p/60 fps.

**Observed — Misako:** **00:26.0–00:26.8** contains close-range exchanges, compact body changes, bright contact bursts and opponent recoil. In the consecutive **00:26.000–00:26.283** frames, overlap and effects obscure some fist ownership; this is contact/recoil evidence, not proof that every hit is Misako's light punch. **00:36.4–00:37.9** shows much larger downward ground strikes with a gathered posture, downward commitment and recovery. That contrast is clear, but these are ground attacks, not a neutral heavy-punch template. **00:17.6–00:20.0** is a trash-bin interaction/throw, excluded from unarmed-punch evidence.

[Misako exchange](../artifacts/combat_reference_research/misako_light_SEQUENCE.png) · [Consecutive contact frames](../artifacts/combat_reference_research/MISAKO_CONTACT_NATIVE.png) · [Larger ground-strike context](../artifacts/combat_reference_research/misako_wide_SEQUENCE.png).

**Observed — Kyoko:** **00:25.0–00:27.3** is a crowded exchange with bright contact shapes and clear victim displacement, but pom-poms, other fighters and effects hide much of Kyoko's arm path. A long weapon/assist strike from another fighter must not be attributed to her fist. **00:37.7–00:38.9** shows a grab, rotating/inverted throw and crouched-to-upright recovery. This is a throw, **not a verified heavy punch**.

[Kyoko exchange](../artifacts/combat_reference_research/kyoko_light_SEQUENCE.png) · [Consecutive contact frames](../artifacts/combat_reference_research/KYOKO_CONTACT_NATIVE.png) · [Throw and recovery, excluded as M2 anatomy](../artifacts/combat_reference_research/kyoko_heavy_SEQUENCE.png).

**Transfer:** distinguish M2 with a larger gathered torso shape, stronger contact alignment and more visible recoil than M1. Clear victim response helps communicate force. Keep Iven's fist readable before adding large effects.

**Do not copy:** ground finishers, cartwheels, throws, prop attacks or large advancing strings. **Mapped Light/Heavy inputs, exact recovery lengths and cancel windows remain UNVERIFIED.** These edited spotlights do not show an input trace. The separately located *River City Girls : All Moves Set (1080p)*, [video link](https://www.youtube.com/watch?v=ooT8Ps-PlsY), could not be examined because retrieval returned HTTP 429/sign-in checks; it is **UNVERIFIED** and supplies no findings. No access restriction was bypassed.

## 3. Mother Russia Bleeds — compact physical impact

**Video:** [Mother Russia Bleeds   Gameplay Trailer](https://www.youtube.com/watch?v=uxYtskZkyK4), MOTHER RUSSIA BLEEDS, 58.254 s, 720p/29.97 fps. The trailer visibly labels its build **ALPHA FOOTAGE**; it is not evidence of final-release tuning.

**Observed:** at **00:37.20–00:37.77**, the bearded playable fighter in green shorts on the left makes short rightward unarmed strikes against armored opponents. Extension, modest forward torso commitment, victim head/shoulder recoil and retraction are visible. The feet remain under a bent-knee support base; a new jump or deep stance change is unnecessary for each short hit. Crowd overlap limits precise reach analysis. At **00:38.3 onward**, the red-trousered fighter's grab/headbutt sequence is a different action and is excluded. Earlier **00:21.5–00:24.8** includes jump kicks and grappling, not a basic-punch template. The gun held around **00:40** is also excluded.

[Sequence context](../artifacts/combat_reference_research/mrb_chain_SEQUENCE.png) · [Consecutive source frames, 37.20–37.77 s](../artifacts/combat_reference_research/MRB_CONTACT_NATIVE.png).

![Mother Russia Bleeds: consecutive source-video frames; developer gameplay trailer, alpha footage](../artifacts/combat_reference_research/MRB_CONTACT_NATIVE.png)

**Transfer:** put the strongest body alignment and the enemy's first recoil at the same visible contact event. Small torso compression and a stable base can sell a short strike. **Do not copy** gore, mutilation, grabs, prolonged beatdowns, crowd clutter or forced animation locks. Exact hitstop and damage values are **UNVERIFIED**; blood and camera effects alone do not establish them.

## 4. Dead Cells — movement continuity and small-sprite clarity

**Video:** [Dead Cells - You'll get better... Eventually.](https://www.youtube.com/watch?v=ReZCldo7HdM), Motion Twin, 51.974 s, 720p/29.97 fps. This is an early-access-era edited trailer, not a current input test.

**Observed:** the continuous platform shot around **00:24.79–00:26.9** contains weapon contact, a readable torso/head axis and victim reaction. **00:25.926–00:26.293** shows the bright contact/weapon arc in consecutive source frames. By **00:26.3–00:26.8**, the character assumes a low travelling pose consistent with a roll. This establishes visible attack-to-low-movement succession; it does **not** prove the attack was cancelled rather than completed. A cut around **00:26.99** prevents an attack-to-jump claim. **00:30.5–00:33.0** mixes airborne, drop and ground-combat shots; the cuts cannot establish causal transition windows.

[Attack and low movement](../artifacts/combat_reference_research/dc_attack_SEQUENCE.png) · [Consecutive contact frames](../artifacts/combat_reference_research/DC_CONTACT_NATIVE.png) · [Traversal montage and visible cuts](../artifacts/combat_reference_research/dc_traverse_SEQUENCE.png).

**Documentation:** Motion Twin's lead designer describes accessible, fast and fluid combat/control goals in [this developer article](https://blog.playstation.com/2018/01/25/rogue-lite-action-platformer-dead-cells-coming-to-ps4-this-year/). It does not specify the cancel windows sought here.

**Transfer:** preserve a recognizable body axis through attack and movement, localize contact feedback, and let a small set of strong shapes carry the action. **Do not copy** sword arcs/reach, weapon-specific lunges, roll immunity or special movement rules. RUN→attack and attack→jump cancel availability, input latency and exact hitstop duration are **UNVERIFIED** in this evidence. Repeated captured poses are not sufficient to distinguish a held drawing from a simulation pause.

## 5. Katana ZERO — Studio 51 classification and pacing

**Video:** [hard mode studio 1-1, but without  a sword](https://www.youtube.com/watch?v=zAomU01utGU), Stuf Lane, 110.094 s, 720p/60 fps. The scene visibly identifies **STUDIO 51**. It includes hard-mode attempts, tutorial/planning freezes and pauses, so upload time cannot be equated with normal gameplay timing. Zero is the dark/blue fighter; the yellow/blond character is V.

**Observed:** **00:03.4–00:05.3** contains a tutorial freeze, not measured hitstop. **00:05.4–00:06.2** shows Zero moving low past V's shot, with dust; dust is not proof of a punch or door kill. In the room at **00:26.97–00:27.20**, Zero strikes the door, which swings toward the first enemy; displacement and a bright encounter follow while gunfire crosses the room. That is a door interaction, not a fist's attack reach. Around **00:27.42–00:27.60**, Zero separately brings a pale bottle-like object behind his shoulder and releases it toward the room. Object motion, enemy reactions and crossing gunfire overlap; a precise kill attribution for every blood burst cannot be resolved from these frames.

[Outside dodge/tutorial context](../artifacts/combat_reference_research/kz_door_SEQUENCE.png) · [Door strike, consecutive frames](../artifacts/combat_reference_research/KZ_DOOR_NATIVE.png) · [Throw release, consecutive frames](../artifacts/combat_reference_research/KZ_THROW_RELEASE_NATIVE.png) · [Following low movement and room reaction](../artifacts/combat_reference_research/kz_door_verified_SEQUENCE.png).

**Finding:** no standard Zero bare-fist combo is verified. Door hits and throwable/projectile encounters must not be presented as an unarmed combo. The weaponless sequence is useful for separating action types, but does not document Zero's entire moveset or normal sword-combat rules.

**Documentation:** [Askiisoft's official description](https://askiisoft.com/) emphasizes acrobatic combat and instant defeat. That is developer intent, not proof of input latency or fist attacks.

**Transfer:** brief, clear causal events and a quick return to movement can carry impact without a long performance. **Do not copy** instant-kill balance, sword reach, time manipulation, door mechanics or lethal throws. Exact input response, attack cancels and hitstop are **UNVERIFIED**. No authenticated/age-restricted footage was retrieved to fill these gaps.

## Comparative study — observed evidence

This table compares the inspected excerpts, not every move in each game. “Unknown” is an evidence limit. Documentation and Iven proposals are separated above/below.

| Criterion | Gal | River City Girls | Mother Russia Bleeds | Dead Cells | Katana ZERO Studio 51 |
|---|---|---|---|---|---|
| Startup anticipation | Compact ready shape before short extensions | Compact exchanges; larger gather in ground strikes/throw | Small gather from guard | Gather partly obscured by weapon effects | Door/throw preparation; tutorial freezes excluded |
| Active contact | Fist/shoulder extension and yellow burst | Burst and overlapping bodies; exact fist ownership sometimes hidden | Extended arm with victim recoil | Weapon arc/burst at victim | Door displacement, then separate object release; not fist contact |
| Follow-through | Short recoil, later string becomes kicks | Large ground/throw follow-through versus compact exchanges | Modest torso commitment | Weapon follow-through then low movement | Movement/projectiles continue through encounter |
| Recovery | Recoil ready for next beat | Upright/crouched recovery visible; input acceptance unknown | Retract toward guard | Low travelling shape follows attack | Low movement follows room encounter |
| Upper body | Small shoulder/profile change | Stronger shape changes in larger actions | Torso lean and fist extension | Clear head/torso axis despite effects | Arm/object preparation distinct from body travel |
| Lower body stability | Feet nearly fixed during selected punches | Stable bases in some exchanges; throws leave ground | Bent-knee base under short punches | Attacks and traversal use different support shapes | Low movement/dodge; no planted punch base verified |
| Attack reach | Short limb-length extension | Mixed contact, weapon, grab and ground actions; not one reach value | Close limb-length strikes, partly occluded | Weapon-extended reach; unsuitable for fists | Door/object reach is environmental/projectile reach |
| Animation speed | Close successive extensions/recoils | Short contacts contrasted with broader actions | Repeated short strikes | Rapid visual succession, edited trailer | Brief causal events; slowed/planning sections distort timing |
| Enemy hit reaction | Visible displacement/contact reaction | Lean, lift and knockdown in different actions | Clear head/shoulder recoil | Reaction localized at weapon contact | Displacement/fall/blood; overlapping sources |
| Hitstop / impact VFX | Contact burst; pause mechanism unknown | Stars/bursts; pause length unknown | Blood/recoil; pause length unknown | Bright arc/burst; hold vs hitstop unresolved | Trails/blood; tutorial freeze is not hitstop |
| RUN / ROLL / JUMP compatibility | Ready return visible; cancel timing unknown | Movement/combat juxtaposed; precise cancels unknown | Ground/air attacks present; cancels unknown | Continuous attack→low movement; jump cut prevents causal proof | Dodge, throw and movement sequence; standard punch transitions unknown |

## Three practical directions — design proposals

| Evaluation | A — Minimal / Snappy | B — Arcade Brawler | C — Hybrid **recommended** |
|---|---|---|---|
| Visual satisfaction | Crisp but risks a hand flick | Stronger rhythm and weight | Quick M1 with a decisive contact shape; controlled M2 contrast |
| Ease of animation | Lowest pose count/work | More rotations and recovery to solve | Modest work concentrated on contact/recoil |
| Smooth transitions | Small displacement helps; overly abrupt contact can pop | Larger body changes complicate RUN/ROLL joins | Compact root/pelvis, short recoverable upper-body change |
| 50–60 px readability | Weak if fist stays inside chest silhouette | Strong if limbs separate; bulky costume can cluster | Prioritize fist gap and spare-hand separation at native scale |
| Existing rig | Existing arm/spine chains suffice | More garment/twist stress | Existing chains, restrained range; no rig edits |
| Sprite pipeline | Few drawings; direction still needs inspection | More distinct drawings and larger bounds | Few semantic poses, same camera/pivot/scale |
| Snapping / stiffness risk | Minimal torso response can look rigid | Large rotation can snap into locomotion | Shoulder lead and short recoil supply continuity without a long commitment |

**Why C:** Gal and the selected MRB punches demonstrate that short grounded strikes can have clear contact without extensive leg choreography. RCG demonstrates the value of strength contrast, although its mapped Light/Heavy distinction remains unresolved. DC/KZ support preserving visible movement continuity, not copying attack anatomy. C best fits the existing rig and small-sprite pipeline without a new combat movement system. No psychological symbolism or elaborate martial arts is needed.

## Proposed storyboards — not final assets

The original production brief's targets are **our prototype budgets**, not measured reference-game durations: M1 startup **0.04 s**, active **0.06 s**, recovery **0.10 s**; M2 **0.10 / 0.08 / 0.16 s**. These are provisional until tested. Physics timing and drawing playback are separate; 30 fps renders must not silently redefine 60 Hz attack windows. Three semantic poses below do not prescribe three total animation frames.

### M1-A — quick punch, first prototype after approval

| Element | Proposed construction |
|---|---|
| Anticipation, roughly 0–20% | Brief gather: striking fist near lower chest, spare fist slightly separated, elbow natural. Begin visible response immediately; no extra planted windup before accepting input. |
| Contact, roughly 20–50% | Short direct punch. Shoulder leads slightly; fist/forearm project beyond the chest edge through the locked camera. Soft elbow, no hyperextension or hand scaling. Spare hand remains identifiable. |
| Recovery, roughly 50–100% | Retract along a short path toward a usable guard/locomotion arm position. Avoid a second flourish or mandatory stop at the last cel. |
| Torso / hip | Small shoulder rotation over a quieter pelvis; no large reverse windup. Rotation magnitude chosen from actual camera renders, not an arbitrary degree target. |
| Feet / pelvis | Stable, slightly flexed support in standing tests; no root lunge or automatic crouch. Moving tests must respect continuing horizontal velocity. |
| RUN / IDLE return | From IDLE, settle into the existing idle support. From RUN, preserve movement and return to the current locomotion phase; do not restart RUN at a fixed contact frame. Roll/jump priority follows the approved controller rules. |

Use Gal for compact rhythm and MRB for contact/recoil alignment. Test both facing directions: the far arm must not disappear into the torso at 75°. Aim for a small visible hand/forearm gap where anatomy allows; judge at native scale, without stretching the arm or changing proportions.

### M1-B — alternate-arm continuation, proposal only

| Element | Proposed construction |
|---|---|
| Anticipation, roughly 0–20% | Use M1-A's retracting shape to prepare the opposite anatomical arm; avoid returning to a fresh neutral between punches. |
| Contact, roughly 20–50% | Opposite fist extends to the same intended gameplay range; first hand is withdrawn and visible. Equal gameplay role does not require identical projected anatomy. |
| Recovery, roughly 50–100% | Compact recoil toward IDLE or ongoing RUN; no compulsory third attack. |
| Torso / hip | Reverse the small shoulder lead with limited pelvis response; do not mirror Euler values blindly. |
| Feet / pelvis | Reuse the same support language; no extra step solely to distinguish the arm. Moving contact still needs its own visual test. |
| RUN / IDLE return | Same transition contract as M1-A. Alternate attacks without stacking long recovery locks or resetting locomotion phase. |

The alternation is a design inference from short-strike rhythm, not a claim that the footage reveals every anatomical arm. Do not author this Action before M1-A's gate is satisfied.

### M2 — short strong punch, proposal only

| Element | Proposed construction |
|---|---|
| Anticipation, roughly 0–29% | Slightly broader gather than M1: fist draws back, shoulder/hip prepare together, knees absorb a small weight shift. Keep head and hands separated. |
| Contact, roughly 29–53% | One controlled horizontal punch with a clearer torso commitment. Align fist, forearm and shoulder without a locked elbow. No launcher, spin, leap or exaggerated heroic stance. |
| Recovery, roughly 53–100% | Limited follow-through, then immediate recoil toward usable locomotion. No long balance performance or extra recovery beat. |
| Torso / hip | More coordinated hip/shoulder transfer than M1, bounded by costume deformation and native silhouette quality. |
| Feet / pelvis | Transfer pressure between supporting feet; no gameplay displacement baked into the sprite. No planted foot held rigid while the actor travels rapidly. |
| RUN / IDLE return | Preserve player movement, avoid automatic root acceleration and permit the approved defensive cancellation behavior. Short recovery must connect to either existing state. |

Use RCG's contrast in gathered/contact shapes and MRB's localized recoil principle. Do not copy their ground finisher, grab or throw anatomy. Stronger impact should come from pose alignment and accepted damage feedback, not merely a much longer clip.

## Iven pipeline audit and technical risks

A read-only Blender 3.6.23 opening of [the current library](../maincharacter/dodge_roll/IVEN_DODGE_ROLL.blend) found **101 AccuRIG bones**, existing RUN, SKID STOP, JUMP_START, JUMP_AIR, FALL, LAND and DODGE ROLL Actions, and **no M1/M2 Actions**. The source was not saved. [Audit receipt](../artifacts/combat_reference_research/IVEN_READ_ONLY_AUDIT.json).

The actual **RESEARCH_Y75_P00** camera is orthographic, scale **2.2200000286**, and its matrix matches [the established lock](../maincharacter/iven_animation_research/CAMERA_AND_ASSET_LOCK.json) with **maximum element error 0.0**. Current native output is **82×82**, approximately **60 px body**, 30 fps, Workbench, Standard / Medium High Contrast, exposure +0.45, gamma 1. Reuse this exact camera, framing, orientation, materials and rendering setup. No newly calculated yaw/Euler camera, refitting or rescaling to hide clipping. Inspect actual renders in both directions, not only numerical angles.

1. **Projection and costume:** the far fist can merge into the chest; broad torso rotation can stress the coat/sash. Existing garment acceptance limits remain. Use the current candidate, restrained poses and local camera-relative adjustments; no rig/weight repair or costume redesign.
2. **Full-body sprite limits:** current sprites cannot independently blend upper-body punches over arbitrary running legs. A planted lower-body image while Godot continues moving may visibly skate. The M1-A test must include moving entry/contact/return; do not conceal the problem with an input lock. Reusing the RUN leg language in a new attack copy is a possible animation-side solution, not permission to alter the approved RUN or build niche variants now.
3. **Contact synchronization:** derive future fist positions from evaluated hand bones through the locked camera. Align the visible contact cel, hitbox and enemy reaction. A long cosmetic bridge must not hide the contact while damage occurs. Existing roll entry/exit bridges require explicit interruption tests.
4. **Gameplay displacement:** Godot owns horizontal movement. Keep punch sprite root displacement in place; no automatic attack lunge, duplicate displacement or air boost. Do not restore the historical 0.70 s roll: [latest roll tuning](FINAL_ROLL_FEEL_QA.md) is 0.29 s / approximately 100 px, with immediate input cancels. No movement parameters are changed here.
5. **Integration remains future work:** reuse `NLBHealth` and its accepted damage events. Damage numbers should use accepted `hp_before - hp_after`, not requested damage. Multiple hitboxes must share one victim guard per attack instance; per-box marks alone do not prevent duplicate damage. Preserve E Motion Swap selection's LMB/RMB/Q roles and existing no-touch-damage rules. No new framework or health/UI implementation is delivered in this phase.
6. **Attachment and bounds:** preserve the current red flame assets. Future neck/fist metadata must follow the evaluated pose; do not freeze the flame in a world-space head position. Check sprite alpha bounds at the fixed pivot before full rendering; neither hands nor impact feedback should be cropped.

## Evidence limitations and next gate

- No games were manually played for this study; no controller input traces, internal hitboxes, game animation rates, exact cancels or hardware latency were measured. Audio was not evaluated.
- RCG light/heavy button assignments and cancels remain unresolved. Its throw/ground attacks demonstrate visual contrast, not proof of a particular neutral heavy punch.
- KZ's inspected Studio 51 run supplies door/object/dodge evidence, not a verified standard punch combo. Overlapping gunfire prevents attributing every defeat to one source.
- MRB alpha and DC early-access montage evidence may differ from current releases. Cuts, crowd occlusion, CRT effects, compression and held drawings limit timing conclusions.
- The Dead Cells 3D-to-2D article returned HTTP 403 in this run; its cached material was not substituted for newly inspected gameplay. Existing project pipeline instructions remain the production authority.
- No new combat poses or before/after sheets exist yet. Reference sheets above contain only the explicitly attributed source footage. Existing foundation test results are historical; no gameplay suite rerun is claimed for this documentation-only phase.

[Preservation receipt](../artifacts/combat_reference_research/RESEARCH_VALIDATION.json) records the protected-file and camera comparisons. The research evidence and this report are the only new deliverables of this phase.

**Approval requested: Option C — compact, responsive M1 with clear contact; a short, controlled M2 weight transfer. After approval, resume the original brief with M1-A only, rendered at the locked camera in native and nearest-neighbor enlarged views, including moving/standing entry, both facings and return to movement. Stop for M1-A visual review before producing M1-B or M2 animations.**
