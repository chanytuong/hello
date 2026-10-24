# Phase E — final movement/body-language law

Status: **LOCKED FOR PRODUCTION — B, BRACE, THEN DRIVE**. No hybrid. No final pixels or animation created in Phase E.

## One-sentence definition

The support leg drives the pelvis while the ribcage stays enclosed beneath the neckward right shoulder, opens briefly for the action, and returns over support before the arms and attached flame settle.

## Selection and evidence

The [decision matrix](phase_e_decision_matrix.md) compares both retained candidates against nineteen construction fields, twelve gameplay states, ten questions per state, nine interruption cases, six generic priors and twelve numeric construction probes. Equal Phase D text totals did not select this law. B's compact enclosure survives directly selected destination poses with fewer obligatory intermediate beats; its proposed dash/contact occupy 44/41 px BODY widths and use 12/9 px head lead, versus A's 51/50 px and 18/17 px. Both can fit the canvas, but A depends more on a visible catch to distinguish a reach from a stock lunge.

The lock is an art-direction commitment, not visual approval. Native-scale silhouette, emotional interpretation, contact and real animation remain unproven until actual Pixelorama masters and runtime QA. If masters fail, repair the construction under this law and record the change; do not silently substitute A, a hybrid or a trained fighter.

## Coordinate and anatomy convention

Canonical art faces right. Anatomical RIGHT is the near/grip/striking arm in that view; LEFT is the free balancing arm. Horizontal reflection preserves anatomy, not a reassignment of near-side hands. Both legs have equal construction, strength portrayal and complete alternating support roles. The rest pose may favor the right support, but neither leg becomes permanently weak, trailing or locked.

Texture coordinates use x right/y down and the existing continuous engine anchor (32,62). Local point = (u−32,v−62); world point = player origin + (facing×local.x,local.y). Head lead means void center minus pelvis center in canonical x, not a flame-tip distance. Torso angle means the pelvis-to-rib-center line's angle forward from vertical; it is not whole-sprite rotation.

Right-facing rest target: pelvis (31,42), rib center (33,30), collar/neck root (34,20), void center about (34,14), left shoulder (28,24), right shoulder (38,22), left wrist (26,40), right grip (48,32), ankles (25,60)/(36,60), sole row 62. These are construction targets, not a procedurally filled character. Ribcage, pelvis and limb volumes must be drawn natively by hand through MCP.

## A. RESTING BODY LAW

Keep the pelvis slightly behind the rib center (+2 px rib lead), with a mobile shallow spine rather than a deep hunched back. Right shoulder sits about 2 px nearer the collar than left; right palm/grip stays below the head/face. The left elbow leaves a 2–3 px wide, roughly 5–8 px tall wedge against the rib side. Quiet support and restrained local breathing make tension legible without a body-wide bounce.

Rest does not announce sadness, a combat block or bodily incapacity. The head stays on the neck; no constant droop, tremor, looping flinch or abortive step. Release of a shoulder or wrist is unequal and purposeful, not random wobble. Armed and unarmed palms preserve right ownership and the same core shoulder/rib relation; any grip-shape adjustment must be explicit metadata, not a new law.

## B. LOCOMOTION LAW

The actual root accelerates immediately. In drawings, a loading support moves the pelvis into its next travel position while the torso remains briefly contained, then the rib center opens to +2–5 px lead before recontainment at the next loaded beat. Both legs alternate through identifiable contact/down/passing/high/recovery relationships. Keep support beat spacing coherent; do not mirror half a cycle or add a compulsory limp/catch step.

The right arm has the tighter, purposeful grip/commit path; the left moves more freely as a counterweight but is never frozen. Restrained arm participation must have a visible shoulder/rib response; pelvis and shoulders are not one rigid diagonal wedge. Clothing stays quiet and retains volume. Brisk movement is authored through different loading/opening exposures, not through random jitter or oversize stride.

Use the real 18 px distance-sampled baseline and six-drawing cycle as compatibility evidence; do not declare a new global FPS or change movement. Run distance continues beneath grounded attacks and does not reset at stop. A later visual-only sampling refinement requires measured need. Held drawings slide between samples: perfect world-space foot pinning is not claimed.

On reversal, facing follows input immediately while velocity may still be old-direction. Use a compact support/braking relation (rib lead 0–2 px), preserve current leg phase and read the real velocity for travel lag. No turn-through-front animation, mandatory skid or extra root displacement. Ordinary braking returns to competent support without a comedy stumble.

## C. AIRBORNE LAW

Jump release is immediate at the existing −640 px/s input result; there is no added grounded brace. The pelvis leaves support while the neckward right shoulder and left wedge preserve the person. Fold limbs through real hip/knee relationships, with both feet accounted for; do not copy a heroic parkour tuck or run a cycling-leg loop in the air.

A ledge fall enters directly into unsupported pelvis and feet preparing below it. A passive descending pose must differ from rising release and from a seated kick; preserve ankle/leg separation or explain occlusion with adjacent keys. Follow the current rise gravity, fall multiplier, short-hop cut, coyote time and jump buffer. No minimum airborne exposure or apex hold.

On actual landing, support loads the pelvis and the ribs recontain above it, with modest knee/spine articulation. A shallow landing is not a deep collapse. Hard landing uses the existing >700 speed signal. Cosmetic land compression can be replaced immediately by eligible attack/dash/buffered jump; never require a corrective footstep or finished recovery.

## D. DASH LAW

Pelvis drive produces a low compact transit; rib lead is about +5 px, torso axis about 24°, void center up to +12 px ahead of pelvis. The right shoulder remains enclosed, left arm/body wedge and folded-leg ownership remain visible. Body should change between entry, transit and exit rather than remain a rigid crouched cutout beneath an expanding head.

Preserve 150 ms at 650 px/s: entry <20 ms, transit until 110 ms, exit to150 ms. These are existing picker boundaries, not a mandate that every rendered entry appears. Ground and air dash use appropriate support cues. The final60 ms allows actual dash-strike: dash supplies the wind-up and the attack contact/commit drawing replaces dash without a backward coil. Do not insist on dash exit afterward.

## E. ATTACK LAW

Preparation is an enclosed rib center almost directly over pelvis (−1..+1 px lead), right grip below face, left elbow wedge visible. The feet/support and pelvis drive the action; the chest opens briefly to +5–7 px lead, with a connected right-hand/forearm/weapon contact and left balancing response. This is civilian bodily commitment, not a boxing guard, uppercut, expert hip snap or triumphant hero stance.

Preserve startup 50 ms, active 120 ms, recovery 80 ms. Dash-strike preserves its real startup clock while its picker skips the ordinary anticipation drawing. Damage opens on the existing simulation boundary; art does not activate it. Reach82/104, forward step60, confirmation bite and existing hitstop remain unchanged. Do not stretch the torso or flame to span the hitbox reach: collision extent is not a physical fist-length specification. The actual target contact gap must be judged later in runtime.

Active whiff and confirmed contact differ in body consequence, not stronger magical flame power. One right striker/grip persists. Armed/finisher reactions may reflect the existing confirm and bite but cannot add an attack, direction, reach or lock. A correctly rooted short smear may bridge a rapid transition; it is neither the damage emitter nor the only readable contact key.

## F. RECOVERY LAW

The pelvis/support recontains the rib lead toward +1–3 px before the wrists and flame finish. Reclosure retains the neckward right shoulder and open left-elbow role; never return to symmetrical fists. Whiff can expose a modest empty excursion before retrieval; confirmed contact rebounds sooner under the existing picker/hitstop.

The existing 80 ms may show only a whiff-return pair or a direct confirmed return. Additional350 ms cooldown is not a required animation hold. Run reentry can land at an advanced distance phase. A real cancel drops the remaining settle; it does not replay the old return or force idle.

Hurt is an involuntary disturbance rather than voluntary preparation. Accepted nonfatal hits supply a120 ms timer but do not cancel attack. Attack/dash priority can hide standalone hurt; any later same-phase strain variant must preserve contact time, right striker and true support rather than manufacture a gameplay flinch cancel. Fatal damage takes the separate died path.

Death is the failure of support/pelvis retrieval: physical mass lowers and settles, with both limbs and floor contacts accounted for. The same right shoulder/arm construction rotates with the torso rather than maintaining a screen-up shrug. Body persists; flame loses coherence separately. Follow continuing root motion/gravity and1.2 s reload; no added input or physics freeze. An airborne fatal body cannot already claim floor contact.

Drawable overlap target: when a return is actually displayed, put the rib center back within its +1–3 px recovery relation while the left wrist is still 1–2 px short of its final settle position and the flame tips still trail the prior opening. Resolve them in at most the next available authored exposure. During run, place the pelvis at its loading/contact relation before the key that opens the ribs. This is redrawn pose spacing, not a separately simulated limb or an added millisecond delay; if the enclosing state is replaced or too short, omit the delayed settle.

## G. INTERRUPT LAW

The real destination state chooses the drawing and anchor immediately at its existing boundary. Do not manufacture missing anticipation, opening, retrieval or settling beats. Identity is carried by the compact shoulder/rib role, connected anatomy and support relationship visible in the selected pose, not by demanding a long complete sequence.

- Run→attack uses the eligible attack key without a neutral reset.
- Dash→attack obeys remaining≤60 ms; ordinary antic picture is bypassed while startup still exists.
- Attack→dash is blocked during startup/active and cancels recovery only when actual gates permit.
- Landing→attack may replace cosmetic land loading immediately.
- Attack→Blink ends the swing and holds the exact last drawing/anchor as visual updates stop; it is not a paused attack to resume.
- Blink→attack fires only when cooldown/buffer gates permit on reentry; no false contact picture while waiting.
- Hits during anticipation/recovery follow existing attack/dash priority and remaining hurt time; do not add a flinch lock.
- Reversal changes facing immediately but keeps anatomical grip and the actual leg phase.

Hold player BODY/FLAME and the selected hand-anchor lookup through Blink; no independently ticking player flame or imaginary recovery. The root can still move under existing gravity, and existing hitstop remains authoritative. The held prop has its own _process path without a fight_frozen guard: preserve its transformation/lift clock rather than imposing a new weapon freeze. FREE pickup is blocked while the player is frozen. Starting a swing forces a pre-snap prop transformation to the existing 285 ms snap milestone; do not replay earlier fracture beats. Any resulting held-pose/prop-lift discrepancy is a later visual integration risk to measure, not permission to change either mechanic.

## H. FLAME SECONDARY-MOTION RELATIONSHIP

The physical person encloses, briefly commits and recontains; the attached head exaggerates that commitment as distorted self-image. FLAME begins at the registered neck root, encloses a faceless dark void, and trails changes of the primary mass. It cannot make a weak BODY pose distinctive.

Idle stays contained with unequal tips; run trails backward; jump stretches after release; fall tips drag upward; dash shears severely but stays attached; antic compresses; contact tears/shears along action; recovery snaps after bodily return; hurt deforms locally; death loses coherence after bodily support fails. Use a later pose/exposure relationship only while the real state survives; there is no mandatory extra delay, independent flame clock or detached return animation.

No eyes/skull points, hero hair, meteors, spell/aura arcs, diffuse glow, reflected light, autonomous particles or additional damage. Each smear has named source/path/destination and preserves the neck or grip root. BODY-only proof is required for every master.

## Five invariants

### INVARIANT 1 — Registered physical construction

Every BODY/FLAME frame keeps the 64×64 native canvas, pivot (32,62), connected anatomy and the same material volumes; projection/occlusion and articulated bending replace scaling or changing limb length. A separate weapon module keeps its own registered hilt pivot.

### INVARIANT 2 — Persistent upper-body ownership

The anatomical right shoulder is the collar-side shoulder (about 2 px higher than the left in upright enclosed keys), and the left elbow owns the open rib-side wedge; contact may release enclosure but never swaps these anatomical roles. Carry this relationship in torso-local construction through oblique poses and collapse, not as a fixed screen-up offset.

### INVARIANT 3 — One grip/striker

The anatomical right hand is the grip and primary contact hand in every frame and facing; its connected shoulder/elbow/wrist chain and pose anchor persist even when occluded or the weapon is broken. The left hand never silently becomes the grip.

### INVARIANT 4 — Support-led causal rhythm

Voluntary exertion starts from support/pelvis drive and a protected torso, with brief opening and support retrieval where time survives; interruption selects the real destination without an obligatory completion. Airborne release and fatal support failure are consequences of that chain, not invented grounded steps.

### INVARIANT 5 — Body before attached self-image

BODY alone must retain the person and action; FLAME is faceless secondary anatomy rooted at the same neck, obeys the selected/frozen presentation and never supplies damage, an independent projectile, glow or a substitute for physical body mass.

These invariants constrain construction and causality, not a constant silhouette. Opening, airborne support loss, impact and death can change pose substantially. A terminal corpse is not required to reclose or regain support; it must remain the same connected physical body. A cut is not required to show every beat; it must not replace the person or move simulation events.

## Locked handoff and remaining risks

[Phase F constraints](phase_f_constraints.md) lock dimensions, tolerances, palette budget/roles, layers, negative-space requirements and grip metadata. The right shoulder/left-elbow distinction is only a small part of identity; if the rhythm is absent, the body can still become a generic hunch. Numeric probes cannot prove 1× character or prevent comic/impairment misreads. Foot slide, live mirroring, occluded grips, same-phase hurt, terminal contact and frozen weapon handling all remain later proof obligations.

No gameplay, legacy asset or production raster changed. PHASE E COMPLETE. NEXT: PHASE F — MASTER KEY POSES IN PIXELORAMA. STOP.
