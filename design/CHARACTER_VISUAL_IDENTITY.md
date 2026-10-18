# CHARACTER VISUAL IDENTITY — NEVERLOOKBACK

**Status: DIRECTION LOCK (pre-production). Not final art. No assets are produced by this
document.** Written from the running prototype: `DESIGN_BRIEF.md`,
`design/PERCEPTION_WEAPON_EXPERIMENT.md`, `design/PROTOTYPE_EXIT_REVIEW.md`, and the live
values in `scripts/player.gd`, `scripts/prop.gd`, `scenes/*.tscn`.

---

## 0. The identity in one line

**An ordinary, slightly wrong person in a dark coat who believes they are a hero —
and the belief is white-hot, while the person is grey.**

Everything below derives from that sentence: reality is dark and desaturated, the
delusion is bone-white, the enemies are saturated, and the body language is authored
wrongness rather than random noise.

---

## 1. Silhouette direction

### 1.1 Proportions (side-view, facing right; left = mirror)

- **Target on-screen height: ~56 px** (graybox body today is 44 px; art may exceed the
  28×44 collision rect — collision stays as-is).
- **~5.5 heads tall** — deliberately *not* the heroic 7-head proportion. Slightly leggy,
  short torso, ordinary build. The hero proportion is the delusion, not the reality.
- **Legs are the star.** This is a run/jump/dash game; the leg line carries the run
  stride, the skid, the dash diagonal, and the landing. Long, clear legs with visible
  knee break in stride frames.
- **Narrow-to-medium shoulders.** No superhero trapezoid. Aggression is expressed by the
  coat and the weapon line, not by bulk.
- **Head ~10–12 px.** Small enough to keep the body dominant, large enough for one eye.

### 1.2 Stance (neutral)

- Weight on the **back foot**, slight rearward slump, shoulders not square — an
  asymmetric standing silhouette. Stillness that reads as *held in*, not relaxed.
- The head sits 1–2 px forward of the spine line (a small forward drift, always facing
  the direction of travel). "Never look back" is baked into the neutral pose.
- Feet slightly apart, front foot lighter. Grounded at all times — no floating, no
  wide heroic stance.

### 1.3 Head / hair

- **Long unkempt hair swept across the face, permanently covering ONE side** (the near
  side when facing right — it covers the eye the world sees least). This is the single
  most important silhouette marker: at a glance you know this character by the hair
  cutting the face in half.
- Hair is a **secondary-action element**: it lags one frame behind the head in run,
  whips forward on skid, snaps back on dash, settles after landing. Drawn into the
  frames — never simulated, never random.
- **No hood, no mask, no helmet.** Hoods read as generic edgy; a visible (half-hidden)
  face is required for the "ordinary person" read.

### 1.4 Jacket / shoulders / torso

- A plain, slightly-too-large **work jacket** with a popped collar. In neutral the
  collar is half-collapsed (uneven, one side up = asymmetry again); in anticipation
  frames the collar **flares open like a mantle** — the hero fantasy leaking into
  clothing.
- Jacket **tails/flaps** reach mid-thigh and are longer on one side (uneven hem — the
  silhouette is never symmetrical). Tails lag the body: they are the whip that makes
  aggression read bigger than the frame that caused it.
- One **diagonal seam/zip line** runs across the torso from shoulder to opposite hip —
  a literal crack motif at zero FX cost (see §2).

### 1.5 Legs / footwear

- Plain straight trousers, plain flat shoes/boots — deliberately boring from the knee
  down. The lower body is the "reality" half: it never does anything impossible.
- Dash and skid read through **foot placement** (trailing heel lifted, front foot
  planted forward), not through dust FX.

### 1.6 Weapon-holding posture

- Bare-handed neutral: arms hang, weight back.
- Armed rest: the weapon **trails low and behind** — matches the locked `HOLD_ROT
  −0.66` (~−38°) at `HOLD_OFFSET (16, −30)`. Blade behind the body = the swing is
  always pre-loaded; the silhouette already contains the coming arc.
- Armed neutral is *wider* than bare neutral by exactly the weapon line — picking up
  the weapon must change the silhouette (that is half the pickup payoff).

### 1.7 How the silhouette changes during aggression

Two anchors define the whole range:

| anchor | silhouette | state |
|---|---|---|
| **narrow vertical** | slump, coat hanging, hair down, arms low | idle / walk |
| **wide diagonal** | body + coat + hair + weapon all on one forward diagonal line | dash, anticipation, contact |

Aggression = the entire silhouette rotates onto **one diagonal line of action** and
**widens horizontally** (the existing pose language: dash `scale (1.34, 0.80)`,
whiff `(1.48, 0.78)`→`(1.56, 0.74)`, contact `(1.16, 1.16)` with lean 0.26/0.32).
In authored frames these become *drawn poses*, not continuous scale (see §5.6).

**Silhouette test (mandatory for every key pose):** fill the pose solid black, place it
against both the cyan-tinted (State A) and amber-tinted (State B) background washes —
it must read as "the coat person, doing that action" with zero internal detail.

---

## 2. Costume / shape language

### 2.1 What the player sees in ordinary neutral state

An under-dressed-for-conflict ordinary person: too-big work jacket, plain trousers,
messy long hair, no gear, no straps, no pouches, no shoulder armour. If it looks
tactical, equipped, or "geared up," it is wrong — the character owns nothing but the
pipe they find on the floor.

### 2.2 Subtle elements that imply fractured perception

- **The diagonal seam** across the torso: in reality it is a dull stitching line; in
  hero-perception states (armed, transform settled) it brightens to bone-white. The
  *clothes* remember the delusion, not the body.
- **Uneven hem + uneven collar + covered eye**: three asymmetries that make the
  outline subtly "off" while standing perfectly still. Instability without motion.
- **Half a face.** The covered eye side is the recurring motif; reality never shows
  both eyes clearly.

### 2.3 Where the hero delusion leaks into reality

- **The white slit:** in hero-perception states only, a **1-px bone-white slit** shows
  on the hair-covered side — "the hero's eye." It appears with the weapon (armed) and
  during the transform's post-snap phase; it disappears when bare-handed. Zero FX, one
  pixel, and it makes the two identities visible on one body (gate: both identities
  visible together — already required by `test_weapon`).
- **The collar flare** in anticipation frames (§1.4).
- **The weapon itself** is the largest leak: reality grey pipe → bone-white blade.

### 2.4 Avoid over-detail

Allowed detail budget on the whole sprite: **hair mass, one eye, seam line, collar,
hem split, hands.** That is it. No belts, no buckles, no badges, no glowing runes, no
face scars, no cybernetics, no torn-shirt patterns. Every element must serve
silhouette, asymmetry, or the white/dark palette split — otherwise it is cut.

---

## 3. Palette direction

### 3.1 The semantic rule (this is the whole palette)

| channel | meaning | palette |
|---|---|---|
| **dark / desaturated** | reality, the real self, the ordinary world | ash, slate, ink |
| **bone white** | the delusion: hero weapon, hero eye, seam leak, **delusion echoes** | near-white only |
| **saturated mid-value hue** | external threat: enemies | red (melee), purple (ranged) — already in the build |
| **cyan / amber wash** | the two world states (A/B tints) — background only | never used on the player |

One hue = one meaning. The player never wears a saturated hue (that channel belongs to
enemies), never wears bone-white as a body colour (that belongs to the delusion), and
never wears cyan/amber (that belongs to the world states).

### 3.2 Base palette (approximate; final swatches chosen with the first sprite)

- **Ink / outline / deep shadow:** near-black indigo (~`#15151E`)
- **Jacket / upper body:** dark slate (~`#3A424E`), shadow step ~`#262C35`
- **Trousers:** one step darker than jacket (~`#2A303A`)
- **Skin (visible half):** pale, slightly ashen (warm-neutral, not healthy-rosy)
- **Hair:** ink family, one lighter step for the top mass

### 3.3 Accent palette

- **Bone white (~`#F4F6FA`)** — the ONLY accent on the player channel: blade, seam in
  hero state, hero eye slit, and the delusion echoes (which are white-channel by rule).
- No second accent. No warm accent (amber belongs to State B), no red accent (belongs
  to the melee enemy), no cyan accent (belongs to State A and the graybox player).

### 3.4 Contrast priorities

1. **Value first.** The player is a dark mass against the mid-value arena in both state
   tints; the weapon/echo is the brightest object on screen. Read order: player body →
   weapon line → enemy → background.
2. **Hue second** (enemies' saturation vs player's neutrality).
3. **Never solve a readability problem by adding a colour** — solve it with value,
   position, or pose (the project's standing refuse list: no glow, no flash as signal).

### 3.5 Separating the three layers without noise

- **Reality objects** (pipe, arena props): grey `Color(0.60,0.62,0.66)` — as built.
- **Hero perception:** the *same* shapes with value pushed apart (darker darks, the
  bone-white weapon/seam/eye) — **no hue shift**. A hue shift reads as "powered up";
  a contrast push reads as "seeing it differently."
- **Delusion echoes:** bone-white channel at partial alpha, offset — **never a new
  colour, never a new shape family**. They are made of the same pixels as the hero
  state, which is exactly why they read as perception and not as magic.

---

## 4. Face / head readability

- At a 10–12 px head, the honest budget is: **hair mass + one visible eye + optional
  1-px mouth line.** Nothing else survives pixel scale.
- **Emotion reads through three channels, in priority order:**
  1. **Head angle / body pose** (head drops into dash, tips back on hurt, drives
     forward on commit) — 90 % of the read.
  2. **The one visible eye, 3 authored states only:** calm (narrow slit), committed
     (wide, brow driven down), hurt/gritted (squint + jaw line). ~2 px each.
  3. **Hair position** as follow-through.
- **No facial animation system.** Eye state is a function of gameplay state
  (neutral / committed / hurt), never random, never interpolated per-frame.
- Instability is **not** shown on the face (no crazy grin, no spiral eye, no blood
  shot) — it is shown by asymmetry, half-covered face, and body language. The face
  stays boringly human; the *perception layer* carries the madness. This is the line
  between "psychological" and "horror monster."

---

## 5. Pixel-art style decision (PHASE 4)

### 5.1 Lean: **clean readable action** (not painterly mood)

The game is decided in 60-frame windows (hitstop 0.045 s, dash 0.15 s, transform
0.465 s). Painterly ambiguity loses those reads. Hybrid elements (mood in background
wash, dither in scenery) are allowed; **characters are always cel-clean.**

### 5.2 Target sizes

- **Body sprite cell: 64×64** (character ~56 px tall, fits stride/hair/coat overflow).
- **Weapon is a separate sprite layer** (already the architecture: `prop.gd` owns
  Reality/Hero). Weapon cells: **96×64**, blade drawn as authored *orientations* (see
  5.6) — horizontal, −38°, −70°, +20°, etc.
- **Enemy cells: 48×64** (melee ~40 px, ranged ~38 px tall as built).
- On-screen scale: **1:1 at 1280×720** (viewport as configured today). No camera zoom.

### 5.3 Detail level & palette discipline

- **Modern-pixel, lean:** 3-tone shading per material (base / shadow / highlight),
  hard cel edges, light source top-right (consistent with the local pixel-art skill).
- **Locked master palette: ≤ 24 colours total**, ≤ 12 per sprite. Characters carry no
  dithering; dither is reserved for background/atmosphere only.
- **No anti-aliasing, no sub-pixel opacity on the sprite pixels** (alpha exists only
  for the echo/veil layer, which is a rendered copy, not drawn pixels).

### 5.4 Outline

- **1 px ink outline on characters and weapons only** (selective outline). Background,
  tiles and props stay outline-free so the actors always detach from the world.
- Rationale: at 56 px over two different state tints, an inked actor guarantees the
  silhouette test passes in both; outline-free pixel art (Katana ZERO, Dead Cells) works
  but needs much stronger background value control than this build currently has.

### 5.5 Shading style

- Cel, 3 steps, top-right light. **No gradients, no rim lighting, no glow passes.**
- The bone-white weapon is *flat white with one grey step* — brightness, not emission.

### 5.6 Animation frame budget and the parametric-pose problem (critical)

The prototype expresses poses **parametrically** (`body_vis.scale`/`rotation` lerped
every frame: `(0.80,1.28)`, `1.56`, lean 0.42 …). **Continuous non-uniform scale and
rotation destroy a pixel-art grid** (wobble, non-integer pixel sizes, blur under
`canvas_items` stretch).

**Format decision: authored keyframes replace the parametric pose layer in production.**

- The animation *language* — every phase, every blend rate, every measured value —
  survives **as timing and as drawn key poses**: anticipation `(0.80,1.28)/−0.42` becomes
  *draw that squashed coiled frame and hold it for the 0.05 s startup*; contact
  `(1.16,1.16)/+0.26..0.32` becomes *draw that planted frame and hold it for the active
  window*; the five rates (δ·40 coil → δ·44 commit → δ·52 plant → δ·30 release →
  δ·52 arrival) become **frame-change cadence** (how many logic frames each authored
  frame is held), not lerp factors.
- Runtime rotation of pixel sprites is **banned**; swings use authored weapon
  orientations (5.2).
- Sub-pixel crawling: **snap sprite draw positions to whole pixels** (round the visual
  node position each frame). Gameplay positions stay continuous.
- Sprite playback cadence: authored frames held **2–4 logic frames (~15–30 sprite
  fps)** inside the 60 fps simulation; the *held* beats (contact, arrival, transform
  peak) hold longer, matching the measured holds (contact 6 frames, enemy recoil 5,
  arrival 7, transform peak 3).

### 5.7 Frame budget per animation (approximate)

| animation | frames | notes |
|---|---|---|
| idle | 4 | breathing 1 px, asymmetric slump constant |
| run | 6 | stride + hair/coat lag |
| skid / reversal | 3 | heel dig, coat flips forward |
| jump / fall / land | 4 | 1 anticipation, 1 rise, 1 fall, 1 squash-land |
| dash | 3 | entry extreme, hold, exit |
| attack (standing) | 6 | coil, commit, contact, overshoot, recover, neutral |
| dash→attack | 5 | one continuous arc, no backward coil |
| pickup / reach | 3 | reach, hold, release |
| perception transform | 6 | matches the 6 locked beats of `prop.gd` |
| blink arrival | 3 | land, hold, release |
| hurt | 3 | impact, held recoil, ease |

---

## 6. Animation-language principles (PHASE 5)

### 6.1 Global principles

1. **Overcommitment on the way out, restraint on the way back.** Every action travels
   past where physics would stop (whiff extends to `(1.48,0.78)` — *further* than a hit
   `(1.16,1.16)`); recovery is fast, clean, and lands exactly where the active pose
   ended (no seam, no pop — the v6 seam defect is the cautionary tale).
2. **Instability comes from timing contrast and asymmetry, never from randomness.**
   The five authored rates on one timeline (slow coil → violent commit → instant plant
   → held contact → fast release) *are* the insanity. Random twitches are banned.
3. **One line of action per pose.** Torso, hair, coat and weapon share a single
   diagonal in committed poses; they deliberately *disagree* only during anticipation
   (coil away while weapon raises) — disagreement is a specific beat, not a style.
4. **Hierarchy:** torso/leg line (primary) → arm/weapon line (secondary) → hair/coat
   (tertiary, 1-frame lag). Never let tertiary motion be the loudest thing on screen.
5. **Strong contact moments are HOLDS, not impacts-with-FX.** Contact pose holds ~6
   frames, extended by hitstop; the enemy recoil holds its extreme for 20 % of its
   time. The eye needs stillness to read a hit.
6. **Heroic-in-mind vs physically real:** elongation, extension, blade-high,
   wider-than-possible reach = the protagonist's self-image. Feet planted, no vertical
   launch, horizontal-only knockback, weight settling *down* on land/arrival = physics.
   **The upper body exaggerates; the lower body never lies.**

### 6.2 Per-state specification

| state | exaggerates | stays restrained | heroic-in-mind | physically real |
|---|---|---|---|---|
| **idle** | asymmetry: slump, uneven hem, hair over half the face | no jitter, no random twitch (4-frame loop only) | — | weight on back foot, breathing 1 px |
| **run** | stride length, coat/hair whip, forward head drive | torso level (±1 px bob), head steady | the silhouette is *always chasing* something | foot plant order, contact→passing→contact |
| **reversal / skid** | heel digs out, coat flips AHEAD of the body, hair falls forward | no dust FX (pose-only read) | — | friction pose, feet stay on floor line |
| **jump / fall** | anticipation crouch (1–2 frames), limbs trailing UP on fall | apex is brief, no float | the leap looks chosen, not physics-driven | asymmetric gravity already in code; landing squash 2 px |
| **dash** | **the signature:** whole body onto one horizontal-diagonal, head down, arms trailing, coat fully extended | 0.15 s, 3 frames, no FX trail | he believes he is a projectile | starts from the feet, ends with a plant |
| **attack (standing)** | coil `(0.80,1.28)/−0.42` → overshoot past contact `(1.48,0.78)/+0.34` | release δ·30, back to neutral by +0.20 s | extension beyond reach, blade-high | feet planted on contact; whiff slides, hit anchors |
| **dash→attack** | one gesture: dash posture loads *forward* to `(1.38,0.76)`, contact leans **0.32** | no backward coil (the v6 reversal defect), monotonic through hand-off | the strike carries the whole run | momentum preserved (probe P7 delta=0) |
| **pickup** | reach is hesitant-braced `(0.90,1.16)/−0.20`, recoil startles `(1.16,1.24)/+0.24` | transform never locks input; no flourish | — | the body reaches; it does not levitate anything |
| **perception transform** | 6 beats, band tear to `(1.80,0.48)/+0.40`, 3-frame held peak, 1-frame snap | 0.468 s total, no camera, no flash, no lock | the hero blade *should* appear | reality object obeys physics before the snap |
| **hurt / recoil** | head whips, coat lags, torso compresses `(1.28,0.66)` on enemies | feet planted, horizontal only, held extreme then ease | — | no vertical launch, no ragdoll, no spin |
| **blink arrival** | weight settles DOWN `(1.08,0.98)/+0.20`, 2-frame land, 7-frame hold | arrival pose is a stance, not a grow | he arrives *ready* | 0.16 s, first action after is instant |

---

## 7. Storyboard A — CHARACTER IDENTITY SHEET

Master sheet: **side view, facing right, 64×64 cells, palette strip, silhouette-test row.**
Five stances, presented in order as a vertical strip.

| beat | purpose | pose | framing | timing | must be readable | emotion sold |
|---|---|---|---|---|---|---|
| **A1 neutral stance** | establish the ordinary self | back-foot slump, hair over near eye, collar half-collapsed, arms low, uneven hem | full body, feet on a ground line, 1:1 | hold; 4-frame idle loop behind it | "an ordinary person who is not okay" as a solid black fill | containment, waiting, held-in |
| **A2 aggressive stance** | show the silhouette rotating onto one diagonal | weight forward, collar flared, hair back, arm/weapon line rising, legs wider | same framing, side by side with A1 | hold; entered via anticipation frames only | the whole body on ONE diagonal line vs A1's vertical | intention, threat, the hero surfacing |
| **A3 dash stance** | the signature motion shape | head down, body horizontal-diagonal, arms trailing, coat fully extended, trailing heel lifted | same; optionally a 3-frame strip | 0.15 s / 3 frames | a horizontal ARROW shape, unmistakable at 1 screen-tenth | committed velocity, no going back |
| **A4 attack contact stance** | the money pose | planted front foot, torso extended past the support base, weapon at its far point, coat/hair at maximum lag | same; weapon included in-cell or as the attached layer | holds ~6 logic frames + hitstop | body *stopped by its own blow* — feet planted, upper body over-committed | violence arrested, impact held |
| **A5 post-hit recovery stance** | prove recovery is fast and clean | returning to A1's numbers exactly: torso upright, weapon back to `HOLD_ROT −0.66`, hair catching up 1 frame late | same | release within ~0.2 s / 3–5 frames | continuity: no seam between A4 and A5, no pop | back to containment, ready, nothing celebrated |

**Sheet extras (not beats, but required rows):** palette strip (dark channel / bone-white
channel), silhouette test (A1–A5 as solid black against cyan wash and amber wash), three
eye states (calm / committed / hurt), and the armed-neutral variant (weapon trailing at
−38° + white eye slit visible).

---

## 8. Storyboard B — PERCEPTION WEAPON PICKUP

Maps 1:1 onto the six locked beats already implemented in `scripts/prop.gd`
(total **0.468 s**, under the 0.5 s ceiling; gameplay never locks).

| beat | time | purpose | pose / object state | framing | timing | must be readable | emotion |
|---|---|---|---|---|---|---|---|
| **B1 ordinary object** | pre-touch | ground truth: this is a pipe on the floor | grey bar `Color(0.60,0.62,0.66)`, player bare-handed, neutral A1 | camera static, object in lower-third near the hazard strip | until touch (`|dx|≤26, |dy|≤44`) | an unremarkable piece of junk | mundane, no anticipation given to the player |
| **B2 pickup + lift** | 0.000–0.070 | the body claims it | object lifts with a squash wobble; **player reaches braced** `(0.90,1.16)/−0.20` — hesitant, not heroic | static; player and object both fully visible | 0.070 s | the *player's hand* causes the motion, not the object alone | doubt, reaching anyway |
| **B3 fracture (overlap → tear)** | 0.070–0.240 | perception disagrees with reality | double image: hero visible *with* reality, ~61° of rotation disagreement; 3 bands tear angularly to `(1.80,0.48)/+0.40`, Seg1/2/3 `−0.60/+0.40/−0.30` | static; both identities on screen together (gate) | ramps to peak at 0.240 | ONE object breaking apart — bands registered at rest — not three objects | reality failing, double vision |
| **B4 held peak** | 0.240–0.285 | authored beat, not a glitch | peak held **bit-identical for ~3 frames**; hero deliberately kept "wrong" | static | 0.045 s hold | stillness before the decision — the eye reads *intention* | suspended breath |
| **B5 hero snap** | 0.285 | the reinterpretation lands | 1-frame visibility flip: reality gone, hero registered; **player recoils** `(1.16,1.24)/+0.24` (δ·46) | static, no flash, no camera move | 1 frame | the same object, now white — plus the body reacting to its own perception | shock, then recognition |
| **B6 settle → armed rest** | 0.285–0.468 | ownership transfers | hero settles to `HOLD_ROT −0.66` / `HOLD_OFFSET (16,−30)`, player pose 2 releases to neutral, **white eye slit appears** | static | 0.183 s | armed silhouette is visibly WIDER than A1; the hero's eye is open | quiet certainty, the delusion accepted |

**Explicit non-beats:** no flash, no glow, no particles, no gameplay lock, no camera
move, no HUD. The fracture is angular and positional only (standing refuse list).

---

## 9. Do / Don't rules

**DO**
- DO keep one hue per meaning (dark = real, white = delusion, saturated = enemy).
- DO keep three asymmetries in every neutral pose (covered eye, uneven hem, uneven
  collar).
- DO author every pose as drawn keyframes with held beats; hold contact/arrival/peak.
- DO make aggression one diagonal line; make the lower body always believable.
- DO test every key pose as a solid black fill against BOTH state tints.
- DO let the weapon change the silhouette (armed ≠ bare, visibly).
- DO keep detail budget: hair, one eye, seam, collar, hem, hands.

**DON'T**
- DON'T use glow, bloom, particles, screen flash or colour-shift as the identity
  signal (project refuse list).
- DON'T rotate or continuously non-uniformly scale pixel sprites at runtime — author
  the frame instead.
- DON'T add a second accent colour to the player, or any saturated hue to the player.
- DON'T make the character tactical/equipped/armoured, nor a hooded edgy archetype,
  nor a monster — no scars, runes, tech, capes, masks.
- DON'T animate the face beyond 3 authored eye states; no expression animation.
- DON'T add random twitches, random eye darts, or any randomness to pose.
- DON'T let hair/coat motion be the loudest motion in a combat frame.
- DON'T let the hero state become a hue change — it is a *contrast* change only.
- DON'T redesign the enemies here (their saturated channel is already correct).

---

## 10. Why this supports NEVERLOOKBACK

1. **It makes the premise visible every frame.** The title's rule ("never look back")
   and the game's premise (controlled insanity) are carried by the permanent half-face,
   the forward-drifting head, and the dark/white split — no cutscene required.
2. **It gives "controlled insanity" a body.** Insanity = asymmetry + timing contrast
   authored on a timeline; control = determinism (no randomness, lower body physically
   honest). The identity is legible *after* the action, which is exit-gate item 20.
3. **It funds the perception weapon and Delusion Echoes for free.** The bone-white
   channel already exists for the hero blade; echoes are made of the same channel and
   the same contact frame — one visual vocabulary, zero new FX.
4. **It passes the game's own gates:** both identities visible on one body (white eye
   slit + grey reality), silhouette readable in both state tints, aggression readable
   as body language (exit items 9, 13, 19), no added FX (refuse list), determinism
   preserved (all states are functions of gameplay state, never `randf`).
5. **It is affordable.** ≤24 colours, 64×64 cells, ~49 body frames + a weapon sheet —
   a vertical-slice-sized commitment, listed in `VERTICAL_SLICE_ART_PLAN.md`.
