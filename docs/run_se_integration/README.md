# RUN (South-East) integration — record

## Source of truth
- **Approved source:** `maincharacter/Idle_running-8-frames_south-east.gif`
  - SHA-256 FB768442C9E688625DD11C081AD397834E9E987C9997F7072BD04D767E05972E — unchanged.
  - 8 frames, 88×88, 1-bit alpha, 200 ms/frame, loop 0, disposal 2.
- **Production frames:** `art/character/player/run_southeast/run_se_00..07.png`.
  - Lossless extraction, verified pixel-identical to the decoded GIF frames.
  - Alpha 0/255 only; 88×88 kept.
- **Import:** `compress/mode=0` (lossless), `mipmaps/generate=false`. The player sprite sets `TEXTURE_FILTER_NEAREST`, and no global render setting changed.

## Runtime binding (`scripts/player.gd`)
The existing system is kept: one `Sprite2D` plus the `_pick_frame()` picker. There is no AnimatedSprite2D/AnimationPlayer, and none was added.

| Item | Detail |
|---|---|
| Frame names | `run_se_00..07`; the picker returns them by distance. |
| Pivot | Texture (44,71) = feet = player origin. The legacy 64×64 frames keep (32,62); `_show_frame` switches the offset with the texture. |
| Cadence | One drawing per 24 px of real ground travel: about 13 drawings/s at 280 px/s, slower while accelerating. The GIF's 5 fps would skate badly at gameplay speed. |
| Run condition | Grounded **and** actually travelling (`get_real_velocity()`), so pushing into a wall shows idle, not a treadmill. |
| Update order | The sprite frame updates after `move_and_slide()`, so there's no 1-tick run frame after takeoff. |
| Texture swaps | Only when the picked frame name changes, so nothing restarts per tick. |
| Facing | Right = South-East as authored; left = mirrored via the existing `sprite.scale.x = -1` facing path. |

Gameplay, physics, collision, hitboxes and timings are unchanged.

## Evidence
| File | What |
|---|---|
| `logs_baseline/`, `logs_after_integration/`, `logs_after_cleanup/` | 7 suites, 122/122 each time |
| `probe_graphical_final_1.log`, `probe_graphical_final_2.log`, `probe_headless_final.log` | `tests/probe_run_se.gd`, 40/40 each |
| `capture/`, `shots.txt`, `runtime_crops_3x.png` | Real-renderer screenshots with exact player screen positions |
| `pre_change_hashes.json` | Pre-change snapshot (the project is not a git repository) |
| `deletion_manifest.json` | Path, SHA-256 and reason for every deleted file |
