# Phase D — research synthesis for production

Status: COMPLETE. This document defines constraints and testable craft rules; the final body law and palette remain Phase E work. No poses have been drawn.

## What the evidence supports

Design deductions: make intention legible in a few keys; let the existing controller set duration; restore support after an excursion; give the body identity before flame; spend detail where it explains mass or contact. Source games demonstrate different character capabilities and pipelines. Their principles transfer; their trained-fighter gestures, source sprites and implementation methods do not.

The [source ledger](external_research.md) records what was actually read. IDs below link directly to primary evidence. The Phase B clock, Phase C judgments and project rulebook remain the authority for this project's mechanics and exclusions.

## Action-game questions resolved

| Question | Transferable lesson / project deduction | Evidence |
|---|---|---|
| Pose clarity | Resolve intent with a few strong body keys before adding transitions. | [S01](https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i-), [S07](https://blasphemous.backerkit.com/hosted_preorders/project_updates?page=7) |
| Anticipation and responsiveness | No cosmetic anticipation may postpone accepted input. Compress preparation into the existing startup. | [S02](https://www.gamerevolution.com/originals/520685-katana-zero-interview), [S03](https://sourcegaming.info/2025/04/09/straight-from-the-source-team-cherry/), [S24](https://saint11.art/img/pixel-tutorials/AttackSheet.gif) |
| Active/contact frames | A contact key presents the existing damage window; it does not trigger damage. | [S01](https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i-), [S06](https://www.gamedeveloper.com/design/classic-postmortem-klei-entertainment-s-i-mark-of-the-ninja-i-) |
| Overshoot and recovery | An excursion needs a visible consequence and restoration; smoothness is not the goal. | [S13](https://www.animationmentor.com/blog/slow-in-and-slow-out-the-12-basic-principles-of-animation/), [S21](https://pmc.ncbi.nlm.nih.gov/articles/PMC9290492/) |
| Gameplay silhouette | Test against actual backgrounds, at actual size, before detailed polish. | [S05](https://www.gamedeveloper.com/design/-i-my-friend-pedro-i-s-journey-from-flash-cult-hit-to-indie-success), [S07](https://blasphemous.backerkit.com/hosted_preorders/project_updates?page=7), [S14](https://saint11.art/blog/thoughts_on_low_resolution/) |
| Hit readability | Distinguish unexpected flinch from voluntary attack and confirmed contact from whiff. | [S06](https://www.gamedeveloper.com/design/classic-postmortem-klei-entertainment-s-i-mark-of-the-ninja-i-), [S19](https://pmc.ncbi.nlm.nih.gov/articles/PMC4928472/) |
| Dash readability | Direction, body transition and attachment must explain the move; do not rely on a long detached streak. | [S08](https://80.lv/articles/development-of-dystopian-platformer-sanabi-its-chain-hook-arm-mechanics), [S22](https://saint11.art/img/pixel-tutorials/MotionBlur.gif) |
| Jump / fall readability | Commanded release and unsupported descent need different bodily intentions. | [S09](https://www.proko.com/course-lesson/how-to-draw-gesture/), [S13](https://www.animationmentor.com/blog/slow-in-and-slow-out-the-12-basic-principles-of-animation/), [S19](https://pmc.ncbi.nlm.nih.gov/articles/PMC4928472/) |
| Held frames | Spend exposures on informative keys; holds remain subordinate to state changes and existing hitstop. | [S01](https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i-), [S24](https://saint11.art/img/pixel-tutorials/AttackSheet.gif) |
| Smears | Treat a smear as a path between named states and parts, not an independent effect. | [S22](https://saint11.art/img/pixel-tutorials/MotionBlur.gif) |
| Compression / extension | Change torso relation and folded limbs, preserving solid mass and joint connections. | [S09](https://www.proko.com/course-lesson/how-to-draw-gesture/), [S10](https://www.proko.com/course-lesson/how-to-draw-structure-in-the-body-robo-bean) |
| Body / secondary offset | Establish core action first, then purposeful lag and settling without hiding the limb silhouette. | [S11](https://www.animationmentor.com/blog/twinning-and-why-you-should-usually-avoid-it/), [S12](https://www.animationmentor.com/blog/tutorial-animate-overlap-and-follow-through/), [S20](https://journals.biologists.com/jeb/article/217/14/2456/12120/The-metabolic-cost-of-human-running-is-swinging) |

## Every Phase C group mapped

The following sixteen rows retain Phase C's actual verdicts: fourteen motion/effect groups (6 FIX, 8 REPLACE), two static groups (1 FIX, 1 REPLACE). They are research remedies, not reclassification or production approval.

| Reference Problem | Why It Fails | Research Principle | Production Rule for NEVERLOOKBACK |
|---|---|---|---|
| **head_idle — FIX**. HEAD VARIATION (IDLE): eye-like paired lights, changing void width/tilt, unknown attachment. | Face cues defeat the faceless brief; separate studies cannot establish continuity. | Primary construction remains stable beneath secondary variation. [S12](https://www.animationmentor.com/blog/tutorial-animate-overlap-and-follow-through/), [S15](https://saint11.art/blog/glossary/) | Build one registered void/root system; vary unequal tips around it. Remove eyes/skull pips. Body-hidden tests cannot substitute for body-only tests. |
| **head_action — FIX**. HEAD DURING ACTION: missile-like leading void, no root or returning shape. | Shape change lacks a causal origin and recovery. | A smear must connect to its preceding anatomical source. [S12](https://www.animationmentor.com/blog/tutorial-animate-overlap-and-follow-through/), [S22](https://saint11.art/img/pixel-tutorials/MotionBlur.gif) | Keep neck/root attachment, deform along the actual body motion, then recover a recognizable void. A stretched head cannot read as a launched projectile. |
| **idle — FIX**. IDLE: final frontal turn mixed with breathing; neck/limb continuity unclear. | An orientation change masquerades as a loop; quiet body remains interchangeable. | Gesture and unequal overlap convey intent more clearly than a contour bob. [S09](https://www.proko.com/course-lesson/how-to-draw-gesture/), [S11](https://www.animationmentor.com/blog/twinning-and-why-you-should-usually-avoid-it/) | Keep one facing, support and grip ownership through the loop; use unequal body rhythms derived from the eventual law, not a whole-sprite bob. |
| **walk — REPLACE**. WALK: repeated wide splits; missing passing/opposite support; reads as slow run. | No complete weight-transfer cycle is visible. | Locomotion must show distinct phases and alternating support. [S18](https://pmc.ncbi.nlm.nih.gov/articles/PMC5546309/), [S23](https://saint11.art/img/pixel-tutorials/RunCycleSimple.gif) | Author contact, low, passing and opposite contact for the actual locomotion cycle. Do not add a walk input or new walk speed because the reference has a row. |
| **run — REPLACE**. RUN: athletic lunge repetition, ambiguous paired limbs, hand/shirt changes, unproven seam. | A heroic wedge and incoherent ownership conceal the person's movement. | Arm participation and torso motion are coupled; contact phases must remain identifiable. [S20](https://journals.biologists.com/jeb/article/217/14/2456/12120/The-metabolic-cost-of-human-running-is-swinging), [S23](https://saint11.art/img/pixel-tutorials/RunCycleSimple.gif) | Track both legs and anatomical arms through a complete cycle. Couple arm restriction to torso compensation. Preserve clothes and grip; check three loops and both facings. |
| **jump — FIX**. JUMP: no launch coil; overlapping limbs; compressed ending; board positions are not a trajectory. | Intent and release cannot be distinguished from a tuck or kick. | Connected torso construction and purposeful spacing distinguish release from a folded pose. [S10](https://www.proko.com/course-lesson/how-to-draw-structure-in-the-body-robo-bean), [S13](https://www.animationmentor.com/blog/slow-in-and-slow-out-the-12-basic-principles-of-animation/) | Show release immediately after real launch, optional compact rising pose, apex adjustment and descent transition. Fit visual compression around existing movement, never before input takes effect. |
| **fall — REPLACE**. FALL: grounded first pose, seated/kick-like forward feet, unclear descent and restoration. | A passive loss of support reads as another commanded action. | Gesture identifies intention; an unexpected loss of support is not the same action as a jump. [S09](https://www.proko.com/course-lesson/how-to-draw-gesture/), [S19](https://pmc.ncbi.nlm.nih.gov/articles/PMC4928472/) | Separate falling from rising using unsupported pelvis, preparation for landing and non-kicking feet. A ledge fall must work without any jump anticipation. |
| **dash — REPLACE**. DASH: fixed lunge, giant final head, no exit/reconnection. | Head spectacle replaces state change and body consequence. | Visual direction and transition must communicate the core mechanic. [S08](https://80.lv/articles/development-of-dystopian-platformer-sanabi-its-chain-hook-arm-mechanics), [S22](https://saint11.art/img/pixel-tutorials/MotionBlur.gif) | Give body distinct entry, transit and exit shapes within 150 ms; use directionally attached deformation. Exit reconnects to the true grounded/air/attack state. |
| **attack_quick — REPLACE**. ATTACK 1: repeated guards, changing striker, lifted foot/arm detour, no source return. | The strike lacks one cause, contact and consequence. | Strong keys and a readable return must fit responsive action timing. [S01](https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i-), [S24](https://saint11.art/img/pixel-tutorials/AttackSheet.gif) | Use one consistent anatomical striker/grip; compact startup, forward contact, distinct whiff/confirmed recovery. Keep a supported foot and a readable return. |
| **attack_heavy — REPLACE**. ATTACK 2: flame as weapon, giant smear with small body change, unstable return; no heavy action in game. | It promises mechanics and reach that do not exist. | The actual mechanic and context determine the visual promise. [S02](https://www.gamerevolution.com/originals/520685-katana-zero-interview), [S07](https://blasphemous.backerkit.com/hosted_preorders/project_updates?page=7) | Do not produce a heavy state. Reuse only the abstract compression/contact/recovery lesson in existing armed/finisher confirmation, without larger reach or fire damage. |
| **attack_up — REPLACE**. ATTACK 3: absent upward mechanic, changing strike direction, arm/flame ambiguity, spell arc. | An unsupported move and magical ownership obscure actual direction. | Action cues must identify the mechanic and direction the player actually controls. [S06](https://www.gamedeveloper.com/design/classic-postmortem-klei-entertainment-s-i-mark-of-the-ninja-i-), [S08](https://80.lv/articles/development-of-dystopian-platformer-sanabi-its-chain-hook-arm-mechanics) | Do not produce an up-attack state. Every existing attack must clearly face and contact in its actual direction, with attached body and weapon. |
| **hurt — FIX**. HURT: attack-like guards, unspecified impact direction, no restored support, torso/limb drift. | A voluntary attack and involuntary flinch become indistinguishable. | Unexpected postural disturbance and support restoration differ from deliberate action. [S19](https://pmc.ncbi.nlm.nih.gov/articles/PMC4928472/), [S21](https://pmc.ncbi.nlm.nih.gov/articles/PMC9290492/) | Show unexpected contraction/support disturbance followed by restoration within the hurt visual window. Use directional response only if existing data provides direction. |
| **death — FIX**. DEATH: merged legs, disappearing final body, unknown final contacts. | Collapse loses material mass and anatomical cause. | Solid connected masses must survive changing balance and contact. [S10](https://www.proko.com/course-lesson/how-to-draw-structure-in-the-body-robo-bean), [S21](https://pmc.ncbi.nlm.nih.gov/articles/PMC9290492/) | Track loss of support into a settled body with both limbs accounted for. Keep physical body present; flame loses structure separately. Respect actual floor and reload clock. |
| **extra_effect — REPLACE**. EXTRA: detached blobs/streak/U-curl, no event/root/endpoints, particle/aura association. | Decoration invents an emitter or projectile. | Secondary motion and smear require an attached cause and temporal endpoints. [S12](https://www.animationmentor.com/blog/tutorial-animate-overlap-and-follow-through/), [S22](https://saint11.art/img/pixel-tutorials/MotionBlur.gif) | No autonomous effect animation from these samples. A needed smear belongs to an existing event and named attached part, with readable source and destination. |
| **turnaround — FIX**. Large views: unregistered feet/stance, shifting head volume, jacket/hand uncertainty. | Inconsistent construction cannot be a production model sheet. | Stable construction and selective detail preserve identity through projection. [S10](https://www.proko.com/course-lesson/how-to-draw-structure-in-the-body-robo-bean), [S14](https://saint11.art/blog/thoughts_on_low_resolution/) | Derive a fresh native-size construction sheet, fixed landmarks and material masses. Track projected shortening rather than shrinking body dimensions per pose. |
| **silhouette — REPLACE**. SILHOUETTE: faint generic outline, flame included, no distinct pose exploration. | The head can conceal a body without identity. | Body shape, pose variety and gameplay-background readability must be established before polish. [S07](https://blasphemous.backerkit.com/hosted_preorders/project_updates?page=7), [S17](https://www.proko.com/course-lesson/how-to-draw-interesting-shapes/) | Judge new body-only poses at actual gameplay size and compare transitions. Require the chosen later law to survive flame, texture and color removal. |

## Human motion: practical interpretation

Use a line of action to connect intention through the ribcage, pelvis and supports. Distinguish torso tilt from a change in limb length. Weight transfer is a relationship among masses and contacts; a pelvis moving while the chest remains rigid, or arms swinging without any torso consequence, needs an explicit reason. [S09](https://www.proko.com/course-lesson/how-to-draw-gesture/), [S10](https://www.proko.com/course-lesson/how-to-draw-structure-in-the-body-robo-bean), [S18](https://pmc.ncbi.nlm.nih.gov/articles/PMC5546309/), [S20](https://journals.biologists.com/jeb/article/217/14/2456/12120/The-metabolic-cost-of-human-running-is-swinging)

Our civilian can overreach and regain support, brace before committing, or unwind from an awkward twist. These are alternatives, not a selected law. A shove, forearm or shoulder contact should have a connected proximal cause, plausible support and recoil; avoid an expert fist guard, martial pose or triumphant finish. Desperation can live in uneven arm participation and a hurried catch of balance while legs still alternate. A constant forward lean alone is insufficient identity.

Unexpected hurt may briefly raise or contract both arms; deliberate asymmetry is not a blanket biological rule. A stumble needs a disturbed support and a credible catch, not random jitter. Scientific sources concern ordinary gait, running and laboratory perturbations; they do not validate these specific stress performances. All such choices remain animation hypotheses requiring native-scale and runtime evidence. [S11](https://www.animationmentor.com/blog/twinning-and-why-you-should-usually-avoid-it/), [S19](https://pmc.ncbi.nlm.nih.gov/articles/PMC4928472/), [S21](https://pmc.ncbi.nlm.nih.gov/articles/PMC9290492/)

## Low-resolution construction and authored omission

The baseline is a 64×64 texture with approximately 56 pixels of visible body height, pivot (32,62), offset (-32,-62), native scale and nearest filtering. A 48–64 px research target is a readability range, not permission to silently shrink this protagonist. Phase E must settle final measurements and safe gutters from the saved scene evidence. Extreme reach may need additional transparent gutter space while preserving the anchor; do not scale poses to fit.

Use broad body value/material masses, quieter interiors, and limited highlights at form changes. Let an elbow gap, cuff or sole explain a connection. Simplify hands to an intentional palm/grip shape with a wrist; simplify feet to a volume and directional sole/toe. Finger speckles, two competing bright hand dots or clothing noise cannot substitute for ownership. [S14](https://saint11.art/blog/thoughts_on_low_resolution/), [S15](https://saint11.art/blog/glossary/), [S16](https://pixeljoint.com/forum/forum_posts.asp?PID=139318&TID=11299)

Keep a landmark ledger for collar, shoulder joints, ribcage limits, pelvis, paired wrists/knees/ankles, sole and grip. Foreshortening changes visible length, not the implied bone. Reject an unexplained missing limb, swapped skin cluster, expanding shirt opening or changing sleeve thickness. Occlusion must be traceable in neighboring keys. Register comparisons by pivot; compare body landmarks separately from deformable flame.

Test body silhouette, grouped values and full color at 1× on the saved game backgrounds; inspect integer enlargement only for repair. BODY-only and full-color tests answer different questions. No alpha smoothing, interpolation, random distress, dither, wallpaper folds, universal black outline, glow or reflected flame light. Require alpha 0/255 in future exports. Cluster count and palette count support inspection but cannot prove motion quality.

Anti-generic checks are authored criteria, not AI detection: preserve one body behavior across quiet, moving, striking and hurt states; contrast quiet masses with a few meaningful shape breaks; use uneven timing only where force/intention explains it; document what was omitted. At least two candidate-defining body relationships must remain visible without flame or surface detail. Clean edges alone do not satisfy this. [S04](https://www.gamedeveloper.com/business/the-ultra-modern-stylings-of-hyper-light-drifter), [S11](https://www.animationmentor.com/blog/twinning-and-why-you-should-usually-avoid-it/), [S13](https://www.animationmentor.com/blog/slow-in-and-slow-out-the-12-basic-principles-of-animation/), [S17](https://www.proko.com/course-lesson/how-to-draw-interesting-shapes/)

## Testable production rules A–L

These rules are proposals for later production and QA, not claims of tests already passed. Durations come from Phase B. At 60 Hz, nominal seconds need not correspond to an exact count of displayed drawings: inspect captured boundaries, including short-window skips, instead of extending gameplay.

### A. IDLE

**Rule:** Keep support, anatomical arm ownership, facing and garment volume stable; internal breathing/weight adjustment must retain the eventual law. Flame does not drive a global body bob.
**Timing:** Interrupt on the real next state; no mandatory loop completion or turn-through-front.
**Test:** Three loops at 1× and BODY-only, both facings; compare first/last roots and landmarks. Reject sliding soles, orientation pop, paired-arm duplication or hand identity changes.

### B. RUN

**Rule:** Author a full leg-ownership cycle including both contacts, down/loading, passing/recovery and airborne/high phases as appropriate. Arm participation and torso compensation must express the eventual civilian law. No copied heroic split-lunge cycle.
**Timing:** Baseline is distance-driven: 18 px per drawing, six drawings / 108 px per cycle; at 280 px/s this is about 0.386 s. This is a compatibility baseline, not a mandated final frame count or global FPS. Preserve acceleration/reversal and the existing phase behavior unless a later visual-only change is justified.
**Test:** Label near/far anatomical limbs through three cycles. At distance-sample boundaries inspect the stance foot's world-space trace and compensate root advance where appropriate. Held art moves with the root between samples: quantify that residual slide rather than claim perfect pinning. Any later visual sampling remedy must not change motor speed or mechanics. Test starting, stopping and reversal without requiring a reset or completed cycle.

### C. JUMP

**Rule:** Present release immediately at launch, retain both limb identities during fold, and make apex adjustment lead into descent. Show compression through articulated relationships, not image squashing.
**Timing:** Jump starts at -640 px/s; rise gravity 1600, release cut 0.45, coyote 100 ms and buffer 120 ms remain unchanged. No added grounded anticipation. A prelaunch coil may appear only when already available without delaying launch.
**Test:** Press, tap/release, buffered landing jump and coyote jump. Reject planted feet after airborne launch or the same tucked pose for all vertical phases.

### D. FALL

**Rule:** Depict unsupported weight and preparation to meet the floor; avoid a seated forward kick. Enter directly from a ledge as well as from apex.
**Timing:** Existing stronger descent gravity remains authoritative. No minimum fall exposure or artificial apex hold. On real landing, permit a compact cosmetic response without locking controls; a hard landing uses the existing >700 speed signal.
**Test:** Compare rise/apex/fall thumbnails BODY-only. Capture ledge descent, short hop and hard landing. Reject fall poses with implied floor contact or a delayed visual landing.

### E. DASH

**Rule:** Distinct entry, transit and exit body shapes; stable material identity beneath attached deformation. Exit reads the actual next state.
**Timing:** Existing 150 ms at 650 px/s; baseline entry <20 ms, transit until 110 ms, final 40 ms exit. A late dash strike occurs in the existing final 60 ms and may supersede the normal exit.
**Test:** Ground dash, air dash, wall encounter, opposite facing and dash strike. Reject a huge head masking unchanged lunge anatomy, an obligatory exit after strike, or a new startup delay.

### F. ATTACK ANTICIPATION

**Rule:** One compact bodily preparation with a clear intended direction and consistent striker/grip. No sequence of trained guards.
**Timing:** Fit inside startup 50 ms. The existing dash-strike display bypasses the first anticipation drawing; preserve that exception. No extra windup or input lock.
**Test:** Boundary captures must already progress to active presentation when startup expires. Check both facings and held weapon; no hand swap or cosmetic windup that suggests damage has begun early.

### G. ATTACK CONTACT

**Rule:** A connected body contact shape conveys the current reach and forward step. Confirmed contact and whiff differ in consequence. Smear can bridge motion but cannot be the sole contact evidence.
**Timing:** Active window 120 ms follows startup; current forward step 60 and reach 82/104 are unchanged. Existing confirmed feedback/hitstop (45/75/100 ms by case) supplies impact punctuation; no extra pause and no damage from animation events.
**Test:** Compare miss, unarmed, armed and finisher confirmation at actual damage boundaries. The body and weapon must face the existing hit direction; flame must not imply fire damage, extra reach or an up/heavy move.

### H. ATTACK RECOVERY

**Rule:** Show the cost of reaching/contact and a readable restoration of support; whiff can pass through overreach while contact rebounds. Return preserves the same person and hand.
**Timing:** Existing recovery 80 ms. Baseline whiff uses one drawing for its first 40 ms then returns; confirmed recovery uses the other return drawing. Total action 250 ms, with existing additional 350 ms cooldown and 600 ms buffer retained. Do not confuse cooldown with mandatory visible recovery.
**Test:** Miss and hit should return differently without a new state or extra clock. Running may already be progressing beneath attack presentation; test the actual cycle reentry rather than force a neutral reset.

### I. HURT

**Rule:** Immediate unexpected contraction/support disturbance, followed by restoration; separate from attack readiness. Avoid implying a directional impact the presentation cannot know.
**Timing:** Nonfatal health change provides a 120 ms visual window; 1 s invulnerability does not justify a 1 s hurt animation lock. Fatal damage follows died rather than the nonfatal changed path.
**Test:** Stationary, running and airborne hits, both facings and fatal hit. Preserve input/physics. Check flinch recognition BODY-only and ensure real support survives the return.

### J. DEATH

**Rule:** Loss of support produces an anatomically traceable collapse and settled physical mass; flame structure fails separately. Do not dissolve the body into embers.
**Timing:** Fit recognizable consequence and a final body before the 1.2 s reload. The existing controller continues during death: artwork follows actual root/floor rather than freezing physics or imposing an input lock.
**Test:** Grounded, moving and airborne fatal cases. Label both legs through collapse; check actual contacts and ensure no body disappearance or invented levitation.

### K. FLAME SECONDARY MOTION

**Rule:** Root belongs to the anatomical neck; void remains faceless. Body leads, flame exaggerates self-image through attached shape response: contained idle, rearward running lag, rise stretch, upward descent drag, dash shear, antic compression, contact tear, recovery snap, hurt disruption and death loss of coherence.
**Timing:** Secondary exposure offsets fit the enclosing state and existing freeze/hitstop. No independently ticking flame during a frozen presentation. No forced universal delay or separate attack emitter.
**Test:** Toggle FLAME off: state and body law still read. Restore it: attachment, source/return and event direction remain clear. Reject eye pairs, skull, hero hair, glow, aura, autonomous particles or projectile identity. Quantitative head-area measurements cannot replace this visual test.

### L. SMEAR FRAMES

**Rule:** Each smear has a named emitting body/flame/weapon part, previous source, directional path and next destination. Keep root/grip ownership. Use the minimum informative exposure and follow with a recognizable body key.
**Timing:** Only within existing rapid action transitions; never create a new held damaging interval. A full-screen pause or persistent trail is not a substitute for an actual transition.
**Test:** Inspect the source/smear/destination triplet at 1× and under hitstop or interruption. A paused smear must not turn into a spell or lose the body. Remove it temporarily: core action should still make sense.

## Integration limits carried forward

Weapon FREE/HELD/BROKEN behavior, fixed present anchor and draw order, five uses and four-second respawn are unchanged. Later authored hand anchors must preserve the same anatomical grip across mirrored frames; current anchor may visibly fail extreme poses. Pickup/perception/fracture sequence remains 465 ms with its audited milestones; carry body identity through those states without adding mechanics.

Blink freezes fight/timers and skips visual updates for 280 ms while gravity continues. Do not run secondary animation or recovery through that freeze, delay buffered action, or invent extra teleport poses that imply changed movement. Preserve existing veil/arrival presentation and check reentry later. Camera, global render settings, hitboxes and hidden-body test behavior remain untouched.

No walk/heavy/up mechanics will be added to service reference rows. No final law or hex palette is selected here. Production stays native Pixelorama MCP with separate BODY, FLAME and WEAPON, two real correction passes and later runtime QA.

## Unresolved questions for later phases

1. Which retained candidate best survives native-scale eight-master proof? Text scores are provisional.
2. Exact body measurements, material hex values, gutters and allowed landmark tolerances remain E decisions.
3. Visual foot slide under the current distance-sampled holds must be measured; any remedy belongs to later visual integration.
4. A stress-specific live movement reference is still unverified. The chosen performance must be tested as an authored civilian hypothesis.
5. Pose-dependent hand anchors, interrupted smear exposure, moving/airborne death and hurt direction availability need later integration checks.
6. Reference provenance, original grid, temporal order/exposures and loop seams remain unknown; research does not resolve them.

Next: PHASE E — FINAL MOVEMENT/BODY-LANGUAGE LAW. Stop at the Phase D boundary.
