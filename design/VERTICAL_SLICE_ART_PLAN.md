# VERTICAL SLICE ART PLAN — minimum production art set + build order

**Status: DIRECTION LOCK companion. This lists the MINIMUM real art needed next and the
order to make it in. It is a plan, not a production run — nothing here has been drawn.**

Sources: `design/CHARACTER_VISUAL_IDENTITY.md` (format + identity),
`design/DELUSION_ECHOES.md` (echo source-frame requirement),
`design/PERCEPTION_WEAPON_EXPERIMENT.md` (transform beats), live prototype scenes.

---

## 0. Format recap (locked by CHARACTER_VISUAL_IDENTITY §5)

| item | value |
|---|---|
| sprite cell | body **64×64** · weapon **96×64** · enemy **48×64** |
| character height | ~56 px on screen, 1:1 at 1280×720, no camera zoom |
| palette | ≤24 colours master, ≤12 per sprite; dark = real, bone-white = delusion, saturated = enemy |
| shading | 3-step cel, top-right light, no AA, no dither on characters |
| outline | 1 px ink on characters/weapons only |
| animation | **authored keyframes** replacing the parametric scale/rotation layer; runtime sprite rotation banned; draw positions snapped to whole pixels |
| player sheet | side-facing right; left = engine mirror (verify mirroring before committing to it) |

**The single biggest format consequence:** the current `body_vis.scale`/`rotation`
pose layer (`player.gd` `_update_visuals`, lines 419–520) cannot survive on pixel art.
Every measured pose value in that function becomes a *drawn frame held for N logic
frames*. The blend rates (δ·40 coil, δ·44 commit, δ·52 plant, δ·30 release, δ·52
arrival) become **frame-change cadence**, not lerps. Until art exists, the parametric
layer remains as the prototype stand-in — art replacement is a like-for-like swap of
*when frames change*, and every existing test (`test_identity` phase 7 pose gate,
`probe_feel3` Q1/Q2/Q3/Q5 holds) must still pass against frame timing.

---

## 1. The minimum real production art set

### A. Master character sheet (the contract)

64×64 cells, side-right, from which every other asset is checked:

1. **Neutral stance** (A1) — back-foot slump, hair over near eye, uneven hem/collar.
2. **Aggressive stance** (A2) — one diagonal line of action, collar flared.
3. **Dash stance** (A3) — horizontal arrow, coat extended, arms trailing.
4. **Attack contact stance** (A4) — planted feet, body extended, weapon at far point.
5. **Post-hit recovery stance** (A5) — returning to A1 numbers, hair 1 frame late.
6. **Armed neutral variant** — weapon trailing at −38°, white eye slit visible.
7. **Palette strip** + **silhouette test row** (all stances as solid black against a
   cyan wash and an amber wash) + **3 eye states** (calm / committed / hurt).

*Why first:* everything downstream is a variation of these five poses; identity drift
is cheapest to catch here.

### B. Locomotion set

| # | asset | frames | notes |
|---|---|---|---|
| B1 | **idle** | 4 | asymmetric slump constant; 1 px breath; no random twitch |
| B2 | **run** | 6 | stride + hair/coat lag (secondary action 1 frame behind) |
| B3 | **reversal / skid** | 3 | heel dig, coat flips forward; pose-only, no dust FX |
| B4 | **jump / fall / land** | 4 | anticipation crouch, rise, fall (limbs trailing up), squash-land |
| B5 | **dash** | 3 | entry extreme → hold (0.15 s) → plant exit |

### C. Combat set

| # | asset | frames | notes |
|---|---|---|---|
| C1 | **basic attack (standing)** | 6 | coil `(0.80,1.28)/−0.42` · commit · contact `(1.16,1.16)/+0.26` **held** · overshoot past contact (whiff) · recover (start at contact's exact values — no seam) · neutral |
| C2 | **dash→attack** | 5 | ONE gesture: loads *forward* from dash posture `(1.34,0.80)→(1.38,0.76)`, contact lean **0.32**, monotonic — never a backward coil |
| C3 | **hit-confirmed variant of C1 contact** | (reuse) | same frames; whiff vs hit differ by *duration held*, not by new art — contact frame holds to end of active window on confirm, overshoot continues on whiff |
| C4 | **pickup / reach** | 3 | braced reach `(0.90,1.16)/−0.20` · hold · release |
| C5 | **hurt (player)** | 3 | impact, held recoil, ease — horizontal, feet planted |

### D. Perception transform set (object + body)

| # | asset | frames | notes |
|---|---|---|---|
| D1 | **reality object (pipe)** | 1 base + 6 beat states | matches `prop.gd` beats exactly: instability wobble · overlap/double image · band tear (3-band misregistration, angular) · **held peak (~3 static frames)** · snap (visibility flip) · settle |
| D2 | **hero object (blade)** | 1 base + wear tint steps | bone-white blade + guard + grip; 5-use wear (existing tint), break shards (4 frames, deterministic), respawn fade is code |
| D3 | **transform body poses** | 3 | reach (C4 reuse) · recoil at snap `(1.16,1.24)/+0.24` · settle to neutral |
| D4 | **weapon swing orientations** | 5 | authored blade angles for held/anticipation/apex/contact/rest — **replaces runtime rotation** |

### E. Blink set

| # | asset | frames | notes |
|---|---|---|---|
| E1 | **blink arrival** | 3 | land `(1.08,0.98)/+0.20` (weight settles DOWN), hold (7 frames), release to neutral. Must never read as a grow/pop/stutter |

### F. Enemy set (one hit reaction only — no second enemy)

| # | asset | frames | notes |
|---|---|---|---|
| F1 | **melee chaser: idle** | 3 | saturated red channel, broad forward-leaning mass |
| F2 | **melee chaser: hit reaction** | 4 | impact extreme held (20 % of recoil time, matching `e = clamp(raw×1.25)` hold), horizontal whip, **feet planted** (pivot at bottom-centre — the 12px-float fix is now an art requirement), ease back. No ragdoll, no spin, no launch |
| F3 | **ranged: hit reaction** | (mirror of F2 logic) | optional in slice; reuse F2's staging rules if cut |

### G. Weapon / object sheet

Covered by D1/D2/D4 (pipe, blade, orientations, break). This is the **one** object
sheet in the slice — no inventory, no second weapon.

### H. Minimum FX sheets

**None required.** By design:
- Delusion Echoes render from the **existing contact frame** (zero new frames — see
  DELUSION_ECHOES §4.1).
- Transform is misregistration of existing geometry (no added FX — refuse list).
- Blink flash/veil, hit flash, camera shake already exist in code.
- The swoosh overlay is permanently removed (pose is the cue).

The only "FX-adjacent" art ever considered: a **4-frame enemy hit flash** — already
superseded by the 0.03 s code flash. Do not add FX art without a fresh design pass.

---

## 2. Build ORDER (each step ends in a look review, not just a file)

| step | asset(s from §1) | why this position | exit check |
|---|---|---|---|
| **1** | **A — master character sheet** (+ palette + silhouette row) | locks identity before any motion exists; every later sheet is checked against it | silhouette test passes against BOTH state tints; dark/white channel split obvious; reads as "ordinary person, half a face" |
| **2** | **B1 idle, B2 run** | the two animations seen most; proves the sheet works in motion | loop clean at 60 fps; hair/coat lag 1 frame; no pixel crawl (positions snapped) |
| **3** | **C1 basic attack** | the combat core — everything the gate pass tuned lives here | frame holds reproduce measured beats: coil → contact hold (≈6 frames incl. hitstop) → overshoot (whiff) / release-from-contact (hit); **no seam** |
| **4** | **B5 dash + C2 dash→attack** | the signature gesture; C2 must be authored *with* C1 to guarantee the monotonic hand-off | one gesture, no reversal (compare-pair C) |
| **5** | **B3 skid, B4 jump/fall/land, C5 hurt** | completes the movement set; skid shares priority chain with arrival pose | skid → dash → run chain continuous; landing squash reads |
| **6** | **F1/F2 melee enemy + hit reaction** | hit feel needs BOTH bodies; the held planted recoil is half the readability | feet never leave the floor line; extreme held; horizontal only |
| **7** | **D1/D2/D3/D4 perception transform + weapon sheet** | the experiment's headline; depends on C1 (swing) and B (body poses) | beats match `prop.gd` table (0.000/0.070/0.170/0.240/0.285/0.345, total <0.5 s); held peak visibly static ~3 frames; snap is 1 frame; both identities visible together |
| **8** | **E1 blink arrival** | small, but was rewritten twice in the gate pass — needs eyes on it | lands in 2 frames, holds ~7, releases clean; never a grow/pop |
| **9** | **C4 pickup/reach** | ties body to object; cheapest after D3 exists | body reaches, object never transforms "on its own" |
| **10** | **Delusion Echo validation (no new art)** | render one static echo copy from C1's contact frame in-engine and LOOK at it | reads as a second self at α0.40/12px; if artifact → increase separation, not alpha. *(A look-review probe only — not the echo system.)* |

**Order rationale:** identity → motion → combat → the two most-judged moments
(transform, arrival) → presentation. Nothing is drawn before the sheet it derives from.
Each step is a *reviewable deliverable* (a sheet + a silhouette test), so a wrong
direction is caught while only one sheet exists.

---

## 3. Explicitly NOT in this plan

- No second enemy, no enemy roster, no NPC/NPC art.
- No tiles/arena/background production art (the graybox arena + state tints stay).
- No UI/HUD art beyond what exists; no portraits, no cutscene art, no storyboards as
  illustrations (the markdown storyboards in the identity/echo docs are the spec).
- No full animation roster (no crawl, no swim, no death sequence, no emotes, no
  victory pose).
- No echo *system* implementation — step 10 is a static look-review only.
- No second weapon, no inventory icons, no item variety.
- No final production pass on the whole game; this is the vertical-slice minimum.
- No code refactors required to *start* — but note the one real integration task:
  when the first real sprite lands, `_update_visuals` gains a frame-picker that must
  reproduce the existing pose timing. That swap is deliberately its own future task,
  gated by the existing suites.

---

## 4. What must be true before asset production starts (beyond approval)

1. Human look-review of the gate pass (compare-pairs A–F) — the pending review from
   `PROTOTYPE_EXIT_REVIEW.md`. Art direction should not be committed on an unjudged
   prototype: if the transform doesn't read right in Play, D1 changes.
2. Confirmation of the §0 format numbers (64×64 / 56 px / 1:1) against how the game
   actually looks on the developer's display.
3. One palette pass: pick the exact ≤24 swatches and lock them as a file **before**
   the first sprite (pixel-art skill discipline: palette first, spec lock, audit
   before export — `agentskill/agent-skill-pixel-art-4.3.0`).
