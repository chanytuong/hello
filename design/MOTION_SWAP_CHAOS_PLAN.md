# Motion Swap chaos — pre-edit audit and implementation plan

2026-10-18. Checkpoint: `5148847f05c6a10f2673557a888ec9faf04152b9`.
No root/ancestor AGENTS.md exists. Enumerated all 16 agentskill packs; applied
Godot Game Studio, Godot physics/input/testing references, and Game Feel. Reused
MOTION_SWAP_IMPLEMENTATION_PLAN.md and MOTION_SWAP_LAB_QA.md, including its recorded
movement-suite timing flake. Inspected the previous zone C screenshot: oversized
debug text, widely separated props, a slow cannon, no self-target affordance.
No previous lab video was found in artifacts/motion_swap.

Protected: all `art/**`, `maincharacter/**` (including AccuRIG/R3/Blender sources),
`scenes/player.tscn`, movement test scene/controller, Iven movement visual/flame
scripts, shaders, approved animation atlases/anchors, existing camera framing and
zoom. SHA256 manifest: artifacts/motion_swap_chaos/protected_before.json. Source
checkpoint intentionally excludes large binary asset/history/tool trees.

## Design evidence and inference

- [Askiisoft](https://askiisoft.com/): fast acrobatic combat. Inference: make a
  gunner's locked pre-fire line readable, then give the shot a short travel time.
- [SUPERHOT](https://superhotgame.com/superhot): tactical time manipulation.
  Inference: a bounded slow window lets the player read live motion, then returns
  immediately to danger. Do not copy its movement-dependent clock.
- [DeadToast](https://www.deadtoast.com/): slow motion and expressive environmental
  action. Inference: use shared contact rules, so the same launch can move a crate,
  kill a patrol, or punish Iven against a wall. No scripted area explosions.
- Godot official docs: [CharacterBody2D](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html),
  [space queries](https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate2d.html),
  [RigidBody2D](https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html),
  [Area2D](https://docs.godotengine.org/en/stable/classes/class_area2d.html),
  [Engine](https://docs.godotengine.org/en/stable/classes/class_engine.html),
  [Time](https://docs.godotengine.org/en/stable/classes/class_time.html).
  Use monotonic real-time deadlines for selection/cooldown; physics stays scaled.
  Use swept shape queries for bullets and CharacterBody contact normals for impacts.
- katanazero.com returned 403; do not claim its trailer was watched. Official
  developer/store imagery is supplemental; gameplay claims require our own replay.

## Architecture and ordered gates

P0: keep adapters; add tactical SELECTING state and E/LMB/Q/RMB/Escape actions;
register Iven only in the lab; add a 0.24 s player launch and 0.28 s wall stun;
separate faithful exchange from one-shot, optional 1.25x/250 px/s/0.12 s Overdrive;
sweep fast physical shots at 1200 px/s; use relative normal contact speed for the
first enemy/wall consequences. Prove these in a runtime harness and one Human
Projectile lane before P1.

P1: extend that same contact resolver to enemy/enemy, enemy/crate and rigid-body
contacts; retain machine channels and persistent settings; update existing six
zone builders and add direct F2–F7 zone access for rapid retry. Add no enemy species.

P2: compact always-visible instructions, optional F1 details and Overdrive toggle,
thin tracers, target brackets/arrows, short contact particles/hitstop, bounded
camera offset only. Existing camera limits/follow/zoom remain unchanged.

Verify actual contacts, both selection orders, zero/vertical velocities, expiry,
deletion, death, reset/reload/exit, repeated swaps, gravity and ordinary locomotion.
Retain raw failed and passing logs. Capture rendered input replay and a short
recording if supported. Human fun/readability approval remains a separate gate.
