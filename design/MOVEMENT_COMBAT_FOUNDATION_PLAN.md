# Foundation repair — diagnosis before gameplay edits

2026-10-18. Git checkpoint: `4d8c41ae17f9d10127bc200f9e23ba1be2b69177`.
No root/ancestor AGENTS.md exists; the only copies are within unrelated skill
packs. Re-enumerated agentskill; reused the Godot implementation/physics/input/
testing and Game Feel workflows already read, plus its response-tuning reference.

Before evidence: `artifacts/foundation_repair/BEFORE.avi`, before/reproduction.json,
before_replay.log. The SAME controller/collision fixture will be replayed after.

Measured: configured roll .70 s, 195.99 px, .7167 s including exit update; reversal
still +280 px/s, remaining .6833 s; no air roll. Stationary Patrol at x=3033 vs
Iven x=3000 causes two 1-HP hits and -3.33 px displacement without an attack.
The 33px gap exceeds capsule radii 14+15 but overlaps TouchHitBox radius 22.
Literal one-hit full-health death was not reproduced in this controlled case.

Code causes: roll overwrites running/reversal each frame, requires was_floor and
clears itself in air, has .8s cooldown, plays all 21 cells across .7s. All lab
enemies and both legacy enemies begin continuous TouchHitBox damage at ready.
Generic impact applies at 180 px/s with character momentum transfers even for
ordinary running/rolling. Normal movement passes a stale pre-input velocity to
impact solving. Forced-motion cancellation consumes jump/dodge then returns,
preventing the requested replacement action on that update. Damage lacks source
provenance. Legacy projectiles can remain continuous damaging Areas after a hit.

Plan: .24s / 320px/s roll (~80px at 60Hz), fresh direction/jump cancels on the
same update, repeated rolls assign bounded velocity, air roll keeps gravity and
jump budget, existing clips sample faster with roll priority while airborne.
Remove passive contact damage. Arm Charger contact hitbox only during real charge,
require swept body contact, one epoch per charge. Separate attack vs impact
authority per contact. Use current incoming velocity and 480px/s gate for ordinary
character/character collisions; preserve swapped high-speed impacts and hazards.
Add optional source-labelled damage traces (off by default). Prove these before
changing one existing zone into the requested small arena.

Protected: art/**, maincharacter/**, rigs, sprite/frame/anchor data, flame script,
shaders and camera framing. Playback logic may change; source animation files do
not. Reuse the previous SHA256 manifest for immutable assets and verify after.

Research: [Motion Twin lead developer](https://blog.playstation.com/2018/01/25/rogue-lite-action-platformer-dead-cells-coming-to-ps4-this-year/)
emphasizes responsive controls, enemy patterns and a dedicated dodge;
[Playdigious's first-person development account](https://www.gamedeveloper.com/design/porting-i-dead-cells-i-to-mobile-an-in-depth-breakdown)
describes testing and rejecting ambiguous jump/dodge input. [Askiisoft](https://askiisoft.com/)
describes tight acrobatic action. Inference for this project: prioritize distinct
input intent and short, interruptible movement; do not copy undocumented frame
counts or add invulnerability merely because another game's roll has it.
Godot [CharacterBody2D](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html)
and [KinematicCollision2D](https://docs.godotengine.org/en/stable/classes/class_kinematiccollision2d.html)
support collision-solved movement and contact-normal velocity measurement.
No external video is claimed as watched.
