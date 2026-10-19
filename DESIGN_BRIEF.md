# NEVERLOOKBACK — Prototype 1 Design Brief
*(answers PHASE 5 + records PHASE 1/2/4 research; prototype question only)*

> ## STATUS — 2026-10-18: the active ability is MOTION SWAP
> **Blink (the arena A/B toggle) is RETIRED and removed from the project.** The
> ability that ships in this build is **Motion Swap**: pick two valid targets and
> trade their *current* motions — two reads, then two writes, no teleport, no
> position swap, no stored momentum, no auto-knockback, no identity change.
>
> Everything in this document that describes Blink, State A/State B, the arena
> toggle, the 4.0 s Blink cooldown, frozen enemies or Blink VFX is a **historical
> record of prototype 1** and must not be re-implemented. Those sections are
> marked `[HISTORICAL]` inline where they could be mistaken for live systems.
>
> Live references now:
> - `design/MOTION_SWAP_IMPLEMENTATION_PLAN.md` — the swap contract, the channel
>   table, the Blink-removal audit, and the lab spec.
> - `design/MOTION_SWAP_LAB_QA.md` — the playable six-zone lab, its controls,
>   its verification evidence and the manual test checklist.
> - `labs/motion_swap_lab.tscn` — the lab (now the project's main scene).


## 0. Prototype question (the ONLY question)
**"Is movement + melee combat + Motion Swap fun in a single room?"**
*(proto-1 asked the same question about Blink; the question survived the swap of
the ability, the A/B arena did not.)*
Kill criteria: a fresh player moves/attacks on purpose within ~30s and replays the room voluntarily.
Out of scope: story quality, map, progression, enemy count, graphics.

## 1. Player verbs
run / jump / dash / melee attack / **Motion Swap**. Combat must be usable WITHOUT Motion Swap.

## 2. Core loop
Move → read encounter → fight → **Motion Swap to change the situation** → reposition → finish encounter.

## 3. Player skill tested
timing, positioning, movement execution, enemy reading, **Motion Swap target reading + exchange timing**, state awareness.

## 4. Research → principles applied (not copied)
- **Dead Cells:** front-loaded response (<100ms), 2-second combat rule, dodge as cautious tool, pattern-based enemies + panic option, authored chunks over slop. Applied: snappy accel (top speed in ~0.1s), asymmetric gravity, melee telegraph 0.4s, dash i-frames, short TTK (2–3 hits).
  NOT copied: weapons, biomes, exact timings, procedural generation.
- **Hollow Knight:** 3-layer readability (fg/mid/bg), landmarks + room purpose, simple geometry with identity. Applied: one readable arena, cyan-A vs amber-B background tint, labeled platform/hazard, SAFE zone marker. NOT a Metroidvania — no gating/backtracking here.
- **My Friend Pedro:** self-expression via recombining a small move set + environment; playful combat. Applied: dash + jump + Blink let player remix the same 2 enemies (e.g. Blink mid-air to drop the ranged enemy, dash through melee). NOT copied: slow-mo, score/stunt system.
- **MO:Astray:** one deep mechanic introduced → expanded → remixed → tested; traversal/puzzle/encounter from one verb. Applied rule: before adding any system ask "Can **Motion Swap** be deepened instead?" The project keeps exactly one ability. *(Proto-1 asked this about Blink; the rule outlived the mechanic.)*
- **Superhot:** one strange world rule learned through play, no exposition. Applied: Blink taught by doing (two labeled states, instant flash + HUD line), no tutorial text wall. NOT copied: slow-motion.
- **Poki/web:** 1280×720 / 16:9, GL Compatibility renderer, zero external requests, <10s load (graybox primitives, no assets), first-input-to-gameplay immediate, skippable everything (nothing to skip), R = instant restart, no gore, keyboard+mouse with remappable actions, tablet/mobile schemes reserved. No monetization in prototype.

## 5. Blink risk analysis (10 risks → 1 prevention rule each) — [HISTORICAL: Blink is retired]
*(kept as a record of how the retired mechanic was pressure-tested; the same
exercise for the live mechanic is §5b)*
1. **Too powerful** — why: solves everything. Rule: every Blink fixes exactly one problem and creates another (hazard off BUT blockers + faster chaser).
2. **Gimmick/puzzle-only** — why: no combat value. Rule: Blink repositions a live threat (ranged loses height but stays dangerous).
3. **Confusing combat** — why: unreadable swap. Rule: freeze all enemies + clear projectiles during 0.35s transition; attacks suppressed.
4. **A/B hard to read** — why: subtle diff. Rule: two-channel minimum — geometry (platform there/gone) + color (cyan/amber) + HUD text.
5. **Spam** — why: no cost. Rule: 4.0s cooldown, blocked during transition, HUD bar.
6. **Solves positioning instead of rewarding movement** — why: teleport thinking. Rule: Blink never moves the player; only the arena changes — player still must run/jump/dash.
7. **Unfair deaths from arena change** — why: solid appears inside player. Rule: `_resolve_player_overlap()` ejects player; solids toggle deferred one physics frame apart.
8. **Unpredictable enemies** — why: AI changes silently. Rule: only ONE authored delta per enemy (melee +25% speed in B; ranged teleports A-perch↔ground, same fire logic).
9. **VFX obscures combat** — why: fullscreen flash lingers. Rule: flash ≤0.85 alpha decaying in 0.35s; shake on camera offset only, never on bodies.
10. **Story overwhelms gameplay** — why: lore text interrupts loop. Rule: zero story in prototype; reality-flash idea reserved for later.
## 5b. MOTION SWAP risk analysis (10 risks → 1 prevention rule each) — ACTIVE
1. **"Swap means teleport"** — why: the verb itself invites that reading. Rule: an exchange never touches a position; it only moves *motion*. Taught in zone A, where the crate visibly runs away while the patrol keeps its feet planted.
2. **The second target feels random** — why: no feedback between the two clicks. Rule: the first pick is drawn and named (marker + line + HUD `A: CRATE [LINEAR] v=(0,0)`), and every refusal answers with a reason instead of failing silently.
3. **Incompatible pairs read as a bug** — why: a crate swapped into a lift "should" do something. Rule: one declared channel table refuses the pair with an explicit sentence, and the refusal keeps the A selection alive so the player can immediately pick a legal B (zone E is built around teaching exactly this).
4. **Machines silently reverting** — why: the player put speed into a lift and later finds it gone. Rule: machine settings persist by construction — they are never tied to the ~2.5 s character override clock, and the runtime suite checks that past that window.
5. **Zero read as "frozen"** — why: a receiver with no motion looks stuck if it hangs midair. Rule: gravity and collisions keep acting through every override; a zero exchange means "no controllable motion", never a suspended body.
6. **Characters puppeted forever** — why: an exchanged enemy never gets its own behaviour back. Rule: overrides expire, the AI resumes from the position the body actually reached, and nothing is restored or teleported back to where it started.
7. **Momentum fiction** — why: swapping a *stored* number is not swapping what the object is doing. Rule: adapters read the live physics quantity at the instant of exchange (`RigidBody2D.linear_velocity`, the character's own velocity, the projectile's real velocity), and both reads happen before either write.
8. **Parked projectiles piling up** — why: a shot swapped to zero speed that lives forever is a bug the player creates. Rule: the lifetime keeps running, and a shot under the parked threshold deflates and retires; the lab also caps live shots.
9. **Spam** — why: no resource cost. Rule: ~1 s cooldown between exchanges plus a single-selection timeout, and the level itself limits what any exchange can buy.
10. **Swapping deleting the encounter** — why: if the exchange just removes a threat, the mechanic is a delete button. Rule: the lab is authored so every exchange trades a capability in both directions (a stopped belt is also a missing bridge; a lift's speed is also a stopped lift), and it never touches hp, damage or teams.

**Deliberately NOT implemented:** a targeting time-slow. The project already has a hitstop token that owns `Engine.time_scale`; a second slow-motion owner would fight it. Documented rather than half-built — see `design/MOTION_SWAP_IMPLEMENTATION_PLAN.md`.

## 6. State A / State B (authored, never random) — [HISTORICAL: the arena no longer toggles]
*(the legacy arena scene `scenes/main.tscn` was migrated to a single authored
state when Blink was removed; there is no A/B switch left in the project)*
- **A:** upper platform EXISTS (800,400,300×20); hazard ACTIVE (500,568,150×32); ranged ON high ground (950,350); melee speed 140.
- **B:** platform GONE; hazard INACTIVE; ranged GROUNDED (950,540, same 2.2s/0.5s fire pattern); two low blockers APPEAR (350/700,520,30×80) + melee speed 175.
- Transition 0.35s, cooldown 4.0s.

## 7. Tuning (exposed @export, live-tunable) — v3 identity pass
Move: run 280, accel 2600, REVERSE 4200, friction 3200, air×0.7. Jump: vel −640, rise g 1600, fall ×1.8 (h≈128), coyote 0.10, buffer 0.12, cut ×0.45. Dash: 650 / 0.15s / 0.8 cd + buffer 0.12 + strike-window 0.06 + i-frames, 1 air dash. Attack: startup 0.05 / active 0.12 / recovery 0.08 / cd 0.35 / buffer 0.2, range 82, dmg 1, kb (260,0) horizontal-only, step +60, hit-brake ×0.55 + anchor-to-stop through active on confirm (v5). Hitstop 0.045s@0.05 + shake 0.3 on confirm; hurt shake 0.35; landing shake 0.15 over 700 speed. Melee: 150→185, HP3, windup 0.4 / strike 0.12 / recover 0.4 / cd 1.0, stagger 0.09s, slam kb (170,−50), touch kb 120. Ranged: HP2, cycle 2.0 / aim 0.45 (lock last 0.15) / recover 0.3, bullet 360, sight 900. Player HP5, hurt iframes 1.0, hazard tick 0.25s. Platform top y=480.
*(`Blink: cd 4.0, transition 0.28, frozen timers+intent preserved` was removed with
the mechanic — [HISTORICAL].)*

**Motion Swap tuning (active, all @export on `NLBMotionSwapController`):** max
range 520 px, grab radius 40 px, single-selection timeout 5.0 s, cooldown 1.0 s,
character override 2.5 s. Machines ignore the override clock by design. Lab
numbers: floor y 600, world 0–7840, jump h≈128 px / ~196 px air travel, run
280 px/s; belt speeds ±120 / ±100, lift speeds +80 and +120 with 160/80 px
paths; player mask gains props (256) + machines (512) *inside the lab only*.

## 8. Cancel/buffer matrix (v3, tested in test_identity.gd)
- run→attack: instant, inherits momentum + forward step; **whiffs slide at full speed, hits anchor to a stop through active** (the whole hit-vs-miss mobility contrast — before v5 both were identical).
- jump→attack: free anytime airborne; dash→attack: allowed in late dash only (≤0.06s left), keeps dash velocity; earlier presses buffer to dash end.
- attack→dash: cancels RECOVERY only; startup/active refuse (dash stays buffered, fires after).
- landing→attack: buffer covers it.
- **Motion Swap is input-level, not physics-level (ACTIVE):** selecting or
  exchanging never freezes anything, never touches `Engine.time_scale`, and
  never suppresses attacks or timers, so it cannot appear in the cancel matrix —
  attacks/dash/jump and swap selection coexist in the same frame. A swap writes
  motion only, and only for the two chosen targets.
- *(HISTORICAL, removed with Blink: `Blink→attack/dash: presses recorded during
  freeze`, `attack→Blink / dash→Blink / Blink→dash: always allowed`.)*
- Simultaneous fresh dash+attack: dash wins, swing follows buffered.

## 9. Visible identity layer (v4, graybox primitives only — no art pass)
- Swing Swoosh (player.tscn): hidden idle → gray blade in ACTIVE → bright pop on confirm → fades through recovery. Dash-strike stretches it (1.5×, low) across its whole startup+active.
- Enemy hit-pop: body punches to 1.3× for 0.12s on damage (visual scale only).
- Soft body separation (game.gd): horizontal-only, runs in `_process` AFTER node physics (verified by marker probe), pushes ONLY the enemy (never the player), 8px/frame cap; y and velocity untouched. *(The `skipped in Blink freeze` branch was deleted with the mechanic — separation is unconditional now.)*
- Blink arrival snap *(HISTORICAL — removed with Blink; no geometry toggles exist in the project)*: swapped-in geometry visuals pop 1.08→1.0 in 0.18s; start veil decays over the full transition, arrival flash 0.5 in 0.2s, camera shake 0.3 on arrival.
- **Motion Swap readability (ACTIVE):** the controller draws the picked target's marker, the A→hover line and the exchange beat itself; each body draws its own motion arrow whose length is speed and whose colour says who owns the motion now (own AI vs received). Enemies carry a state label (`PATROL v=(90,0) WALK R`). No full-screen effects.
- Swing teardown unified in _end_swing() (dash-cancel/freeze/natural end all hide the swoosh).

## 10. Takeover feel pass (v5) — root causes found by live measurement
Built `tests/probe_feel.gd` + `tests/probe_feel2.gd` (read-only runtime probes) instead of trusting reports. Four verified defects:

1. **Invisible drag (Context layer).** Separation split the correction 50/50 and ran before `move_and_slide`, so every frame an enemy was near it teleported the player back. Measured travel 161 px/s vs 266 px/s with no enemy → a ~40% speed loss that only existed in combat, plus a permanent ~5px body overlap (gap 25, touch at 30). Now: player never moved, enemy yields, solve runs after physics. → gap holds 30.0, player travel 182.
2. **The bite never happened (Response layer).** The whole confirm feedback was one `velocity.x *= hit_brake`, which both acceleration arms ramped out of within ~50ms — and inside the 45ms hitstop. Hit and whiff velocity curves were identical in play. Now a confirmed hit anchors the body for the rest of the active window (arm placed ABOVE the held-input arm). → whiff travel 195 vs hit 124; gap opens 44→61.
3. **Launcher component (Rules layer).** Swing knockback was `(260, −80)` — a −80 upward impulse on every grounded target. Now `(260, 0)`: horizontal only by construction. → enemy min vy 0.0.
4. **Blink had no beat (Polish layer).** *[HISTORICAL — the mechanic is retired; the fix below was verified at the time and the code it touched is gone.]* Start veil died at 0.22s but the transition runs 0.28s → 4 frames of frozen dead air, and the arrival carried no camera impulse (press shake had already decayed to 0). Now veil = full transition, arrival adds flash 0.5 + shake 0.3. Also fixed two flash tweens racing one property (the older zeroed the arrival flash).

Also: dash-strike's swoosh branch sat below the generic fade arm, so its whole 0.05s startup rendered the standing-whiff arc — dash and swing read as two actions. Branch reordered; a confirmed dash-strike keeps the stretched shape.

**Guard tightened:** `test_identity` phase 6 ("whiff keeps sliding") was passing for the wrong reason — the chaser had closed to gap 44 (inside 82px reach), so it was confirming. Setup now forces gap > 82 and asserts `not _bite_done`.

## 11. Perception-weapon micro-experiment (v6) — ONE object, ONE transformation, ONE attack
Full storyboard: `design/PERCEPTION_WEAPON_EXPERIMENT.md`. Skill inventory: `design/SKILL_STACK_WEAPON_TRANSFORM.md`.

**Foundation defects found in PHASE 2/3 (before adding anything):**
1. **Bulldozing.** Walking into a chaser *carried it* — 538px of displaced foe from simply holding right. `separate_bodies()` rewritten so each body undoes only the encroachment IT caused: walk-into-contact rejects the player's advance (blocked at 30px, never dragged), foe walk-in pushes back, a dash keeps momentum and shoves. → `P4 foe_displaced = 0`, `P4b gapMin −25 → 30, frames_below_30 0/200` (bodies used to interpenetrate the wall).
2. **Invisible drag re-verified:** chased-from-behind travel ratio **100%** (proximity never slows the player; only contact blocks).
3. **Leftover glow artifact:** the Swoosh node was still in `player.tscn`. Removed entirely — swing readability now comes from a **pose cue on the player's own Body** (elongate + lean into the strike), i.e. silhouette, not overlay. → `P10_SWOOSH child_node_present=false`.
4. **`test_arena` silent gate bug:** line 120 read `p.health.hp` before `_ready`; the error skipped the last 3 assertions while still printing ALL PASS. Fixed to `hb.health_node().hp` + an exact-damage check.

**The experiment:**
- **Object:** metal pipe at **(575, 594)**, inside the hazard strip. Reality = one 46×8 dull bar; hero = blade 82×10 + crossguard + grip, **100px** silhouette. Not the final canonical weapon.
- **Pickup:** auto on touch (|dx|≤26, |dy|≤44). No new input, no UI, no menu, no inventory.
- **Transformation:** 6 beats, **0.42s** total, frame-driven. Anticipation lift → one ghost offset → shear/break → **one hard node-visibility swap at 0.24s** with a local colour flash → overshoot 1.42→1.0 → rest. Gameplay never locks; no camera move; no time freeze; no full-screen flash.
- **Attack:** same input/timings, resolution only — reach 82→104, kb 260→460, hitstop 0.045→0.075, bite 0.55→0.35, damage stays 1 (impact carries the weapon, not the number). 5 confirmed hits → deterministic break as payoff → 4.0s respawn.
- **Motion Swap relation (exactly one):** the pipe is a *prop, not a swap target* — Motion Swap never transforms or throws it. What the ability changes is who is holding the speed in the room: the pipe's 5-hit pay-off stays a melee decision. *(Historical: `Blink changes access — State A hazard live costs 1 HP, State B dead is free`; State A/B no longer exist.)*
- **PHASE 11 rebalance (exact before → after):** melee HP **3 → 4**, ranged HP **2 → 3**. Player HP **5** / iframes **1.0s** unchanged (max intake 1 HP/s). No damage values changed. Reason: 5 total enemy HP made the pipe's break coincide with clearing the room, so the payoff never landed mid-fight; 7 gives the weapon an honest full-use window and still ends 2 HP short of a sponge.

**Measured:** `WEAPON_DX bare=17.7 armed=49.4 reach=104 kb=460 hitstop=0.075` — the weapon separates ~2.8× harder than bare hands with identical input.

**Known defect fixed during implementation:** `game._on_player_hit_landed()` read live `weapon_power`, but the prop reacts to `landed_hit` first (the player connects to `swing_box.landed` before game does). The 4th hit would have inherited the finisher's hitstop and the 5th — the payoff — would have inherited bare hands. Impact is now snapshotted at swing start (`player._impact_hitstop` / `_impact_shake`).

**Suites:** `test_arena`, `test_runtime`, `test_feel`, `test_strand`, `test_identity`, `test_weapon`, **`test_motion_swap`** (swap contract) and **`test_motion_swap_lab`** (the six-zone lab, end to end) — all ALL PASS, plus `audit_combat` unchanged on every v5 gate. *(The `test_killblink` suite was deleted together with Blink; `test_motion_swap._test_no_blink_remnants()` is the standing guard that it stays gone.)*

**Not yet proven:** everything visual and every game-feel claim below requires a manual Play. Automated runs cannot see pixels.

## 8. Manual test checklist (Phase 7, for player) — [SUPERSEDED]
The live checklist for the ability that ships is in
`design/MOTION_SWAP_LAB_QA.md` §"Manual playtest checklist". Kept for the record:
1. Clear room without Blink? 2. Does Blink change the fight? 3. Is Blink always beneficial (must be NO)? 4. Unfair Blink death? 5. Attacks during transition? 6. Ranged pressure after Blink? 7. Melee forces movement? 8. A/B readable in 2s? 9. Spam possible? 10. Fun across 5+ replays + retune values?
