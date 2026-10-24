# Phase E — decision matrix

Status: COMPLETE. Selected: **B — BRACE, THEN DRIVE**. A is retired for this rebuild; C remains rejected. No hybrid and no production art.

## Evidence and method

The five required saved documents were fully reread: [runtime audit](project_runtime_audit.md), [reference sprite audit](reference_sprite_audit.md), [reference animation audit](reference_animation_audit.md), [research synthesis](research_synthesis.md), and [candidate definitions](movement_law_candidates.md). Skills were not reread. Targeted sections of the preserved player/prop snapshots clarified interruption and anchor details, without redoing Phase B or changing current code.

This is a structural design test: mechanically reachable joint endpoints, canvas occupancy, mirror transforms, timer/selector boundaries and interrupted-state reasoning. It is **not** a runtime replay, drawn silhouette study, native-size perception test or finished animation proof. Twelve centerline probes are mathematical analysis only; they are not a rig, raster-production recipe or reusable art. No Pixelorama action was necessary for this structural choice. Final art and 1× proof belong to F onward. [Machine-readable checks](phase_e_structural_checks.json) preserve all definitions, 240 state assessments, nine interruption comparisons and numeric probes.

Both Phase D totals were 86/100. Those equal text scores did not decide this phase. B wins because its smaller excursion and protected shoulder relation remain legible as construction at the destination of abrupt changes, while A more often needs a displayed retrieval to distinguish itself from a generic reach. This is a constraint-based art-direction decision, not a claim that A cannot ever animate well.

## Precise definition of both candidates

Coordinates are texture-space design targets, y downward; right-facing is the canonical view. Right denotes anatomical right/grip arm and is drawn as the near arm in that view. The root remains (32,62). Head means the faceless void/head mass, not the longest flame tip. Angles are pelvis-to-rib center axes measured forward from vertical.

| Required definition | A — Reach, then catch up | B — Brace, then drive |
|---|---|---|
| Default spine | Collar forward of pelvis 3–4 px at rest; pelvis-to-rib axis about 14°. Preserve a shallow connected curve, not a permanently falling line. | Collar forward of pelvis about 3 px; pelvis-to-rib axis about 9.5°. Short waist connection and a mobile curve; rest is not deep crouch. |
| Head position | Void center +4 px ahead of pelvis in idle, +12 run, +18 dash, +17 contact. Anatomical neck remains attached. | Void center +3 px idle, +6 run, +12 dash, +9 contact. Attached neck; no head-led impact surface. |
| Shoulder relationship | Right/grip shoulder 1 px nearer the neck than left in baseline; chest-forward excursion dominates this small offset. | Right/grip shoulder is about 2 px higher than left in upright enclosed targets; carry its collar-side anatomical role with the torso through oblique keys, not an exact screen-y gap. |
| Ribcage orientation | Rib center leads pelvis by 3 px idle, 8 run, 10 dash/contact; approximately 14–45° forward axis in six targets. | Rib center leads pelvis by 2 px idle, 3 run, 5 dash, 0 antic, 6 contact, 2 recovery; approximately 0–25° forward axis. |
| Pelvis orientation | Near-level belt plane, projecting after the chest. Use 1–2 px belt tilt with alternating contact; no rotating rigid cutout. | Near-level belt plane initiates the support transfer; 1–2 px tilt alternates with support. Ribcage yaw/lean responds at smaller or later amplitude. |
| Center of gravity | Torso/pelvis drawing proxy moves toward front support; an excursion needs subsequent retrieval. Never equate this proxy with measured whole-body mass. | Proxy stays within static support in quiet keys, moves forward in action and is recontained. A running mass need not be within the current foot at every instant. |
| Weight-bearing leg | Right leg favored at rest; both anatomical legs alternate without a permanent weaker side. A forward catch is not a forced gameplay step. | Right leg favored at rest; both legs alternate. A support/down accent precedes chest opening. Equal competent legs; no permanent unilateral drag. |
| Arm spacing | Wide action/grip versus trailing free arm; six targets have 22–33 px horizontal wrist separation. One narrow free-elbow window remains required. | Right grip stays below head/face, left elbow supplies a 2–3 px open wedge against ribs; six targets have 20–29 px wrist separation. No paired raised fists. |
| Leg rhythm | Distinct right contact/down, passing/flight, left contact/down and return, with faster visual gathering under advancing chest. | The same complete bilateral support sequence; loading accents precede short chest releases. Alternate legs fully rather than mirroring half a gait. |
| Movement initiator | Upper chest visually commits first; pelvis and support catch the advance. | Support loading and pelvis drive lead the action; ribcage initially stays enclosed beneath the right shoulder. |
| Delayed body part | Pelvis/support retrieval then trailing shoulder, free wrist and attached flame. This chain may need more than the remaining visible exposure. | Chest opens after support drive; left wrist and flame finish after torso reclosure. Offsets are spatial/pose relationships within the current clock, never extra input delay. |
| Forward acceleration | Actual root accelerates immediately; chest lead grows 3→8 px rib-to-pelvis across selected keys, then support catches. No planted prelaunch hold. | Actual root accelerates immediately; pelvis changes first in the pose, rib lead grows 2→3 px and chest briefly opens. No brace wait. |
| Braking | Actual friction/reversal changes root velocity; chest retains forward excursion until a support retrieval key. Cancellation may omit that defining catch. | Real braking loads support; rib lead shrinks toward 0–2 px while the left elbow stays legible. No forced skid duration or additional displacement. |
| Attack loading | Compact chest commitment, retaining consistent right striker; six-target antic rib lead 3 px. Returning from run to this key drops rib lead by 5 px. | Rib center nearly above pelvis, grip below face, right shoulder close to collar; antic rib lead 0 px. From run the lead changes only 3 px. |
| Attack contact | Right palm/weapon acts forward with pelvis trailing chest by 10 px; head lead 17 px. Support and restoration must justify the overreach. | Pelvis projects, chest opens to 6 px lead, right hand connects forward while left elbow stays separate; head lead 9 px. No trained straight-punch guard. |
| Recovery | Support/pelvis retrieves the chest before wrist/secondary settling. The law is clearest only if the catch is displayed. | Rib lead contracts to 2 px and protective shoulder relation remains; wrist/secondary settle afterwards. A cut can discard final settle without changing the body's identity. |
| Interrupted-state behavior | Discard unfinished catch on real cancel; use destination pose and preserve anatomical ownership. A frozen/cut lunge risks leaving only stock reach. | Discard final settle on real cancel; choose the destination compact/open key directly, retaining protected shoulder, support relationship and grip. No mandatory rest reset. |
| Mirror behavior | Use facing × (texture point − pivot); anatomical right remains right and leg phase is not swapped. Large head lead reverses instantly with facing even while velocity still opposes it. | Same transform/ownership. Smaller lead permits a compact braking pose when facing changes before velocity crosses zero; no interpolated turn-through-front. |
| Weapon-anchor implications | Rest grip (48,32) matches legacy offset. Target grip travel reaches local (27,-29); fixed legacy anchor cannot hold the arm through action. | Rest grip (48,32) matches legacy offset. Target contact (56,32), local (24,-30), requires pose metadata; no change to prop state, collision, reach or transformation time. |

## Twelve actual-state comparisons

Each table answers all ten requested questions for both candidates. A statement that a proxy fits means occupancy/segment feasibility only; recognizability and emotional interpretation require later real pixel art. Directions and contacts are drawn according to the actual state, not inferred from illustration layout.

### IDLE

| Question | A | B |
|---|---|---|
| Is the law visible? | Visible only through a small checked inclination; whole-cycle support retrieval is absent. | Enclosure visible through right shoulder and left elbow wedge. |
| Anatomically believable? | Supported stance; right loading must not lock the other leg. | Supported stance; keep knee flexion modest and spine mobile. |
| Fast response preserved? | Directly leave idle on accepted action. | Already compact: next state needs no new wait. |
| Fits/reads at 64×64? | 32×45 BODY proxy fits; identity at 1× unproven. | 31×45 BODY proxy fits; gap/identity still needs raster proof. |
| Survives mirroring? | Fits transform; small head lead reflects cleanly. | Same asymmetry reflected without hand reassignment. |
| Modular weapon coexistence? | Legacy rest anchor fits right hand. | Legacy rest anchor fits right hand. |
| Flame reinforcement? | Small contained unequal tips; no flame-driven bob. | Contained flame disagrees subtly with physical restraint. |
| Generic risk? | High if only a forward slouch is drawn. | High if enclosure replaces release rhythm; static hunch alone fails. |
| Goofy risk? | Repeated aborted leans could look indecisively comic. | Large repetitive shrug would look comic; cap at 1–2 px. |
| Movement-impairment misread risk? | Persistent off-center sway could imply instability; keep supports quiet. | Do not hold a rigid painful-looking curl; preserve easy breathing and mobile supports. |

### RUN

| Question | A | B |
|---|---|---|
| Is the law visible? | Chest lead and fast support retrieval can identify the law. | Load→short chest release repeats across bilateral contacts. |
| Anatomically believable? | Both contacts/flight must be clear; no trailing dead leg. | Arm restriction needs torso response; both legs work normally. |
| Fast response preserved? | Root follows actual 2600 acceleration immediately. | Support accent is drawn inside current distance cadence. |
| Fits/reads at 64×64? | 42×39 proxy fits, but broad wedge competes with detail. | 35×40 proxy fits; open left wedge remains required. |
| Survives mirroring? | Keep actual leg phase; immediate facing change may flip a long lead. | Compact lead helps reverse without a turn animation. |
| Modular weapon coexistence? | Grip moves to (51,41); metadata needed. | Grip (49,37); right ownership retained. |
| Flame reinforcement? | Rearward lag, attached neck, no independent trail. | Rearward flame reinforces brisk drive rather than propulsion. |
| Generic risk? | High if all keys repeat the same athlete's diagonal. | Moderate: compact jog becomes stock if chest never opens. |
| Goofy risk? | Excess retrieval can look like repeatedly tripping. | Tiny frantic steps would look comic; retain complete stride. |
| Movement-impairment misread risk? | Do not exaggerate one leg's catch or drag; both must carry normal strides. | No unequal leg length, permanent drag or one-sided cadence. |

### REVERSE DIRECTION

| Question | A | B |
|---|---|---|
| Is the law visible? | Defining catch may be skipped by immediate facing reversal. | Compact enclosure survives even when release is cut. |
| Anatomically believable? | Ground support must respond to old velocity, not simply new facing. | Support handles old velocity; posture faces input while braking. |
| Fast response preserved? | Reverse acceleration 4200 remains untouched. | Immediate response; no required skid hold. |
| Fits/reads at 64×64? | Use compact braking variant; full forward lunge is unsafe as an immediate flip. | 0–2 px rib lead braking target fits; no new broad turn. |
| Survives mirroring? | Facing changes before velocity crosses zero; large lead strongly reverses. | Reflect right anatomy; distinguish facing from current velocity. |
| Modular weapon coexistence? | Mirror pose anchor and preserve the held hand. | Grip stays registered through braking variant. |
| Flame reinforcement? | Flame must use actual travel/deceleration cue; freeze obeyed. | Lag may briefly remain in old-travel direction within attached envelope. |
| Generic risk? | Mirrored heroic run is a major failure risk. | Stock skid risk if a dramatic leg split is used. |
| Goofy risk? | S-shaped wobble after each reversal reads comic. | Avoid exaggerated tiptoe pivot or repeated bounce. |
| Movement-impairment misread risk? | Do not imply a failing ankle or repeated involuntary collapse. | Both legs can brake; no permanently compromised support. |

### JUMP RISE

| Question | A | B |
|---|---|---|
| Is the law visible? | Chest lead without foot support makes a catch less meaningful. | Pelvis release preserves protected chest relation without requiring ground after launch. |
| Anatomically believable? | Use unsupported fold and account for both knees/feet. | Fold both limbs through hips; no planted feet once airborne. |
| Fast response preserved? | Launch at -640 immediately; no grounded coil. | No anticipatory wait; short-hop cut preserved. |
| Fits/reads at 64×64? | Need separate airborne key; no raster proof. | Vertical recovery fold must separate ankles at least 2 px when distinguishable. |
| Survives mirroring? | Both anatomy labels retained; flip does not swap feet. | Anatomical limb roles remain consistent. |
| Modular weapon coexistence? | Right grip tracks pose; no floating fixed-anchor pipe. | Right grip connected; air pose anchor required. |
| Flame reinforcement? | Delayed upward stretch can reinforce release. | Rise stretch follows bodily release, not prelaunch magic. |
| Generic risk? | Parkour tuck risk if chest leads every launch. | Stock tuck risk; right shoulder/left wedge must persist. |
| Goofy risk? | Running-in-air or pedal action can look comic. | Avoid tiny cycling legs or exaggerated frightened curl. |
| Movement-impairment misread risk? | Don't use a dragged leg as jump identity. | Both legs move and prepare landing; no unilateral limitation. |

### FALL

| Question | A | B |
|---|---|---|
| Is the law visible? | Forward catch can be misread as another intentional lunge or kick. | Enclosure is already legible; pelvis lacks support and feet prepare below it. |
| Anatomically believable? | Prepare support below pelvis, not seated feet ahead. | No simulated floor contact; paired ankles resolve through overlaps. |
| Fast response preserved? | Enter from ledge directly; actual gravity wins. | No mandatory apex or fall hold. |
| Fits/reads at 64×64? | Distinct silhouette needed beyond the six checked keys. | Distinct hanging/ready pose needed; native proof pending. |
| Survives mirroring? | No front/back limb ownership swap. | Mirror preserves right upper-body role and both legs. |
| Modular weapon coexistence? | Weapon stays on right; cannot remain at obsolete shoulder height. | Pose-specific air anchor, without weapon trajectory mechanics. |
| Flame reinforcement? | Upward drag distinguishes descent if body already reads fall. | Attached upward drag follows descent. |
| Generic risk? | Seated kick reference failure likely if reach pattern dominates. | Generic frightened fall if arms rise together; retain unequal role. |
| Goofy risk? | Flailing corrections can read slapstick. | Avoid both feet bicycling or comic airborne panic. |
| Movement-impairment misread risk? | No permanent leg drag; unsupported descent is contextual. | Temporary unsupported movement must not become a chronic limp. |

### LAND

| Question | A | B |
|---|---|---|
| Is the law visible? | Chest excursion followed by catch explains impact only if time remains. | Actual support loads pelvis; chest recontains above it. |
| Anatomically believable? | First real support accepts mass; avoid an invented extra step. | Knee/spine articulation absorbs pose compression; volume unchanged. |
| Fast response preserved? | Landing attack/jump may immediately supersede retrieval. | Direct attack or buffered jump can replace landing at once. |
| Fits/reads at 64×64? | Body compression must not merge knees/hands. | Compact land target retains elbow/leg gaps; no actual drawing yet. |
| Survives mirroring? | Whichever actual support is depicted remains traceable. | Both mirrored land keys retain anatomy. |
| Modular weapon coexistence? | Grip may shift; never leave weapon at a prelanding position. | Right grip follows land/attack destination. |
| Flame reinforcement? | Flame overshoot occurs only while the landing pose is displayed. | Brief attached overshoot; discarded if the state is replaced. |
| Generic risk? | Stock deep hero landing risk. | Stock crouch if pelvis drops too far; short load must restore. |
| Goofy risk? | Repeated forward stumble after every shallow landing would be comic. | No pogo or prolonged squat. |
| Movement-impairment misread risk? | Healthy bilateral rebound; no compulsory buckling after ordinary landing. | No deep collapse on every landing; only fatal collapse loses support. |

### DASH

| Question | A | B |
|---|---|---|
| Is the law visible? | 51 px body envelope and 18 px head lead make one large lunge. | 44 px body and 12 px head lead leave distinct compact transit. |
| Anatomically believable? | Both limbs connected, but low torso needs clear entry/exit support. | Pelvis initiates, right shoulder stays enclosed; ground/air support must differ. |
| Fast response preserved? | 150 ms clock unchanged; catch cannot extend exit. | Entry <20 ms, hold to 110 ms, exit until 150 ms; all skippable by real state. |
| Fits/reads at 64×64? | Fits numerically; narrower flame corridor and near-edge palm remain risks. | Fits with more gutter than A; flame/weapon still unproven. |
| Survives mirroring? | Large reflected lead is hard to reconcile with residual old velocity. | Same grip and shape relationships reflect; no root lag. |
| Modular weapon coexistence? | Grip (56,40); legacy anchor visibly wrong. | Grip (52,40); metadata required. |
| Flame reinforcement? | Long connected shear could easily become the forbidden rocket head. | Severe attached shear within gutter, rather than an independent emitter. |
| Generic risk? | Very high straight-lunge/athletic-wedge risk if exit is cut. | Stock crouched dash risk unless entry/transit/exit body deltas remain. |
| Goofy risk? | Oversized leaning head can look cartoonish. | No head inflation, rigid sled posture or bouncing crawl. |
| Movement-impairment misread risk? | Don't ground both feet rigidly while the root travels. | Air dash removes plants; no invented weak leg or drag. |

### ATTACK ANTICIPATION

| Question | A | B |
|---|---|---|
| Is the law visible? | Chest commitment is small; a preceding wide run may look like it recoils backward. | Enclosed rib over driving pelvis is readable as a compact load. |
| Anatomically believable? | Right striker connected; support must remain real. | Right shoulder neckward, palm below face; no identical fists. |
| Fast response preserved? | Only 50 ms; no extra catch/loading frame. | 50 ms maximum; dash strike skips antic drawing. |
| Fits/reads at 64×64? | 33×44 proxy fits; glove-like silhouette could look trained. | 31×44 proxy fits; protect the left elbow gap. |
| Survives mirroring? | Right striker mirrors, not alternates. | Same anatomy; no swing hand switch. |
| Modular weapon coexistence? | Grip (46,30); attachment must survive short startup. | Grip (45,32); pipe registration independent of gameplay. |
| Flame reinforcement? | Compact secondary compression, no eye cues. | Attached contraction without delaying body action. |
| Generic risk? | Boxer wind-up risk if wrist rises toward face. | Guard/boxer risk remains if both arms frame the face. |
| Goofy risk? | Big backward arm circle would be comic. | Avoid exaggerated shoulder squeeze or deep squat. |
| Movement-impairment misread risk? | No strained spinal bend or lopsided bad leg implied. | Small mobile brace reads tension; no rigid painful bend. |

### ATTACK CONTACT

| Question | A | B |
|---|---|---|
| Is the law visible? | 10 px rib lead and 17 px head lead make the overreach unmistakable. | Pelvis drive opens ribs to +6 px; shoulder identity survives contact. |
| Anatomically believable? | Support can justify it, but live mass and limb ownership need proof. | Supported forward contact; left arm remains a separate counterweight. |
| Fast response preserved? | Active 120 ms and existing confirm hitstop only. | Same 120 ms active, confirm/whiff picker and hitstop. |
| Fits/reads at 64×64? | 50×38 body fits; a tiny destination margin limits overlap freedom. | 41×42 body fits; gap and material volumes still need raster proof. |
| Survives mirroring? | Reflection preserves ownership, but reach can dominate identity. | Same right palm/grip remains striker across facings. |
| Modular weapon coexistence? | Grip (59,33); +11 px x beyond legacy anchor. | Grip (56,32), local (24,-30); separate prop tracks it. |
| Flame reinforcement? | Contact shear may eclipse small body if uncontrolled. | Attached tear follows contact; body and weapon carry damage read. |
| Generic risk? | High straight-punch/hero-lunge risk. | Straight-lunge risk controlled by compact shoulder and differentiated recovery. |
| Goofy risk? | Large head lead can make the face look like the weapon. | No balloon fist, long neck or giant flame arc. |
| Movement-impairment misread risk? | An overreach is one action, not an always unstable body. | Stable connected force chain; no compulsory knee collapse. |

### ATTACK RECOVERY

| Question | A | B |
|---|---|---|
| Is the law visible? | Support catch is the clearest identity beat; dash/Blink can delete it. | Rib lead retracts to +2 px before wrist/flame settle; enclosure is visible even if cut. |
| Anatomically believable? | Retrieval must not shorten bones or pop clothes. | Regained support and unchanged volumes; contact rebound differs from whiff. |
| Fast response preserved? | Only 80 ms, at most current whiff/return slots; don't add time. | 80 ms only; dash/Blink discards the rest. |
| Fits/reads at 64×64? | 36×43 proxy fits; terminal retrieve may be skipped. | 32×44 proxy fits and permits immediate destination selection. |
| Survives mirroring? | Reentry phase preserved; no neutral forced reset. | No hand swap; actual run phase survives return. |
| Modular weapon coexistence? | Grip (53,34) returns toward legacy rest. | Grip (49,33); destination pose has its own anchor. |
| Flame reinforcement? | Secondary snap only after surviving body return. | Snap follows torso return if displayed; never continues through freeze. |
| Generic risk? | If cut, prior lunge can remain completely generic. | Guard return risk if both elbows tighten symmetrically. |
| Goofy risk? | Overshoot→stumble on every swing can look comic. | No springy chest bounce or looping shrug. |
| Movement-impairment misread risk? | No involuntary leg weakness or repeated fall without cause. | No locked protection or impaired step; healthy support is regained. |

### HURT

| Question | A | B |
|---|---|---|
| Is the law visible? | Interrupted reach can support flinch but may resemble attack/catch. | Abrupt involuntary compression differs from voluntary enclosed startup. |
| Anatomically believable? | Impact data does not include a reliable presentation direction. | Keep feet responding to true airborne/grounded situation. |
| Fast response preserved? | Attack priority can hide _hurt_t; no forced hurt cancel. | Same suppressed/remaining hurt rules; no new control lock. |
| Fits/reads at 64×64? | Needs attack-compatible strain variant or residual hurt; no current art proof. | Candidate supports local strain without deleting striker; actual proof deferred. |
| Survives mirroring? | Same grip; impulse direction cannot be invented. | Right identity stays intact; no fabricated directional flinch. |
| Modular weapon coexistence? | Attach weapon to the selected strain/residual pose. | Selected attack-strain or hurt anchor keeps grip. |
| Flame reinforcement? | Local connected disruption; no detached particles. | Short deformation of attached head, no autonomous debris. |
| Generic risk? | Attack-guard reuse is a major reference risk. | Brace can look like guard; distinguish onset and disrupted support. |
| Goofy risk? | Fist-to-face reaction and random limb flail look comic. | No repeated shrug, tiny jitters or exaggerated knee collapse. |
| Movement-impairment misread risk? | Only momentary support disturbance caused by a hit, never permanent impairment. | Temporary hit consequence; return must show capable ordinary motion. |

### DEATH / COLLAPSE

| Question | A | B |
|---|---|---|
| Is the law visible? | Support catch fails permanently; continued reach must resolve into actual mass. | Support-driven law fails at its source: pelvis no longer retrieves protected torso. |
| Anatomically believable? | Account for both legs and floor contacts; no disappearance. | Support loss and mass settlement are traceable; no mandatory kneel. |
| Fast response preserved? | Controller continues; reload after 1.2 s unchanged. | No input/physics freeze; grounded/airborne consequence follows real root. |
| Fits/reads at 64×64? | Horizontal corpse must stay within 58 px body budget; not checked in six-key proxy. | Needs later horizontal compression proof in existing 64×64; do not shrink corpse. |
| Survives mirroring? | Corpse mirrors anatomical ownership rather than a new hand. | Same limb ledger survives rotation/collapse and mirror. |
| Modular weapon coexistence? | Held/broken state still belongs to prop; no invented drop. | Grip persists while prop remains held; visual occlusion recorded. |
| Flame reinforcement? | Flame loses structure after support failure; body persists. | Coherence decays while physical body remains. |
| Generic risk? | Stock forward kneel if all supports change at once. | Standard kneeling collapse still a risk; preserve unequal arm/support sequence. |
| Goofy risk? | Unmotivated rolling or dramatic stretch reads comic. | No disappearing body, bouncing corpse or heroic death tableau. |
| Movement-impairment misread risk? | Fatal loss of support is contextual; not a chronic locomotion cue. | Only fatal event loses support; ordinary states retain mobile competent legs. |

## Interrupt / cancel comparison

These are nine structural transition tests against the preserved code, not newly executed gameplay. Crucially, an attack is not canceled by nonfatal damage; startup/active cannot be dash-canceled; Blink ends a swing instead of preserving it for later continuation. Preserve buffer/cooldown eligibility rather than promising immediate action on every arrival.

| Transition | Existing contract | A | B |
|---|---|---|---|
| run → attack | Eligible buffered swing starts at actual _atk_t=0; +60 horizontal step. Run distance continues underneath grounded attack. | Run rib lead 8→antic 3 px, head lead 12→4 px. Without a bridge this cuts away the defining catch; an inserted bridge would consume startup. Destination must still be chosen directly. | Run rib lead 3→antic 0 px, head lead 6→2 px. Compact load can replace running without a rest reset or new timer; keep right grip and current support. |
| dash → attack | Allowed only with dash remaining ≤60 ms; move state becomes NORMAL, dash momentum retained. Startup time still exists but picker skips a0 to a1. | Dash head lead 18→contact 17 px leaves only a long lunge until a catch is shown. Candidate identity risks disappearing when later recovery is canceled. | Dash head lead 12→contact 9 px and enclosed right shoulder remain. Direct contact/commit key carries inherited momentum; no backward reload. |
| attack → dash | Dash blocked through startup/active (_atk_t≤170 ms); allowed during recovery if cooldown/buffer/air-dash gates permit. _end_swing occurs on cancel. | A visible catch is not guaranteed before dash; early eligible cancellation can erase the defining retrieval. Never wait for it or change the buffer. | Drop pending settle and select dash entry immediately. Enclosure and right ownership persist; no obligatory recovery/idle drawing. |
| landing → attack | No dedicated gameplay landing lock. Buffered attack checks current eligibility; floor state is sampled before move_and_slide, so presentation may change on the next physics/visual update. | Required catch may conflict with immediate loaded strike; do not force a planted corrective step or land hold. | Existing support load supplies preparation; attack can replace cosmetic landing at once. Do not claim a newly authored landing frame exists in today's picker. |
| Blink → attack | Freeze 280 ms preserves cooldown/buffers; gravity/movement continue and visuals are skipped. Arrival opens eligibility, not a guarantee that a cooling attack fires immediately. | Held reach may return directly to a new action without a catch. Body identity then depends mostly on a static lean. | Resume selected destination at the actual clock when eligible; compact shoulder/grip remain identifiable without completing arrival settle. If cooldown persists, do not show fake active contact. |
| attack → Blink | set_fight_frozen(true) ends current swing. Last selected drawing is held because visuals are skipped; root keeps moving under gravity. It is not an attack paused for continuation. | A reached key can remain frozen without support retrieval; no invisible catch may be imagined. Select real postfreeze state directly. | Hold exact drawing and its anchor through freeze, with no new secondary advance; clear the pending swing picture on normal visual reentry. No replay of old recovery or contact. |
| hit during anticipation | Accepted nonfatal damage sets _hurt_t=120 ms and knockback; it does not cancel the attack. Attack picker has priority, so standalone hurt can be entirely hidden by the remaining swing. | Use only a same-phase strain variant if later visual integration supports it; do not force a separate catch/flinch sequence or reverse contact direction. | A short added contraction/left-elbow disruption can preserve the right striker and existing attack phase. This is a future presentation variant, not a current selector feature or a gameplay cancel. |
| hit during recovery | Attack presentation keeps priority until attack ends; remaining hurt time can show afterward. Dash may also outrank hurt. No new hurt lock. | Do not try to complete retrieval before the real destination. A lost catch and residual off-balance pose can be confused with another attack. | Select appropriate same-phase strain/residual hurt without a new wait; return or cancel keeps the same support/grip relationships. Fatal hit follows separate died path. |
| direction reversal during locomotion | Facing changes immediately from input while velocity is still old-direction; reverse acceleration and _skid already exist, run distance does not reset. | A long lead flips before travel reverses; must author compact braking. This reduces the very feature that otherwise defines A. | Use compact loaded key with 0–2 px rib lead; old-travel flame lag may remain briefly attached. Keep current leg phase and anatomical hand, not a swapped half-cycle. |

### Additional preserved prop-clock exception

Targeted saved prop-source inspection confirms: FREE pickup is blocked during fight_frozen; a HELD prop continues its _process transformation/lift without that guard; starting a swing forces a pre-snap transformation to285 ms. Player BODY/FLAME and hand-anchor lookup hold during skipped visual updates, while prop milestones remain authoritative. Pickup/lift during Blink can therefore expose a grip mismatch; do not solve it by changing action, transform, pickup, use or respawn logic. This clarification does not rerun Phase B or alter its preserved evidence.

## Native-scale silhouette-family plan

All dimensions below are approximate BODY occupancy measured from the continuous centerline probes with simple width allowances. BODY includes the neck/collar and physical clothes/limbs; FLAME is excluded. They are **not measurements of an image**. In quiet rest BODY is about 45 px high and the intended attached flame/void restores the full actor to about 56 px tall, matching the existing full-sprite visible scale. No source reference was resized.

Arms below means horizontal separation between wrist centers, not the elbow-to-torso gap; legs means ankle-center separation. We separately require a 2–3 px left-elbow/rib negative-space wedge. Bone probe lengths: upper arm 10, forearm 8, thigh 10.5, shin 9 px; both halves use the same lengths, with ordinary projection/occlusion still required in art. The analytic solutions do not select a final elbow or knee contour.

| Candidate / key | BODY W×H | Torso axis | Head lead / pelvis | Wrist separation | Ankle separation | Negative-space target |
|---|---:|---:|---:|---:|---:|---|
| A / IDLE | 32×45 | 14° | 4 px | 24 px | 11 px | Unequal left elbow/rib wedge; modest leg slit; right grip open below head. |
| A / RUN | 42×39 | 33.7° | 12 px | 26 px | 29 px | Passing-leg notch and left rib wedge; do not trade them for a broad athlete split. |
| A / DASH | 51×34 | 45° | 18 px | 33 px | 33 px | Rear arm/body wedge and diagonal knee opening; neck/flame bridge remains visible. |
| A / ANTICIPATION | 33×44 | 14° | 4 px | 22 px | 12 px | Left elbow gap persists while right palm stays below face; no twin fist windows. |
| A / CONTACT | 50×38 | 37.6° | 17 px | 32 px | 32 px | Left elbow/rib wedge plus open right striking forearm; clear support/flight feet. |
| A / RECOVERY | 36×43 | 22.6° | 7 px | 25 px | 18 px | Elbow wedge reopens before wrist settle; legs remain distinct during retrieval. |
| B / IDLE | 31×45 | 9.5° | 3 px | 22 px | 11 px | Unequal left elbow/rib wedge; modest leg slit; right grip open below head. |
| B / RUN | 35×40 | 14° | 6 px | 26 px | 24 px | Passing-leg notch and left rib wedge; do not trade them for a broad athlete split. |
| B / DASH | 44×35 | 24.4° | 12 px | 29 px | 30 px | Rear arm/body wedge and diagonal knee opening; neck/flame bridge remains visible. |
| B / ANTICIPATION | 31×44 | 0° | 2 px | 20 px | 12 px | Left elbow gap persists while right palm stays below face; no twin fist windows. |
| B / CONTACT | 41×42 | 24.8° | 9 px | 28 px | 26 px | Left elbow/rib wedge plus open right striking forearm; clear support/flight feet. |
| B / RECOVERY | 32×44 | 9.5° | 2 px | 22 px | 14 px | Elbow wedge reopens before wrist settle; legs remain distinct during retrieval. |

The checks found twelve reachable probes, with fixed chain lengths, unchanged mirrored lengths and occupied allowances inside x=2..61/y=2..62. B reduces the proposed dash width from 51 to 44 px and contact width from 50 to 41 px, and reduces corresponding head lead from 18/17 to 12/9 px. These margins matter because flame and a separately anchored weapon still need readable separation. A can fit too; canvas fit alone is not its failure. B's run probe has a right support sole at row 62 and left recovery sole four pixels above it. A's run probe is airborne/extended; its contact proxy ends its sole allowances at row 61, so that target still requires a one-pixel footwear/endpoint correction before any claim of planting. These are approximate construction diagnostics, not timed foot-contact evidence.

B family: compact enclosure (idle/antic/recovery), a modest support-led opening (run/contact), and a low but attached compressed transit (dash). The left elbow wedge and neckward right shoulder remain related across those silhouettes. BODY-only identity and whether the 1–2 px shoulder difference survives clusters must be demonstrated in Pixelorama, not assumed from the coordinates.

## Anti-generic / anti-AI craft tests

| Failure prior | A: where / why | B: where / prevention |
|---|---|---|
| Generic hunched guy | Idle inclination and unresolved run-end lean can collapse to a stock slouch. | Permanent enclosure with no release would be a stock hunch; require load/open/recontain changes and mobile waist. |
| Generic sprint | Most run/dash targets are a broad chest-first diagonal; 42/51 px envelopes invite an athletic wedge. | Compact leg-driven jog becomes stock unless both contact/down accents and offset chest releases are distinguishable BODY-only. |
| Generic boxer wind-up | Guard-like right wrist can replace chest intent in short antic. | If both palms rise toward face, the brace becomes a trained guard; keep right grip below head and left elbow window open. |
| Generic straight lunge | Dash and contact head leads 18/17 px are very similar when the catch is cut. | A repeated transit key would still fail; distinguish pelvic load, chest opening and reclosure, with stable shoulder relation. |
| Generic sad urban protagonist | Rest leaning and repeated failed catches can communicate defeat rather than urgent intent. | A drooped head plus endless enclosure would imply sadness; keep active supports and abrupt directed releases; flame alone cannot supply agency. |
| Generic action-game body | Trained stride/strike plus static lean could overwhelm the law when recovery is skipped. | Support→restrained opening→recontain must survive more than pose shape; use whiff/confirmed difference and unequal upper-body spacing without leg impairment. |

These are authored craft diagnostics, not an AI-image detector or a diagnosis of disability. The chosen performance depicts a psychologically tense but physically capable civilian. Neither arm is frozen; both legs have equal construction and full support roles. Ordinary locomotion does not limp, buckle repeatedly, tremble randomly or require a balance-correction step. Recoil and collapse belong to actual received impact or fatal loss of support.

## Selection against ten criteria

| Criterion | Structural result deciding B | Remaining disproof condition |
|---|---|---|
| Body-language identity | Protected right shoulder and support/reclosure relation can remain in directly selected destination keys. | If the body only reads as a hunch, redesign the keys under this law. |
| Locomotion distinctiveness | Loading followed by brief chest release contrasts with the reference athletic wedge; arms participate unequally, both legs alternate. | If contacts/passing are interchangeable or legs imply a limp, fail F/G review. |
| Gameplay readability | Reduced head lead leaves body/weapon direction more independent of flame. | Wrong contact/whiff, fall-as-kick or face-as-weapon fails runtime QA. |
| Fast-action compatibility | Antic/contact/return can select directly; no completed catch or brace wait is required. | Any extra delay, long bridge or mandatory loop exit is prohibited. |
| Animation feasibility | Narrower dash/contact occupancy and less torso excursion reduce occlusion/anchor workload. | Numeric feasibility does not establish pixel quality; both real correction passes remain required. |
| Anatomy believability | Equal paired segment budgets and traceable support; no body shrinking to fit. | Real joints, cloth volume, contact and airborne/corpse construction still need proof. |
| Mirror compatibility | Immediate facing reflection preserves right ownership and permits compact old-velocity braking. | Hand swap or swapped leg half-cycle fails. |
| Weapon modularity | Rest matches existing (16,-30); action anchors stay within canvas and can be documented separately. | Fixed legacy anchor is insufficient in motion; visual-only integration is still required. |
| Flame self-image | Assertive attached flame can exaggerate a physical body that encloses then briefly commits. | If head spectacle conceals body identity, fail BODY-only proof. |
| Anti-generic strength | Rhythm of load/open/recontain plus upper-body role asymmetry exceeds a single posture quirk. | Constant hunch, fighter guard, comic brace or copyable stock gait fails. |

## Decision and limits

Lock **B — BRACE, THEN DRIVE**, with numeric limits and phase relationships in [final_movement_law.md](final_movement_law.md). No hybrid: upper-chest-first initiation and A's obligatory retrieval are not imported. Ordinary follow-through, forward contact and later support restoration are general mechanics already present in B, not a graft of A.

A loses primarily at interrupted recovery/arrival and broad dash/contact: a static lunge can remain when its defining catch is absent, or extra retrieval would compete with existing clocks. Its larger head lead and shoulder/pelvis separation also leave less native-frame freedom for modular grip and flame. B still has a substantial permanent-hunch/guard risk; it wins only with visible opening/reclosure and competent bilateral legs, not with a static protected pose.

Remaining evidence: actual native-size silhouette family, 1× identity, limb occlusion, grip offsets across all frames, frozen/interrupt variants, foot slide under 18 px held samples, airborne death, exact contact-to-target visual gap and interpretation of civilian tension. These are explicitly not solved by this structural matrix. Construction coordinates are starting checks, never permission to generate procedural production raster.

PHASE E COMPLETE. NEXT: PHASE F — MASTER KEY POSES IN PIXELORAMA. STOP.
