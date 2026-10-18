# SKILL STACK — WEAPON / PERCEPTION TRANSFORMATION EXPERIMENT

Phase 0 deliverable. Scope: ONE ordinary object, ONE pickup transformation, ONE weapon
attack, in the existing room. This doc says which local skill under
`E:\neverlookback\agentskill` is worth opening, what it is good for, and where it must
NOT be trusted.

Only these roots were inspected (per instructions):

- `godot-game-studio-agent-main`
- `game-feel-skill-main`
- `agent-skill-pixel-art-4.3.0`
- `2dimg2motion-main`
- `awesome-gamedev-agent-skills-main`
- `skills-main`

The rest of `agentskill` (`agents-main`, `codex-skills-main`, `skills-open-source-main`)
was deliberately **not** read.

---

## 1. Skills actually relevant to this experiment

| # | Skill file | Root |
|---|---|---|
| S1 | `SKILL.md` (godot-game-studio-agent) | godot-game-studio-agent-main |
| S2 | `skills/game-feel/SKILL.md` | game-feel-skill-main |
| S3 | `skills/disciplines/game-feel/SKILL.md` | awesome-gamedev-agent-skills-main |
| S4 | `skills/godot/godot-gdscript/SKILL.md` | awesome-gamedev-agent-skills-main |
| S5 | `skills/godot/godot-animation/SKILL.md` | awesome-gamedev-agent-skills-main |
| S6 | `skills/godot/godot-gdscript-headless-testing/SKILL.md` | awesome-gamedev-agent-skills-main |
| S7 | `skills/godot/godot-physics/SKILL.md` | awesome-gamedev-agent-skills-main |
| S8 | `skills/disciplines/shader-programming/SKILL.md` | awesome-gamedev-agent-skills-main |
| S9 | `skills/disciplines/camera-systems/SKILL.md` | awesome-gamedev-agent-skills-main |
| S10 | `skills/disciplines/input-systems/SKILL.md` | awesome-gamedev-agent-skills-main |
| S11 | `skills/workflows/prototype-fast/SKILL.md` | awesome-gamedev-agent-skills-main |
| S12 | `skills/genres/platformer/SKILL.md` | awesome-gamedev-agent-skills-main |
| S13 | `skills/engineering/godot/SKILL.md` (dated 4.7 snapshot) | skills-main |
| S14 | `skills/productivity/game-design/SKILL.md` | skills-main |

### Gaps called out honestly

These categories were requested but **no usable skill exists in the allowed roots**:

- **Combat feel** — there is no `combat` skill anywhere in the inspected roots.
  Closest substitute = S2 + S3 (hit-stop, knockback, feedback layering) read as a
  substitute, and they must be cross-checked against this project's own measured
  numbers in `DESIGN_BRIEF.md` §7–§10.
- **Storyboard / comic presentation** — nothing. `skills-main/…/productivity/to-story`
  is a Jira-ticket rewriter, not a storyboard tool. The storyboard for this experiment is
  hand-authored in `design/PERCEPTION_WEAPON_EXPERIMENT.md`.
- **Short dialogue / scene beats** — nothing appropriate. `disciplines/dialogue-systems`
  builds branching Ink/Yarn dialogue runners, which is far outside a micro-experiment.
  Scene beats here are limited to HUD one-liners via `NLBHUD.set_message`.

---

## 2. What each skill is good at / what it must NOT be trusted to do

### S1 `godot-game-studio-agent` — the workflow spine
- **Good at:** the evidence loop — connect design intent to real runtime behavior, then
  require playable evidence before declaring success. This is the pass's process rule.
- **Do NOT trust it to:** decide *what* is fun, or supply tuning numbers. It is a
  verification discipline, not a design authority.

### S2 `game-feel-skill-main/skills/game-feel` — diagnosis layer model
- **Good at:** the six-layer decomposition (Input / Response / Context / Polish /
  Metaphor / Rules) and the hard perceptual constraints (response inside ~100 ms,
  never past ~240 ms, 30–60 fps floor). Use it to decide *which layer owns a defect*
  before touching code — e.g. "the transformation reads as nothing" is a **Polish/Metaphor**
  defect, not a Response defect.
- **Do NOT trust it to:** tune this game's swing timings, hitstop length, or knockback.
  Its numbers are generic. Authoritative values for NEVERLOOKBACK are the ones measured
  in `DESIGN_BRIEF.md` §7/§8 and the current `@export`s in `scripts/player.gd`.

### S3 `awesome-gamedev…/disciplines/game-feel` — juice vocabulary
- **Good at:** the *menu* of polish primitives — hit-stop, screen shake, tween easing,
  squash & stretch, layered A/V feedback — and knowing which primitive answers which
  perception problem.
- **Do NOT trust it to:** tell us whether we already have too much. It is additive by
  construction. The "no giant flash / no camera nausea / no visual noise" constraints in
  this brief override it.

### S4 `godot-gdscript` — the implementation reference
- **Good at:** idiomatic Godot 4.7 GDScript — static typing, `_ready/_process/
  _physics_process` ordering, `@export/@onready`, signals, `await`, Tween creation.
  Critical for the known ordering fact in this project: node physics runs before
  `game._process`.
- **Do NOT trust it to:** catch project-specific conventions (GDScript rejects `//`
  comments; PowerShell regex edits have corrupted `game.gd` before — use the `edit` tool).

### S5 `godot-animation` — how to build the transformation beat
- **Good at:** choosing *which* animation mechanism — `create_tween()` for a sub-second
  procedural beat (what we need), `AnimationPlayer` for authored clips, `AnimationTree`
  for state blending. Also easing curves and `set_ease`/`set_trans` for overshoot/snap.
- **Do NOT trust it to:** design the beat. And do **not** introduce an `AnimationPlayer`
  node for a <0.5 s graybox beat — a Tween chain is the smaller change.

### S6 `godot-gdscript-headless-testing` — regression gate only
- **Good at:** `godot --headless --script res://tests/…` runners that exit non-zero, which
  is exactly how this project's six suites run.
- **Do NOT trust it to:** prove game feel. Headless runs cannot show pixels. It can prove
  "no upward velocity injected" and "hitstop restored"; it cannot prove "reads as a
  transformation." **This is the single most important limit in this document.**

### S7 `godot-physics` — collision/shape correctness
- **Good at:** Area2D vs CharacterBody2D semantics, `monitoring`/`monitorable`, shape
  resource sharing pitfalls (a `sub_resource` shape is shared across instances — mutating
  it mutates every copy; must `duplicate()` before per-object changes).
- **Do NOT trust it to:** body-separation policy. Our separation rule (enemy-only yield,
  run after physics, horizontal only) is a project decision, not an engine default.

### S8 `shader-programming` — local distortion only
- **Good at:** the vocabulary of *local* 2D distortion — UV offset, slice/scanline
  displacement, RGB split, outline — applied to one `ColorRect`, in a `canvas_item` shader.
- **Do NOT trust it to:** keep it readable. A shader can trivially produce exactly the
  "glitch spam" this brief forbids. Cap beats, not amplitude. If a shader is not needed,
  prefer scale/scale-offset tweens on primitives — fewer moving parts.

### S9 `camera-systems` — restraint reference
- **Good at:** what a camera *could* do (deadzone, look-ahead, shake hook).
- **Do NOT trust it to:** decide we should add any of it. Camera already has offset shake
  only; this brief explicitly forbids camera nausea and camera takeover. Read it to know
  what to refuse.

### S10 `input-systems` — action mapping correctness
- **Good at:** named action mapping (`attack`, `blink`, `dash` already exist in
  `project.godot`), so pickup does **not** need a new key.
- **Do NOT trust it to:** add rebinding/UI. Zero new input plumbing for this experiment.

### S11 `prototype-fast` — scope discipline
- **Good at:** the keep/kill criteria mindset — one question, hard timebox, graybox
  primitives, throwaway vs keep. This is the correct frame for "is one ordinary object
  worth becoming a weapon."
- **Do NOT trust it to:** quietly expand into a weapon system. When the gate fails, the
  answer is "do not build a larger weapon system."

### S12 `platformer` — grounding reference
- **Good at:** coyote time, jump buffering, variable jump height — already implemented
  and passing here. Use only as a reminder that a grounded swing must not disturb these.
- **Do NOT trust it to:** melee design.

### S13 `skills-main/engineering/godot` — version-checked API lookups
- **Good at:** a dated 4.7 snapshot of syntax/API/`.tscn` text format, useful when editing
  scene files by hand. It explicitly warns the snapshot ages.
- **Do NOT trust it to:** be current — verify version-specific claims against behavior in
  this repo (run it) rather than from the snapshot.

### S14 `skills-main/productivity/game-design` — design question framing
- **Good at:** MDA/core-loop framing, asking "is this fun or a dominant strategy," and
  catching scope creep (it explicitly covers loadout/inventory/loot design — i.e. the
  things this brief forbids).
- **Do NOT trust it to:** produce systems. We are deliberately building NO system here.

### Explicitly unused, and why

| Skill | Why not used |
|---|---|
| `agent-skill-pixel-art-4.3.0` | Generates PNG pixel assets with a palette lock and a mandatory `quality_audit.py` gate. This experiment is graybox ColorRect primitives with **no art pass**. Opening it would push toward producing assets this brief forbids. |
| `2dimg2motion-main` (+ `img2mo-std`, `img2mo-learn`) | Generates animation frame sequences from a **baseline image**. We have no baseline image and no sprite pipeline; the "hero weapon silhouette" must be built from primitive scale/skew/color, not from generated frames. Using it would create an art dependency for a throwaway test. |
| `disciplines/create-game-assets` | Asset production pipeline / style bibles — same reason as pixel-art. |
| `disciplines/dialogue-systems`, `genres/visual-novel` | Branching dialogue runners; no dialogue in this experiment. |
| `productivity/to-story` | Rewrites Jira tickets into user stories. Not a storyboard tool. |
| `skills-open-source-main` (godot, game-design, game-patterns…) | Not in the allowed root list for Phase 0. |

---

## 3. Recommended workflow for this experiment

Order matters; each stage has exactly one artifact and one gate.

1. **Frame the defect (S2, S14).** Decide which feel layer owns the problem *before*
   writing code. Write the layer next to each finding.
2. **Storyboard first (hand-authored, S5 for the mechanism only).**
   `design/PERCEPTION_WEAPON_EXPERIMENT.md` — six beats, each with duration, pose, FX,
   camera, sound placeholder, and gameplay lock/unlock. Total ≤ 0.5 s.
   Gate: the storyboard must be readable as text with no art described.
3. **Implement the smallest thing (S4, S7, S8-if-needed).** One object, one pickup, one
   transformation, one attack. Prefer Tween over AnimationPlayer; prefer scale/offset on
   a ColorRect over a shader; add a shader only if a beat is unreachable otherwise.
   Parse-check every edited `.gd` immediately.
4. **Run + observe (S1, S6).** Headless suites prove *regression only*: grounded,
   no launch, hitstop restored, separation, dash-cancel rules. Explicitly record which
   claims are **not** proven by the run.
5. **Change ONE thing, run again.** No batches. This is the pass's hard rule.
6. **Manual gate (S1 + S11 keep/kill).** The 15-question gate decides whether this idea
   continues. A failed gate means *do not build a bigger weapon system*, not "iterate
   forever."
7. **Record before/after numbers** (damage, timings) in `DESIGN_BRIEF.md` so the next
   agent does not have to trust this report.

### Authority order (when sources disagree)

1. The **currently running game** (measured in-editor / by probe).
2. `DESIGN_BRIEF.md` §7–§10 and the `@export` defaults in `scripts/player.gd`.
3. This project's test suites (regression only).
4. Local skills (vocabulary + mechanism).
5. Prior agent reports — including this one. **Not trusted blindly.**

### Hard refusals for this experiment

Inventory, menus, rarity, loot, stats screens, upgrades, durability meters, a second
weapon, a second room, progression, generated art/sprites, RNG on anything, full-screen
flashes, camera takeover, new input actions, new MCP installs.
