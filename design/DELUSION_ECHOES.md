# DELUSION ECHOES — design spec (pre-production, NOT implemented)

**Status: DIRECTION LOCK. This document specifies a presentation feature. No code for it
exists or should be written in this pass (PHASE 9: do not overbuild).**

---

## 0. Feature definition

**DELUSION ECHOES:** on a *confirmed* hit, a single real attack may briefly appear as
one or two phantom copies of the protagonist's own contact pose, spatially misregistered
from the real body — as if the protagonist's perception insisted the blow landed harder,
further, or elsewhere than it did.

The echoes are **the protagonist dramatizing their own action.** They are not clones,
not afterimages of movement, not projectiles, not time effects. They are made of the
**same frame the real body is holding**, drawn in the **bone-white delusion channel**,
at **partial alpha**, **behind the player**, for **4–6 frames**.

## 1. Purpose

- Express **controlled insanity through presentation, never through mechanics**
  (the game's core rule: no broken controls, no random inputs).
- Make each of the three entry rhythms — *standing, dash, Blink* — visibly different in
  **quality of impact**, so the player feels their own momentum without a damage number
  changing.
- Give confirmed hits a signature effect that is **body-driven** (consistent with the
  project's decision to remove the swoosh overlay: the pose is the cue), instead of
  reintroducing slash FX.
- Extend the exact visual vocabulary already locked in the perception transform:
  **misregistration of a real thing**, not emission of a new thing.

## 2. Trigger conditions (common)

An echo event fires **only** when:

1. `swing.landed_hit` confirms (a real hit on a real target) — **whiffs never echo**
   (this preserves the hit/whiff contrast: a miss must stay empty), and
2. none of the suppression rules in §6 apply.

**Echo tier is decided by how the swing started:**

| tier | condition | echo type |
|---|---|---|
| normal | swing started while standing/running | **Normal Hit Echo** (§3.1) |
| dash | `_struck_from_dash` (swing started in the late-dash window) | **Dash Hit Echo** (§3.2) |
| blink | swing started within the Blink-arrival rhythm (press recorded during the 0.28 s transition or within `ARRIVE_TIME` 0.16 s after arrival) | **Blink Hit Echo** (§3.3) |

Tier is a property of the **entry**, not of the damage: damage stays 1, hitstop stays
0.045/0.075/0.10, reach stays 82/104. Echoes **read** the existing impact snapshot
(`_impact_hitstop` / `_impact_shake`, snapshotted at swing start per the v6 fix) and
never write gameplay values.

---

## 3. The three echo types

Common to all three: **the phantom is a copy of the real body's current contact pose**
(single source of truth — the frame the player is actually holding), rendered in the
bone-white channel at partial alpha, drawn **behind the player** (see §4), positioned on
the **ground line** (never floating), and **hard-cut in/out** (no long magical fade —
see §5.3).

### 3.1 NORMAL HIT ECHO

| property | spec |
|---|---|
| **trigger** | confirmed hit, standing/running entry |
| **purpose** | the protagonist's self-image: *"I hit harder than that."* |
| **silhouette shape** | **ONE full-body phantom** of the current contact pose (identical shape, no new pose drawn), +0.12 rad extra rotation — the misregistration signature from the transform |
| **placement** | **+12 px forward** of the real body along the facing direction, on the ground line. Between player and enemy; **never covers the enemy's core or head** (enemy recoil must stay readable) |
| **overlap with player** | yes, partially — it sits behind the player, its forward half visible past the player's front edge |
| **visibility concept** | constant **α 0.40** bone-white channel; enters and exits by hard cut |
| **duration** | **4 logic frames (0.067 s)** — spawn on the confirm frame, which lands *inside hitstop*: the frozen frame shows the double, then it is gone |
| **full body or partial** | full body (a partial slash would read as an FX; a full body reads as *a second self*) |
| **why psychological, not magical** | it is the protagonist's own body duplicated in space — a perception/proprioception error. No glow, no particles, no new colour, no light emission, no sound requirement; it obeys nothing but the real pose it copies |

### 3.2 DASH HIT ECHO

| property | spec |
|---|---|
| **trigger** | confirmed hit with `_struck_from_dash` |
| **purpose** | *"I went through there more than once."* — the attack exceeded reality along the line of motion |
| **silhouette shape** | **TWO phantoms of the same contact pose**, both offset **along the dash motion line backwards**: copy A at **−16 px**, copy B at **−32 px** from the real body (the comic *partial reduplication* read: repeated figures = speed), with progressive misregistration **+0.08 rad / +0.16 rad** |
| **placement** | strictly on the **motion line** (horizontal, ground-anchored: phantom feet snap to the ground line even as the copies trail), in the space the player just crossed — **behind** the player, **never on the enemy** |
| **overlap with player** | yes for copy A (partially), copy B is usually clear of the body |
| **visibility concept** | hard cut in; copy A **α 0.45**, copy B **α 0.28** (depth by value, not by blur); hard cut out |
| **duration** | **5 logic frames (0.083 s)** — lives through the armed hitstop (0.075 s) + 2 frames |
| **full body or partial** | full body ×2 (this is the only tier allowed two silhouettes) |
| **why psychological, not magical** | the copies occupy positions the player *actually occupied* a moment ago — a memory smear of one's own motion, not a summoned object; the forward dash posture is unchanged, the ghosts trail, so causality still reads forward |

### 3.3 BLINK HIT ECHO

| property | spec |
|---|---|
| **trigger** | confirmed hit on the first attack in the Blink-arrival rhythm (the documented Blink→attack rhythm) |
| **purpose** | the strongest perception rupture: *"I was already behind them."* |
| **silhouette shape** | **ONE full-body phantom of the contact pose, facing BACK toward the player** (reversed facing) — position **and** orientation are both impossible |
| **placement** | **beyond the target**: its leading edge starts at the **enemy's far edge** (≈ reach + enemy half-width + 0–4 px along facing), on the ground line. ≥ 60 % of the phantom is clear of the enemy rect; the enemy's head/core/contact side is never covered |
| **overlap with enemy** | at most touching the enemy's far edge (bounding boxes meet); it may overlap *empty space* the player never reached |
| **overlap with player** | no — the whole point is that it is somewhere the player is not |
| **visibility concept** | hard cut in, **α 0.50** bone-white, hard cut out |
| **duration** | **6 logic frames (0.10 s)** — the longest, but still inside one swing's recovery |
| **full body or partial** | full body (impossible *positioning* only reads if the whole self is there) |
| **why psychological, not magical** | it is a self-location error — proprioception reporting a body position that never happened — the classic shape of unstable perception. It still casts no light, spawns no particles, moves nothing: the game world ignores it completely |

---

## 4. Visual rules (all echoes)

1. **One source frame.** An echo is a rendered copy of the *current* contact pose.
   No separately authored echo poses exist — the echo is always literally the player's
   own frame. (This also means Delusion Echoes cost **zero new sprite frames**.)
2. **Bone-white channel only.** The copy is tinted/limited to the delusion palette
   (§3.4 of `CHARACTER_VISUAL_IDENTITY.md`). **No new hue may ever appear.**
3. **Z-order: behind the player, in front of the background.** The real body is always
   fully visible at α 1.0; the echo can only ever show as a misregistered fringe.
   (Exception by placement, not by z-order: the Blink phantom sits far from the player.)
4. **Ground-anchored.** Echo feet snap to the ground line; echoes never float, never
   drift, never orbit.
5. **Fixed offsets, no randomness.** Every offset/rotation/alpha in §3 is a constant.
   Determinism gate: same input → same echoes, 10/10 (echoes must not touch `randf`).
6. **Static pose.** A phantom does not animate while alive — it is a held *imprint*,
   like a duplicated comic panel. It only translates nothing and fades nothing; it is
   cut in, held, cut out.
7. **No gameplay effect whatsoever.** No hitbox, no damage, no hitstop, no shake, no
   camera, no slowdown, no sound obligation, no aggro, no collision. If the echo were
   deleted, gameplay would be bit-identical.
8. **No self-overlap stacking.** A new confirm **replaces** any live echo instantly
   (queue depth 1 — same pattern as `attack_buffer`).

---

## 5. Readability rules

1. **Separation minimum:** a phantom must differ from the real body by **≥ 10 px
   translation OR ≥ 0.10 rad rotation** — otherwise the double reads as a blur/glitch
   rather than a second figure. All three types satisfy this by construction (12 px /
   16+32 px / full field separation + reversed facing).
2. **Alpha ceiling 0.50.** The real body (α 1.0) always wins the value contest; the
   eye must resolve *real first, echo second* in every frame.
3. **Never cover the enemy's read.** The enemy's held recoil (its `(1.28,0.66)` extreme,
   its planted feet) is the other half of the hit's readability — no echo may overlap
   the enemy's head/core except the Blink phantom, which by rule sits beyond the far
   edge.
4. **Never cover the player's contact point.** The player + weapon silhouette at the
   moment of impact stays unobstructed (echoes are behind the player, so this is
   structural).
5. **Hard cut, not fade-through.** Alpha steps: at most **two levels** in a lifetime
   (e.g. 0.45 → 0.28 for the dash copies as separate copies, but each copy is constant
   while alive). A smooth multi-step fade reads as a trailing ghost = magical; a cut
   reads as a perception *imprint* = psychological.
6. **Read order preserved:** player body → weapon line → echo fringe → enemy →
   background. If any frame inverts that order, the echo is mispositioned.
7. **It must be understandable AFTER the fact** (exit-gate item 20): a player watching a
   replay frame-by-frame should see "the same man, twice, in slightly the wrong place"
   — never "what is that shape?"

---

## 6. Suppression rules (when echoes must NOT appear)

Readability is preserved by subtraction. Echoes are suppressed when:

1. **On any whiff** — trigger is confirmation only (§2.1). A miss must stay empty; this
   is what keeps hit-vs-whiff legible.
2. **During the perception transform** (0.465 s) — the transform is already the loudest
   presentation beat on screen; echoes during it would stack two fracture events.
3. **During the Blink transition / veil** (0.28 s) — the veil already owns the screen;
   echoes spawn only on a post-arrival confirm.
4. **While another echo event is alive** — a new confirm replaces it (never two events
   concurrently). Hard ceiling: **max 2 phantom silhouettes on screen at any moment**
   (only the Dash tier reaches 2; Normal and Blink are 1 each).
5. **On the weapon break / finisher payoff** (5th use) — the deterministic break is its
   own spectacle; echoes yield the frame to it.
6. **While the player is in the hurt state** (iframe window) — no echo may fire off a
   hit landed while reeling; it would double up with the hurt pose.
7. **On enemy-landed hits on the player** — echoes are exclusively the protagonist's
   self-dramatization; the enemies never get them (their channel is saturated colour,
   not white).
8. **Never during hitstop > the tier's own window is *not* a suppression** — the
   opposite is true: the echo is *designed* to be seen in the frozen frame; hitstop is
   its stage. (Stated here so implementers don't "clean up" the overlap later.)

---

## 7. Integration with Blink / weapon / combat

- **Combat hook:** `swing.landed_hit` confirm → read entry state
  (`_struck_from_dash`, arrival rhythm) → pick tier → spawn copy of current pose → live
  N frames → cut. No new signals are required beyond what the swing already emits; the
  impact snapshot (`_impact_hitstop`, snapshotted at swing start) tells the echo which
  tier strength it may *display* (armed hits may display +2 px extra offset; bare-hand
  uses base offsets) — display only.
- **Weapon integration:** echoes use the pose, and the pose includes the weapon layer —
  armed echoes show the blade, bare-hand echoes show the empty hand. Same trigger rules
  for both (bare-hand hits also echo: the delusion does not require the weapon; the
  weapon only sharpens it).
- **Blink integration:** Blink contributes **exactly one thing** — the third tier
  (Blink Hit Echo on the first post-arrival confirm). No new Blink power, no cooldown
  interaction, no change to `blinkables`, transition (0.28 s), or `ARRIVE_TIME`
  (0.16 s). Echoes are suppressed during the transition (§6.3).
- **Hitstop/stage:** the confirm frame lands inside hitstop (0.045 / 0.075 / 0.10 s) —
  the echo is born frozen, which is precisely why a 4-frame lifetime is enough to read:
  2–3 of those frames are *held still* by the freeze.
- **Camera:** echoes never add shake. Existing shake caps (0.6) are untouched.
- **Identity document coupling:** colour channel, z-order and pose source are defined
  in `CHARACTER_VISUAL_IDENTITY.md` §3; this document may not contradict it.

---

## 8. Visual-only vs. possible future mechanics

| aspect | status now | could it ever become mechanical? |
|---|---|---|
| phantom copy on confirm | **visual only** | **No.** An extra hitbox would convert a perception joke into a clone-attack system — explicitly banned by this feature's definition and by the project's "no extra hitboxes" rule. |
| tier differences (normal/dash/blink) | display only | **No damage or timing changes.** If ever tuned, only the *offsets/alphas/durations* in §3 may move. |
| echo as combo/scoring signal | not present | Possible *later* as a UI read (e.g., an accessibility toggle "show echo feedback"), still with zero gameplay effect. |
| echo intensity slider | not present | The one sanctioned future change: an **accessibility opacity option** (0 % / 50 % / 100 %). Does not change gameplay. |
| echo charges / echo as resource | **never** | Would break the feature's meaning. Do not. |

**Rule: the only numbers in this feature that may ever affect gameplay are… none.**

---

## 9. Strict anti-slop rules

1. **No new FX are permitted to be added to make echoes louder** — no particles, no
   glow, no bloom, no chromatic aberration, no RGB split, no motion-streak lines, no
   sparks, no shockwaves, no rings.
2. **No camera effects:** no shake, no zoom, no flash, no time freeze from echoes.
3. **No randomness:** no random offsets, angles, alpha, lifetime, or spawn position.
4. **No stacking:** max 2 silhouettes; queue depth 1; a new confirm replaces the old.
5. **No duration creep:** the per-type lifetimes (4/5/6 frames) are the ceiling, not a
   starting point. If an echo needs *longer* to read, it is mispositioned — fix
   placement, not duration.
6. **No echo on locomotion.** Running, jumping, dashing, Blink travelling, transform —
   none of these echo. Echoes exist **only** on confirmed hits. (Afterimage trails on
   movement are a different, banned feature.)
7. **No new colour, no new shape family.** Echoes are copies of an existing frame in an
   existing palette channel.
8. **No gameplay coupling** (§8). No new input, no new HUD element, no tutorial text.
9. **No implementation in this pass** — this is a direction lock (PHASE 9). The next
   build step, if approved, is a single read-only probe that renders one static echo
   copy for a look review — see `VERTICAL_SLICE_ART_PLAN.md`.
10. **Refuse-list compliance:** everything on the project's standing refuse list
    (glow-as-signal, amorphous particles, continuous pulsing, full-screen effects,
    camera spam, randomness in state) applies verbatim to this feature.

---

## 10. Storyboard C — DELUSION ECHO COMBAT

| beat | purpose | pose / presentation | framing | timing | must be readable | emotion |
|---|---|---|---|---|---|---|
| **C1 normal hit echo** | baseline self-dramatization | real body holds contact pose (planted, extended) **+ one phantom 12 px ahead, +0.12 rad, α 0.40**, feet on ground line; enemy mid-recoil beyond | camera static; both player and enemy fully in frame | spawn on confirm (inside 0.045 s hitstop), alive **4 frames (0.067 s)**, hard cut | TWO of the same man, the front one slightly wrong — and the enemy untouched by the phantom | *"I hit harder than that."* — vanity, self-aggrandizement |
| **C2 dash hit echo** | violence along the line of motion | real body in dash-contact (lean 0.32) **+ two trailing phantoms at −16/−32 px on the motion line, +0.08/+0.16 rad, α 0.45/0.28**; trail occupies the space just crossed | camera static; the trail must fit in-frame behind the player | spawn on dash confirm, alive **5 frames (0.083 s)** through the 0.075 s armed hitstop, hard cut | a three-frame comic strip of ONE motion compressed into one instant; enemy clear at the far end | *"I was already through."* — momentum as violence |
| **C3 blink hit echo** | perception rupture | real body in front of the target in contact pose; **one phantom BEYOND the enemy's far edge, facing BACK, α 0.50**, on the ground line | camera static; enemy between the two figures | spawn on the post-Blink confirm, alive **6 frames (0.10 s)**, hard cut | the impossible triangle: player here — enemy there — *me, behind them, looking back* | *"I was already behind them."* — derealization, the self unmoored from place |

**Frame-level beat structure shared by all three:** frame 1 = confirm + echo cut-in
(frozen by hitstop) · frames 2..N = held imprint while the enemy's recoil extreme holds
· final frame = echo cut out, real body releasing toward recovery. The echo and the
recoil **end together** so the hit reads as one event, not two.

---

## 11. Open questions for human review

1. Does the normal echo at α 0.40 / 12 px read as *a second self* or as a rendering
   artifact at speed? (If artifact: increase separation, not alpha.)
2. Is two trailing copies on the dash tier too close to clone spam? (Fallback: cut copy
   B to α 0.20 or drop to one copy at −24 px.)
3. Is the Blink phantom's reversed facing legible in 0.10 s, or does it read as an enemy
   spawning? (Fallback: keep facing same-way and rely on impossible *position* alone.)
4. Does 4 frames (0.067 s) feel too short without a Play session confirming the
   hitstop hold covers it?
5. Do echoes on **bare-hand** hits feel right, or should the delusion only show when
   armed? (Recommendation: keep for both — the delusion is the protagonist's, not the
   weapon's — but this is a taste call.)
