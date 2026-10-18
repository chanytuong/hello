# Movement integration notes — 2026-10-18

Source inspection before implementation: `project.godot`, `scenes/player.tscn`,
`scripts/player.gd`, `DESIGN_BRIEF.md`, canonical sprite workflow and current
RUN/skid/jump/roll/flame exports. No applicable AGENTS.md exists. Enumerated
14 agentskill packages; applied Godot Game Studio implementation/quality gates,
Godot development, animation, 2D movement and input-system skills.

The existing CharacterBody2D controller already provides acceleration, reversal,
jump cut, coyote time and buffering. Reuse those functions. Its current dash
grants i-frames and its visuals use an older PixelLab run, so add an opt-in
movement prototype mode to that same player, with separate presentation and
ground-roll behavior. Preserve the existing combat scene as a regression case.

Use a small movement test scene as the launch scene. Keep old main.tscn available.
No enemies, attack or Blink in this test. Preserve normal movement numbers and
the existing capsule. Roll uses the processed 21-frame in-place export, 30 FPS,
0.7 seconds, current run_speed 280 px/s, through move_and_slide only. This gives
196 px unobstructed travel, close to the source reference's projected 195 px.
Jump cancels roll immediately; falling off an edge cancels the ground roll.
Roll direction commits until completion or jump; no i-frames. Release skid is
visual only and interrupts immediately on new movement/jump/dodge input. Normal
direction reversal keeps the existing acceleration and changes facing promptly.

Only five visible states. No approval evidence for latest jump/roll/flame is
present: label them TEMPORARY review candidates. IDLE is a held existing standing
frame. JUMP holds current AIR as a temporary fallback; do not introduce FALL/LAND.
RUN and SKID source drawings stay exact. Pack native 82px cells losslessly,
without resizing, trimming, color processing or camera reconstruction. Retain
separately rendered left/right cells and exact per-frame neck anchors.

Reuse the existing 12-cel V3 flame and its spring arithmetic. For the roll only,
use exported neck-to-tip vectors as an angular attachment, keeping the root
fixed. This is attachment integration, not new flame artwork.

Verification: real Godot parse/import and controller regression tests, followed
by frame-timed input replays in the actual movement scene. Save runtime traces,
framebuffers and a short capture, inspect native and 4x nearest crops. No manual
feel PASS without a human playtest. No connected Godot editor session is exposed;
use the installed Godot 4.7.2 executable, not simulated Blender output.

Documentation checked: [AnimatedSprite2D](https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html),
[SpriteFrames](https://docs.godotengine.org/en/stable/classes/class_spriteframes.html),
[CharacterBody2D movement](https://docs.godotengine.org/en/4.7/tutorials/physics/using_character_body_2d.html).
Keep frame/progress when changing directional clips; play only on state changes.
Read grounded/collision results after move_and_slide; physics owns displacement.

Git is not configured. Save original project/controller files and hashes before
editing them. Final evidence and exact playtest steps belong in
MOVEMENT_INTEGRATION_QA.md. Stop for human review after this focused integration.
