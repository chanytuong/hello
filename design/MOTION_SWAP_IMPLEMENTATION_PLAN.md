# MOTION SWAP — implementation plan (Phase 0 output)

2026-10-18. Written BEFORE any code change. Companion document: `MOTION_SWAP_LAB_QA.md`
(written after implementation, holds verified results).

## 0. What was inspected

- `project.godot` — Godot 4.7.2, GL Compatibility, 1280×720, physics 60 Hz.
  Launch scene `res://scenes/movement_test.tscn`. Input actions: `move_left`,
  `move_right`, `jump`, `dash`, `attack`, **`blink`**, `restart`.
- `scenes/movement_test.tscn` + `scripts/movement_test.gd` — the ACTIVE playable
  scene (movement prototype room). No Blink usage at runtime.
- `scenes/player.tscn` + `scripts/player.gd` — the real Iven controller
  (`CharacterBody2D`, two modes: legacy combat and `movement_preview` used by the
  active scene). Movement tuning is preserved and not touched.
- `scenes/main.tscn`, `scripts/game.gd`, `scripts/arena.gd`, `scripts/hud.gd`,
  `scripts/blink_manager.gd`, `scripts/{melee_chaser,ranged_enemy,projectile,
  prop,hazard,health,hitbox,hurtbox}.gd` — the older single-room Blink arena
  ("legacy combat scene"; still openable with F6).
- `tests/*` — 7 headless suites + probes; several reference `NLBBlinkManager`
  and the `blink` input action.
- `art/iven/movement/` — the approved Iven body atlas, anchors and flame; the
  player scene already renders them (`iven_movement_visual.gd`, `iven_flame.gd`).
- `agentskill/` (16 skill packs). Read deeply only: `game-feel-skill-main`
  (feel = engineering target, six layers, 100 ms response rule, verification
  checklist) and `godot-game-studio-agent-main` (evidence levels L0–L4, scene
  ownership rules, "no new debugger errors = gate").
- Godot 4 docs behaviour used: `CharacterBody2D.move_and_slide`,
  `RigidBody2D.linear_velocity` (set outside the physics step), `Area2D`
  overlap routing, `AnimatableBody2D` + `sync_to_physics` for carriers.
- Design references (SUPERHOT, Into the Breach): a strange world rule taught by
  doing, threats telegraphed before they resolve, environmental objects that are
  usable from many positions (not special-cased), and player choices that are
  legible at a glance.

## 1. Blink audit — verdict per file

| File | Blink content | Verdict |
|---|---|---|
| `scripts/blink_manager.gd` | the whole mechanic | **REMOVE** |
| `project.godot` | `blink` input action, description | **MIGRATE** |
| `scenes/main.tscn` | `BlinkManager` node | **MIGRATE** |
| `scripts/game.gd` | blink signals, freeze, flash, projectile clearing | **MIGRATE** |
| `scripts/arena.gd` | A/B state toggling, eject rules, `blinkables` | **MIGRATE** |
| `scripts/hud.gd` | BLINK bar/state text | **MIGRATE** |
| `scripts/player.gd` | `fight_frozen` freeze path, Blink arrival pose | **MIGRATE** |
| `scripts/melee_chaser.gd`, `ranged_enemy.gd` | `is_b`, `apply_blink`, `set_fight_frozen` | **MIGRATE** |
| `scripts/hazard.gd` | `apply_blink` wrapper, `blinkables` group | **MIGRATE** |
| `scripts/prop.gd` | Blink access hint text, `fight_frozen` guard | **MIGRATE** |
| `tests/test_killblink.gd`, `tests/probe_state_b.gd` | Blink-only tests | **REMOVE** |
| `tests/test_arena.gd`, `test_runtime.gd`, `test_weapon.gd`, `test_identity.gd`, `test_movement_integration.gd`, `probe_feel*.gd`, `probe_run_se.gd`, `dbg_*.gd`, `audit_combat.gd` | Blink scenarios/assertions | **MIGRATE** (drop Blink, keep everything else) |
| `docs/**` | historical Blink records | **RETAIN** (history, not runtime) |
| `_archive/prototype-v1/**` | old Blink prototype | **RETAIN** (archived already) |

Preserved: perception-weapon experiment (prop + player `weapon_*` contract),
movement tuning, run/skid/jump/roll, enemies, hitbox/hurtbox/health, hazards,
all approved art and Blender sources. Nothing is renamed from Blink to Motion
Swap: the toggle behaviour is deleted, not relabelled.

## 2. Motion Swap — architecture

```
scripts/motion_swap/
  motion_channels.gd      channel enum + explicit compatibility table
  motion_swap_target.gd   component: identity + adapter + group registration
  motion_swap_controller.gd  targeting state machine, range, cooldown, exchange
  adapters/adapter_base.gd        read_motion() / apply_motion() / label()
  adapters/adapter_character.gd   LINEAR  (CharacterBody2D)
  adapters/adapter_rigid_body.gd  LINEAR  (RigidBody2D crate)
  adapters/adapter_projectile.gd  LINEAR  (Area2D projectile)
  adapters/adapter_conveyor.gd    SURFACE (persistent surface speed)
  adapters/adapter_platform.gd    PLATFORM (bounded travel, persistent command)
```

- One target = one component + one adapter. The controller never inspects the
  host's class, so a new swappable object costs one adapter file, not a branch
  in a growing manager.
- Exchange is always: capture A, capture B, **then** apply B to A and A to B.
- Channels: `LINEAR` (world velocity, full Vector2), `SURFACE` and `PLATFORM`
  (signed travel speed along the object's own axis — a machine's operating
  speed is not its body velocity). Compatibility is declared in one table:
  LINEAR↔LINEAR, SURFACE↔SURFACE, PLATFORM↔PLATFORM, SURFACE↔PLATFORM.
  Anything else is refused with an explicit on-screen reason; the values are
  never silently massaged.
- Character override: exchanged velocity is held for `swap_override_time`
  (2.5 s default) with gravity still acting and collisions still resolving; AI
  is paused, not deleted; when the window ends the AI re-derives its motion
  from wherever the body actually is. No teleport, ever.
- Machines keep the exchanged setting until another valid change or an explicit
  lab reset (they are not tied to the character override clock).

## 3. Lab

`res://labs/motion_swap_lab.tscn` — one continuous industrial facility, six
connected zones (A basic exchange, B projectiles, C charge/collision,
D machinery, E plate/gate puzzle, F mixed). Zone geometry is built from explicit
per-zone builder functions (readable, greppable, resettable), objects come from
small scenes under `labs/objects/` and `labs/enemies/`. Ground is continuous,
no gap exceeds the measured jump distance (`v=-640, g=1600/2880 → h≈128 px`,
run 280 px/s → ≈196 px of air travel), every zone has a checkpoint and a reset.

## 4. Order of work

P0 Blink removal → P0 exchange core + enemies A/B/C + crate/plate/reset →
P0 lab zones A/B/C/E/F → P1 machinery + zone D → debug overlay → tests
(headless logic + lab runtime + graphical capture) → QA document → STOP.
