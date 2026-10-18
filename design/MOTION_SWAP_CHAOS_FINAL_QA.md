# Motion Swap Chaos — implementation and verified handoff

2026-10-18 · Godot 4.7.2 stable, Windows, Compatibility / ANGLE.

**Implemented in the existing project.** E tactical selection, exact two-way
velocity exchange, explicit Overdrive, Iven launches, contact damage, fast physical
gunfire, crate chains, persistent machinery and quick retries are playable.
Final evidence: **L3 INPUT_REPLAY**, 10 clean suites / **412 checks**, rendered
input replay and a verified 10.2-second recording. **Human feel approval remains
pending.** Automated checks do not establish that the game is fun.

- [Gameplay recording, MP4](../artifacts/motion_swap_chaos/MOTION_SWAP_CHAOS_REPLAY.mp4)
- [Raw Godot movie, AVI](../artifacts/motion_swap_chaos/MOTION_SWAP_CHAOS_REPLAY.avi)
- [Final suite summary](../artifacts/motion_swap_chaos/final_suite_summary.json)
- [Acceptance receipts](../artifacts/motion_swap_chaos/acceptance_results.json)
- [Lab receipts](../artifacts/motion_swap_chaos/lab_results.json)
- [Graphical input trace](../artifacts/motion_swap_chaos/capture/input_replay.json)
- [Protected-file verification](../artifacts/motion_swap_chaos/protected_verification.json)
- [Pre-edit audit / design sources](MOTION_SWAP_CHAOS_PLAN.md)

## Launch and controls

Open `E:\neverlookback\project.godot` in Godot 4.7.2 and press **F5**.
Main scene remains `res://labs/motion_swap_lab.tscn`.

| Input | Behavior |
|---|---|
| A/D, arrows | Existing run / reversal / skid |
| Space, W, Up | Existing jump, buffer, coyote time and jump cut |
| Shift, L | Existing dodge roll |
| **E** | Open tactical slow motion; E again cancels |
| **LMB** | Select A, then B; the second valid target executes immediately |
| **Q / RMB** | Choose Iven in either slot; enter E mode first |
| Escape | Cancel and restore full speed |
| **1** | Reset current zone, its puzzle/enemies/crates and Iven to a safe retry point |
| 2 | Clear motion in place, restore machine commands and retire shots |
| 3 | Respawn / reset the enemy roster |
| R | Reload the whole lab, including during tactical selection |
| **F2 / F3 / F4 / F5 / F6 / F7** | Jump directly to zones A / B / C / D / E / F and reset that zone |
| F1 | Expand debug details; ordinary instructions remain visible |
| F8 | Toggle Overdrive for subsequent exchanges |

Changed InputMap actions: `swap_select` is LMB only; `swap_cancel` is Escape only.
Added `swap_activate` (E), `swap_self` (Q/RMB), `lab_overdrive_toggle` (F8), and
`lab_zone_a` through `lab_zone_f` (F2–F7). Removed LMB from legacy `attack` to give
selection exclusive mouse ownership. Existing J/Z legacy attack bindings remain;
the lab still uses movement-preview mode and adds no punching system.

**Fast first test:** F4 → wait for the Charger's committed rightward rush → E →
click Charger → Q. Iven launches right and can kill the nearby patrol on contact.
Press 1 to retry. For a wall crash, stand near the right wall and take a rightward
test-cannon shot with Iven selected. F5 supplies a leftward bullet launch.

## Exchange data flow

1. E starts one monotonic deadline covering **both** selections. All world physics
   uses `Engine.time_scale = 0.12`; the controller and HUD read real time.
2. LMB uses the **click event's viewport position**, transformed through the
   camera into world coordinates. Q/RMB selects Iven's target directly.
3. The component/adapter registry checks live hosts, range, distinct identities,
   finite motion and channel compatibility. No menu, physics-hitbox enlargement,
   AI-goal exchange or position exchange is involved.
4. Capture A's actual motion and B's actual motion **before either write**.
   Apply B to A, then A to B. Record the original received values.
5. Apply the separate optional Overdrive modifier once. Record the final values.
   An active modifier carries its remaining expiry if transferred again, so the
   same boosted motion is not multiplied twice.
6. Restore full speed immediately and start a real-time cooldown. Character
   locomotion yields briefly; gravity and collision solving continue.
7. Actual contact normals and relative incoming velocities produce consequences.
   Empty-space speed, targeting, and visual effects never cause damage.

Deletion/disabling/range loss of A, death, timeout, cancel, invalid channels,
reset, controller exit and scene exit restore the clock. Empty-space clicks keep
the current selection only until the original bounded deadline. Repeated-target
selection cancels. R consumes its event before removing the old scene.

## Tuning and target combinations

All listed gameplay tuning is exported on the relevant controller/actor scripts.

| Parameter | Default | Clock / meaning |
|---|---:|---|
| `slow_motion_scale` | 0.12 | World simulation multiplier |
| `selection_timeout` | 1.5 s | Monotonic real time from E, not from A |
| `cooldown` | 0.5 s | Monotonic real time after success |
| `max_range` | 520 px | Player to target anchor |
| `grab_radius` | 40 px | Cursor targeting slop |
| `projectile_grab_radius` | 48 px | Targeting only; physical bullet radius remains 7 px |
| `overdrive_enabled` | true | F8 A/B toggle |
| `overdrive_multiplier` | 1.25 | Applied once after the exact exchange |
| `overdrive_min_speed` | 250 px/s | Minimum received magnitude for amplification |
| `overdrive_duration` | 0.12 s | Physics time; does not rearm locomotion timers |
| `character_override_time` | 0.65 s | Enemy AI yields, resumes at current location |
| `swap_launch_duration` | 0.24 s | Iven's short forced-motion window |
| `swap_launch_drag` | 650 px/s² | Launch deceleration before ordinary recovery |
| `living_projectile_threshold` | 480 px/s | High-impact Iven state; includes Overdrive crossing it |
| `wall_stun_duration` | 0.28 s | Nonlethal wall-crash input lock |
| Gunner `projectile_speed` | 1,200 px/s | Physical, non-homing shot |
| Gunner aim / locked slice | 0.65 / 0.22 s | Honest pre-fire line |
| Gunner cycle / recovery | 1.15 / 0.4 s | Holds between aimed shots |
| Charger `charge_speed` | 600 px/s | Direction committed during 0.5 s warning |
| Projectile `max_life` | 2.0 s | World time; parked rounds deflate after 1.6 s |
| `hitstop_real_seconds` | 0.028 s | Contact accent at 0.04 scale; optional |
| `camera_shake_pixels` | 1.8 px | Bounded offset; 0 disables shake |

At expiry, Overdrive removes its remaining added component from the current
velocity. It does not restore a stale source value or resurrect motion removed by
collision. A zero exchange stays zero until gravity/contact changes it. Machines
skip Overdrive and retain their command until another swap or explicit reset.

| Channel | Compatible pairs | Exchanged quantity |
|---|---|---|
| LINEAR | Any two distinct Iven / enemy / projectile / crate targets | Full current world-space Vector2 |
| SURFACE | Belt ↔ belt, belt ↔ platform | Signed operating speed |
| PLATFORM | Platform ↔ platform, platform ↔ belt | Signed path command within authored bounds |

LINEAR ↔ machine and unknown channels are refused without writing either target.
Enemy identity, bullet ownership/team, positions and authored machinery paths
remain their own. Both orders work. There is no Blink action, manager, A/B
transition, active Blink group, freeze, UI or VFX.

## Self launch and physical consequences

Iven receives velocity directly and immediately. During the short launch, normal
run acceleration cannot overwrite it; orientation follows its horizontal sign,
gravity remains active, and existing movement clips carry presentation. After the
initial 0.10 s commitment, a new jump/dodge press can request early recovery. Normal
movement resumes when the launch expires. This adds no new animation or long lock.

Contact speed is `max(0, -(incoming_velocity - collider_velocity).dot(normal))`.
Below the resolver's 180 px/s noise floor there is no impact response. Targets
then apply their exported class thresholds:

| Target / contact | Threshold | Result |
|---|---:|---|
| Normal enemy, medium contact | 220 px/s | 1 damage and 0.30 s stagger |
| Normal enemy, high contact | 430 px/s | 2 damage and stagger |
| Normal enemy, extreme contact | 680 px/s | Up to its full HP in damage |
| Normal enemy hit by launched Iven | 480 px/s closing speed | Up to full HP; ordinary running never enables this rule |
| Heavy Charger, extreme / human-projectile contact | Same speed gates | 3 damage, stagger and physical response; starts at 5 HP |
| Iven launched into wall | 480 px/s closing speed | Remove wall-normal motion and stun 0.28 s; no automatic death |
| Iven launched into crate/body | High-speed contact | Remove/reduce normal momentum and shorten recovery |
| Iven struck by fast crate | 520 px/s | 1 damage and 0.16 s reaction, through existing Health iframes |
| Hazard | Existing hurtbox contact | Remains dangerous; self swap grants no immunity |

Enemy HP remains Patrol 4, Gunner 3, Charger 5. Existing damage iframes remain.
A recent accepted hit can therefore gate another damage event. Character-body
momentum response is a tunable gameplay approximation, not a Newtonian mass solver:
normal impulses push crates, while character contact transfers a fraction of the
normal motion (reduced for heavies). Rigid crates retain Godot's collision solver.

Damage is attached to actual slide/contact reports. Pair/frame marks suppress
duplicate manifold/slide callbacks; health iframes provide a second gate. Fast
tangential floor travel does no damage. Crates use shape CCD and contact reports;
shots ShapeCast their entire displacement **before** moving each physics step.
They still travel over multiple frames and remain selectable. Enemy bullets keep
their enemy team; the two lab cannons fire explicitly harmless LAB rounds.

Hazard HitBoxes now defer the first contact hit out of the physics flush instead
of waiting for their periodic tick. This fixes fast Iven crossing spikes between
samples. It does not add area damage, explosion triggers or supernatural immunity.

## Six retained zones

The same continuous facility and zone builders remain; no final map was made.

| Shortcut | Zone | Main experiment |
|---|---|---|
| F2 | A — Bullet to Enemy | Ground Gunner, Patrol and impact wall; two crates behind the teaching lane |
| F3 | B — Charger to Crate | Charging enemy, two crates and Gunner for contact chains |
| F4 | C — Human Projectile | Charger, close normal target, open recovery lane, crate, rightward test cannon and crash wall |
| F5 | D — Projectile to Iven / machinery | Leftward 1,200 px/s test cannon; retained two belts, lift and crates |
| F6 | E — Physics puzzle | Original lift → belt → crate → latching plate → gate chain |
| F7 | F — Mixed Chaos | Patrol, Gunner, Charger, crates, belt and spike strip |

There are nine instances of the same three enemy classes, eleven crates, six
machines, one latching plate and gate, and two test cannons. Zone reset retires
shots, restores objects/enemies and clears launch/stun/cooldown/time. Enemy respawn
ledger entries and pending fall recovery are reconciled to avoid duplicate respawns.
Fallback player weight still opens the gate. Existing world limits, camera zoom,
follow settings and movement-test locked camera are preserved; feedback adds only
the bounded lab camera offset.

## Tests executed and actual results

Final selection of logs is recorded in `final_suite_summary.json`; earlier failed
logs remain present and are not labelled passes. The old 95-check lab suite used
obsolete controls, object positions and a 2.5 s override. It was migrated to 32 lab
integration checks plus the separate 65-check chaos acceptance suite.

| Executed suite | Result |
|---|---:|
| `test_motion_swap_chaos.gd` | 65 checks, 0 failures, no script errors; latest `test_motion_swap_chaos_final_04.log` |
| `test_motion_swap_lab.gd` | 32 checks, 0 failures |
| `test_motion_swap.gd` | 43 checks, all pass; Overdrive disabled to isolate the faithful exchange |
| `test_runtime.gd` | 7 checks, all pass |
| `test_arena.gd` | 15 checks, all pass |
| `test_identity.gd` | 21 checks, all pass |
| `test_weapon.gd` | 50 checks, all pass |
| `test_feel.gd` | 10 checks, all pass |
| `test_strand.gd` | 3 checks, all pass |
| `test_movement_integration.gd` | 166 assertions, 0 failures, 2,032 samples |
| Headless import and main-scene boot | PASS; validation receipt `20261018T094809234Z-3d497f16` |
| Normal graphical replay | PASS on corrected staging/input; `graphical_03.log` |
| Godot movie/input replay | 7 visible assertions, 0 failures, 610 sampled states; `movie_01.log` |
| MP4 decode verification | Exit 0, no decode errors; 1,280×720, 612 frames, 60 FPS, 10.2 s |
| Protected SHA256 comparison | 29,789 files compared, **0 changed** |

The 22 requested scenarios are covered as follows:

| Requested scenario | Evidence |
|---|---|
| 1–4: E, 1.5 real seconds, completion, cancel | Clock tests; observed unarmed selection ~1.50–1.52 real seconds; E/E and Escape tests |
| 5–8: fast selection, bullet/enemy, Charger/crate, enemy/enemy | Acceptance contacts and exact-value checks; graphical LMB replay |
| 9–10: Iven/Charger and Iven/projectile | Actual committed AI → 750 rightward launch; -1,200/-120 source → -1,500/-150 received Overdrive |
| 11–14: normal kill, wall stun, normal run, heavy | Physical contacts; heavy retains 2/5 HP; normal run leaves enemy alive |
| 15: chains | Enemy/enemy, crate/Gunner, Iven/crate, finite body states, actual machine puzzle |
| 16–17: optional Overdrive and no stacking | Disabled exact exchange; one-shot boost, expiry and same-frame inherited-provenance test |
| 18–20: gravity, persistent machines, no Blink | Zero-motion falling, platform riding, machine persistence, Blink guard |
| 21: movement | RUN, SKID_STOP, JUMP, DODGE_ROLL in lab and full 166-assertion training-room suite |
| 22: reset | All zone shortcuts/reset checks, target reset, enemy reset, death, and actual R reload during selection |

Additional contact evidence: a 1,400 px/s bullet stops before a **2 px wall**;
a fast CCD crate stops at x≈729 before a wall at x=750; high-speed Iven moves a
crate to x≈690 with ~820 px/s remaining crate velocity. No direct damage callback
was used to fake these collision outcomes.

Actual graphical observation checked selected brackets/arrows, the shrinking real
timer, thin rounds, right/left launch direction, patrol disappearance on contact,
STUN countdown, machine crossing, plate/gate and readable compact/debug HUDs.
PNG frames are in `artifacts/motion_swap_chaos/capture/01_entry.png` through
`12_debug.png`. The replay uses real E/Q/LMB input events, zone shortcuts, and
explicit test-cannon firing to arrange the short demonstration. It is scripted
engine gameplay, not an unscripted human playtest.

Normal graphical sample, separate from movie encoding: Intel HD Graphics 4600,
ANGLE/D3D11, 1,280×720, mixed zone with quick resets, 9 enemies, up to 3 live shots.
Over 6.008 real seconds / 446 frames: FPS monitor median **75**, minimum **50**;
median frame interval **13.366 ms**, p95 **17.082 ms**. Synthetic E event to a
completed rendered frame with the veil visible: **28.939 ms**. These are bounded
samples, not worst-case performance or physical keyboard/display latency claims.
See `capture/performance.json` and `profile_03.log`.

The skill's original validator uses `.NET ProcessStartInfo.ArgumentList`, absent
on this host's PowerShell 5.1. A task-local copy adapts that one argument-building
line; it produced the passing import/runtime receipt. The original skill is
unchanged. Godot also reports its existing Intel OpenGL driver fallback to ANGLE.
Neither is hidden as a gameplay test pass.

## Exact source changes

Machine-readable inventory: `artifacts/motion_swap_chaos/changed_files.json`.

Modified existing files:

```text
design/MOTION_SWAP_LAB_QA.md
labs/enemies/charger.tscn
labs/motion_swap_lab.tscn
project.godot
scripts/hitbox.gd
scripts/lab/enemy_charger.gd
scripts/lab/enemy_gunner.gd
scripts/lab/lab_cannon.gd
scripts/lab/lab_crate.gd
scripts/lab/lab_debug_overlay.gd
scripts/lab/lab_enemy_base.gd
scripts/lab/lab_projectile.gd
scripts/lab/motion_swap_lab.gd
scripts/motion_swap/adapters/adapter_base.gd
scripts/motion_swap/adapters/adapter_character.gd
scripts/motion_swap/adapters/adapter_rigid_body.gd
scripts/motion_swap/motion_channels.gd
scripts/motion_swap/motion_swap_controller.gd
scripts/motion_swap/motion_swap_target.gd
scripts/player.gd
tests/capture_lab.gd
tests/test_motion_swap.gd
tests/test_motion_swap_lab.gd
```

Added files:

```text
.gitignore
design/MOTION_SWAP_CHAOS_PLAN.md
design/MOTION_SWAP_CHAOS_FINAL_QA.md
scripts/lab/lab_motion_feedback.gd
scripts/lab/lab_motion_feedback.gd.uid
scripts/motion_swap/impact_response.gd
scripts/motion_swap/impact_response.gd.uid
tests/capture_motion_swap_chaos.gd
tests/capture_motion_swap_chaos.gd.uid
tests/test_motion_swap_chaos.gd
tests/test_motion_swap_chaos.gd.uid
```

All task-generated logs, receipts, captures, the compatibility validator copy and
recordings are under `artifacts/motion_swap_chaos/`. The pre-existing movement
test also writes its normal `artifacts/movement_integration/runtime_*.json` outputs.

No Git repository existed initially. Created a source checkpoint before code:
`5148847f05c6a10f2673557a888ec9faf04152b9`. `.gitignore` excludes large approved
binary/history/tool trees; they are protected by hashes rather than copied into
Git. `art/**`, `maincharacter/**` (including AccuRIG, Meshy, R3, rigs and animation
sources), player scene, Iven movement/flame visual scripts and movement test
scene/controller were not changed. The final gameplay changes remain reviewable
as the working-tree diff plus the listed new source files.

## Remaining limits and human playtest checklist

- Human judgement of intensity, clarity, learning time and fun is **not approved**.
  Existing enemy grayboxes and the existing no-op audio hook remain; no character
  art, rig, approved clip or additional weapon system was produced.
- The 6-second performance sample does not cover the 16-shot population cap,
  arbitrary crate piles, all machines running, every device, or long-session soak.
- External reference pages informed principles; Katana's site returned 403,
  direct media retrieval was unavailable, and no external trailer is claimed as
  watched. Previous lab screenshots were inspected; the delivered replay is ours.
- The inherited movement suite previously documented a timing flake; this run's
  166 assertions passed. Do not infer that one run proves the flake cannot recur.
- Lab rounds are harmless experimental motion sources. Gunner rounds are real
  threats. Damage iframes and per-pair contact deduplication are intentional.
- L4 export / black-box release validation was not requested or run.

Human checklist:

1. Enter E from ordinary movement and during a close incoming shot. Identify A/B
   without F1; judge whether the real 1.5 s decision window is readable enough.
2. Repeat F4 → Charger → Iven ten times, with both orders and left/right sources.
   Judge whether the launch is expressive and recovery remains responsive.
3. Hit the normal target, heavy, crate and wall. Confirm consequences are legible,
   wall stun feels brief, and low-speed contact is not confused with a kill move.
4. Use F5 to take a leftward bullet; test vertical motion while airborne. Confirm
   direction is predictable without auto-aim and hazards still punish mistakes.
5. Compare F8 on/off at the same spacing; keep/tune multiplier, drag and thresholds
   based on actual feel rather than the passing values alone.
6. Try F3 crate chains, F6 puzzle/fallback gate, then F7 mixed combat. Break/reset
   the lab repeatedly, including death, falls, active E mode and scene reload.
7. Check target acquisition with real mouse input at native resolution, long
   sessions, crowded overlaps and the shot cap. Review shake at 1.8 px and 0 px.
8. Confirm RUN/JUMP/SKID/DODGE retain their approved feel and character appearance.

## Reproduce the gates

```powershell
$engine = 'C:\Users\Aloha\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& $engine --headless --path E:\neverlookback --script res://tests/test_motion_swap_chaos.gd
& $engine --headless --path E:\neverlookback --script res://tests/test_motion_swap_lab.gd
& $engine --headless --path E:\neverlookback --script res://tests/test_motion_swap.gd
& $engine --headless --path E:\neverlookback --script res://tests/test_movement_integration.gd
& $engine --path E:\neverlookback --script res://tests/capture_motion_swap_chaos.gd
& $engine --path E:\neverlookback --script res://tests/capture_motion_swap_chaos.gd -- --profile
```

The compatibility `tests/capture_lab.gd` entry now invokes the updated capture.
For movie output, append `--write-movie E:\neverlookback\artifacts\motion_swap_chaos\MOTION_SWAP_CHAOS_REPLAY.avi`.
