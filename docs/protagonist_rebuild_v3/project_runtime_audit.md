# Phase B — project and runtime audit

Status: COMPLETE. Phase C is next and has not begun. No production art or integration was performed in this phase.

## Authority and preserved baseline

The two supplied rebuild briefs, continuation instructions, and latest one-phase-per-turn policy govern this work. `skills_read.json` records all 421 skills and the selected support material as complete; none of the completed skills were reread for this audit. `production_rulebook.md` retains the craft synthesis. Historical design documents and failed art reports are context, not permission to reuse rejected art or reinstate obsolete approval gates.

The project root has no Git repository. A SHA-256 baseline covers 45 existing gameplay scripts, scenes, test scripts, and `project.godot`; all 45 remained unchanged after the audit. Text snapshots are stored under `baseline_sources/`. Legacy art stays in place. Existing source uses UTF-8 with occasional BOMs; JSON readers must tolerate a leading BOM.

Primary sources inspected: `project.godot`; scenes/main, player, arena; scripts/player, prop, health, hurtbox, blink_manager, game, arena; current test fixtures; existing PNG import settings; relevant character identity/palette and failed production reports. Current code overrides stale prose constants. This audit does not approve the former A2, v2, or procedural v3 body designs.

## Runtime presentation contract

The installed engine is Godot 4.7.2 stable, official hash `ed1daf0bf001b61586d9930840f2f1394092c079`. Main scene is `res://scenes/main.tscn`. Physics runs at 60 Hz. The actual captured viewport is 1280 × 720, camera position (640,360), zoom (1,1), and normal canvas transform is identity. Project stretch mode is `canvas_items`. Clear background is approximately #0D0F17. Floor top is y=600; playable floor spans x=40..1240. State A has a 300 × 20 platform at (800,480), a live hazard strip, and elevated ranged enemy; State B changes obstacles and enemy placement through the existing Blink mechanic.

`player.tscn` has no authored Sprite2D, AnimatedSprite2D, SpriteFrames, or AnimationPlayer. `player.gd` creates one Sprite2D, loads PNG caches, and selects frames directly from simulation state. Its existing presentation contract is:

| Property | Observed value |
| --- | --- |
| Default set | `art/prototype/character_a2/` |
| Fallback/compare set | `art/prototype/character/` |
| Runtime files per set | 15: neutral, run_00..05, d0_entry/d1_hold/d2_exit, attack_a0..a4 |
| Canvas | 64 × 64, RGBA, binary alpha in all 30 inspected runtime PNGs |
| Pivot | texture coordinate (32,62), offset (-32,-62), `centered=false` |
| Local filtering | `CanvasItem.TEXTURE_FILTER_NEAREST`, enum value 1 in this engine |
| Scale/rotation | scale.x = facing ±1, scale.y = 1, rotation = 0 |
| A2 neutral visible bounds | [23,7)..[45,63): width 22, height 56 pixels |
| A2 visible colors | 14 per runtime frame; legacy palette, not the new rebuild palette |
| Existing comparison input | V toggles A2/baseline and refreshes the picked texture |

The collision capsule is radius 14, height 44, centered at (0,-22); the hurtbox shares that shape. SwingHitBox sits at (40,-20) with a local-to-scene circle resource. These are gameplay geometry and must remain unchanged. The hidden Body ColorRect still runs old pose math and is asserted by some tests. Its deformation is not inherited by the visible Sprite2D. Do not mistake passing those checks for proof of visible sprite motion.

Existing PNG import configuration is lossless with no mipmaps. Fractional player coordinates are normal. Existing camera shake also creates fractional offsets (seen during Blink), which can affect raster stability. This is an inherited QA condition; this rebuild is not authorized to tune global rendering or camera behavior to conceal it.

## Motion and combat clocks to preserve

| System | Actual code contract |
| --- | --- |
| Ground movement | speed 280 px/s, acceleration 2600, reverse acceleration 4200, friction 3200 |
| Air control | 0.7 multiplier |
| Jump | initial velocity -640, rise gravity 1600, fall multiplier 1.8 |
| Jump intent | coyote 0.10 s, buffer 0.12 s, early release multiplier 0.45 |
| Dash | 650 px/s, 0.15 s duration, 0.8 s cooldown, 0.12 s buffer, one air dash |
| Dash-to-strike | existing late window 0.06 s; startup/active swing cannot be canceled by dash |
| Attack | startup 0.05 s, active 0.12 s, recovery 0.08 s; total 0.25 s |
| Re-attack | cooldown 0.35 s added to the swing total: next eligibility after 0.60 s |
| Attack intent | buffer 0.60 s in current code, not the obsolete 0.20 s documented elsewhere |
| Forward attack step | 60; first confirmed hit retains 0.55 momentum unarmed, 0.35 armed, 0.25 finisher |
| Reach/knockback | unarmed 82/260, armed 104/460, finisher knockback 660; damage remains existing value |
| Hitstop | 0.045 / 0.075 / 0.10 s, implemented by current Game time-scale logic |
| Hurt visual clock | 0.12 s on nonfatal health change; damage immunity 1.0 s |
| Hard landing | existing signal when previous fall peak exceeds 700 px/s |
| Blink | 0.28 s transition/fight freeze; 4 s cooldown; existing veil and arrival flash |
| Death | existing health.died signal, 1.2 s game restart delay; no new movement lock |

Impact parameters are snapshotted at swing start, before weapon use/break events can alter armed values. Frame selection must not drive hitbox activation, damage, cancels, cooldowns, input consumption, or these snapshots.

Current picker priority is attack → dash → hurt/neutral → grounded run → neutral. Run frames advance every 18 traveled pixels, six frames per 108-pixel cycle, above speed 20. At speed 280 this implies about 0.386 s per cycle, not a fixed global FPS. Distance accumulation continues during grounded attacks in the current visual update; stopping does not reset that accumulator.

Dash selection divides the existing 150 ms into entry before 20 ms, hold until 110 ms, then exit. Attack a0 occupies startup, except dash-strikes skip it to a1. Active unconfirmed swings show a1; confirmed contact shows a2 through the rest of active. Whiff recovery first uses a3 for 40 ms, then a4; confirmed recovery uses a4. At 60 Hz short intervals quantize to rendered/physics steps; future authored exposure must respect that clock.

During Blink fight freeze the player records buffered intent and continues gravity/movement, while action timers are preserved and normal visual updates are skipped. Active swing teardown, projectile clearing, enemy relocation, and arrival effects already belong to existing gameplay. Future presentation must follow this behavior.

## Weapon and grip contract

The prop is a sibling after Player and currently draws over the player. It is FREE/HELD/BROKEN, auto-picks up within |dx| < 26 and |dy| < 44, grants existing armed parameters, breaks after five confirmed uses, and respawns after four seconds. The pipe is initially at (575,594) in the hazard area. Blink changes access, not weapon transformation.

Held origin is player position + (16 × facing,-30) plus the existing transformation lift; scale.x follows facing. Under the old 64-pixel pivot this maps to texture coordinate (48,32) when facing right. Rest angle is -0.66 radians. This is a fixed legacy anchor, not evidence that every pose's hand actually grips it. Later master poses must specify one anatomical grip hand and matching pose anchors; any visual-only adaptation must preserve weapon mechanics and its transformation clock.

The 0.465 s perception sequence has overlap at 0.070, fracture at 0.170, peak at 0.240, held disagreement until hard snap at 0.285, body recoil through 0.345, and settle through 0.465. `perception_pose` already exposes reach/recoil/settle. Those signals currently deform only the hidden Body, so the visible sprite does not express pickup beats. Existing weapon ColorRects rotate and scale continuously; they are prototype presentation to replace later, not a raster-production method or a reason to change gameplay.

## Required presentation coverage exposed by the audit

Idle, run, jump, fall, dash, attack, hurt, and death have actual runtime meaning. Hard landing, reversal/skid, weapon pickup/fracture/settle, armed attacks, dash-strike, whiff versus confirmed impact, and Blink arrival need visual coverage derived from existing signals/fields. No new walk-speed mechanic, heavy/up attack, aerial combat move, or gameplay state is implied by reference rows. Phase C will decide which reference gestures can support these actual needs.

Death needs particular care: fatal damage emits `died` without the nonfatal `changed` signal, and the current controller continues until reload. A cosmetic death response may observe that state; adding a physics/input freeze would change gameplay and is outside scope. Likewise hurt, airborne, pickup, and arrival presentation cannot be inferred from the current neutral fallback.

## Verification evidence and limits

`baseline_runtime_probe.gd` loads the real main scene and drives existing Input actions. Eight graphical viewport captures were taken after `RenderingServer.frame_post_draw`, with matching state records in `baseline_runtime/observations.json`. This is synthetic-input graphical evidence, not manual controller play or an exported-build test. Full idle and attack captures and all eight 4× nearest screenshot crops were visually inspected.

| Capture | Actual selected sprite and state |
| --- | --- |
| 01_idle | neutral.png, grounded, velocity zero |
| 02_run | run_02.png, grounded, x velocity 280 |
| 03_jump_rise | neutral.png, airborne, y velocity about -426.67 |
| 04_fall | neutral.png, airborne, y velocity about +453.33 |
| 05_dash | d1_hold.png, DASH, x velocity 650 |
| 06_attack_active | attack_a1.png, attack clock about 0.06667, unconfirmed active |
| 07_blink_transition | neutral.png, frozen, existing veil/shake visible |
| 08_blink_arrival | neutral.png, freeze ended, existing camera offset still decaying |

Native-scale inspection confirms the present human-headed coat silhouette and absence of flame art. Airborne neutral reuse is visible in the enlarged capture crops. Existing baseline art has not been promoted to rebuild output.

All seven existing headless suites completed with exit code 0 and empty stderr: runtime 8 checks, identity 21, weapon 52, feel 10, arena 26, killblink 2, strand 3 — **122 passing checks**. Raw outputs are in `baseline_tests.json`. These verify current baseline behavior, not the quality of future art or unimplemented integration. No new production tests were added.

The initial PowerShell capture wrapper returned 1 after formatting native renderer diagnostics. A direct child-process rerun isolated the actual Godot exit code: **0**, all eight captures complete. `baseline_runtime_raw.json` preserves stdout/stderr. The Windows renderer fell back to ANGLE on Intel HD 4600; it also reported inability to create a shader cache directory. Rendering and PNG capture succeeded. No global renderer/user-directory fix was applied. Later QA should keep those environment diagnostics distinct from sprite faults.

Pixelorama MCP is connected: 103 tools discovered, live canvas listing succeeds, current document is an untouched unsaved 64 × 64 untitled canvas. No production pixels have been drawn. Godot editor MCP reports `PLUGIN_DISCONNECTED`; CLI scene loading, headless tests, and graphical capture all work. No setup reinstall or editor restart was necessary for Phase B. Keep Pixelorama open; reconnect its MCP transport only if the session drops.

The current captures do not yet prove left-facing grip, armed graphical motion, hurt/death sequences, transitions across three loops, or final runtime visual quality. Those belong to production/integration and Phase I. Source audit and existing tests establish the mechanics that must survive those stages.

## Saved artifacts and resumption

- `baseline_source_hashes.json` and `baseline_source_verification.json`: 45-source preservation receipt.
- `baseline_sources/`: text snapshots, including player and prop originals.
- `baseline_runtime_probe.gd`, `baseline_runtime.log`, `baseline_runtime_raw.json`: reproducible graphical audit and process evidence.
- `baseline_runtime/`: eight full captures, matched observations, and an analysis-only nearest crop composite (order left-to-right, top-to-bottom matches observations).
- `audit_existing_assets.py`, `existing_asset_audit.json`: read-only metrics for 30 legacy runtime PNGs. Pillow is used only for inspection/cropping, never production drawing.
- `baseline_tests.json`: all seven suite outputs and exit codes.
- `support_read.json`: manifest for the 67 completed support reads, with four absent optional rig references noted.
- `checkpoint.json` and `checkpoint.md`: authoritative phase state and next action.

STOP HERE. Next turn starts Phase C: reference sprite and animation audit with PASS / FIX / REPLACE decisions. Do not start research, body-law synthesis, or raster production in this turn.
