# Combat Feel Research — Dead Cells, Katana ZERO, Hollow Knight

**Scope:** This document records the external research used to retune NEVERLOOKBACK's live crowbar combo and roll. It is a design reference, not a claim that these games use the exact numbers below. The target is a 60 Hz Godot 4 action game with a three-hit grounded combo, a committed dodge roll, and Motion Swap as a world mechanic.

**Research question:** Why do these games feel responsive and weighty at the same time, and which parts of that can be reproduced with timing, input buffering, hitstop, camera impulse, blood/damage-number feedback, knockback, and enemy reaction without changing the underlying combat rules?

---

## 1. Dead Cells — fast chaining with readable commitment

### Findings

- Dead Cells ships a very large weapon roster (the developer's own design article discusses designing each of the game's 50 weapons to feel distinct). Variety comes from **timing, reach, commitment, and feedback**, not from a single universal attack speed. ([Game Developer — Designing each of the 50 weapons in Dead Cells](https://www.gamedeveloper.com/design/designing-each-of-the-50-weapons-in-i-dead-cells-i-to-feel-distinctive))
- Community/system breakdowns describe the "juice" layer as a short **freeze frame**, a brief slowdown, particles, and sound layered on critical hits. The freeze is deliberately short; it punctuates contact rather than stopping play. ([Teemo.dev — Dead Cells game feel and juice](https://teemo.dev/game-design/dead-cells/systems/game-feel-and-juice/))
- The same breakdowns emphasize **input buffering and cancel windows**: the next action can be queued before the current animation visually finishes, and recovery can be shortened by a valid follow-up. This is what makes repeated presses read as a combo instead of a queue of separate attacks.
- Weapon feel is also carried by **enemy reaction**: hit stun, knockback, and death response differ by weapon weight. A fast blade and a heavy shield do not share one hit reaction.

### What NEVERLOOKBACK borrows

1. **Short, local hitstop** (0.03–0.05 s), not a global freeze. The player's combo clock pauses, the victim pauses, and the rest of the world keeps moving.
2. **Recovery canceling at the first recovery frame**: M1/M2 open the next step at `active_end` (`0.10 / 0.15 s`), before the authored tail has elapsed. A press during recovery starts the next strike on that same update.
3. **A one-press buffer**: a press made during late active frames is stored and consumed at the gate. Holding the button does not auto-repeat.
4. **Weight by strike**: M1 is the lightest, M2 is a downward commit, M3 is the finisher with the longest stop, the widest shake, and gold damage text.
5. **The full Dead Cells contact stack**: hitstop, directional shake, blood, damage number, enemy flash/squash, and knockback all fire on the same accepted hit. Sound is layered on top.

### What NEVERLOOKBACK deliberately does not copy

- No global time freeze for a normal M1 hit. The live combo already owns a local clock (`stop_left`), so a global `Engine.time_scale` freeze would also stop the enemy's flash and the camera shake.
- No random weapon variance. The crowbar's three strikes keep authored, deterministic timings so the combo can be tested frame by frame.

---

## 2. Katana ZERO — control latency is the feel

### Findings

- Katana ZERO's combat is built around **immediate, precise control**: dash, deflect, slash, and slow-motion are available with almost no wind-up, and the player is expected to chain them without fighting the animation system. Interviews and reviews repeatedly describe the game as rewarding flawless, immediate execution rather than stat comparison. ([GameRevolution — Katana ZERO interview](https://www.gamerevolution.com/originals/520685-katana-zero-interview), [GameSpot — Katana ZERO review](https://www.gamespot.com/reviews/katana-zero-review-slow-motion-for-me/1900-6417126))
- The slow-motion mechanic is a **player-owned tactical layer**, not a hit-reaction freeze. Time is slowed so the player can read and choose; the game does not take control away to show impact.
- The one-hit-kill design means **the attack's commitment is short**, so a missed or late input is punished by position and enemy action, not by a long recovery animation.

### What NEVERLOOKBACK borrows

1. **No 0.6 s attack dead zone.** M1/M2 can cancel into the next strike at `0.10 / 0.15 s`; M3's finisher escape is `0.35 s`, just after its active window. A press is never swallowed for the length of a legacy cooldown.
2. **The player owns the next action.** A press during late active frames is buffered to the gate; a press during recovery starts the next strike immediately; a press after the authored end uses the `0.45 s` combo window. It never silently disappears or rewinds to M1.
3. **Defense stays immediate.** Jump, roll, and Motion Swap still cancel the combo on the same physics update. The combo never delays a defensive input.

### What NEVERLOOKBACK deliberately does not copy

- No global slow motion on hit. Motion Swap already owns tactical time; adding hit slow-mo would make the two systems fight over `Engine.time_scale`.
- No one-hit-kill retune. The crowbar keeps its existing damage values; this pass changes feel, not balance.

---

## 3. Hollow Knight — readable slash, recoil, and enemy-specific reaction

### Findings

- Hollow Knight's base nail slash is a **quick, readable arc** (roughly a fifth of a second in normal play), with the player free to move almost immediately afterward. The attack is short because the read is carried by the pose, the arc, and the enemy's reaction. ([Game Informer — The Making of Hollow Knight](https://gameinformer.com/2018/10/15/the-making-of-hollow-knight))
- Hits produce **recoil and hit-pause**. The pause is not identical for every target: armored or heavy enemies react differently from small ones, and the player's own knockback/recoil sells the contact. ([Socratopia — compelling game design, chapter 13](https://www.socratopia.app/library/game-design-compelling-en/chapter-13), [Teemo.dev — Hollow Knight game feel and juice](https://teemo.dev/game-design/hollow-knight/systems/game-feel-and-juice/))
- The visual language is restrained: a white flash / bright contact accent and a small camera impulse do more work than a large particle explosion.

### What NEVERLOOKBACK borrows

1. **A short white flash** on the victim (2 frames at 60 Hz), timed to the contact frame and allowed to decay during hitstop so the enemy does not stay a white silhouette for the whole freeze.
2. **Directional camera impulse** along the strike direction, 3–5 px, rather than an omnidirectional shake.
3. **Enemy recoil** already exists in the crowbar combo (`recoil_pixels`); this pass keeps it and adds a one-shot 20–30 px knockback plus a squash punch around it.
4. **Strike-specific pauses**: 0.03 / 0.04 / 0.05 s for M1 / M2 / M3, so the finisher reads heavier without making the light opener sluggish.
5. **Restraint is relative**: Hollow Knight's flash is restrained, but Dead Cells layers blood, damage numbers, and sound on top of the same white-flash/impact core. NEVERLOOKBACK borrows the full six-layer stack for the crowbar while keeping the small pixel-art scale.

---

## 4. Synthesis — target feel for NEVERLOOKBACK

### 4.1 Crowbar combo

| Strike | Startup | Active end | Contact | Chain gate | Authored end | Recovery cancel | Hitstop | Shake |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| M1 horizontal | 0.050 | 0.100 | 0.0667 | 0.100 | 0.200 | 0.100 | 0.030 | ≈3.9 px |
| M2 overhead | 0.0833 | 0.150 | 0.100 | 0.150 | 0.300 | 0.150 | 0.040 | ≈4.5 px |
| M3 rising | 0.2667 | 0.3333 | 0.2833 | — | 0.650 | 0.350 | 0.050 | ≈5.0 px |

**Chaining rules:**

- The chain gate is the first recovery frame (`active_end`): M1 `0.10 s`, M2 `0.15 s`.
- A press during late active frames is buffered (0.25 s buffer, enough to cover a full strike from its first frame) and consumed at the gate.
- A press during recovery starts the next strike on that same update. The branch stays open through the whole authored strike; it is not closed at the gate.
- After a non-finisher ends, the next step stays available for **0.45 s of real time**. A deliberate click inside that window continues M1 → M2 or M2 → M3; only a pause longer than 0.45 s resets the combo to M1.
- M3 does not chain further. Any press during the finisher is queued and restarts M1 at the **0.35 s** recovery-cancel gate (just after the 0.3333 s active window). A press at or after 0.35 s restarts immediately. The authored 0.65 s tail still plays in full if the player does not ask for another attack.
- Holding the button is one press. There is no auto-combo.
- Jump, roll, damage, and Motion Swap cancel the combo on the same update.

**Why this removes the dead zone:** the old live path closed the branch at the chain gate, then waited for the full authored duration. A press during recovery was ignored until the final buffer window, and even then only set `restart_pending`, so the next click restarted M1. The new path keeps the branch open through the authored end, starts the next step at the first recovery frame, carries a 0.45 s combo window across the end, and shortens M3's escape hatch from 0.60 s to 0.35 s. The next click advances the branch instead of rewinding it, and the finisher no longer owns a 0.60 s hole.

### 4.2 Roll

| Property | Value | Reason |
|---|---:|---|
| Duration | 0.50 s | Approved V03 ground clip length (15 frames at 30 fps). |
| Speed | 400 px/s | 400 × 0.50 = **200 px** travel. |
| Cooldown | 0.35 s | Unchanged; starts on completion or cancellation. |
| Ground clip | `DODGE_ROLL` 15 frames | Approved V03 sheet. |
| Air clip | `AIR_ROLL` 7 frames | Approved V03 air sheet; plays at 30 fps then holds its final frame while the 0.50 s physics roll continues. |
| Color | RUN-palette remap, then `Color(0.84, 0.765, 0.739, 1.0)` | Palette B modulate retained; the lighter V03 sheet is remapped to the RUN palette at load time, no re-render. |

**Transition rule:** the roll family is chosen at roll start (ground vs air) and held for the whole roll, so landing mid-air-roll cannot pop the clip. On exit, the visual goes directly to RUN / IDLE / JUMP; V03's final frame is run-ready, so the old V2 entry/exit bridge clips are no longer used. State entry explicitly stops the previous drawing and starts the new roll at frame 0, while the legacy body is hidden, so jump→roll and land→roll cannot stack or leak a stale jump/land drawing.

**Colour rule:** the V03 sheet is a 21-colour B palette that is lighter and cooler than RUN. A warm modulate alone left the roll looking grey. `scripts/iven_roll_palette.gd` maps each opaque roll colour to the nearest RUN colour and pre-divides by the modulate, so the rendered pixels use RUN's navy/cloth palette. The source PNG and anchors are unchanged.

### 4.3 Impact feedback

Every accepted hit fires the six layers on the same frame:

1. **Hitstop:** local to the attacker and victim. The attacker's combo clock pauses; the victim's physics pauses; the world continues. `0.03 / 0.04 / 0.05 s` by strike.
2. **Camera:** directional impulse along the hit, with a small vertical component. Base `4.2 px`, strike strength `0.82 + 0.12 * strike` (≈3.9 / 4.5 / 5.0 px), duration `0.13 * (0.90 + 0.10 * strike)` (0.130 / 0.130 / 0.143 s). The existing Motion Swap shake remains separate so the two cannot overwrite each other.
3. **Blood:** 5–10 red particles burst outward in the hit direction, have gravity, and fall. Armored targets throw gold sparks instead.
4. **Damage number:** a 13 px outlined floating label above the contact, cream for M1/M2 and gold for M3; pops, rises, and fades over `0.55 s`.
5. **Enemy reaction:** 2 frames of white plus a `1.22 × 0.82` squash that settles over `0.14 s`. The flash decrements during hitstop, so it is visible at contact but gone before the freeze ends.
6. **Knockback:** one-shot `220 / 240 / 260 px/s`, decelerated at `900 px/s²` during the `0.12 s` stagger. Measured M1 slide: `22.4 px`. The old per-tick re-add was removed because it accumulated into runaway acceleration.

**Audio:** layered `hit_1/2/3` transient plus `organic` or `metal`, with deterministic pitch variation; `defeat` adds the kill accent. The existing crowbar ribbon and whoosh remain the primary wind-up read. No global post-process or global time freeze is introduced.

---

## 5. Implementation mapping

| File | Change |
|---|---|
| `scripts/iven_movement_visual.gd` | V02 JUMP/LAND clips, V03 DODGE_ROLL/AIR_ROLL clips, RUN-palette roll normalisation, explicit Palette B modulate, hard state-entry reset, legacy-body exclusion, direct roll exit, per-state foot offset, V03 anchors. |
| `scripts/iven_roll_palette.gd` | Runtime-only V03-to-RUN palette remap; source art and anchors untouched. |
| `scripts/player.gd` | `roll_speed = 400`, `attack_cooldown = 0.05`, preview-path `_air_time` / `_jump_land_t` tracking. |
| `art/iven/m1_crowbar/attack_metadata.json` | Chain/recovery gates: M1 0.10 s, M2 0.15 s, M3 0.35 s; knockback `220 / 240 / 260`. |
| `scripts/combat/crowbar_feel_combo.gd` | First-recovery-frame chain gate, full-strike buffered follow-up, 0.45 s post-strike combo window, queued M3 restart at 0.35 s, 0.03/0.04/0.05 stops. |
| `scripts/combat/m1_crowbar.gd` | Live 1.0× playback, local stops 0.03/0.04/0.05, 0.25 s buffer, accepted damage forwarded to contact VFX. |
| `scripts/combat/impact_fx.gd` | Blood particles, floating damage numbers, layered hit audio, existing motes. |
| `scripts/combat/crowbar_fx.gd` | Brighter contact cross plus the shared six-layer package. |
| `scripts/lab/motion_swap_lab.gd` | Connect `contact_feedback`, 4.2 px directional camera impulse, separate Motion Swap shake. |
| `scripts/lab/lab_enemy_base.gd` | 2-frame white flash, squash punch, one-shot knockback with stagger deceleration. |
| `tests/` | Roll expectations updated to 200 px / V03 frame 14 / AIR_ROLL; new 43-check crowbar combo/feel gate and 24-check roll colour/transition gate. |

---

## 6. Verification targets

1. `main.tscn` and `labs/motion_swap_lab.tscn` both load.
2. RUN → JUMP → LAND → RUN uses the V02 30-frame sheet; landing shows frames 25–29 for 5/30 s.
3. Roll travels 195–205 px in 0.50 s, plays V03 ground frames 0–14, uses Palette B modulate, and renders on the RUN palette.
4. Air roll plays the 7-frame V03 air clip, then holds the final frame for the rest of the 0.50 s physics roll; state is `AIR_ROLL`.
5. Three clicks at a natural cadence produce M1 → M2 → M3 without restarting M1; the sprite sample advances and the three steps render distinct authored atlas regions.
6. A press during M1/M2 recovery starts the next step on the same update. A press during late active frames is buffered to the first recovery frame.
7. A single click produces exactly one strike; holding produces one strike.
8. Any press during M3 queues a restart, and M3 restarts M1 at its 0.35 s cancel point; a press at or after 0.35 s starts M1 immediately.
9. Every confirmed hit produces a 0.03–0.05 s local stop, a 3.9–5.0 px directional camera impulse, 5–10 blood particles, a floating damage number, a 2-frame white flash plus squash, a 20–30 px one-shot knockback, and layered impact audio.
10. Motion Swap still cancels the combo and still exchanges motion.
11. Jump→air-roll and land→ground-roll enter on roll frame 0, with exactly one visible body and no stale jump/land clip; both facings match the RUN palette.

---

## 7. Sources

- Game Developer — *Designing each of the 50 weapons in Dead Cells to feel distinctive*: <https://www.gamedeveloper.com/design/designing-each-of-the-50-weapons-in-i-dead-cells-i-to-feel-distinctive>
- Teemo.dev — *Dead Cells: game feel and juice*: <https://teemo.dev/game-design/dead-cells/systems/game-feel-and-juice/>
- GameRevolution — *Katana ZERO interview*: <https://www.gamerevolution.com/originals/520685-katana-zero-interview>
- GameRevolution — *Katana ZERO preview*: <https://www.gamerevolution.com/originals/520357-katana-zero-preview-switch-pc>
- GameSpot — *Katana ZERO review*: <https://www.gamespot.com/reviews/katana-zero-review-slow-motion-for-me/1900-6417126>
- Game Informer — *The Making of Hollow Knight*: <https://gameinformer.com/2018/10/15/the-making-of-hollow-knight>
- Socratopia — *Compelling Game Design*, chapter 13: <https://www.socratopia.app/library/game-design-compelling-en/chapter-13>
- Teemo.dev — *Hollow Knight: game feel and juice*: <https://teemo.dev/game-design/hollow-knight/systems/game-feel-and-juice/>
