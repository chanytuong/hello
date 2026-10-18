**PROTOTYPE EXIT REVIEW — FINAL PROTOTYPE GATE PASS (E:\neverlookback, 2026-10-03)**

**Rule applied:** a visual / feel criterion is never marked PASS on the strength of a
headless test alone. Headless evidence proves *that a number happened*; only a human
Play session can prove *that it felt right*. Where a section says PASS, the non-visual
half is gate-verified **and** the section was hand-reviewed by the developer in an
earlier recorded pass; the visual half is listed explicitly under **Still needs manual
confirmation**. Where this pass itself rewrote visual logic that has never been seen by
a human, the section says **NEEDS WORK**.

**Verdict of this pass: 2 PASS · 4 NEEDS WORK.** See the recommendation at the end.

**Evidence vocabulary**
- **gate** — an assertion in a suite. The 7 suites use `_check(cond, name)`, which
  increments `_failures` and ends with `quit(1 if _failures > 0 else 0)`. A suite that
  is not `ALL PASS` actually exits non-zero.
- **probe** — read-only instrumentation that prints numbers and **cannot fail**:
  `probe_feel`, `probe_feel2`, `probe_feel3`, `probe_input`, `probe_transform`,
  `audit_combat`.
- **manual** — a human Play session. **Not yet done for this pass.**

**Correction to the previous revision of this document.** It labelled several
`audit_combat` lines as "Gate". `tests/audit_combat.gd` contains no `FAIL` string and
ends in an unconditional `quit(0)` — it is instrumentation, never a gate. Its value is
the *numbers* it prints, not a pass/fail. Every `P*` line below is therefore cited as a
**probe**. The real gates are the 7 suites.

**Final verification state of this pass**
- `--import` clean · no `SCRIPT ERROR`, no `Parse Error`, no `Failed loading`.
- **All 7 suites `ALL PASS`** — `test_arena`, `test_runtime`, `test_feel`, `test_strand`,
  `test_killblink`, `test_identity`, `test_weapon` — re-run after *every* edit, including
  the last one.
- Every edited file parse-checked with `--check-only` before the next step; every edit
  verified with `grep`.

---

# Movement

**PASS** *(mechanics: PASS, gate-verified and untouched by this pass · look: pending manual)*

**Evidence**
- Gate: all 7 suites `ALL PASS`; `--import` clean. This pass never touched the movement
  integrator, the input map, or a single movement tuning value (run 280 / accel 2600 /
  rev 4200 / fric 3200, jump −640/1600/×1.8, dash 650/0.15s/0.8cd all unchanged).
- Gate: `test_arena`, `test_runtime` green — coyote 0.10, jump buffer 0.12, cut ×0.45,
  one air dash, hard landing.
- Probe `audit_combat` **P7 DASH→ATK** `vx_at_dash_end=710 → vx_at_swing_start=710,
  delta=0` — dash momentum survives a swing start untouched.
- Probe **P3 DRAG** `travel=192px, ratio=100%` — proximity to an enemy never slows the
  player; only contact blocks (gapMin=30).
- Probe **P4 BULLDOZE** `foe_displaced=0px, gapMin=30, gapMax=31` — walking into a
  chaser no longer carries it, and bodies never interpenetrate.
- Probe `probe_feel3` **Q2** (see Combat for the full table): the dash→swing hand-off is
  monotonic in both `scale.x` and lean; the hand-off frame sits *between* its
  neighbours. The layer that sits on top of movement never reverses the motion underneath.
- Manual: run / jump / dash / skid were hand-reviewed in earlier recorded passes
  (`E:\videotosave\*.mp4`).

**Remaining weakness**
1. The dash posture is a *visual* layer — `scale (1.34, 0.80)` with lean **+0.30** —
   asserted nowhere and never seen by a human in this build. If it is too squashed it
   will read as a sprite stretching rather than a body leaning, and no gate will fail.
2. Landing recovery and the skid are still the two least-instrumented moments in the
   movement set.
3. The Blink arrival pose (see **Blink**) now sits in the same priority chain as the
   skid; a skid can silently override it.

**Still needs manual confirmation**
- Does the dash posture read as *leaning into the run*, not *being stretched*?
- Does the skid → dash → run chain feel continuous at 60fps with the pose layer on top?
- Is there any visible pop when `perception_pose` / `_arrive_t` / `_skid` release into
  neutral while moving?

---

# Combat

**NEEDS WORK**

This pass rewrote the attack read again: deeper coil, faster anticipation, a dash-strike
that no longer reverses, a stronger contact pose, an aligned recovery, a held enemy
recoil with a new pivot, a shortened hurt-flash, and a **change to how much input is
retained**. Every one of those is new visual or feel logic and **none of it has been
seen by a human**. The measurements are strong; a measurement is not a feel.

**Evidence — what was found and fixed (before → after)**

| defect | before | after |
|---|---|---|
| coil never reached its own target | blend **δ·26** → only ~64% of (0.84,1.22)/−0.34 shown | blend **δ·40**, target **(0.80,1.28)/−0.42** |
| whiff → recovery **seam** | active ended at lean **+0.30**, recovery restarted at **+0.34** — a 0.04 rad lurch | both arms start from the same number (standing 0.34, dash 0.36, contact 0.26/0.32) |
| dash-strike **reversed** | anticipation target began at (1.24,0.94), *behind* the dash posture → `scale.x 1.33 → 1.29 → 1.28` over f8–f10 | starts exactly on (1.34,0.80) and loads forward to (1.38,0.76); strictly monotonic |
| contact straightened a dash strike | flat contact lean **+0.20** regardless of entry | **+0.32 from a dash / +0.26 standing** — the body *plants* |
| **input dropped** (PHASE 8) | `attack_buffer = 0.20` → **2/10 presses trusted**, a 0.35s dead hole covering the whole animation | `attack_buffer = 0.60` → **10/10 trusted**, every one firing at 0.60–0.63s |
| enemy pivot at the **top-left** | recoil rotated about the head; at `scale.y = 0.66` the feet rose 12px — the enemy **floated off the floor when hit** | `pivot_offset` set to each rect's bottom-centre; feet stay planted |
| enemy contact pose never read | `e` decayed linearly from frame 1 | `e = clamp(raw × 1.25, 0, 1)` **holds the extreme for 20% of `RECOIL_TIME`** |
| FX hid the body pose | white hurt-flash ran **0.07s** — longer than the hold | cut to **0.03s**; colour returns at f14 while scale is still (1.28,0.66) |

**Evidence — probes and gates**
- Gate: `test_feel`, `test_identity`, `test_weapon`, `test_runtime` all green after every
  change; `test_identity` phase 7 (pose gate at `_pf==10` / `_pf==46`) still satisfied by
  the deepened coil.
- Probe `probe_feel3` **Q1 standing whiff**: coil **−0.353** (f10) → active **+0.340**
  (f16), **span 0.693 rad** (was 0.519); scale **0.83 → 1.45**; active→recovery hand-off
  **+0.340 → +0.312**, continuous — the seam is gone.
- Probe `probe_feel3` **Q3 armed hit**: frozen frame is the **body extended into the
  strike (r +0.178, scale 1.12/1.17) with the blade still at its raised apex (arc
  −1.15)**; contact pose reaches **r +0.260, scale (1.16,1.16)** and holds **6 frames**
  (f28–f33), neutral by +0.20s.
- Probe `probe_feel3` **Q3 enemy**: **f23–f27 = `r +0.420, scale (1.28,0.66)` —
  bit-identical for 5 frames** (extended by hitstop), then eased to 0 by f37; peak
  displacement **+49px horizontal**, `foeVyMax = 0`.
- Probe `probe_feel` **S1 MISS vs S1 HIT** — identical anticipation, then divergence on
  six axes: `time_scale` 1.0 vs **0.05**; shake **0.0** vs **0.6→0**; body extends to
  (1.48,0.78)/+0.34 vs **arrested (1.16,1.16)/+0.26 held**; travel **195px vs 124px**;
  enemy unchanged vs recoil; blade free follow-through vs lerp back to `_tf_rot`.
- Probe `audit_combat`: **P1** MISS `shakeMax=0 tsMin=1.0 confirm=false` · **P2** HIT
  `tsMin=0.05 confirm=true plyVyMax=0 foeVyMax=0 foeHp 4→3 gapMin=30` · **P3** 192px/100% ·
  **P4** 0px · **P7** delta 0 · **P10** `child_node_present=false`.
- Probe `probe_input` (new): the full 10-offset trust sweep quoted above.
- Grep: `FLASH_COL`, `Ghost`, swoosh, particles, glow, bloom absent; `_pop_t` **gone from
  both enemy scripts** (declared, armed at 0.12 and decremented, never read — residue of
  the deleted uniform hit-pop).

**Remaining weakness**
1. **Blade lag at contact.** The hitbox opens at `attack_startup`, which is exactly where
   the blade sits at its apex. On a point-blank hit the frozen frame shows body committed
   and blade raised, and the blade smashes down *after* the freeze. That is legitimate
   drag-and-release staging — and it may read as the weapon arriving after the fact.
   Headless data cannot distinguish those two readings.
2. **Pickup-reach → swing hand-off.** Swinging during the transform hands the body from
   `perception_pose 0` (lean −0.20) to the attack anticipation, so the body briefly
   un-coils ~0.08 rad (~3 frames) before re-coiling. A real non-monotonicity, largely
   hidden under hitstop.
3. **The 0.60s buffer is now generous by design.** Queue depth is provably 1 (the swing
   consumes its own press) and holding cannot spin, but "never drops input" and "plays for
   you" are different ends of one dial, and only eyes and hands say which side this sits on.
4. The enemy reaction is still a *transform*, not animation: correct, cheap, and now
   pivoted and held — but a sprite scale is always one step from looking like a sprite
   scale.
5. `audit_combat` **P2 `shakeMax` measured 0.329–0.350 across runs** (the peak is sampled
   per-frame, so a one-frame scene-startup shift moves it ~5%). Not a gameplay change and
   not gated, but it means probe peaks are not bit-reproducible.

**Still needs manual confirmation**
- Does whiff vs hit land as a *felt* difference at 60fps, or only as a number?
- Is the frozen frame (body extended, blade raised) the right beat, or does the blade lag
  too far and read as a separate object?
- Does the enemy now read as a *body* being struck — feet planted, torso whipped and
  held — rather than a sprite scaling?
- Does the 0.35s of dead time after a swing feel like commitment rather than lag?
- Does the 0.60s buffer ever feel like the game swung for you?
- Does the pickup-reach → swing hand-off flicker visibly?

---

# Blink

**NEEDS WORK** *(architecture: PASS, gate-verified and deliberately untouched · arrival
stance: NEEDS WORK — rewritten twice this pass, never seen)*

**Evidence**
- Probe `audit_combat` **P8 BLINK `dead_frames=0/18`, `transition_done=true`** — the veil
  spans the full transition; there is never a frame of unprotected frozen gameplay.
- Gate: `test_killblink`, `test_identity`, `test_weapon` all green; `test_weapon` phase 8
  asserts Blink deactivates the hazard strip **without touching the prop**.
- Gate/grep: **no change** to `blinkables`, `apply_blink()`, cooldown (4.0s), transition
  (0.28s) or the input map. **No new Blink power was added**, no Blink redesign.
- Probe `probe_feel` **S4**: 17-frame transition, platform pop scale 1.077, arrival shake
  0.3, veil α 0.48 → 0.
- All three rhythms are wired and exercised by the suites: Blink→attack,
  Blink→dash→attack, dash→Blink→attack.

**Evidence — what changed this pass (arrival stance only)**
| | before | after |
|---|---|---|
| pose | **(1.10, 1.14)** — *larger in both axes* | **(1.08, 0.98)** — weight settles **down**, leans forward +0.20 |
| blend | δ·30 → only asymptotes, so it hit its **peak on the very frame it expired** (swell → peak → release = a pulse) | **δ·52** → lands over 2 frames and **HOLDS 7 frames** (f21–f27), then eases out |
| first fix | — | **δ·60, which is *exactly* 1.0 at 60fps** — a one-frame snap that would silently become a 5-frame ease at 144Hz. Rejected and replaced. |

Probe `probe_feel3` **Q5**: neutral → **+0.200 / (1.08,0.98) over 2 frames (f18–f21)**,
held bit-identical **f21–f27**, released over ~0.3s with no jump.

**Remaining weakness**
1. The arrival stance arms on the frozen→unfrozen **edge**, i.e. **after** the veil has
   lifted — so the stance is the first thing seen, and it appears in full view rather
   than being covered by the veil.
2. `ARRIVE_TIME 0.16` is asserted only as *"a pose exists for 0.16s"*. Asserting a pose
   exists is not asserting it looks like landing.
3. δ·52 was chosen to remove a frame-rate dependence, which is an argument about *code*,
   not about *eyes*. Whether 2 frames of land reads as a plant or as a snap is unproven.

**Still needs manual confirmation**
- Does the arrival stance read as the body *landing and readying*, or as a stutter /
  hesitation, or as a pop on the frame the veil lifts?
- Do all three rhythms (Blink→attack, Blink→dash→attack, dash→Blink→attack) feel like
  one continuous intent?
- Is 0.16s short enough to be invisible as a delay but long enough to read as a stance?

---

# Perception Weapon

**NEEDS WORK**

The entire fracture is new, and this is the experiment's headline criterion — *does it
read as perception breaking rather than as an item powering up* — and **no headless test
can answer it**. This pass added the held peak that makes the beat read as authored; it
has never been seen.

**Evidence — what changed this pass**
| | before | after |
|---|---|---|
| total transform | 0.442s | **0.468s** (still under the 0.5s ceiling) |
| fracture peak | ramped continuously into the snap | ramps to **0.240** and **HOLDS to 0.285** |
| snap | 0.260 | **0.285** |
| band tear | Seg1 (−2,−9)/−0.46 · Seg2 (−6,+8)/+0.30 · Seg3 (+8,−6)/−0.22 | **Seg1 (−3,−12)/−0.60 · Seg2 (−8,+11)/+0.40 · Seg3 (+11,−8)/−0.30** |
| reality at peak | (1.62,0.58) rot +0.30 | **(1.80,0.48) rot +0.40** |

The hold was inserted *inside* the existing ramp, so it cost **zero net time**.

**Evidence — gates and probes**
- Gate `test_weapon`, all green: `transformation finishes under 0.5s (0.468s)` ·
  `reality AND hero shown together` (a real double image) · `reality silhouette tore
  apart BEFORE the swap` · `player body pose driven by the perception break` · `perception
  pose released at rest (pose=-1)` · attack accepted *during* the transform with gameplay
  never locked · armed reach/kb/hitstop/bite/radius all differ · armed separation
  **49.4px vs bare ≈18px** · horizontal-only knockback · 5 uses → finisher → break →
  respawn at slot · finisher impact snapshot survives the break.
- Probe `probe_transform` (**new**, frame-by-frame) — the held peak, directly observed:

  | t | reality scale | rot | bands Seg1/2/3 | hero |
  |---|---|---|---|---|
  | 0.235 | (1.76, 0.51) | +0.38 | −0.56 / +0.37 / −0.28 | α0.92 |
  | **0.255** | **(1.80, 0.48)** | **+0.40** | **−0.60 / +0.40 / −0.30** | α1.00, 1.08 |
  | **0.269** | **(1.80, 0.48)** | **+0.40** | **−0.60 / +0.40 / −0.30** | identical |
  | 0.289 | *reality gone* | — | — | 1.38, pose 1 |

  The peak rows are **bit-identical** and the row before differs by ~2%, so the eye gets
  **≈3 visually-static frames** of maximum disagreement before the snap — the difference
  between an authored beat and a rendering bug. During the double image the two copies
  disagree by **~61° of rotation** (reality +0.14 vs hero −0.92). The hero is kept
  deliberately *wrong* through the hold, so both identities are still in conflict when
  the snap lands. Snap → settle ends at exactly `HOLD_ROT −0.66`.
- Grep/refuse list: no glow, no colour flash as the primary signal, no full-screen bloom,
  no camera move, no time freeze, no gameplay lock, no added FX — the power-up cues were
  removed rather than replaced with more particles.

**Remaining weakness**
1. **The 0.285s snap is a 1-frame visibility flip.** By design — a hard perceptual snap
   needs zero duration. Zero duration is also exactly what a *bug* looks like. If it
   reads as a pop, the concept fails and no gate will catch it. The new hold makes the
   snap *more* legible (motion stops, then one decisive change) — that is a hypothesis
   about perception, not a fact about the code.
2. **Three bands could read as three objects instead of one object tearing.** They stack
   identically at rest, which should ground them, but that is a claim about human
   perception.
3. **The tear is angular/positional, never colour** — correct per the research
   (misregistration over glow, subtract not add) — but *quieter* than a flash. The
   opposite failure is equally live: too subtle to notice at speed.
4. **Ownership is split.** The reach (beat A) is driven by `perception_pose` written in
   `prop.gd` and rendered in `player.gd`. A future edit to either can desynchronise hand
   and object.
5. **Force-snap shortens the fracture** whenever the player swings early, so fast players
   may never see the full beat.

**Still needs manual confirmation** *(this is PHASE 11 compare-pair D)*
- Does it read as **perception reinterpreting the object**, or as **the item levelling
  up**? *(The decisive question of the whole experiment.)*
- Is the held peak long enough to read as authored without the transform feeling slow?
- Is the 1-frame snap at 0.285s readable, or does it look like a pop/bug?
- Is the tear legible as *the same object* breaking, or as three objects?
- Is the fracture *too quiet* at full speed?
- Does the reach (beat A) read as the hand pulling it in, or as the body shrugging?
- Compare normal pickup vs perception pickup — do they feel like different events?

---

# Controlled Insanity Identity

**NEEDS WORK**

"Controlled insanity" is a feel judgement about the *whole*, not a property of any one
system. Proxies exist and they are green; the identity itself has never been judged by a
human playing this build.

**Evidence — the four sanctioned sources are present, none of the banned ones are**
- **perception fracture** — 3-band misregistration, held peak, 1-frame snap, 0.18s
  settle, all while movement / dash / Blink / swing stay live (gate: transform under 0.5s
  with an attack accepted during it).
- **overcommitment** — wind-up lean **+0.42** past the support base, strike to **+0.34 /
  +0.36**, whiff overshoot to `over + 0.20`; measured standing-whiff span **0.693 rad**
  (was 0.519).
- **rapid recovery** — recovery 0.08s, cooldown 0.35s; Q1 back to neutral by +0.20s, Q3
  by +0.20s after contact.
- **Blink timing** — the arrival stance arms only on the frozen→unfrozen edge.

**Evidence — banned sources verified absent (grep + gates)**
Random inputs, random animation, camera spam (shake only ever follows a confirm, cap
0.6), screen-wide glitch, full-screen bloom, and unreliable hitboxes (the rect resolves
only inside its declared window; camera shake never moves a hitbox). Determinism
preserved: pose targets and blend rates are constants; randomness exists only in
non-state cosmetics. Gate: `test_identity` green — including its frame-10 pose gate
measured against the documented 2-frame input lag.

**Evidence — this pass's identity argument**
Insanity here is produced by *frictionless timing contrast*, not by noise: a slow heavy
coil (δ·40) → a fast commit (δ·44) → an almost instantaneous plant (δ·52) → a held
contact → a fast release (δ·30). Five different rates on one timeline, all pure functions
of `_atk_t`. Nothing is random and nothing is added; the two loops in this pass that
produced a *wobble* instead of an intent (the recovery seam, the dash reversal) were
treated as defects and removed.

**Remaining weakness**
1. **The identity is the sum of numbers that individually look sane.** Nothing in the
   suite can detect "the pieces are correct and the whole is boring" — or the reverse,
   "the pieces are correct and the whole is noisy".
2. The body pose layer (`_update_visuals`) carries five competing concerns in a fixed
   priority order — attack → dash → perception → arrive → skid. Priority is
   deterministic, but a perception pose can be silently overridden by a swing (intended)
   while an arrive pose can be silently overridden by a skid (maybe not).
3. **One known non-monotonicity remains**: the pickup-reach → swing hand-off
   (~0.08 rad over ~3 frames). "Insanity" that comes from a wobble in the *implementation*
   rather than from the *language of the body* is exactly the failure mode to avoid.
4. "Fast" and "snappy" are different words for the same number, and only eyes tell them
   apart.
5. Everything about the new aggression was tuned **against measurements**, not against
   play. Numbers that were pushed harder to satisfy a criterion can overshoot it.

**Still needs manual confirmation** *(PHASE 11 compare-pairs E and F, PHASE 12 items
19–24)*
- Does the whole thing read as a body that is *committed and recovering*, or as a sprite
  that is *jittering*?
- Is the insanity legible — can you follow what happened *after* it happened?
- Compare: pre-Blink vs post-Blink; enemy idle vs enemy hit. Authored, or random?
- Is there any moment where you thought you pressed something and it did not register?
- Would you show this to someone as "the game"?

---

# Stability

**PASS**

**Evidence**
- Gate: `--import` clean; no `SCRIPT ERROR`, no `Parse Error`, no `Failed loading`.
- Gate: **all 7 suites `ALL PASS`** — `test_arena`, `test_runtime`, `test_feel`,
  `test_strand`, `test_killblink`, `test_identity`, `test_weapon` — re-run after every
  edit of this pass (suites exit `1` on any `_failures > 0`, so `ALL PASS` is a real
  result, not a print).
- Gate: every edited file parse-checked with `--check-only` before the next step; every
  edit verified with `grep`.
- Gate: no runtime errors in any probe run (`probe_feel`, `probe_feel2`, `probe_feel3`,
  `probe_input`, `probe_transform`, `audit_combat`).
- Determinism: probes reproduce the same numbers across runs for poses and transforms;
  the transform is frame-driven, not `Tween`-driven; `Engine.time_scale` is only ever
  touched by hitstop and is always restored.
- Files changed this pass: `scripts/player.gd`, `scripts/prop.gd`,
  `scripts/melee_chaser.gd`, `scripts/ranged_enemy.gd`, `scenes/melee_chaser.tscn`,
  `scenes/ranged_enemy.tscn`, plus two new read-only probes
  (`tests/probe_input.gd`, `tests/probe_transform.gd`) and both design documents.
- Defects found and fixed this pass (4 real bugs, all caught before play): the
  **whiff→recovery seam** (0.04 rad lurch), the **dash-strike reversal**
  (`scale.x 1.33→1.28`), the **enemy floating 12px off the floor on every hit**
  (top-left pivot), and the **dropped-input window** (0.35s of every 0.60s cycle).
  Plus two hygiene items: dead `_pop_t` in both enemy scripts, and an FX (0.07s white
  flash) that was covering the body pose it was meant to announce.
- Scope hygiene: `agentskill\`, `.godot\`, `opencode.json`, `project.godot`,
  `DESIGN_BRIEF.md` §0–11, MCP config and `_archive\` untouched; no new MCP installed;
  no new input action; no Room 2 / chapter / progression / second weapon / combo system /
  Blink redesign / arena redesign / final art.

**Remaining weakness**
1. The repo is **not a git repo** — there is no commit history to bisect if a regression
   appears later. Every change is recoverable only from the files themselves.
2. `probe_feel3` Q3's stage is hand-timed (walk 14 frames, drop the target at frame 16,
   swing at 17). Deterministic, but it depends on the documented 2-frame input lag; a
   3-frame lag would silently re-time it, as already recorded for `test_identity` phase 7.
3. Probe peaks are not bit-reproducible: `audit_combat` `P2 shakeMax` measured
   0.329–0.350 and `test_weapon` `WEAPON_DX bare` measured 17.7 → 18.1 across runs
   (armed stable at 49.4). Small, non-gated, and attributable to scene-startup frame
   phase — but it means a probe number quoted to 3 decimals is overstated precision.
4. **Headless runs cannot see pixels.** A visual regression — a pose reading wrong, a
   colour wrong, a tear reading as three objects, a stance reading as a pop — would not
   fail any of the above. This is the single largest hole in the evidence above.

**Still needs manual confirmation**
- One full manual session across compare-pairs A–F with no tests running: **A**
  bare-hand vs weapon · **B** whiff vs hit · **C** standing vs dash attack ·
  **D** normal vs perception pickup · **E** pre/post-Blink · **F** enemy idle vs hit.
  Does anything stutter, pop, or feel wrong?
- Any scene / restart / death path (`dbg_death`, `dbg_crash`) behaving differently when
  the prop is mid-transform or mid-break?
- Frame pacing on the developer's actual machine during a hit with camera shake.

---

**PHASE 12 — EXIT GATE** *(grouped Movement 1–4 · Combat 5–13 · Perception 14–18 ·
Identity 19–24; items derived from `DESIGN_BRIEF.md` §0 kill criteria, §5 risk rules and
§8 manual checklist — no separate gate file exists in the repo)*

| # | criterion | status |
|---|---|---|
| 1 | Run/jump/dash respond front-loaded (<100ms); top speed in ~0.1s | facts ✅ · feel ❓ |
| 2 | Jump forgiveness (coyote / buffer / cut / asymmetric gravity) | ✅ gates |
| 3 | Dash is a tool (0.15s, i-frames, 0.8cd, 1 air dash), not a teleport | ✅ gates · feel ❓ |
| 4 | Momentum never lost silently (drag, bulldoze, dash→swing) | ✅ probes |
| 5 | Fresh player attacks on purpose within ~30s, replays voluntarily | ❓ **human only** |
| 6 | Whiff vs hit differ on six axes **and the difference is felt** | facts ✅ · ❓ |
| 7 | One strong contact pose; impact reads before displacement; correct frozen frame | facts ✅ · ❓ |
| 8 | Dash → attack is ONE gesture, no stop→swing, no reversal | ✅ monotonic + ❓ |
| 9 | Body drives the swing, not a sliding rectangle | facts ✅ · ❓ |
| 10 | No dropped/delayed input; dead time reads as commitment not lag | ✅ 10/10 · feel ❓ |
| 11 | Enemy reaction reads as a body (planted, held, horizontal, no ragdoll) | facts ✅ · ❓ |
| 12 | Melee telegraph 0.4s readable; melee forces movement; TTK 3–4 hits | facts ✅ · ❓ |
| 13 | Controlled overcommitment + fast recovery, no wobble | facts ✅ · ❓ |
| 14 | **Transform reads as perception changing, not an item powering up** | ❓ **decisive** |
| 15 | Snap readable as authored; held peak not too slow | facts ✅ · ❓ |
| 16 | Three-band tear reads as one object breaking | ❓ |
| 17 | Gameplay never locks; both identities visible; transform < 0.5s | ✅ gates (0.468s) |
| 18 | Bare vs perception pickup are clearly different events | ❓ |
| 19 | Whole reads as controlled insanity — committed, not jittering | ❓ |
| 20 | Insanity is legible *after* it happens | ❓ |
| 21 | A/B readable in 2s; Blink changes the fight; never purely beneficial | facts ✅ · ❓ |
| 22 | No unfair Blink death; no attack during transition; no camera spam | ✅ gates |
| 23 | Determinism — same input, same result | ✅ probes |
| 24 | Would you show this as "the game"? | ❓ **human only** |

**Tally: 11 of 24 verified by evidence; 13 of 24 (including every criterion in
Perception and Identity) rest entirely on a human Play session that has not happened.**
Items 14 and 16–18 and 19–24 are the ones that decide the experiment, and not one of
them is answerable headless.

**RECOMMENDATION: DO NOT START PRODUCTION.**
Combat, Perception Weapon and Controlled Insanity Identity are **NEEDS WORK** — not
because they are known to be broken, but because they are unjudged, and the gate rule is
explicit that a failure in any of those three forbids production. Running the compare-pair
session costs one Play session; starting production on top of an unjudged headline
criterion does not. **Wait for the human playtest review. Do not build Room 2, Chapter 1
or any production content.**
