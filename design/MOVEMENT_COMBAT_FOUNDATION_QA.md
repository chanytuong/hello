# Movement and combat foundation repair

> Current roll prototype: [Dodge roll V2 QA](DODGE_ROLL_V2_REDESIGN_QA.md) supersedes roll repeat/readiness and presentation below. Damage, Motion Swap and collision rules remain the foundation baseline.

> Later roll tuning: [Final roll feel QA](FINAL_ROLL_FEEL_QA.md) supersedes this report's 80 px / 0.24 s roll specification. Damage, Motion Swap and collision rules below remain the foundation baseline.

2026-10-18 · `E:\neverlookback` · Godot 4.7.2 stable · Windows / Compatibility / ANGLE.

**Implemented and verified in the existing project.** The roll now travels **80 px**, supports air use and immediate input cancels, and passive enemy presence causes no damage. One action arena replaces the existing Zone F encounter. **Human movement feel, visual acceptance and arena enjoyment remain pending.**

Checkpoint before gameplay edits: `4d8c41ae17f9d10127bc200f9e23ba1be2b69177` (`checkpoint: Motion Swap Chaos before movement and combat foundation repair`). Earlier Motion Swap and movement reports describe their historical tuning; this report supersedes their roll, enemy contact and Zone F sections.

## Evidence

- [Before / after recording](../artifacts/foundation_repair/BEFORE_AFTER.mp4), [before separately](../artifacts/foundation_repair/BEFORE.mp4), [after separately](../artifacts/foundation_repair/AFTER.mp4).
- [Arena recording](../artifacts/foundation_repair/ARENA.mp4): real Gunner shot, E slow motion, LMB shot/Gunner exchange, physical launch, air roll and reset.
- [Final suite summary](../artifacts/foundation_repair/final_verified_summary.json): **12 suites, 461 checks/assertions, zero failures or script errors**.
- [Foundation receipts](../artifacts/foundation_repair/foundation_results.json), [arena receipts](../artifacts/foundation_repair/arena_results.json), [damage trace and foundation log](../artifacts/foundation_repair/test_foundation_repair_verified.log).
- [Before measurements](../artifacts/foundation_repair/before/reproduction.json), [after measurements](../artifacts/foundation_repair/after/reproduction.json), [arena input trace](../artifacts/foundation_repair/arena/replay.json).
- [Media decode verification](../artifacts/foundation_repair/media_verification.json), [protected asset verification](../artifacts/foundation_repair/protected_verification.json), [delivery receipt](../artifacts/foundation_repair/DELIVERY_RECEIPT.json).

These are scripted runs of the real Godot controller and physics. Rendered frames were inspected. They are not human playtesting or exported-build certification. The native 1280×720, 60 fps MP4s decode without errors. Movie Maker fixes game time to 60 Hz; recording throughput is not a live FPS benchmark.

## Reproduced causes and measured change

The pre-edit replay reproduced both movement restrictions and unearned contact damage. It did **not** reproduce a literal full-health one-hit kill; that claim remains unconfirmed.

| Measurement | Before | After |
| --- | --- | --- |
| Configured roll duration | 0.70 s | 0.24 s |
| Travel on empty ground, no held direction | 195.99 px | 80.00 px |
| Physics time including the inactive exit update | 0.7167 s | 0.2667 s |
| First accepting update | 280 px/s | 320 px/s, movement already applied |
| Left press during a right roll, next update | Still +280 px/s, roll active | −280 px/s, roll cancelled |
| Midair roll | Refused | Active, existing roll clip |
| Stationary Patrol, 33 px centre separation, 90 ticks | HP 5→3, −3.33 px displacement | HP 5→5, zero displacement |

At 60 Hz the new timer produces 15 movement ticks (0.25 s), then the inactive exit tick. This quantization explains the difference from the 0.24 s tuning value; both measured duration and travel satisfy the requested ranges. Travel measurements exclude later held RUN movement.

Actual causes:

1. The controller repeatedly overwrote horizontal input with a 0.70-second roll, required grounded state, cleared the roll in air and imposed the dash cooldown. Animation was following that long gameplay commitment, not creating it.
2. Every lab enemy and both legacy enemies began a continuous TouchHitBox at spawn. The Patrol's 22 px touch radius reached beyond its 15 px solid capsule; the player capsule radius is 14 px. Thus a 33 px gap could hurt and knock back Iven without solid contact or an attack.
3. Generic impacts admitted ordinary character contact at 180 px/s and transferred forced motion. Normal movement also supplied stale, pre-input velocity to the impact resolver. Default character platform layers could carry another character.
4. Forced-motion early cancellation consumed fresh jump/dodge input, then returned without executing the requested replacement action.
5. Legacy projectile Areas could keep their continuous damage route after a hit. Damage events had no source provenance, obscuring which route caused HP loss.
6. Arena verification exposed a second state issue: generic wall-impact cleanup interrupted a Charger's charge before its promised wall stun. The charge-crash state now survives that cleanup. Final arena muzzle placement also clears each Gunner's own perch.

The pre-edit audit, research and implementation order are recorded in [the plan](MOVEMENT_COMBAT_FOUNDATION_PLAN.md). Foundation 33/33 and Motion Swap 65/65 passed before arena construction began; later edge coverage raised foundation acceptance to 34 checks.

## Roll behavior

Fresh Shift/L starts or restarts the roll on the accepting update. It assigns ±320 px/s rather than adding velocity. There is no recovery lock or repeated-roll cooldown. Fresh directional input, direction reversal or release of the previously held direction cancels immediately; already-held RUN input can carry through RUN→ROLL→RUN. A permitted jump cancels into the normal jump. Simultaneous jump/roll gives jump priority.

Air roll keeps ordinary gravity, jump release cut and the existing jump budget. It does not reset coyote time, add a vertical impulse or grant another jump. Repeated ground/air rolls remain bounded at 320 px/s. The same solid collision solver handles movement and stops an airborne roll at a 2 px wall.

The existing roll atlas is sampled on the shorter timer, with roll visual priority in air and the final source drawing retained. Playback introduces no root motion. No sprite, frame, rig, flame source, neck-anchor data or Blender asset was edited. The shared roll path is used by the active lab and movement test; the separate legacy combat scene retains its original dash presentation.

## Explicit damage rules

| Source | Rule |
| --- | --- |
| Detection / proximity | No damage and no force. Patrol and Gunner TouchHitBoxes remain inactive. |
| Ordinary body contact | Solid separation only below 480 px/s closing speed for character pairs; no generic damage or forced-motion transfer. Characters are excluded from character carrier layers. |
| Charger attack | Only CHARGE, with its box armed, committed front-face body contact and at least 200 px/s forward relative speed. One victim hit per charge epoch. Windup, recovery, stun and interrupted charge are inactive. |
| Legacy attacks | Existing STRIKE / slam active windows remain; passive touch damage is disabled. |
| Projectiles | Lab shots use a full-displacement ShapeCast and retire at the first solid hit. Legacy shots use one damage epoch and retire after an accepted hit. |
| Physical impact | Actual contact only: `max(0, -(incoming - other_velocity).dot(normal))`. Character pairs require 480 px/s for the generic response; world/prop contacts retain their separate thresholds. |
| Environment | Explicit hazard Areas retain their existing timed damage. Roll and self launch grant no new hazard immunity. |

One contact has one damage authority. An ordinary Iven/active Charger collision uses the charge attack, including when the Charger catches a running player below the generic impact gate. A self-launched living-projectile Iven uses the physical impact route instead. Attack epoch marks, existing victim iframes and the generic resolver's per-pair 10-tick guard suppress repeated/manifold damage. The charge repeat test disables player iframes to prove the epoch itself prevents repeated hits.

High-speed Motion Swap consequences remain: enemy/object impacts, Iven launching into enemies, crate momentum transfer and a short self-launch wall stun. Ordinary RUN/ROLL wall contact causes neither that stun nor damage. Existing enemy impact damage thresholds remain, as does one player HP damage from a real fast-crate impact at 520 px/s or above. No damage occurs just because a body moves quickly in empty space.

For source-labelled logging, run the project with `-- --damage-trace`. `NLBHealth.trace_damage` defaults to false. Trace events contain kind, source/emitter, incoming/source velocity, contact, amount, accepted/rejected status, HP before/after, victim velocity and physics frame. Contact damage and swept bullets include the real solver point and normal. Area attacks/hazards report the overlap location; they do not invent a physical manifold normal. Events are captured before synchronous death/respawn handlers and the debug buffer is capped at 512.

Example from the real charge test: source `Charger/Charge`, velocity `(−600, 0)`, contact `(3014, 581.93)`, normal `(1, 0)`, amount 1, HP 5→4. Subsequent contact frames do not add damage or a generic impact hit. Normal gameplay prints no `DAMAGE_TRACE` lines.

## One arena, inside Zone F

Use **F7 in the running lab**. The existing Zone F now contains exactly two Gunners, one Charger, two movable crates and an 84 px high jumpable cover wall. No new scene/map, species, sprites or ability was added. The former Zone F Patrol, floor spikes and conveyor were removed; machinery and the plate/gate experiment in Zones A–E remain.

Spawn is `(7080, 599)`, clear of enemy and crate shapes. The Charger shows a 0.65-second committed arrow and the cover stops its opening charge. Gunners use the existing tracking/locked aim lines, 0.75/0.80-second aim windows and staggered fire cycles. Their inward muzzle positions produce actual shots clear of the perches. The left shot offers an open exchange opportunity; the cover blocks the right lane until the player changes position. Jump, roll, cross the cover, exchange a shot into a body/crate, then press **1** to repeat. Roll repositions Iven; it is not an invulnerability window.

Tests verify an undamaged first 0.75 seconds, visible inactive windup, both aim telegraphs, a natural swappable shot, cover stun and a normal jump/air-roll/movement escape with **HP 5/5 and zero deaths** in the final scripted opening. Reset restores HP, spawn, props, removed enemies, selection and normal time. These establish a repeatable, avoidable opening, not that every route is safe or that the arena is fun.

## Actual validation

| Suite | Checks / assertions | Result |
| --- | ---: | --- |
| Foundation repair | 34 | Pass |
| One Zone F arena | 15 | Pass |
| Motion Swap Chaos | 65 | Pass |
| Lab integration | 32 | Pass |
| Motion Swap contract | 43 | Pass |
| Runtime | 7 | Pass |
| Legacy arena | 15 | Pass |
| Identity | 21 | Pass |
| Weapon | 50 | Pass |
| Feel regressions | 10 | Pass |
| Strand | 3 | Pass |
| Movement integration, both directions | 166 | Pass |
| **Total** | **461** | **Zero failures** |

Coverage includes same-update activation, all requested rapid roll sequences, five immediate roll restarts without accumulation, air jump-budget preservation, 2 px wall collision, idle Patrol proximity, detection without pull, ordinary body contact, genuine charge damage, charge chasing a running player, epoch suppression with iframes disabled, one-hit projectiles, genuine high-speed impacts, self swap, Overdrive, real-time selection deadlines, cancellation/death/reload time restoration, and the existing scene/animation/neck/flame regressions.

The rendered arena replay adds four passing visible assertions: natural shot, real LMB shot selection, real LMB shot/Gunner exchange, and quick reset. Project import and headless smoke validation also pass. No exported executable was built or tested. The machine reports a known Intel OpenGL driver warning and automatically uses ANGLE; there are no project script errors in final runs.

Older tests were updated only where the accepted specification changed: 196 px roll expectations became 60–90 px; roll-exit checks inspect the actual transition before a longer replay reaches a boundary; the lab expects five remaining machines; the hazard immunity check now creates an isolated physical hazard instead of depending on the removed arena spikes. Initial fixture/timing failures and their logs remain in the artifact directory; the final summary identifies passing reruns.

## Files changed

- Movement: `scripts/player.gd`, `scripts/iven_movement_visual.gd`.
- Damage provenance and windows: `scripts/health.gd`, `scripts/hurtbox.gd`, `scripts/hitbox.gd`, `scripts/hazard.gd`.
- Enemy/contact/projectile repair: `scripts/motion_swap/impact_response.gd`, `scripts/lab/lab_enemy_base.gd`, `scripts/lab/enemy_charger.gd`, `labs/enemies/charger.tscn`, `scripts/lab/lab_projectile.gd`, `scripts/lab/lab_crate.gd`, `scripts/melee_chaser.gd`, `scripts/ranged_enemy.gd`, `scripts/projectile.gd`. The crate receiver's optional context parameter preserves the shared impact interface.
- Arena: `scripts/lab/motion_swap_lab.gd` (existing Zone F builder).
- Updated regressions: `tests/test_motion_swap_lab.gd`, `tests/test_movement_integration.gd`.
- New real-scene tests/replays: `tests/test_foundation_repair.gd`, `tests/test_foundation_arena.gd`, `tests/foundation_replay.gd`, `tests/capture_foundation_arena.gd`, with generated `.uid` companions.
- Documentation: this report, `MOVEMENT_COMBAT_FOUNDATION_PLAN.md`, and supersession notices in the earlier movement/Chaos reports.

[Exact changed-file manifest](../artifacts/foundation_repair/changed_files.json). The SHA256 verification matched **29,788 protected entries**, including `art/**` and `maincharacter/**`; zero differences. The intentionally edited playback script is explicitly excluded. Camera/framing, source rigging and the open AccuRIG benchmark files remain unchanged. Unrelated pre-existing untracked work was not included in the checkpoint or this repair.

## Reproduce and human playtest

Open `project.godot` in Godot and use editor **F5** to launch the lab. Press **F7 inside the game** for this arena; **1** retries it. A/D or arrows move; Space/W/Up jumps; Shift/L rolls on ground or in air. Test RUN→ROLL→RUN, ROLL→REVERSE, ROLL→JUMP, JUMP→AIR ROLL→MOVE and rapid repeated rolls in the open central lane.

Use **E** to enter tactical slow motion; LMB selects A then B. **Q/RMB** selects Iven as either endpoint. Escape or E cancels. **F8** toggles Overdrive. **2** clears exchanged motion, **3** restores enemies, **R** reloads. The unchanged lab shortcuts **F2–F7** visit Zones A–F; **F1** expands diagnostic details.

For isolated visual movement review, open `scenes/movement_test.tscn` and use editor **F6** to run that scene. Check that the shortened existing roll and air pose read well at native size, and that reversal/jump feel immediate. In the arena, move off a locked aim line, jump/roll, swap a shot into a Gunner or crate, try a self launch, and repeat with 1. Assess readability, input comfort and perceived stiffness; no automated result substitutes for this feedback.

From PowerShell, set the local Godot executable and run the reproducible real-scene suites:

```powershell
$godotExe = 'C:\Users\Aloha\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --path E:\neverlookback --script res://tests/test_foundation_repair.gd
& $godotExe --headless --path E:\neverlookback --script res://tests/test_foundation_arena.gd
& $godotExe --headless --path E:\neverlookback --script res://tests/test_motion_swap_chaos.gd
& $godotExe --path E:\neverlookback --script res://tests/foundation_replay.gd --write-movie E:\neverlookback\artifacts\foundation_repair\AFTER.avi -- --after
& $godotExe --path E:\neverlookback --script res://tests/capture_foundation_arena.gd --write-movie E:\neverlookback\artifacts\foundation_repair\ARENA.avi
& $godotExe --path E:\neverlookback -- --damage-trace
```

The preserved BEFORE recording was captured before edits at the checkpoint. Running the current controller cannot recreate its old behavior; an isolated checkout at that checkpoint plus the diagnostic fixture and existing local assets is required. The replay now defaults to AFTER to protect the original evidence.

Remaining limits: subjective feel/fun approval is pending; no new roll immunity or combat animation was introduced; repeated rolls intentionally allow continuous bounded horizontal movement while gravity continues. Long-duration emergent arena combinations and an exported build have not been human tested. Scope stops at these repairs and this one prototype arena.

Research used primary development accounts: [Motion Twin on responsive controls, enemy patterns and the dedicated dodge](https://blog.playstation.com/2018/01/25/rogue-lite-action-platformer-dead-cells-coming-to-ps4-this-year/), [Playdigious on testing and rejecting ambiguous jump/dodge input](https://www.gamedeveloper.com/design/porting-i-dead-cells-i-to-mobile-an-in-depth-breakdown), and [Askiisoft's description of tight acrobatic action](https://askiisoft.com/). The design inference is to preserve distinct input intent and allow short interruption; no undocumented Dead Cells/Katana ZERO frame counts were copied, and no external gameplay video is claimed as viewed. Collision implementation follows the official [CharacterBody2D](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html) and [KinematicCollision2D](https://docs.godotengine.org/en/stable/classes/class_kinematiccollision2d.html) APIs.
