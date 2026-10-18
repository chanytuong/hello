# PERCEPTION WEAPON EXPERIMENT — storyboard + implementation record

Prototype-only micro-experiment for NEVERLOOKBACK. **One** ordinary object,
**one** sub-0.5s perception transformation, **one** weapon attack, in the
**existing arena only**. This is not a weapon system, not a roster, not a
progression system.

Reference script: `scripts/prop.gd` (class `NLBProp`), scene `scenes/prop.tscn`.
This document is written from the code as it actually runs.

> **Revision 2 — FINAL PROTOTYPE FEEL PASS.** The original experiment answered
> *"can a mundane object become a perception weapon."* This pass answers
> *"does it read as a PERCEPTION FRACTURE rather than a power-up, and does the
> combat read as body-driven rather than as a rectangle sliding sideways."*
> §0 and §2 were rewritten accordingly; §8–§10 are new. Every timing below is
> measured, not intended.

---

## 0. Refuse list (from the storyboard gate)

Anything below is out of bounds for this experiment:

- glow / bloom as the primary "something changed" signal
- amorphous particle clouds; continuous pulsing
- a uniform colour change with an unchanged silhouette
- **a colour flash as the "it transformed" cue** (removed this pass — a flash
  says *"the item lit up"*, which is exactly the power-up reading)
- full-screen flash, screen-wide time freeze, camera move
- **any gameplay lock during the 0.465s** (input, movement, dash, Blink all live)
- random glitch spam; FX that covers the player
- random animation, random inputs, unpredictable movement, camera spam,
  unreliable hitboxes (the "controlled insanity" must come from *body language*)
- an inventory, a menu, rarity, loot, stats, upgrades, a pickup animation
- new Blink powers, a second weapon, combo trees, damage/balance redesign

Readability comes from: pose, silhouette, motion, timing, impact, enemy
reaction, spacing, and *controlled* FX. **Not** from particles or light.

Verified absent in the codebase (grep, this pass): no `FLASH_COL`, no `_flash_t`,
no `Ghost` node, no swoosh overlay, no `CPUParticles`/`GPUParticles`, no glow,
no bloom.

---

## 1. The one object

| | |
|---|---|
| Object | a metal pipe (not the final canonical weapon) |
| Slot | world **(575, 594)** — on the floor inside the hazard strip (x 500–650, y 568–600) |
| Reality form | **three** overlapping dull bands `Reality/Seg1..3`, each 46×8, `Color(0.60, 0.62, 0.66)`, **stacked at the same transform** so at rest they read as one solid bar. They are the fracture primitive: because they share a pivot, any per-band offset/rotation *is* a misregistration of the same object, not a second copy of it. |
| Hero form | **three** rects under `Hero`: `Blade` (2,−5)→(84,5) 82×10 `Color(0.98,0.99,1.0)` · `Guard` (1,−12)→(8,12) 7×24 `Color(0.26,0.23,0.21)` · `Grip` (−16,−3)→(2,3) 18×6 `Color(0.20,0.18,0.16)` |
| Silhouette change | reality width **46px** → hero width **100px**, single bar → blade+crossguard+grip. Value contrast does the work (near-white blade against dark grip/guard) — no glow. |

**Removed this pass:** `Ghost/Bar` (a second copy) and the `FLASH_COL` colour
flash. Both were *additive* cues — a duplicate object and a light event. A
duplicate says *"there are two of them"* and a flash says *"the item lit up"*;
neither says *"your perception of this one object stopped agreeing with itself."*
The three bands keep **one** object and make it *misregister*. Subtractive, not
additive.

---

## 2. Storyboard — five beats, total **0.465s**

Gameplay is **never** locked; the player can run, jump, dash, Blink and swing
through every beat. Camera: **no move**. Time: **no freeze** (`Engine.time_scale`
is untouched). Audio: `NLBAudio.play()` placeholders `&"pickup"`, `&"transform"`,
`&"break"` (the hook is a stub today).

Beats are gated by absolute time constants (not a table of durations), so one
edit can only move a boundary — no beat can silently grow:

```
TRANSFORM_TIME 0.465 · BEAT_OVERLAP 0.070 · BEAT_FRACTURE 0.170
BEAT_PEAK 0.240 · BEAT_SNAP 0.285 · POSE_SNAP_END 0.345 · settle 0.18s (cubic ease-out)
```

**PHASE 3 — the peak is HELD, not just touched.** `BEAT_C` normalises `k` over
`(BEAT_PEAK − BEAT_FRACTURE)` instead of running to the snap, so the fracture
reaches maximum disagreement at **0.240** and then **stops moving** until
**0.285**. Measured by `tests/probe_transform.gd` (new, read-only):

| t | reality scale | reality rot | bands (Seg1/2/3) | hero |
|---|---|---|---|---|
| 0.189 | (1.33, 0.79) | +0.21 | −0.16 / +0.11 / −0.08 | α0.56 |
| 0.235 | (1.76, 0.51) | +0.38 | −0.56 / +0.37 / −0.28 | α0.92 |
| **0.255** | **(1.80, 0.48)** | **+0.40** | **−0.60 / +0.40 / −0.30** | α1.00, scale 1.08 |
| **0.269** | **(1.80, 0.48)** | **+0.40** | **−0.60 / +0.40 / −0.30** | identical |
| 0.289 | *reality gone* | — | — | scale **1.38**, pose **1** |

The row is bit-identical across the peak, and the frame before it differs by
~2% — so the eye gets **≈3 visually-static frames** of maximum fracture before
the snap. That is the difference between an authored beat and a rendering bug,
and it cost **zero net time** (the hold is *inside* the old 0.170→0.285 ramp).
The hero is deliberately kept **wrong** through the hold (offset `(6,−3)`, rot
`HOLD_ROT−0.16`, scale 1.08) so reality and hero are still disagreeing when the
snap lands.

| # | beat | window | player | object / hero | why it is perception, not power |
|---|---|---|---|---|---|
| **A** | *lift* | 0.000–0.070 | reaches/coils: pose **0** → scale (0.90,1.16) lean **−0.20** | bar lifts **26→0**, squashes **(0.84,1.22) → (1.10,0.94)** | the **hand participates** — the body reaches for the object before the object moves |
| **B** | *overlap* | 0.070–0.170 | holds pose 0 | reality at **(−9, +4)** rot **+0.14** scale **(1.16,0.90)**; hero enters at **(15,−9)** rot **HOLD_ROT−0.26** α0.42 scale 1.14 | **real double-image**: reality *and* hero on screen together, offset — the same object seen twice |
| **C** | *fracture* | 0.170–0.240 ramp, **0.240–0.285 HELD** | holds pose 0 | reality scale → **(1.80,0.48)** rot → **+0.40** while the three bands **separate independently** (Seg1 (−3,−12)/−0.60 · Seg2 (−8,+11)/+0.40 · Seg3 (+11,−8)/−0.30); hero registers to α1.0 but stays misaligned at **(6,−3) / HOLD_ROT−0.16 / 1.08** | the silhouette **tears** — angular break, not a colour change — and then **stops moving**, so the disagreement reads as a held pose |
| **D** | **snap** | **0.285** (hard, no easing in) | pose flips to **1**: scale (1.16,1.24) lean **+0.24**, blend **δ·46** | reality **reset + hidden**, hero **α1.0 scale 1.40 rot HOLD_ROT−0.34** | a **1-frame hard snap** — misregistration resolves in zero time. This is the frame the eye reads as *"it re-decided"*. |
| **E** | *settle* | 0.285–0.465 | pose 1 → pose **2**, blend δ·18 | hero eases scale 1.40→1.0, rot →**HOLD_ROT −0.66** over **0.18s**, cubic ease-out | a very short overshoot + settle; residual distortion is **exactly zero** at rest |

`perception_pose` is owned by `prop.gd` and rendered by `player.gd`
(`0` reach/coil · `1` recoil at snap · `2` settle · `-1` released). It is reset
in `_reset_free()` and `_do_break()`, so a broken pipe never leaves the body
stuck mid-pose.

The hard swap is a **node visibility flip**, not a morph: `Reality.visible=false`
/ `Hero.visible=true` on the same frame. A colour morph would keep the same
silhouette and fail the readability gate.

Frame-driven (`_advance_transform` in `_process`) rather than a `Tween`, so the
timeline is deterministic and assertable.

**Force-snap.** If the player commits to violence mid-fracture
(`_atk_t >= 0.0 && _tf_t < BEAT_SNAP`), `_tf_t` jumps straight to `BEAT_SNAP`.
Intent resolves the fracture on the frame it becomes intent — otherwise a
half-broken bar can be rendered underneath a live swing arc. Gameplay is not
locked; the *perception* is.

Measured in `tests/test_weapon.gd`: `transformation finishes under 0.5s (0.468s)`,
`reality AND hero shown together`, `reality silhouette tore apart BEFORE the swap`,
`player body pose driven by the perception break`, `perception pose released at
rest (pose=-1)`.

---

## 3. Pickup (no UI, no key)

- **Auto on touch**: |dx| ≤ 26 and |dy| ≤ 44 between the player origin and the
  pipe. No new input action was added to `project.godot`.
- Blocked while `fight_frozen` (mid-Blink) or the player is dead.
- On touch: `state = HELD`, `player.set_armed(1.0, false)`, `landed_hit`
  connected, HUD message `"PIPE - longer reach, harder shove. It breaks after 5 hits."`
- One-shot proximity hint before the first pickup (State A): *"THE PIPE SITS IN
  THE HAZARD - BLINK TO TAKE IT CLEAN."*, State B: *"WALK OVER THE PIPE TO TAKE IT."*

---

## 4. The one weapon attack

Same input (J/Z/LMB), same startup / active / recovery / cooldown / step / buffer.
**The controller must feel identical** — only the resolution changes.

| value | bare hands | pipe | finisher (5th confirmed hit) |
|---|---|---|---|
| reach | 82 | **104** | 104 |
| swing radius (shape, pos unchanged at (40,−20)) | 42 | **64** | 64 |
| knockback `(x, 0)` | 260 | **460** | **660** |
| hitstop | 0.045s | **0.075s** | **0.100s** |
| bite (velocity kept on confirm) | 0.55 | **0.35** | **0.25** |
| shake (`add_shake`, cap 0.6) | 0.30 | **0.48** | **0.60** |
| damage | 1 | 1 | 1 |

Knockback stays **horizontal by construction** (`y = 0`), so the weapon never
turns into a launcher. Reach grows by radius only: the near edge stays behind
the body, the far edge grows.

Impact (hitstop/shake) is **snapshotted at swing start** in
`player._impact_hitstop/_impact_shake`. The prop reacts to `landed_hit` before
`game._on_player_hit_landed()` runs (the player connects to `swing_box.landed`
first), so reading live `weapon_power` at confirm time would have let the prop
rewrite its own payoff — the 4th hit would inherit the finisher's numbers and
the 5th would inherit bare hands.

**Wear + break.** 5 confirmed hits (whiffs do not spend a use). Wear desaturates
`Hero` progressively so the last swing reads as *chosen*. On the 5th confirm the
pipe splits deterministically (blade/guard/grip separate, fade over 0.24s),
the player drops to bare hands, and the pipe respawns at its slot after 4.0s.

**Prop swing animation** — the blade's arc, on the prop itself so the weapon
motion matches the hitbox instead of hovering. `k` is normalised time:

- **raise** (0 → startup): `_tf_rot → _raise`, eased in with `k*k` — the blade
  *drags* behind the torso instead of snapping upright. `_raise = _tf_rot − 0.89`
  standing (`−0.40` shorter when struck from a dash, so the dash swing stays
  compact and forward).
- **strike** (startup → active end): `1−(1−k)²` — fast in, slow through — from
  `_raise` to `_over = _tf_rot + 0.92` (`+0.96` from a dash).
- **recovery — this is where hit and whiff diverge**: on a confirm the blade
  lerps **straight back to `_tf_rot`** (arrested, the body absorbed it); on a
  whiff it **keeps going** to `over + 0.20`, peaking at `k2 = 0.35`, then
  settles. A whiff gets a free follow-through; a hit does not. The split was
  chosen over mid-arc arrest because arresting the arc at the moment of contact
  made the blade pop.

Idle and recovery both settle onto `_tf_rot`, so a swing ending mid-transformation
cannot pop the prop.

---

## 5. Body-driven attack (PHASE 4) — anticipation / strike / contact / follow-through / recovery

The attack reads from `_atk_t`, not from a rectangle sliding sideways. Every
phase writes **one** target (scale, lean) and the body lerps to it with a
phase-specific blend rate, so unequal timing does the work rather than
uniform speed:

| phase | window | body target | blend |
|---|---|---|---|
| **anticipation** | 0 → `attack_startup` (0.05) | scale (1.0,1.0)→**(0.80,1.28)**, lean 0→**−0.42·facing**, ease-in | **δ·40** (slow — it is loading; was δ·26, which only ever reached ~64% of the coil) |
| **strike** | `attack_startup` → active end | front-loaded toward the contact pose | **δ·44** (fast — it is committing) |
| **contact** (`_bite_done`) | the whole active window | **(1.16,1.16)** lean **+0.26·facing** (standing) / **+0.32** (from a dash), and it **HOLDS** | **δ·52** (arrives in ~1 frame) |
| **follow-through — whiff** | active end | extends to **(1.48,0.78)** lean **+0.34** standing / **(1.56,0.74)** lean **+0.36** from a dash | δ·30 |
| **recovery** | recovery (0.08) | to neutral; on a hit it starts **from the contact pose**, on a whiff from the active-end pose — same numbers, so there is **no seam** | δ·30 |

Weight past the vertical, counter-rotation on the wind-up, overcommitment past
the support base — all expressed through *target pose + blend rate*, never
through a randomiser.

**The confirmed-hit anchor is a pose, not a lock.** On a hit the body stops
extending and braces; on a whiff it keeps travelling. Measured whiff travel
**195px** vs hit travel **124px** from the same velocity curve — that is the
whole point of the anchor (PHASE 10: it is not re-designed here).

**The hitbox now follows the declared timeline.** `swing_box.begin()` used to be
called on the swing-start branch *as well as* from the timeline check, so a hit
could resolve at `_atk_t == 0` on the very first frame of the anticipation.
Consequences observed in `tests/probe_feel3.gd`: hitstop froze a frame in which
the blade was still at rest and the body had barely moved, i.e. the freeze framed
the *wind-up* and the real contact pose arrived ~0.12s later. The start-branch
`begin()` is removed: the box is **off through startup, live from
`attack_startup`**. Re-measured:

- contact lands on the first active frame (`_atk_t == 0.050`)
- the frozen frame is **body already extended into the strike (r ≈ +0.18,
  scale 1.12/1.17) with the blade still at its raised apex (arc ≈ −1.15)** —
  body leads, weapon lags, exactly the drag principle
- the blade then smashes down through the target *after* the freeze releases
- contact pose reaches **r +0.260, scale (1.16,1.16)** and **holds f28–f33
  (6 frames)**, neutral by +0.20s after contact

**PHASE 4 defects found and fixed in the pose layer (before → after):**

| defect | was | now |
|---|---|---|
| coil never reached its own target | blend **δ·26**, so only ~64% of (0.84,1.22)/−0.34 was ever shown | blend **δ·40**, target deepened to **(0.80,1.28)/−0.42** |
| **whiff→recovery seam** | recovery restarted at lean **+0.34** while the active pose ended at **+0.30** — a 0.04 rad lurch at the follow-through edge | both arms now start from the *same* number (standing 0.34, dash 0.36, contact 0.26/0.32) |
| contact leaned back from a dash | contact lean was a flat **+0.20** regardless of how it was started | **+0.32 from a dash / +0.26 standing** — the body plants, it never recoils from its own blow |

Measured (`probe_feel3` **Q1**, standing whiff): coil **−0.353** at f10 →
active **+0.340** at f16, **span 0.693 rad** (was 0.519), scale
**0.83 → 1.45**, and the f17→f18 active→recovery hand-off descends
**+0.340 → +0.312** continuously — the seam is gone.

All 7 suites stayed green after the change (see §7).

---

## 6. Dash → attack is ONE gesture (PHASE 5)

No new attack; the same swing. The rule is *no dash → STOP → swing*:

- the dash-strike anticipation has **no backward coil** — it **starts exactly
  on the dash posture** (scale (1.34,0.80), lean **+0.30**) and loads *further
  forward* (`(1.38,0.76)`, lean **+0.32**) instead of starting behind it, then
  the strike continues to `(1.56,0.74)`, lean **+0.36**
- swing start preserves dash momentum: `vx 710 → 710` at the moment `_atk_t = 0`
  (audit `P7` delta = 0)
- shorter blade raise (`−0.40` vs `−0.89`) and a later overshoot (`+0.96`) keep
  the arc compact while moving forward

**PHASE 5 defect found and fixed.** The old anticipation target *began* at
(1.24,0.94) — **behind** the dash posture — so `probe_feel3` Q2 showed
`scale.x 1.33 → 1.29 → 1.28` across frames 8–10: a visible backward
reversal inside a gesture that has to read as one. Q2 is now strictly monotonic
in both channels:

| frame | 3 | 5 | 8 | **9 (swing starts)** | 11 | 13 | 16 | 19 |
|---|---|---|---|---|---|---|---|---|
| `scale.x` | 1.15 | 1.28 | 1.33 | **1.34** | 1.36 | 1.40 | 1.47 | 1.55 |
| lean | 0.130 | 0.245 | 0.290 | **0.297** | 0.310 | 0.348 | 0.360 | 0.360 |

That row — the hand-off frame (9) sits *between* its neighbours — is the proof
of "one gesture". Deterministic; no input-dependent branching beyond `facing`
and `from_dash`.

---

## 7. Whiff vs hit (PHASE 6) and enemy reaction (PHASE 7)

**Whiff** — free arc, no hitstop, no camera shake, no enemy reaction:

| | whiff | hit |
|---|---|---|
| anticipation | scale → (0.897,1.142) lean −0.22 | **identical** |
| hitstop (`Engine.time_scale`) | **1.0 the whole time** | **0.05** for ~5 frames |
| camera shake | **0.0 the whole time** | **0.6 → 0** over ~25 frames |
| body at the active window | keeps extending to **(1.48,0.78)** lean **+0.34** | **arrested at (1.16,1.16) lean +0.26, held 6 frames** |
| player velocity | slides free 60→132→0 | brakes to 0 via `weapon_bite()` (0.35 armed) |
| travel | **195px** | **124px** |
| enemy | keeps walking, no scale/rot change | recoil + lean + squash, separation |

**Enemy reaction** — no animation system, only `move_and_slide()`-driven pose,
applied *after* the physics step so it can never affect gameplay:

- `RECOIL_TIME 0.18`, armed **on the contact frame**, `_recoil_dir = facing`
- `_recoil_t = maxf(_recoil_t − delta, 0.0)` — clamped in **both** enemy scripts
  (the unclamped `−= delta` could go negative and produce a bogus `e` for one
  frame)
- visual only: directional lean **r +0.420**, stretch/squash **(1.28, 0.66)**
  along the blow, decay to (1.0,1.0)/r 0 by **+0.18s** with **~18–50px** of
  horizontal displacement
- **no vertical launch, no ragdoll, no spin, no uncontrolled physics** — `vy`
  stays 0 through the whole reaction (audit `P2 foeVyMax=0`)
- immediate recovery: the AI resumes `CHASE` the moment `e` hits 0

**PHASE 7 — three defects found and fixed:**

1. **The pivot was at the top-left corner.** `Body` is a `ColorRect` with
   `offset_*` set and no `pivot_offset`, so Godot's default pivot was the
   control's top-left — the recoil rotated about the *head*, and at
   `scale.y = 0.66` the feet rose from y=+2 to y≈−10, i.e. the enemy
   **visibly floated ~12px off the floor every time it was hit**. Fixed by
   `pivot_offset = Vector2(16, 40)` (melee) and `Vector2(15, 38)` (ranged) —
   exactly the bottom-centre of each rect. Feet now stay planted: the squash
   reads as a crouch and the lean reads as a body tipping over.
2. **The contact pose was never actually read.** `e` decayed linearly from the
   frame it appeared, so it was already fading by frame 1. Now
   `e = clamp(raw × 1.25, 0, 1)` **holds the extreme for the first 20% of
   `RECOIL_TIME`** (0.036s) and then releases. `probe_feel3` Q3:
   **f23–f27 = `r +0.420, s(1.28,0.66)` — bit-identical for 5 frames**
   (extended by hitstop), then eased out to 0 by f37.
3. **An FX was hiding the pose.** The white hurt-flash ran **0.07s** — longer
   than the hold above — so a uniform colour change with an *unchanged*
   silhouette covered the very frames the recoil was meant to be read in.
   Cut to **0.03s** (PHASE 10): two frames mark the contact, then the colour
   returns while the pose is still at full strength. `probe_feel` S1_ENEMY
   shows `col → white` at f11–f13 and `col → normal` at **f14 with scale still
   (1.28,0.66)`**.

Also removed in PHASE 10: `_pop_t` was declared, armed (`0.12`) and decremented
in **both** enemy scripts but never read — dead residue of the deleted uniform
hit-pop. Grep for `_pop_t` now returns nothing.

---

## 8. Controlled insanity (PHASE 8) — where it comes from

Explicitly **not** from random inputs, camera spam, screen-wide glitch, or
unreliable hitboxes. It comes from four places that are all still in place:

1. **the perception fracture** — three bands misregistering, a 1-frame hard snap
   with a 0.18s settle, while the player keeps running and swinging through it
2. **overcommitment** — lean past the support base (**+0.42** on the wind-up,
   **+0.34/+0.36** at the end of the strike) and a whiff that overshoots to
   `over + 0.20`; measured standing-whiff span **0.693 rad** (was 0.519)
3. **rapid recovery** — a 0.08s recovery and a 0.35s cooldown that puts control
   back in the player's hands quickly, *after* the commitment has been shown
4. **Blink timing** — the arrival stance (`_arrive_t`, `ARRIVE_TIME 0.16`) that
   lands the body already set

Camera: shake is only ever a consequence of a confirmed hit (cap 0.6), never
spam. Hitboxes: rect + resolution order, deterministic, and camera shake never
moves them.

---

## 9. The one Blink relation (PHASE 9)

**Blink changes access to the object — nothing else.** Blink architecture is
untouched: no new powers, no new states, no change to `blinkables`.

- State A: the hazard strip under the pipe is live (1 HP, gated by 1.0s player
  iframes) → retrieving it costs a hit point.
- State B: the strip is dead → retrieving it is free.

The prop is **not** in the `blinkables` group, so `apply_blink()` never touches
it: Blink never transforms, moves, consumes or re-rolls the pipe. Verified in
`tests/test_weapon.gd` phase 8.

What *did* change is how combat sits **around** Blink:

- **arrival stance**: `set_fight_frozen(false)` arms `_arrive_t = ARRIVE_TIME
  (0.16)` only on the frozen→unfrozen **edge**, so repeated `false` calls (the
  tests fire them constantly) do not pose the player. During those 0.16s the
  body holds scale **(1.08,0.98)** lean **+0.20** at blend **δ·52** — the veil
  lifts onto a body that has already landed.

  **PHASE 9 defect found and fixed.** The old pose was **(1.10, 1.14)** at
  blend δ·30: it stretched the body *larger in both axes* on the frame it
  reappeared (a pop / random stretch), and because δ·30 only asymptotes onto
  the target, it hit its **peak on the very frame it expired** — swell, peak,
  release, i.e. a pulse rather than a stance. It now settles its weight
  *down* and leans forward, and lands at **δ·52** so it has time to hold.
  `probe_feel3` Q5: neutral → **+0.200 / (1.08,0.98) over 2 frames (f18–f21)
  and held identically f21–f27 (7 frames)**, then eased out over ~0.3s.

  The first fix used **δ·60, which is *exactly* 1.0 at 60fps** — a one-frame
  snap that would silently become a 5-frame ease on a 144Hz display. δ·52 is
  the same rate as the contact pose: hard events land poses the same way, and
  no constant is tuned to a frame rate.
- the veil still spans the full transition; `audit_combat` `P8` reports
  `dead_frames=0/18`
- `probe_feel` S4: 17-frame transition, platform pop scale 1.077, shake 0.3,
  veil α 0.48 → 0

Rhythm around Blink (all three tested): **Blink → attack** lands on the arrival
stance and flows into anticipation · **Blink → dash → attack** the arrival pose
hands off to the dash posture which hands off monotonically to the swing ·
**dash → Blink → attack** the veil covers the dash end, the arrival stance is
the coil for the next swing.

---

## 10. Scope kept out

No Room 2, no chapter, no arena redesign, no weapon roster, no progression, no
final art, no combo system, no inventory, no second weapon. Core verbs remain:
run, jump, dash, Blink, one weapon attack. No new input action was added to
`project.godot` (A/D, Space, Shift/L, J/Z/LMB, K/X/E/RMB, R).

---

## 11. Test coverage (all green)

**7 suites, all `ALL PASS`:** `test_arena` · `test_runtime` · `test_feel` ·
`test_strand` · `test_killblink` · `test_identity` · `test_weapon`.
`--import` clean; `audit_combat` reports no `FAIL` lines (exit 0).

`tests/test_weapon.gd` (the one suite that deliberately does **not** park the
prop) asserts: authored slot inside the hazard strip · walk-over pickup with no
key · **transform under 0.5s (0.468s)** with an attack accepted *during* it ·
**reality AND hero shown together** · **reality silhouette tore apart BEFORE the
swap** · **player body pose driven by the perception break** · **perception pose
released at rest (pose=-1)** · armed reach, kb, hitstop, bite and radius all
differ · armed separation ≫ bare-hand separation (measured **49.4px vs 18.1px**)
· horizontal-only knockback · 5 uses → finisher → break → respawn at slot · the
finisher's impact snapshot survives the break · Blink deactivates the strip
without touching the prop.

The other six suites park the prop at (1190, 200) via a `_park_prop()` helper
in their `_snap` so they keep measuring **bare hands**.

**`tests/audit_combat.gd`** (read-only instrumentation, no assertions):
`P1 MISS` (confirm=false, shakeMax=0, tsMin=1.0) · `P2 HIT` (tsMin=0.05,
shakeMax=0.340, confirm=true, plyVyMax=0 foeVyMax=0, foeHp 4→3) · `P3 DRAG`
192px/100% · `P4 BULLDOZE` 0px · `P4b gapMin=30 frames_below_30=0/200` ·
`P7 vx 710→710 delta=0` · `P8 blink dead_frames=0/18` · `P10 swoosh absent`.
Exit 0, no `FAIL` lines.

**Observation probes (not gates):** `probe_feel` (S1 miss/hit, S3 dash,
S4 blink), `probe_feel2`, `probe_feel3` (Q1 standing whiff · Q2 dash-strike ·
Q3 armed hit body+enemy · Q4 pickup pose · Q5 release),
**`probe_input`** (PHASE 8 input-trust sweep, see §12) and
**`probe_transform`** (new — the frame-by-frame fracture timeline used to
verify the held peak in §2).

---

## 12. PHASE 10 responsiveness numbers (measured) — buffer changed in PHASE 8

Per the brief: *do not redesign balance; only soften the anchor if manual play
feels like input lag.* No damage, cooldown, hitstop or anchor value was
altered. **One input-trust defect was found by measurement and fixed.**

| | value | notes |
|---|---|---|
| player HP | 5 | iframes 1.0s vs melee touch, 0.25s hazard tick |
| melee HP | 4 | 1 damage per confirm → **4 hits** |
| ranged HP | 3 | → **3 hits** |
| weapon damage | **1** (unchanged) | reach 82→104, kb 260→460, hitstop 0.045→0.075, bite 0.55→0.35 |
| ⇒ weapon erases encounters? | **no** | same hit count as bare hands; it changes *spacing and feel*, not time-to-kill |
| ⇒ sponges? | **no** | 3–4 hits either way |
| `attack_startup/active/recovery/cooldown` | 0.05 / 0.12 / 0.08 / 0.35 | `total_attack_time() = 0.25s` |
| **time to next swing** | `_atk_cd = 0.35 + 0.25 = 0.60s` from swing start | i.e. **0.35s of dead time after the animation ends** |
| `weapon_bite()` | velocity **multiplier** on confirm, not a duration: 0.55 bare / **0.35 armed** / 0.25 finisher | lower = harder stop = more impact |
| `attack_buffer` | **0.60s** ← was **0.20s** | = exactly one full attack cycle; see below |

### PHASE 8 — the input-trust defect, measured then fixed

`tests/probe_input.gd` (new, read-only) presses attack at fixed offsets after a
swing starts, reads back `Input.is_action_just_pressed` → `_atk_buf` → the frame
the queued swing actually fires, and classifies each case **TRUSTED** (queued
swing fires at the next legal frame) or **DROPPED** (the press was swallowed).

A press is only retained while `_atk_buf > 0`, and the buffer is zeroed by the
swing that starts. So a press at offset `t` survives only while
`t + attack_buffer ≥ _atk_cd = 0.60`.

**BEFORE — `attack_buffer = 0.20`:**

| press registered at | 0.08 | 0.13 | 0.18 | 0.23 | 0.28 | 0.33 | 0.38 | 0.43 | 0.48 | 0.58 |
|---|---|---|---|---|---|---|---|---|---|---|
| result | DROP | DROP | DROP | DROP | DROP | DROP | DROP | DROP | **TRUST** | **TRUST** |

**2 / 10 trusted.** A **0.35s dead hole** — `[0, 0.40)` of a 0.60s cycle —
covered the **entire 0.25s animation** plus 0.15s after it ended. The player
was pressing during a swing they could see, and the press vanished.

**AFTER — `attack_buffer = 0.60`:**

| press registered at | 0.08 | 0.13 | 0.18 | 0.23 | 0.28 | 0.33 | 0.38 | 0.43 | 0.48 | 0.58 |
|---|---|---|---|---|---|---|---|---|---|---|
| result | TRUST | TRUST | TRUST | TRUST | TRUST | TRUST | TRUST | TRUST | TRUST | TRUST |

**10 / 10 trusted**, every one firing at `0.60–0.63` — the next legal swing
frame, never sooner and never twice.

**Why this is not an auto-combo / mash reward.**
- `_atk_buf` is **zeroed by the swing it starts**, so the buffer can hold at
  most one unspent press → the queue depth is **1**, not N.
- Swings only fire from `_update_attack` when `_atk_t < 0` **and** `_atk_cd ≤ 0`,
  so a held button cannot spin: `Input.is_action_just_pressed` fires once per
  physical press.
- The swing itself is uninterruptible during startup/active/recovery
  (`_atk_t < 0` is false), so **animation priority** — not a swallowed press —
  is what enforces commitment. The old buffer was hiding a commitment rule
  inside a defect.

**Not a balance change.** Damage, cooldown, hitstop, anchor and the 0.60s cycle
are all untouched; only the *retention window* now spans the cycle it has to
cover. This was the single most likely source of an "it ate my input" report
and it is now measured closed rather than left for manual play to discover.

Confirmed-hit anchor (PHASE 10): **do not change damage, do not change the
anchor.** It is the fix for identical velocity curves (whiff 195px vs hit
124px). It is documented, not re-tuned.

**Still to judge by hand:** whether 0.60s of retained input ever feels like the
game *actively* swings for you (it should not — it only fires once, on the next
legal frame), and whether the 0.35s of dead time *after* a swing feels like
commitment rather than lag.

---

## 13. What still needs a human (cannot be answered headless)

1. Does the 0.465s fracture read as **perception breaking** rather than **an item
   levelling up**? (visible judgement: is it misregistration or is it a glow?)
2. Is the 1-frame snap at 0.285s *readable* or does it look like a pop/bug? Is the
   **held peak** (3 static frames before it) long enough to read as authored
   without the whole transform feeling slow?
3. Does the three-band tear read as the same object tearing, or as three objects?
4. Does the pickup *reach* (pose 0) read as the hand pulling it in?
5. Does dash → attack read as **one gesture** with real weight, or as a fast
   slide?
6. Whiff vs hit: is the difference **felt** at 60fps, not just measured?
7. Is the frozen frame on a hit (body extended, blade still raised) the right
   beat — or does the blade lag *too* far behind and read as a separate object?
8. Does the enemy recoil look like a body reacting (feet planted, torso whipped
   and held), or like a sprite scaling?
9. Does the 0.35s of dead time *after* a swing feel like commitment rather than
   lag? And does the now-complete 0.60s input buffer ever feel like the game
   swung for you? (§12 — measured 2/10 → 10/10 trusted; the *feel* of it is
   still unproven.)
10. Overall: does the whole thing read as **controlled insanity** without any
    feeling of unreliability?
11. Does the Blink arrival stance read as the body *landing and readying*, or
    as a stutter / a pop on the frame the veil lifts?

Items 1–10 are PHASE 11/12 territory. **No PASS in `PROTOTYPE_EXIT_REVIEW.md`
for a visual/feel criterion may rest on a headless test.**
