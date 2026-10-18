# CHARACTER_REDESIGN_02 — Protagonist redesign, three concepts

**Status: READY FOR HUMAN REVIEW — STOPPED HERE.**
No animations built. Current sprite not replaced. No gameplay code touched
(`scripts/player.gd` last written 18:57, before this task; the previous sprite
pipeline `art/_source/gen_character_art.py` and `art/prototype/character/*`
are untouched).

---

## 1. Method (disclosure)

All concept art in this pass was **drawn programmatically with Python + Pillow**
(no image-generation model is available in this environment). Every figure is a
hand-authored joint pose rasterised as hard-edged pixel shapes: no anti-aliasing,
1 px ink outline, automatic top-right cel rim (light/dark step per material),
silhouettes via alpha-mask black fill. Generator:
`art/_source/gen_redesign_02.py`.

## 2. Reference handling

Reference on disk: `refs/Neverlookback Protagonist Sprite Sheet.png`
(the brief named `protagonist_reference.png`; this is the file that exists).

**Taken from the reference (presentation only):** ~50–60 px character scale,
strict side view facing right, the 5-pose numbered horizontal sheet row
(neutral → ready → dash → attack contact → recovery), silhouette-study band,
delusion-echo demonstration band, reality/perception palette split, the
perception-fracture weapon strip layout.

**Deliberately NOT taken (its design content is the declared failure):**
anime hair, glasses/tired-anime face, open field jacket, tall anime proportions,
its exact poses, its hook-pipe weapon design, its red echo tint. None of those
appear in concepts A/B/C.

## 3. The failure this redesign pivots away from

| Previous design failed as | Pivot in A/B/C |
|---|---|
| too anime / attractive / composed | every neutral is collapsed, closed, crooked; faces are 9–11 px, flat-mouthed, eye-bagged |
| standard edgy indie action protagonist | no coat, no blade, no glow, no pose could be called "cool" |
| not psychologically unstable enough | instability is the *state contrast* (closed reality → beyond-balance combat), not twitching |
| not visually unique enough | each concept owns a different body irregularity, wardrobe, weapon interpretation, and attack axis |

---

## CONCEPT A — "THE SLUMP"

Files: `art/prototype/character_redesign/concept_a.png`

### Design explanation
An office-temp body that has given up: cheap button-up untucked, trousers too
long so they stack on the shoes, two **different** scuffed sneakers. His
irregularity is a **forward head on a collapsed C-chest** — chin already fleeing
the room before anything happens. In combat the C-spine *snaps open*: chest
thrust forward, chin up, limbs flung to all four corners, pipe heaved up-forward
at ~48°. The posture itself performs the delusion — he doesn't pose heroic, he
over-opens into it.

Pose arc: ① unarmed slouch → ② brandishing the plain pipe, upright and proud
→ ③ driving dash, head leading, pipe trailing → ④ contact: deep lunge, pipe
up-forward, free arm flung back-down → ⑤ deflation, spine re-rounding, pipe
dropping, head jutting forward again.

### Neutral silhouette
A closed vertical beanbag: no gaps between arms and body, feet nearly touching,
head pushed past the chest, total width ≈ 20 px. Reads small, tired, avoidant —
cannot be mistaken for cool.

### Combat silhouette
A four-corner star: legs split into a deep lunge, free arm thrown down-back,
fractured pipe thrown up-forward — outline spreads from ~20 px to ~70 px wide.
Black fill stays readable; the pipe's fracture teeth survive at 50 % opacity.

### Why it fits NEVERLOOKBACK
The identity *is* the delta: 650 opaque px in reality → 1083 px at contact
(**1.67×**, the largest growth of the three). Delusion Echoes duplicate exactly
the moment where the slouch becomes a star, so the echo exaggerates a body that
was pathetically small one frame earlier. Perception weapon keeps pipe DNA
(straight tube + coupler ring + elbow nub → elongated tube with a fracture gap
and splintered heroic mouth) — it is still visibly the same drainpipe, not a sword.

### What makes it non-generic
The forward-head C-spine is a *profile-native* trait (readable in the game's
side view at 50 px); mismatched shoes and stacked trouser hems are visible
wardrobe facts, not flavour text; the combat staging flips the spine curve
(collapsed → hyper-open) instead of switching to a standard crouch guard.

### Potential weakness
The neutral can read as merely "tired guy" if the head-jut is drawn too gently,
and the contact lunge is the most conventional of the three stagings — the
slouch-to-snap contrast has to carry the instability.

---

## CONCEPT B — "THE KNOT"

Files: `art/prototype/character_redesign/concept_b.png`

### Design explanation
A laundry-day kid folded into himself: oversized thrift sweatshirt whose sleeves
eat the hands, baggy trousers with uneven hems, huge worn shoes. His
irregularity is **knock-kneed knees plus a self-hold** — both hands knotted on
the opposite sleeve at stomach height. In combat the knot unravels into a
**flat horizontal spear**: feet slam wide, the hidden arm whips out, the pipe
drives forward on one perfectly level line. Heroism for him is *length, not
height*.

Pose arc: ① folded knot, chin to chest → ② unfolding, pipe cocked back,
free arm flung forward → ③ near-horizontal flying drive, pipe leading →
④ contact: extreme low stop-thrust, pipe dead level → ⑤ re-folding, pipe
braced point-down, hands retreating into sleeves.

### Neutral silhouette
A narrow closed column with a knee-break kink: thigh angles forward, shin angles
back, arms knit into a bundle at the front. Visually the smallest of the three
neutrals (no weapon, no gaps, no spread).

### Combat silhouette
A low flat wedge ending in a long horizontal bar: spans ~83 px of width at
contact (feet at x33 → pipe tip at x116). Black fill reads as one committed
line — the opposite axis of his neutral.

### Why it fits NEVERLOOKBACK
The transformation rotates the body's axis 90°: vertical folded knot →
horizontal spear (mass 711 → 1085 px, 1.53×). Echoes of the stop-thrust are a
thick level bar at 50 % opacity — the most *graphic* echo of the three, almost
a stamp of his self-image. Weapon DNA: pipe → tapered battering lance
(uniform tube, mid coupler, socket ring at the tip, blunt mouth) — a tube with
fittings, never an edge.

### What makes it non-generic
Nobody designs knock-kneed, self-holding game protagonists; the self-hold is a
psychological gesture visible in a sprite; the attack stages as a stop-thrust
(length-based) instead of the expected swing, and his recovery literally re-folds
the knot — the trait persists through the whole animation vocabulary.

### Potential weakness
The low thrust stacks arm, pipe and lead leg along one profile line — overlap
risk at 50 px (it held in this drawing, but animation must keep the pipe at
shoulder height); and sleeve-swallowed hands must reappear whenever he grips,
or the pipe floats.

---

## CONCEPT C — "THE HITCH"

Files: `art/prototype/character_redesign/concept_c.png`

### Design explanation
A handyman-ish body that never lines up: faded work shirt with both sleeves
rolled (bare forearms), one trouser cuff shoved up over the boot, the other
dragging; sewn knee patch; scuffed boots. His irregularity is a **hiked weapon
shoulder with a dead-straight tense arm plus an uneven step** — one heel never
quite down, one cuff never quite up. In combat the crooked body over-corrects
into **one clean committed diagonal**: full fold over the front knee, pipe
smashed down-forward, free arm flung up-back. Only violence straightens him.

Pose arc: ① mid-step rest, shoulder up near the ear → ② wound up, shoulder
pulled square, crook-scepter loaded behind → ③ leaping windup, pipe trailing
up-back, free arm punched forward → ④ contact: folded smash, crook tip at
ground, body one diagonal → ⑤ rebound, pipe springing up, the hitch creeping
back into the shoulder.

### Neutral silhouette
A crooked asymmetrical bundle: uneven step (feet 14 px apart with one heel
raised), shoulder line tilted, arm held visibly off the thigh, one bare ankle.
Reads physically off rather than merely tired.

### Combat silhouette
A large X: free arm up-back, pipe down-forward through the contact point, legs
spread under the fold — a single clean diagonal has replaced the crooked line.
Black fill holds at 50 % in every echo treatment.

### Why it fits NEVERLOOKBACK
Reality is misaligned; combat is over-aligned — the delusion is *correction*:
he becomes the straight, committed line he never manages in life
(782 → 1086 px, 1.39×). Weapon DNA: pipe with an elbow end → grown into a
crook-scepter crown (tube + coupler everywhere; a pipe elbow scaled into
rank-symbols — the delusion of kingship built from plumbing).

### What makes it non-generic
The irregularity is carried by three separate profile-visible facts (hiked
shoulder, tense arm, uneven step/cuff) instead of a face gimmick; rolled sleeves
and bare forearms give him a silhouette no other concept has; the attack axis
(down-smash) is the mirror of A's heave.

### Potential weakness
The hitch is the subtlest trait in pure profile — the uneven step and hem must
carry it; and the crook-crown can read "garden tool" instead of "delusion of
rank" at 50 px.

---

## 4. Cross-concept evidence

### Scale (measured body height, head-top → feet, weapon excluded)

| concept | neutral | ready | dash | contact | recovery |
|---|---|---|---|---|---|
| A | **56** | 57 | 48 | 52 | 55 |
| B | **55** | 50 | 34 | 40 | 51 |
| C | **57** | 54 | 42 | 43 | 53 |

Standing/neutral heights are 55–57 px (spec: ~50–60). Poses ③–④ are lower
because the body extends along a *diagonal/horizontal* line of action — total
limb span along that line (e.g. B contact: 83 px of width) exceeds standing
height. This is staging, not scale drift.

### Silhouette growth (opaque pixels, reality → contact)

| A | B | C |
|---|---|---|
| 650 → 1083 (**1.67×**) | 711 → 1085 (1.53×) | 782 → 1086 (1.39×) |

### Delusion-Echo compatibility (tested per concept, 4 tiles on each sheet)
1. **Black fill** — contact pose readable as pure silhouette (silhouette band + tile).
2. **50 % black copy offset behind (+12, −4)** on white — ghost separates, pose holds.
3. **Game spec** (`design/DELUSION_ECHOES.md`: bone `#F4F6FA` at α 0.40, +12 px,
   −0.12 rad about the feet, exactly one phantom *behind*, on `#0D0F17`) — visible,
   non-muddy, does not swallow the figure.
4. **50 % copy in front** on light grey — pose still readable when overlapped.

No pose needs particles or slash FX; all echo material is body + pipe.

### Anti-anime compliance (all three concepts)

| Banned | How avoided |
|---|---|
| anime hair / hair over one eye | flat low cap (A), bedhead lumps (B), practical crop (C); eye always visible, no bangs, no spikes, no sweep |
| long cool coat / tactical / cyberpunk / black trench | waist-length everyday tops only: untucked shirt (A), thrift sweatshirt (B), work shirt (C); domestic desaturated palettes |
| handsome angular face | 9–11 px heads, flat mouth, eye-bag pixel, nose bump; shape over facial detail |
| fantasy swordsman silhouette | no blade exists; the weapon is a tube in every state (steel pipe → bone-white tube variants) |
| permanent glowing eye | no emissive pixels; perception accent (bone white) appears only on the perceived pipe |
| "edgy cool guy" posture | every neutral is closed/ collapsed/ crooked; no pose in the reality column could be called cool |
| fixed uniform / "protagonist outfit" | three different wardrobes, all thrift/damaged/mismatched, each with visible wear facts |

### Controlled insanity (how instability is shown)
Reality column = small, closed, restrained (widths ~20 px, arms pinned, no gaps).
Combat column = line-of-action changes beyond balance (A: center of mass past
the front foot with limbs at four corners; B: fully horizontal beyond any
support; C: folded past the front knee), sudden adjacent-pose contrast
(①→② weapon appears mid-stance, ④→⑤ visible deflation), aggressive diagonals
on three different axes (up / flat / down). Nothing twitches; nothing jitters.

### Palette
Each concept: 6 base chips on the sheet + shared ink/skin/bone/steel —
**24–25 unique colours incl. cel steps** per concept (measured over all five
poses). Reality hues are desaturated domestic tones; the perception accent is
bone white `#F4F6FA` on the perceived weapon only (matches the project palette
doctrine: desaturated dark base + bone-white perception leak).

---

## 5. Recommendation — take **CONCEPT A ("THE SLUMP")** forward

Reasons:
1. **Biggest identity delta** (1.67× silhouette growth; 20 px closed → 70 px
   star). The brief says the contrast *is* the identity — A expresses it in
   outline alone.
2. **Most runtime-proof irregularity**: forward-head slouch is a whole-body
   outline trait readable at 50 px in a side view; B's knock-knees and C's hitch
   are joint-level traits that can wash out in motion.
3. **Clearest "existed before the game" wardrobe** at sprite scale: mismatched
   two-tone shoes and stacked trouser hems are literally visible facts.
4. The five-pose arc tells the delusion story end to end: fold → snap →
   heave → deflate.

Runner-up: **B ("THE KNOT")** — the most original staging (90° axis flip,
length-based heroism) and the most graphic echo; pick B instead if review
values most-unusual attack staging over neutral-scale legibility.
C ("THE HITCH") is the pick only if "physically off" outranks the other traits —
its weakness (profile-subtle hitch) is the reason it is not first.

Honest caveat for the review: A's contact lunge is the most conventional of the
three stagings; if that reads too familiar next to B/C, the fix is to exaggerate
the spine-snap and the flung free arm rather than to switch concepts.

## 6. Files

- `design/CHARACTER_REDESIGN_02.md` — this document
- `art/prototype/character_redesign/concept_a.png` — sheet A (1560 × 952)
- `art/prototype/character_redesign/concept_b.png` — sheet B (1560 × 952)
- `art/prototype/character_redesign/concept_c.png` — sheet C (1560 × 952)
- `art/prototype/character_redesign/redesign_02_overview.png` — three-concept comparison with recommendation stamp
- `art/_source/gen_redesign_02.py` — generator (re-run to reproduce)
- `art/prototype/character_redesign/slump_refine_a1.png` — variant A1 sheet (1560 × 968)
- `art/prototype/character_redesign/slump_refine_a2.png` — variant A2 sheet (1560 × 968)
- `art/prototype/character_redesign/slump_refine_a3.png` — variant A3 sheet (1560 × 968)
- `art/prototype/character_redesign/slump_refine_compare.png` — refinement comparison sheet (1400 × 878)
- `art/_source/gen_slump_refine.py` — refinement generator (imports `gen_redesign_02.py`; re-run to reproduce)

## 7. Refinement round — THE SLUMP combat variants (A1 / A2 / A3)

Status of Concept A: **base direction selected, not final.** The strongest parts
(collapsed C-posture, forward head, cheap everyday clothing, mismatched shoes,
stacked hems, the strongest reality→combat silhouette delta) are kept. The
weakness being fixed: A's original ATTACK CONTACT read as too conventional.
This round tests **body language only** — no animation, no Godot changes, no
sprite replacement.

### What is held fixed vs what changes

| Held fixed | Changed per variant |
|---|---|
| neutral pose (same `A1` joints — byte-identical render), clothing, face, hair, palette, proportions, drainpipe DNA (reality pipe / perceived frac pipe), no glow/particles/FX/aura/armour | combat ready, dash, attack contact, recovery |

### The three variants

- **A1 — FORWARD COLLAPSE.** The collapsed body unfolds *too far forward*:
  chest opens, head stays slightly ahead of the torso, the attack crosses past
  stable balance (rear foot leaves the ground, front foot barely catches),
  recovery crumples inward with the pipe drooping forward. Must not read as a
  standard swordsman lunge — the arm heaves from *below* the chin so the head
  stays framed under the rising pipe.
- **A2 — HORIZONTAL IMPOSSIBLE LINE.** Concept B's strongest staging idea,
  re-authored in A's body. At contact the torso, arm and perceived weapon form
  one near-level vector from rear heel to pipe tip, while the lower body stays
  physically planted (wide grounded legs) and the head cranes *above* the line —
  not a flying pose. Reads: "he thinks he crossed the whole space in one blow."
- **A3 — BROKEN DIAGONAL.** Aggressive asymmetry: shoulders and hips disagree
  (visible torso kink — chest forward, neck back, head jutting wrong), the
  weapon is one huge down-diagonal, the free arm flings up-back (X limbs), legs
  stay grounded and uneven. One authored frame that looks almost *incorrect*
  yet intentional.

### Evidence (measured, but explicitly NOT the selection basis)

| | height px (n,r,d,c,v) | silhouette mass (n,r,d,c,v) | n→c growth |
|---|---|---|---|
| A1 | 56, 58, 40, 51, 54 | 650, 870, 839, 979, 1023 | 1.51× |
| A2 | 56, 53, 31, 44, 44 | 650, 833, 704, 958, 957 | 1.47× |
| A3 | 56, 54, 40, 46, 55 | 650, 869, 870, 946, 1015 | 1.46× |

Neutral is identical across all three (650 mass / 56 px) — identity untouched.
Horizontal/diagonal frames compress standing height by design (same precedent
as Concept B's contact, 40 px). **Selection is by visual personality, not pixel
area.**

Black silhouette test: all five poses per variant hold at zero colour, zero FX,
zero face detail; the three contacts are mutually unmistakable (falling heave /
long bar / X). Echo test per variant — real pose, one +12 px echo, two echoes
stepped along that variant's action line (bone tint, game phantom colour), one
impossible-position Blink echo (rotated copy floating off the ground): all
readable, none cluttered.

Self-QA round before this section was written (PIL render → inspect → fix):
first render had the A1-recovery pipe passing through the shin, the A1-contact
pipe crossing the face, A2/A3 contact pipe tangencies at chin/thigh, and
invisible black-on-dark echo ghosts. All fixed and re-verified at 5× zoom; the
echo ghosts now use bone tint matching the game's phantom spec.

### Rubric comparison

| Axis | A1 FORWARD COLLAPSE | A2 HORIZONTAL LINE | A3 BROKEN DIAGONAL |
|---|---|---|---|
| Aggression | high — body thrown past balance | **highest** — the body *becomes* the line | high — committed wide down-smash |
| Originality | med-high — fall-forward whip is rare | **high** — horizontal body-contact still unusual | high — kinked torso + X limbs |
| Readability @ 50 px | med-high — busy shape, head now framed | **high** — bar unambiguous at any scale | med — zigzag can muddy; needs motion QA |
| Delusion Echo compatibility | good — afterimages tumble up-forward | **best** — echoes step down the line like clone spawns | good — X doubles cleanly; ground-step risk |
| Generic-anime risk | medium — closest to a lunge | **low** — no visual canon for this pose | low-med — X smash common, torso saves it |
| Animation difficulty | hard — past-balance arc, skid, catch | **hardest** — level line + planted feet need careful leg keys | hard — torso zigzag + scissor limbs |

### Verdict

**First pick: A2 — HORIZONTAL IMPOSSIBLE LINE.**
1. Largest *shape* story: the neutral stays a closed ~20 px blob; contact opens
   into a full-space bar — the delusion stated spatially, not just in size.
2. Echoes extend the line: ghost copies stepping along the vector read as clone
   spawns — the strongest "clone summon" result of the three.
3. Unambiguous at 50 px in pure black; zero anime precedent; it is still A's
   body (identity untouched), only stretched.
4. Its risks are visible but contained in the authored frame: wide grounded
   legs + trailing free arm + craned head kill the superman read (verified in
   silhouette); the cost is real — it is the hardest to animate.

Runner-up: **A3** — the most "incorrect" frame, strongest as a single poster
image; risk is 50 px legibility of the torso kink (motion QA needed).
**A1** is the production-safest (closest to A's existing contact structure) but
the least surprising — it stays nearest to the "too conventional" contact this
round set out to fix.

## 8. Next steps (proposed, NOT executed)

1. Human review → pick A1, A2 or A3 from the comparison sheet.
2. Refinement pass on the picked variant (pose polish, wear details).
3. Only then: animation keyframes and runtime sprite swap — separate pass,
   gameplay code still untouched until that pass is approved.

**STOP — waiting for review of the refinement comparison.**

## 9. Production test + runtime review (executed)

The A2 lock (§7 Verdict) was taken into a first production-quality test:
master sheet, run, dash and basic attack only. No roster expansion, no second
weapon, no combat/mechanic change.

### Art method (disclosure)

All frames are **programmatic PIL drawing** (`art/_source/gen_a2_production.py`
on the mask renderer from `gen_character_art.py`) — **no image-generation
model was used at any point**. 64×64, 15-colour palette (Concept A locked
values), ≤14 colours per frame, 0 interior holes, grip pixel (48,32) = the
HOLD_OFFSET contract, whole-pixel placement, NEAREST filter.

### What shipped into the prototype

- `art/prototype/character_a2/` — 15 runtime frames (neutral, run_00–05,
  d0/d1/d2, attack_a0–a4) + master/run/dash/attack display sheets, imported.
- `scripts/player.gd` — dual frame caches + `use_a2` flag + V-key runtime
  toggle (baseline ↔ A2 through the real `_unhandled_input` handler). Frame
  picking, body pose math and `body_vis` untouched.
- `scripts/prop.gd` — swing arc presentation only: raise → snap → **held
  LEVEL through contact** → slight dip → braced/whiff recovery. Same timings,
  same hitboxes, same recovery structure as before.
- `tests/capture_a2.gd` — scripted runtime capture (input-driven, both sets,
  real V handler, pipe pickup, whiff + bite setups).

### Regression evidence

7 suites / 129 assertions: **all PASS, 0 script errors** (identity, feel,
weapon, arena, runtime, killblink, strand). Combat mechanics, timings,
hitboxes and the roster are untouched.

### Runtime capture (19 shots, real renderer)

- Pipe pickup confirmed (prop HELD); carried blade/settle verified before shots.
- V-toggle verified live: `use_a2` flips through the real key handler; every
  shot logs `set=A2/BASE` + texture + frame — both sets captured under
  identical state.
- **Contact arc measured in pixels**: contact body shot blade angle
  **+1.6° (LEVEL)**, whiff follow-through **+3.3°**, startup coil −44° —
  the snap→level→dip arc renders exactly as authored. Screenshot timing lags
  the logged attack clock by ~2–4 physics ticks (viewport texture = last
  presented frame), so mid-active capture windows were shifted late on
  purpose; this is a capture artifact, not a gameplay timing issue.
- Bite confirmed on both sets (`bite=true` on A2 and baseline contact shots).

### Readability verdict (A2 vs the rectangle/baseline set, in motion)

1. **Neutral / run / dash**: A2 keeps its slump, craned neck and mismatched
   soles in every motion frame; the baseline reads visibly straighter and
   more stacked. The identity survives the move to runtime.
2. **Attack**: the contact body (deep planted lunge, trailing arm, craned
   head riding above the arm line) plus the level blade reads as **one
   horizontal line through the torso — arm — blade**, which is the A2 lock
   stated at 50 px in-game, with no glow/slash FX needed.
3. **A2 remains unique and readable at ~64 px on the real background**
   (dark floor, red hazard, white zone labels are the worst case and it
   still separates from the baseline silhouette).
4. Known competition, out of scope of this pass: the enemy hit-flash block
   and zone label text sit near the swing line and can share rows with the
   blade for a few frames; enemy visuals were not touched here.

**STOP — production test + runtime review complete.** Roster expansion,
Delusion Echoes, map/chapter work and combat changes remain out of scope
until this round is reviewed.
