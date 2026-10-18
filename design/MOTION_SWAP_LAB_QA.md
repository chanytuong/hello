# MOTION SWAP LAB — QA and playtest handoff

> Superseded controls, tuning and zone layout: see
> [MOTION_SWAP_CHAOS_FINAL_QA.md](MOTION_SWAP_CHAOS_FINAL_QA.md).
> This earlier implementation report remains as historical evidence.

**Build:** Neverlookback prototype, Godot **4.7.2** (Windows, Compatibility renderer).
**Active ability:** **Motion Swap** — a two-target exchange of *current motion*.
**Blink is retired and removed** from the project (no input action, no manager, no
State A/B, no freeze). `tests/test_motion_swap.gd::_test_no_blink_remnants()` is
the standing guard.
**Main scene:** `labs/motion_swap_lab.tscn` — press **F5** and you are in the lab.
**Status:** implemented, automated suites green, **human feel/visual playtest pending**.

---

## 1. What shipped

| Piece | File | Notes |
|---|---|---|
| Channel model (one table) | `scripts/motion_swap/motion_channels.gd` (`NLBMotionChannels`) | Which pairs may be exchanged, and why a pair may not. |
| The swap target | `scripts/motion_swap/motion_swap_target.gd` (`NLBMotionSwapTarget`) | One component on every exchangeable thing. The controller never inspects host classes. |
| The controller | `scripts/motion_swap/motion_swap_controller.gd` (`NLBMotionSwapController`) | Pick A → pick B → exchange. Owns range, cooldown, feedback, drawing. |
| Adapters | `scripts/motion_swap/adapters/*` | One per object type: crate, enemy/character, projectile, conveyor, moving platform. |
| The lab | `scripts/lab/motion_swap_lab.gd` + `labs/motion_swap_lab.tscn` (+ `labs/objects`, `labs/enemies`) | Six zones, 7 enemies, 12 crates, 6 machines, 1 plate, 1 gate, 2 spike strips (zone C, zone F), checkpoints, finish line. |
| Enemies | `scripts/lab/enemy_patrol.gd`, `enemy_gunner.gd`, `enemy_charger.gd` | Patrol = steady walk; Gunner = aimed non-homing shots; Charger = committed run that cannot re-aim. |
| Debug overlay | `scripts/lab/lab_debug_overlay.gd` | F1. Everything the mechanic reads or writes, on screen. |
| Suites | `tests/test_motion_swap.gd` (contract), `tests/test_motion_swap_lab.gd` (runtime, 95 checks) | See §9. |
| Evidence | `artifacts/motion_swap/` | Logs + 12 screenshots + pre-edit checkpoint copies. |

## 2. Run it

```
Godot 4.7.2 → open E:\neverlookback\project.godot → F5
```
Headless (what CI-ish runs do):
```
godot --headless --path E:\neverlookback --script res://tests/test_motion_swap.gd
godot --headless --path E:\neverlookback --script res://tests/test_motion_swap_lab.gd
godot --path E:\neverlookback --script res://tests/capture_lab.gd     # screenshots, needs a display
```

**Controls**

| Key | Action |
|---|---|
| A/D or ←/→ | run (skid on release, full speed in ~0.1 s) |
| Space / W / ↑ | jump (h ≈ 128 px, ≈196 px of air travel at run speed) |
| Shift / L | dodge roll (0.70 s, i-frames) |
| J / Z / mouse-left | melee (unchanged; the lab's enemies have hp 4 / 3 / 5 for patrol / gunner / charger. Note left click is *also* the melee button — a swap click therefore also swings: harmless at range, and **Q** is the swing-free swap key) |
| **Left mouse / Q (`swap_select`)** | **pick A**, then **pick B** → exchange. Hovering shows the target under the cursor. |
| **Right mouse / Esc (`swap_cancel`)** | clear the selection |
| **1** | reset **zone** (everything in the zone you stand in → authored state) |
| **2** | reset **targets** (machines → authored speeds, characters/crates → standstill **in place**, selection cleared, live shots retired) |
| **3** | respawn **enemies** (killed or fallen, back at their posts) |
| **R** | restart the whole lab |
| **F1** | toggle the debug overlay |

## 3. The swap contract (what the ability does, and refuses to do)

An exchange **is**: read the two live motions → write both, in the same frame, after
both reads.

An exchange is **never**:
* a **teleport** — no position is written by any adapter; the gradual motion that follows is the only movement;
* a **position swap** — the bodies stay where they are;
* a **stored-momentum** trick — the read is the live physics quantity (`RigidBody2D.linear_velocity`, the character's own velocity, the projectile's real velocity, the machine's operating speed);
* **automatic knockback** — nothing is thrown by the swap itself;
* an **identity/team swap** — hp, damage, teams, AI ownership and machine authorship are untouched;
* **homing** — a shot keeps the direction it was fired with, forever;
* **silently clamped or normalised** — what you see in the overlay is what crossed (the only guard in the whole mechanic is documented in §10: a teleport-overlap guard that *moves the player*, never the crate).

Also true, and load-bearing for feel:
* **Zero is a value.** Exchanging a standstill into a mover stops the mover; it does **not** freeze anything midair — gravity and collisions keep acting during the override, so a zeroed body lands.
* **Character overrides expire** (~2.5 s, `@export`). When they do, the AI resumes **from the position the body actually reached**. The original position is never restored.
* **Machines keep what they were handed** — no override clock, no auto-reset. Only the reset tools (1/2) put a machine back.
* **Projectile lifetime keeps running while parked**, and a parked shot deflates instead of piling up.
* **Short cooldown** (~1 s) between exchanges; a lone first pick times out after 5 s. No mana, no skill tree, no boss immunity, no arbitrary velocity limits.

**Range:** 520 px from Iven to the target's anchor; **grab radius:** 40 px
(you click the object, not its exact centre).

## 4. Channels and refusals (the whole compatibility story)

| Channel | Who | What is exchanged |
|---|---|---|
| **LINEAR** | crate, enemy, projectile | the body's full velocity `Vector2` |
| **SURFACE** | conveyor belt | a signed scalar: its operating speed along its own axis |
| **PLATFORM** | moving platform | a signed scalar: its travel speed along its own path |

Allowed: **LINEAR↔LINEAR**, **SURFACE↔SURFACE**, **PLATFORM↔PLATFORM**,
**SURFACE↔PLATFORM**.
Refused: any **LINEAR ↔ machine** pair, with a readable reason and **no write at all**:

```
INCOMPATIBLE: LINEAR <-> PLATFORM cannot be exchanged
(world velocity (full Vector2) vs persistent travel speed along its own path)
```

A refusal never eats the A selection: you immediately pick a legal B. Zone E is
built to teach exactly this — the parked crate sits right next to the lift it can
never be exchanged with.

## 5. The six zones

Ground is continuous; every gap is inside the jump budget (h ≈ 128 px, ≈196 px of
air travel, run 280 px/s). World: x 0…7840, floor y = 600, kill plane y = 830, closed
box at both ends. Checkpoints every zone; dying or falling returns you to the last
checkpoint, never to the start. A camera follows Iven with the world's own limits
(full 720 px height always visible), so nothing can walk off-screen.

| Zone | Span | Lesson | Contents |
|---|---|---|---|
| **A · BASIC EXCHANGE** | 0–1200 | One walk → one crate | PATROL walking 300–700; crates at 820 / 950; low wall at 1090; checkpoint 70 |
| **B · PROJECTILES** | 1200–2500 | A shot in flight is a real motion | Perch 1430 + GUNNER (sight 620, cycle 2.4 s, lock 0.22 s); crates 1850 / 1980; plinth + test CANNON at 2360/2390 firing **left** at 200 px/s; checkpoint 1250 |
| **C · CHARGE & COLLISION** | 2500–3700 | Committed runs, hard stops | CHARGER at 2760 (locks its direction in the telegraph, cannot re-aim); spike strip 3120; crate stack 3420; charge-stop wall 3620; checkpoint 2550 |
| **D · MACHINERY** | 3700–5150 | SURFACE and PLATFORM speeds | Belt A 4000–4300 (+120), belt B 4500–4800 (−120), LIFT at 4860 (up, path 160, +80), ledge 5000–5300 at y 400, crates 4200 / 4700 / 5080, PATROL D 3900; checkpoint 3750 |
| **E · PLATE & GATE** | 5150–6400 | Make a machine do the work | Ground 5150–5620, pit 5620–5800 (floor 660), belt 5800–6080 (+120), ground 6080–6400, corridor ceiling 6240, GATE at 6300 (20×120, slides up 160), latching PLATE at 6080, E-LIFT 5620 (right, path 80, **0**), crate parked at 5700; checkpoint 5200 |
| **F · MIXED ENCOUNTER** | 6400–7840 | Everything at once | Perch 6700 + GUNNER; PATROL 7000; spikes 7300; CHARGER 7520; belt 7560–7760 (−100, against you); crates 6600 / 7420; FINISH line at 7774; checkpoint 6450 |

**Zone E, the designed crossing** (the only multi-step puzzle):
1. The crate is parked on the E-lift; the belt is **stopped**; the plate is clear.
2. **Swap the belt's +120 into the lift.** The belt stops, the lift drives the crate right and delivers it onto the belt (measured: crate rides 5700 → **~5823**).
3. **Swap them back.** The lift parks where it is, the belt drives the crate onto the plate (measured: crate parks at **~6158**, on the pad).
4. The plate **latches** and the gate opens; the gate cannot close behind you. Standing on the plate yourself also opens it, so the zone can never strand you.
5. Trying to swap the crate into the lift is **refused with a reason** (LINEAR vs PLATFORM) — that refusal is the lesson.

## 6. Enemies, projectiles, crates, machines

* **PATROL** — walks its stretch, turns at the bounds. Its exchangeable motion is a steady walk; it is the "source of speed" in zone A.
* **GUNNER** — holds its post, aims (visible line), locks the direction in the last 0.22 s, fires **one non-homing shot**, recovers. Standing still is deliberate: swapping a shot into the gunner parks the shot and launches the gunner.
* **CHARGER** — telegraphs, locks a direction at the start of the windup, runs, slams into walls at 520 px/s, staggers, recovers. It can never re-aim mid-run, so the telegraph is honest.
* **Projectiles** (`lab_projectile.gd`, team `LAB`/`ENEMY`) — real velocity, no homing, keep their lifetime, retire on hit/wall/lifetime, a parked shot (speed < 14) deflates in 1.6 s, 16 live shots cap in the lab.
* **Crates** — 40×40 rigid bodies with *low* friction (μ ≈ 0.12) on purpose: an exchanged motion must stay legible over distance. A crate that falls out of the world returns to its spawn.
* **Machines** — a conveyor's `surface_speed` and a platform's `travel_speed` are persistent operating settings, never body velocities. Rider zones are 34 px tall boxes along the whole belt/platform, so anything standing on them is carried.
* **Fallen enemies** are retired and respawned at their post after a 2.5 s grace — no enemy can get stuck somewhere unreachable.
* Machine ↔ machine pairs are also valid content: belt A ↔ belt B (reverse a belt), belt ↔ platform (steal a speed), negative speeds included.

## 7. Reset and recovery tools

| Key | Tool | Semantics |
|---|---|---|
| **1** | reset zone | Every resettable thing **in the zone you are standing in** teleports to its authored state: positions, machine speeds, plate/gate, dead enemies. |
| **2** | reset targets | Clears *exchanged* motion **without moving anything**: machines → authored speeds, characters/crates → standstill in place, selection cleared, live shots retired. This is the "put the motion back" button. |
| **3** | respawn enemies | Killed/fallen enemies are re-instantiated from the spawn ledger with their configuration re-applied. |
| **R** | restart lab | Full scene reload (also the finish-line "free play" tool). |

The lab cannot be soft-locked: every zone has a checkpoint, every gap is jumpable,
the plate latches, the return path is never lost, and 1/2/3/R exist precisely so a
human can break the lab and put it back.

## 8. The debug overlay (F1)

One screen, top-left (text refreshes every 0.1 s; drawn markers and arrows are immediate):

* **player** — position, velocity, hp/max, dash/roll state.
* **A / hover** — the current first pick and the target under the cursor, each with `[CHANNEL]`, its motion and validity.
* **cooldown / override** — the exchange cooldown, and the remaining character override on the last receiver.
* **compatibility line** — what the current A + hover pair would do (`OK` or the exact refusal reason).
* **machines** — every belt/platform with its operating speed, authored speed and path progress (`[36/80]`).
* **enemies** — every enemy with its AI state and current velocity (the "is this thing actually moving?" read).
* **shots** — live projectiles, their teams, speeds and remaining life.
* **counts** — live/valid/disabled swap targets, so a broken component is visible immediately.
* **last** — the last exchange or refusal in words (`SWAPPED BELT#719 (120,0) <-> LIFT E-LIFT#616 (0,0)`).
* **lab** — current zone, checkpoint, completion state, and the controls reminder.

Every enemy also draws its own motion arrow: **length = speed, colour = who owns the
motion now** (own AI vs received — and the arrow disappears entirely when the body is
holding a received standstill). Enemies additionally carry a state label
(`PATROL v=(90,0) WALK R`). Zone cards in the world repeat the lesson and the exact
solution.

**Crates draw no arrow** (a crate has no AI to contrast against — it is always running
received motion) and **machines draw drive chevrons/crosses** instead of arrows, so
those two read through their actual movement plus the overlay. The zone A card says
exactly this, after a first draft promised arrows on everything.

**The text refreshes on a 0.1 s interval** (drawn markers, arrows and chevrons are
immediate). In a still frame, or right at an exchange, a text line can therefore trail
the moment by up to a tenth of a second — the drawn ring at the second target is the
same-frame evidence, and the capture log prints the exact values at each pick
(`PICK A ok=true feedback=TARGET A: PATROL#959 [LINEAR] (90, 0) — pick target B`).

## 9. Verification evidence

Automatic suites (all green, exit 0):

| Suite | What it proves | Result |
|---|---|---|
| `tests/test_motion_swap.gd` | The swap **contract** with no tree: channel table and refusals, all five adapters, atomic two-way exchange on real crate scenes, opposed movers reversing, zero-is-a-value, machine persistence, AI resume, no Blink remnants | **ALL PASS** |
| `tests/test_motion_swap_lab.gd` | The lab **running**: 95 checks driven frame by frame through the real scene | **ALL PASS (95 checks)** |
| `test_arena`, `test_runtime`, `test_identity`, `test_weapon`, `test_feel`, `test_strand` | No regression in movement/combat/feel | **ALL PASS** |
| boot smoke (`--quit-after 300` with the lab as main scene) | The shipped entry point loads and runs with no script errors | **EXIT=0** |
| parse checks on every motion-swap and lab script | No parse errors (a `.tscn` is not a script; the scene itself is validated by the lab suite and the boot smoke) | **EXIT=0 each** |

**One known flake, recorded rather than hidden.** `test_movement_integration.gd`
(a frame-exact input replay of `scenes/movement_test.tscn`, untouched this session)
reports 0–2 failures **on unchanged code**: repeated runs here gave *2 fails / 1 fail
/ 0 fails*, each time a different landing-timing assertion (`roll exits using current
input`, `landing returns to held run`, `pre-landing jump buffered`), always with the
same 166 assertions / 2032 samples. The suite's dependency set (`scripts/movement_test.gd`,
`scenes/player.tscn` → `scripts/player.gd`) contains nothing touched by the Motion
Swap work, and the same file passed with 0 failures earlier in the session — so this
is harness frame-alignment sensitivity, not a Motion Swap regression. The movement
behaviours it flakes on (RUN, JUMP, DODGE ROLL, landing) are also covered
deterministically by the lab suite's own `RUN still works here`,
`JUMP still works here`, `DODGE ROLL still moves the player` checks, which passed on
every run. The raw outputs of those runs are in the log below.

Logs: `artifacts/motion_swap/final_verification.log`,
`artifacts/motion_swap/motion_swap_suites.log`,
`artifacts/motion_swap/blink_removal_suites.log`,
`artifacts/motion_swap/regression_suites.log`.
Screenshots: `artifacts/motion_swap/shots/*.png` — 12 shots from the final build: all
six zones, the overlay hidden, the zone E belt↔lift exchange photographed with the
crate mid-crossing on the lift, and the zone A patrol↔crate exchange as a three-shot
sequence (A selected → crate running the walk → patrol back on its AI). Rebuild them
any time with `tests/capture_lab.gd` (needs a display).

**The 16 required behaviours, and where each is verified**

| # | Required behaviour | Verified by |
|---|---|---|
| 1 | Patrol ↔ crate exchange | `test_motion_swap_lab`: *pick the PATROL as A* → *PATROL <-> CRATE accepted (both LINEAR)* → *the crate is running the patrol's walk* |
| 2 | Opposed movers reverse | `test_motion_swap`: *opposed movers reverse through each other's motion* |
| 3 | Gunner ↔ projectile | `test_motion_swap_lab`: *pick the shot in flight as A* → *SHOT <-> GUNNER accepted* → *the gunner received the shot's velocity* |
| 4 | Charger ↔ crate | `test_motion_swap_lab`: *the charger's committed run can be exchanged into a crate* → *the crate received the charge exactly* |
| 5 | Zero-velocity receive | `test_motion_swap`: *zero exchange means zero controllable motion*; lab: *the charger received the crate's standstill and stopped*, *the shot received the gunner's standstill* |
| 6 | Gravity after a swap | `test_motion_swap`: *zero exchange is NOT a freeze: gravity still acts* |
| 7 | AI resumes from where it stands | `test_motion_swap`: *override end never restores the original position*; lab: *the patrol resumed from where it was*, *nothing teleported the patrol back to its spawn*, *the gunner's AI holds its ground again* |
| 8 | Machine persistence | `test_motion_swap`: *machines have no override clock*, *machine settings survive a character override ending*; lab: *machine speeds PERSIST past the 2.5 s character override window* |
| 9 | Projectile lifetime | `test_motion_swap`: *projectile receives zero velocity and KEEPS its remaining lifetime*; lab: *the parked shot's lifetime kept running* → *the parked shot deflated instead of piling up* |
| 10 | Plate + gate | `test_motion_swap_lab`: *the belt drove the crate onto the plate* → *the crate latched the plate* → *the latched plate opened the gate*; and the fallback *the player's own weight latches the plate* |
| 11 | Reset tools | `test_motion_swap_lab`: *reset zone un-latches the plate*, *…closes the gate*, *…restores the authored machine speeds*, *…returns the crate to its spawn*, *…returns the lift to its origin*, *…clears any selection*; *reset targets restores the authored machine speed*, *…clears the crate's exchanged motion*, *…does not teleport the crate*; *respawn restores the roster*, *the respawned enemy is at its spawn point* |
| 12 | Target deleted during selection | `test_motion_swap_lab`: *a dying target clears the selection* → *and says why: TARGET A LOST … SELECTION CLEARED* |
| 13 | Incompatible feedback | `test_motion_swap_lab`: *crate -> lift is refused*, *the refusal is readable: INCOMPATIBLE: …*, *a refused swap changes neither side*, *a refusal does not eat the selection*; `test_motion_swap`: the full channel table incl. both refusal directions |
| 14 | Player movement and collision | `test_motion_swap_lab`: *RUN still works here (127 px in 0.5 s)*, *JUMP still works here*, *DODGE ROLL still moves the player*, *player collides with props and machines inside the lab*, *spike strip damages the player*; plus `test_identity`, `test_feel`, `test_strand` (all pass consistently). `test_movement_integration` also covers it but is frame-exact and flaky on this machine — see the note above |
| 15 | No Blink dependency | `test_motion_swap`: *no Blink remnants* (no action, no autoload, no `blink`/`fight_frozen`/`set_fight_frozen` symbol anywhere in the project) |
| 16 | No parse / runtime errors | Parse checks on every motion-swap and lab script + boot smoke (see the log; both suites exit 0 with no `SCRIPT ERROR`) |

**Two real defects the automated pass found and fixed** (kept here so they are not
"hidden failures"):

1. **Teleport-into-a-body launches it.** `player.reset_movement()` (used by
   checkpoint respawns and by tests) places a body by setting its position; landing
   inside a resting crate made the physics engine eject the **crate** at hundreds of
   px/s (measured 763 px/s from one 24 px overlap — enough to fling the zone E crate
   across the lab and open the gate by accident, and it would let a respawn solve the
   puzzle). Fix: `NLBMotionSwapLab.place_player()` — on overlap the **player** steps
   aside, never the crate (the same rule the legacy arena used for arena changes).
2. **A reset could leave the gate open.** The crate teleporting off the plate left a
   one-step ghost overlap in the physics broadphase, which re-latched the plate right
   after `reset_zone()` — the puzzle looked solved with nothing on the pad. Fix: a
   0.06 s settle window in `LabPressurePlate.reset_state()` during which ghost
   overlaps are ignored (a real body re-latches 4 frames later).

## 10. Known limits and deliberate non-features

* **LINEAR ↔ machine is refused by design.** It is taught in zone E, not a gap to be filled.
* **No targeting time-slow.** The project already has a hitstop token that owns `Engine.time_scale`; a second slow-motion owner would fight it. Documented instead of half-built.
* **No punching targets.** Melee is preserved exactly as it was; the lab's enemies have hp 4 / 3 / 5 (patrol / gunner / charger) and no new combat animations were authored.
* **One exchange per ~1 s.** Chaining faster is not possible; the cooldown is on the HUD/overlay.
* **Crate friction is deliberately low** so an exchanged walk stays readable over distance; crates are slippery, and that is a designed property, not a bug.
* **The plate latches for the rest of the zone run** (use **1** to re-run the puzzle).
* **Everything on screen is debug-grade** (rectangles, labels, arrows): the lab exists to test a mechanic, not to look finished.
* Tuning knobs live in one place each: `max_range` / `grab_radius` / `cooldown` / `character_override_time` / `selection_timeout` on the controller; machine and enemy numbers as `@export`s on their scripts; world layout in `motion_swap_lab.gd`'s zone builders.

## 11. Manual playtest checklist (the remaining gate)

Everything below is a question about **feel and legibility**. Automated tests cannot
answer any of it.

1. **Zone A.** Swap the patrol's walk into a crate. Is the *two-click* rhythm clear? Do you understand the state without reading the card? Does the crate visibly *run* while the patrol visibly *stops* (its arrow vanishing)?
2. Try swapping the crate's standstill into the **patrol** instead. Better or worse? Does anything read as a teleport?
3. **Zone B.** Wait for a shot, swap it into a crate. Does the parked shot's shrink-to-nothing read as "this expires" rather than "this is broken"?
4. Stand in the cannon's line and swap its pellet into a crate, then into the patrol. Is the *direction* always believable (no homing, ever)?
5. **Zone C.** Let the charger commit, then swap the charge into a crate: does the crate's flight sell the 520 px/s? Swap a crate's standstill into the charger mid-run: does it feel like a *stop*, not a freeze?
6. **Zone D.** Ride belt A, then swap belt A's speed into belt B while standing on it. Then steal belt B's −120 into the lift and ride it down. Are machine speeds obviously *persistent* (no surprise re-sets)?
7. **Zone E.** Solve the crossing (belt → lift → belt). Was the crate-into-lift refusal **instructive** or **annoying**? Then stand on the plate yourself and check the gate.
8. Break it on purpose: die in zone E (walk into the pit), then use 1 / 2 / 3 / R. Do the reset tools do what you expect without reading this file? Does anything teleport that shouldn't?
9. **Zone F.** Clear it with swaps only (no melee). Is there a swap that feels mandatory, or does the encounter allow several plans?
10. **Overlay.** Play 2 minutes with F1 on. Is every number you *want* there? Any line that lies?
11. **The big question:** after 5 replays, is "who is holding the speed in this room?" a fun thing to think about — and does Motion Swap change the situation more than it deletes it?

Report: zone, what you did, what you expected, what happened, and whether it felt
like the mechanic's fault or the level's.

## 12. Files touched by this change

New: `scripts/motion_swap/*` (channels, target, controller, 5 adapters),
`scripts/lab/*` (`motion_swap_lab.gd`, `lab_enemy_base.gd`, `enemy_patrol.gd`,
`enemy_gunner.gd`, `enemy_charger.gd`, `lab_crate.gd`, `lab_conveyor.gd`,
`lab_moving_platform.gd`, `lab_pressure_plate.gd`, `lab_gate.gd`, `lab_projectile.gd`,
`lab_cannon.gd`, `lab_debug_overlay.gd`), `labs/motion_swap_lab.tscn`,
`labs/objects/*`, `labs/enemies/*`, `tests/test_motion_swap.gd`,
`tests/test_motion_swap_lab.gd`, `tests/probe_lab_machines.gd`,
`tests/probe_lab_overlap.gd`, `tests/capture_lab.gd`,
`design/MOTION_SWAP_IMPLEMENTATION_PLAN.md`, this file.

Changed: `project.godot` (main scene → the lab; actions `swap_select`, `swap_cancel`,
`lab_debug_toggle`, `lab_reset_zone`, `lab_reset_targets`, `lab_respawn_enemies`;
layers 9/10 named), `scripts/player.gd` (one carrier hook, `carry_motion`),
`scenes/main.tscn` / `scenes/arena.tscn` (migrated to a single authored state),
`DESIGN_BRIEF.md`, `design/MOVEMENT_INTEGRATION_QA.md`.

Removed (Blink): `scripts/blink_manager.gd`, the arena A/B toggle and its
`fight_frozen`/`set_fight_frozen` plumbing, `tests/test_killblink.gd`, the `blink`
input action, Blink HUD/VFX/cooldowns and all scene references. *(Pre-edit copies of
everything are in `artifacts/motion_swap/checkpoint/`.)*
