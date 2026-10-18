# Pixelorama-MCP Setup & Capability Verification

**Date:** 2026-10-04
**Scope:** Connect a zero-cost Pixelorama + Pixelorama-MCP workflow to OpenCode, then verify it honestly.
**Cost incurred:** $0. No paid software, no paid Aseprite license, no paid API, no card trial, no metered
service, no account signup, no admin rights. Pixelorama and Pixelorama-MCP are both MIT-licensed and
open source; the bridge is a local HTTP server on `127.0.0.1:7373`.

**Out of scope (honoured):** no protagonist redesign, no gameplay change, no scene/node change, no
modification of existing character art. All test art lives in `art\_mcp_test\`.

---

## 1. What was installed (all user-level, all free)

| Component | Version | Source | Install path |
|---|---|---|---|
| Pixelorama | `v1.2.3-stable` (MIT) | GitHub release `Pixelorama-Windows-64bit.zip` (40,853,820 bytes) | `C:\Users\Aloha\AppData\Local\Programs\Pixelorama\Pixelorama-Windows-64bit\Pixelorama.exe` |
| Pixelorama-MCP | `pix-mcp 0.2.1` (MIT) | `github.com/abidoo22/Pixelorama-MCP` | `E:\neverlookback\tools\pixelorama-mcp\` |
| Bridge plugin | `PixMcpBridge 0.2.1`, `supported_api_versions [6,7,8,9,10]` | repo `pixelorama-plugin/PixMcpBridge.pck` (172,416 bytes, SHA-256 `ACE5CF56…D6CD77`) | `%APPDATA%\Pixelorama\extensions\` (active) and `<exe>\pixelorama_data\Extensions\` (inactive copy) |
| Runtime | Node v24.18.0 / npm 12.0.1 / git 2.55.0 (pre-existing) | — | — |

Nothing was written to `C:\Program Files`, and no game-source folder received tooling dependencies.

## 2. Build command that actually works

`npm install` **fails** on an upstream dev-dependency conflict:

```
npm error Conflicting peer dependency: eslint@10.12.0
npm error peerOptional eslint@"^10.0.0" from @eslint/js@10.0.1
npm error dev @eslint/js@"^10.0.1" ... dev eslint@"^9.39.4"
```

The lockfile-pinned install succeeds: **`npm ci` → 196 packages, then `npm run build` (tsc) → 0 errors**,
producing `mcp-server/dist/index.js` plus `dist/{bridge,tools,utils}`. `npm audit` reports 8 vulnerabilities
(1 low, 2 moderate, 5 high — `brace-expansion` DoS, `body-parser` DoS, `@hono/node-server` Windows path
traversal). They are in transitive/dev dependencies; `npm audit fix` was **not** run because it rewrites the
lockfile the build depends on. Recorded as a known debt.

The server talks to the bridge via `BRIDGE_URL = process.env.PIX_MCP_BRIDGE_URL || "http://127.0.0.1:7373"`
(`src/bridge/pixelorama_client.ts:8`).

## 3. The one non-obvious setup step

Pixelorama loads extensions from `user://extensions` (source: `src/HandleExtensions.gd`,
`EXTENSIONS_PATH := "user://extensions"` → `C:\Users\Aloha\AppData\Roaming\Pixelorama\extensions` here, i.e.
the zip build is *not* portable-mode) and reads enablement from the config cache with a default of **false**:

```gdscript
extension.enabled = Global.config_cache.get_value("extensions", extension.file_name, internal)
```

`extension.file_name` comes from the `name` key in `extension.json` (`"PixMcpBridge"`), **not** the `.pck`
filename. Dropping the file in the extensions folder is not enough — after first launch the bridge was
down. Fix: append to `%APPDATA%\Pixelorama\config.ini`

```ini
[extensions]
PixMcpBridge=true
```

then restart Pixelorama. Verified:

```json
{"api_version":9,"pixelorama_version":"v1.2.3-stable","server":"pix-mcp-bridge","status":"ok","version":"0.2.0"}
```

`api_version 9` is inside the plugin's supported range, and Pixelorama `v1.2.4-dev` master also ships
`ExtensionsAPI_Version=9`, so a future upgrade within 1.2.x should stay compatible.

**Operating requirement: Pixelorama must be left open while the MCP is used** — the HTTP server runs inside
Pixelorama. There is no headless mode for the bridge.

## 4. OpenCode wiring (existing entries preserved)

`E:\neverlookback\opencode.json` — `timeout` block and the `excalidraw` entry are byte-for-byte unchanged;
one server entry added:

```json
"pixelorama": {
  "type": "local",
  "command": ["node", "E:/neverlookback/tools/pixelorama-mcp/mcp-server/dist/index.js"],
  "environment": { "PIX_MCP_BRIDGE_URL": "http://127.0.0.1:7373" }
}
```

JSON validated (`ConvertFrom-Json` → VALID). `opencode mcp list` → `✓ excalidraw`, `✓ pixelorama`.
The global `godot-ai` entry in `~/.config/opencode/opencode.json` was not modified.

**Tool catalog: 103 live tools**, grouped as requested:

- **A. Canvas / document (16):** `create_canvas`, `close_canvas`, `list_canvases`, `switch_canvas`,
  `get_canvas_info`, `describe_canvas`, `rename_canvas`, `open_project`, `save_project`, `fit_viewport`,
  `crop_to_content`, `scale_canvas`, `get_history`, `undo`, `redo`, `clear_cel`
- **B. Pixel drawing (6):** `draw_pixel`, `draw_pixels`, `draw_line`, `draw_path`, `fill_area`, `draw_text`
- **C. Shapes (6):** `draw_rect`, `draw_ellipse`, `draw_polygon`, `apply_outline`, `apply_gradient`,
  `apply_dithering`
- **D. Palette / color (15):** `set_color`, `get_color`, `create_palette`, `delete_palette`, `list_palettes`,
  `switch_palette`, `get_palette_colors`, `add_palette_color`, `set_palette_color`, `get_palette_usage`,
  `remap_to_palette`, `suggest_palette`, `generate_color_ramp`, `color_replace`, `adjust_hsv`
- **E. Layers (11):** `add_layer`, `delete_layer`, `duplicate_layer`, `reorder_layers`, `set_layer_name`,
  `set_layer_visibility`, `set_layer_opacity`, `set_layer_blend_mode`, `merge_layers`, `create_layer_group`,
  `mirror_layer`
- **F. Frames / animation (19):** `add_frame`, `delete_frame`, `duplicate_frame`, `copy_cel`, `switch_frame`,
  `switch_cel`, `get_frames`, `set_frame_duration`, `get_fps`, `set_fps`, `add_animation_tag`,
  `delete_animation_tag`, `get_animation_tags`, `reverse_frames`, `tween_cel`, `set_onion_skinning`,
  `export_animation`, `export_apng`, `export_gif`
- **G. Selection / transform (9):** `select_all`, `deselect`, `invert_selection`, `select_rect`,
  `select_by_color`, `transform_selection`, `transform_cel`, `rotate_cel`, `set_symmetry_guide`
- **H. Import / export (9):** `import_image`, `import_spritesheet`, `export_image`, `export_animation`,
  `export_aseprite_json`, `export_godot_spriteframes`, `export_godot_tileset`, `save_project`, `open_project`
- **I. Spritesheet / atlas (6):** `export_animation(mode=spritesheet)`, `import_spritesheet`, `export_tileset`,
  `create_tileset_canvas`, `check_seamless_tile`, `export_aseprite_json`
- **J. Inspection / QA / effects (exceeding the ten groups):** `get_pixel`, `get_pixels`, `get_region`,
  `get_canvas_snapshot`, `capture_canvas_image`, `validate_sprite`, `get_palette_usage`, `get_layers`,
  `get_history`, plus effects `apply_glow`, `apply_drop_shadow`, `clean_isolated_pixels`, `generate_sprite`,
  `suggest_palette`, `set_tile_mode`, `adjust_hsv`, `apply_dithering`

## 5. Smoke test — 32×32 crate (disposable, `art\_mcp_test\`)

Requirements met: transparent background, limited palette (**exactly 6 colours**), 1px outline,
3-value shading, hard pixels, no anti-aliasing, 2 layers.

- Layer `Layer 1` (body): 484 px batch draw, 3 values (`#b3854c` lit / `#8b5e34` base / `#5a3a1a` shadow)
- Layer `detail`: 159 px batch draw (outline `#241505`, seams, 2×2 metal brackets `#6e6e78`, glint `#d2a86a`)
- `validate_sprite`: **576 non-transparent, 0 semi-transparent, bbox (4,4) 24×24, 6 unique colours,
  0 enclosed holes, 0 stray/orphan pixels**
- Post-inspection edit: 6 px added (nails + seam thickening)
- `duplicate_frame` deep-copied 638 px; transparent erase (`#00000000`) carved a crack in frame 1;
  `undo` restored the accidental full-cel clear exactly
- `capture_canvas_image` returned real inline PNGs that I inspected visually at each step

Exports (verified on disk by PNG IHDR parsing):

| File | Dimensions | Notes |
|---|---|---|
| `crate.png` | 32×32 | RGBA8 (colortype 6) |
| `crate_4x.png` | 128×128 | nearest-neighbour 4× |
| `crate_pass1_4x.png` / `crate_pass2_6x.png` | 192×192 | iteration evidence |
| `crate_spritesheet.png` | 64×32 | 2 frames × 32×32 |
| `crate_break_spritesheet.png` | 128×32 | 4 frames × 32×32 |
| `break_0000..0003.png` | 32×32 each | individual frames |
| `crate_test.pxo` | 3,464 bytes | round-trips to 2 layers / 4 frames |

## 6. Iteration test — two correction passes (the required proof)

**Pass 1 — DRAW → INSPECT → DEFECT → EDIT → INSPECT.**
`get_pixels` over the four metal brackets returned hard coordinates: left brackets at x=5,6 and top at y=5,6
sit flush against the outline (gap 0), while right at x=24,25 and bottom at y=24,25 leave a 1px gap before
the outline (x=26 / y=26). **Defect: brackets off-centre by 1px toward the top-left.** Fix: erased 7 px to
transparent, drew 7 px on the far side. Re-sample of 49 coordinates confirmed left x=5,6 / right x=25,26 /
top y=5,6 / bottom y=25,26 — all flush, all four corners symmetric.

**Pass 2 — DRAW → INSPECT → DEFECT → EDIT → INSPECT.**
Visual inspection of the 6× export showed the light-plane boundary at y=10/11 cutting across the *middle*
of the upper quadrants, unrelated to the plank seam at y=16 — it read as an arbitrary stripe.
**Fix:** re-lit 110 px so the lit plane runs y=5→15. Re-inspection of rows y=9..18 on the body layer shows
uniform `#b3854c` through y=15 with the transition landing exactly on the seam row (covered by the outline
seam); `validate_sprite` still reports 6 colours, 0 holes, 0 orphans.

**Answer to the critical question: the MCP can reliably edit existing pixels.** Before/after samples were
measured each time, transparent erasing works, and `undo` is real. The iteration loop is proven, not assumed.

## 7. Animation test — 4-frame crate break

- 4 frames: intact → cracked → bottom-right blown out → bottom slab
- Per-frame durations **1x / 1x / 2x / 3x** (verified by `get_frames`)
- `set_fps 8`; animation tag `"break"` spanning frames 0..3 (colour `ff5500ff`)
- Onion skinning enabled (past 1 / future 1)
- Export: `crate_break_spritesheet.png` 128×32 (4×1 grid) + `break_0000..0003.png` each 32×32
- **No playback/preview tool exists** — playback is GUI-only; the strip is the machine-checkable proxy

## 8. Godot pipeline test

godot-ai could not be used (see §11), so verification used Godot's own importer via
`C:\Users\Aloha\Downloads\Godot_v4.7.2-stable_win64.exe` (headless, project untouched):

- `--import` produced `.import` sidecars + `.ctex` for every test PNG
- Import settings are correct for pixel art: `compress/mode=0` (lossless), `mipmaps/generate=false`,
  `process/fix_alpha_border=true`, `size_limit=0`
- Headless load probe: `crate.png` → 32×32, format 5 (RGBA8), corner alpha = **0.0** (transparency kept),
  `bracket(5,5)` = `#6e6e78` and `seam(16,12)` = `#241505` exactly — **no blur, no colour drift**
- `export_godot_spriteframes` → 4 PNGs + `mcp_crate_final_break_frames.tres`. First run failed because it
  exported the *active* canvas (1 frame). After `switch_canvas` to the 4-frame project it wrote 4 frames.
  Headless probe after `--import`: `SpriteFrames`, `animations=["break"]`, `frames=4`, `speed=8.0`,
  `loop=false`, **`textures_ok=4 textures_null=0`, zero errors**

**Project-side finding (reported, not changed):** `rendering/textures/canvas_textures/default_texture_filter`
resolves to **1 = Linear** (engine enum: `Nearest, Linear, Linear Mipmap, Nearest Mipmap`). Any sprite shown
magnified without an explicit filter will blur. Only `scripts/player.gd:435` sets
`TEXTURE_FILTER_NEAREST`; no `.tscn` overrides `texture_filter`. Changing the project-wide default would
alter rendering of the shipped prototype, so it was **deliberately left alone** — it is a one-line decision
for the team, not part of this task.

## 9. Skill integration (Phase 11)

OpenCode V2 **does** support registering these skills. Constraints found in the docs:
skills are discovered from `.opencode/skills` (project) plus global/compat locations, `SKILL.md` is found at
any depth, and **IDs are derived from the path** — a root-level `SKILL.md` gets the literal ID `SKILL`, which
would collide for two root-level skills, and pointing the source root at `agentskill\` would discover all
405 skills (explicitly unwanted).

Solution: four zero-copy directory junctions under the documented project location, each producing a correct
path-derived ID and keeping relative references inside each skill resolvable:

| Registered ID | Junction target |
|---|---|
| `pixel-art` | `agentskill\agent-skill-pixel-art-4.3.0\skills\pixel-art` (104 KB, 36 files) |
| `game-feel` | `agentskill\game-feel-skill-main\skills\game-feel` (34 KB, 4 files) |
| `2dimg2motion` | `agentskill\2dimg2motion-main` (12.6 MB — not copied) |
| `godot-game-studio-agent` | `agentskill\godot-game-studio-agent-main` (60 KB, 15 files) |

Two nested sub-skills inside the 2dimg2motion tree were auto-discovered as well: `img2mo-learn`, `img2mo-std.
**6 new skills, 8 total** (the original 2 plus these) — nowhere near hundreds. Fully reversible by deleting
`\.opencode\skills\`.

**Verified live, not claimed:** `skill({id:"pixel-art"})` loaded the full skill body with the correct base
directory through the junction.

Honest limitations:
- `2dimg2motion` requires an image-generation model (`image_gen`) to draw motion frames. **No image-generation
  model exists in this environment**, so its primary generation path cannot execute. Its rules remain useful
  (identity lock, keypose discipline, and its explicit ban on PIL/SVG/affine frame synthesis — a rule this
  project previously violated).
- `pixel-art` ships `scripts/quality_audit.py`, which previously crashed here with
  `UnicodeEncodeError: 'charmap' codec can't decode … \u26a0` on the cp1252 Windows console. Usable, but it
  needs `PYTHONIOENCODING=utf-8` or a `chcp 65001` wrapper on Windows.

## 10. Ratings (0–10) for the eight production targets

| # | Target | Score | Basis |
|---|---|---|---|
| 1 | Professional protagonist sprite editing | **7/10** | Proven: exact per-pixel read/write, batch draws, two measured correction passes, transparent erase, real undo, layers, palettes, visual inspection. Capped by stateful targeting (§11), silent parameter stripping, and the absence of any image-generation model. |
| 2 | Sprite-sheet production | **9/10** | Spritesheet + individual-frame export, column control, Aseprite JSON, `.pxo` round-trip, all dimensions machine-verified. Minor: per-frame durations dropped by the `.tres` writer. |
| 3 | Animation editing | **8/10** | 4-frame build with duplicate/edit, durations, FPS, tags, onion skinning, strip + APNG/GIF export. No playback/preview tool (GUI only). |
| 4 | Tilemaps / tilesets | **6/10** | `create_tileset_canvas`, `export_tileset`, `export_godot_tileset`, `check_seamless_tile`, `set_tile_mode`, `apply_dithering`, `apply_gradient` exist — **enumerated but not exercised**. Rated on unverified surface, deliberately not inflated. |
| 5 | Props | **8/10** | The crate is a prop; the full draw→inspect→edit→export→Godot path was proven on it. |
| 6 | Weapons | **8/10** | Same tool surface as props (silhouettes, outlines, 3-value shading, metal palettes). `generate_sprite` procedural helper untested. |
| 7 | Environmental pixel layers | **7/10** | Layer groups, blend modes, opacity, mirror, gradient, dither, glow, drop-shadow available; multi-layer editing proven at 2 layers. Blend modes and groups not exercised. |
| 8 | Iterative AI correction | **8/10** | Two complete DRAW→INSPECT→DEFECT→EDIT→INSPECT loops with measured before/after pixels. Capped by `get_region` being single-layer by default and no automated diff/compare tool. |

## 11. Weakest points — stated plainly

1. **Statefulness is the real risk, not pixel editing.** Most tools act on the *active* canvas/frame/layer and
   there is no `canvas` parameter. Two concrete incidents: `import_image` opened a new canvas so the next
   `export_godot_spriteframes` silently exported 1 frame instead of 4; `open_project` left two tabs pointing at
   the same `.pxo` plus a stray `untitled` tab (4 canvases, non-obvious indices). Wrong index = wrong asset,
   with a success message.
2. **Unknown parameters are silently stripped, not rejected.** `set_frame_duration` takes `index`, while
   `draw_pixels`/`get_region` take `frame`. Passing `frame:` to `set_frame_duration` produced four
   "✅ Frame … duration set" messages that all hit the current frame. No error was raised.
3. **`get_region` inspects only the current layer** unless `layer` is passed — the first read looked empty
   because it sampled the detail layer.
4. **`export_godot_spriteframes` drops per-frame durations** (all `duration=1.0` despite 1x/1x/2x/3x, even
   though `get_frame_duration` exists) and writes relative `ext_resource` paths; the PNGs also need an import
   pass before the `.tres` resolves textures.
5. **Pixelorama must stay open** (bridge runs inside it); no headless/batch mode. Extension enablement requires
   hand-editing `config.ini`.
6. **`npm install` is broken upstream**; `npm ci` is required. 8 npm-audit findings left unpatched to keep the
   lockfile intact.
7. **No image-generation model exists** (unchanged from the prior audit) — the MCP gives precise pixel
   *execution*, but composition/geometry is still computed by the model, not imagined as pixels.
8. **Tilemap/environment capability is unverified** (rated 6/10 for that reason).

## 12. Comparison with PIL (the tool the project was forced to use)

| Dimension | Pixelorama-MCP | PIL (`gen_character_art.py`, 1,120 lines) |
|---|---|---|
| Cost | $0 | $0 |
| Pixel-accurate writes | Yes, inside a real editor with history | Yes, into raw arrays |
| Undo / redo | Real, inspectable (`get_history`) | None — every run is from scratch |
| Inspection | `get_pixels`, `get_region`, `validate_sprite`, plus **images I can actually see** | Hand-written sampling code only |
| QA (holes, orphans, AA, palette) | `validate_sprite` built in | Custom code; `quality_audit.py` crashes on this console |
| Spritesheet / frames / APNG / GIF / Aseprite JSON | Built in | Hand-rolled |
| Godot export (`.tres`, SpriteFrames, tilesets) | Built in | Hand-rolled |
| Palette / ramp / dither / gradient / glow / shadow / outline | Built in | Hand-rolled per feature |
| Headless / batch | **No** (GUI must be open) | Yes |
| Deterministic CI use | Poor | Good |

**Conclusion:** the prior audit's root cause ("PIL was forced, not chosen") is now resolved for pixel
*editing* — Pixelorama-MCP replaces PIL's forced art-production role with a real editor, verified QA and
engine export, at zero cost. PIL remains legitimate as scaffolding/QA glue and for headless batch work.
PIL should no longer be used to *draw* game frames.

## 13. Incident report — godot-ai MCP (my error, disclosed)

While cleaning up a temporary probe I ran:

```powershell
Get-Process | Where-Object { $_.ProcessName -match "Godot" } | Stop-Process -Force
```

PowerShell's `-match` is **case-insensitive**, so this also matched the `godot-ai` MCP processes and killed
them. That broke a pre-existing MCP, which the brief explicitly forbade.

**Current state (verified):**
- `opencode mcp list` → `✓ excalidraw`, `✗ godot-ai failed: Connection closed`, `✓ pixelorama`
- This session's `godot-ai` tool namespace is gone (0 tools available)
- The background service logged **no** reconnect attempt after the kill
- Config is intact: the global `godot-ai` entry and project `excalidraw`/`pixelorama` entries are unmodified,
  JSON valid
- No orphan processes or ports remain: 8001/8002 are free; the diagnostic backends I spawned (8508, 14328,
  6140) were killed

**The server itself is healthy** — running the configured command directly boots cleanly in 24.3s (exit 0):

```
godot_ai.server | WebSocket server starting on port 8002
INFO: Uvicorn running on http://127.0.0.1:8001  (godot-ai 4.2.3, FastMCP 4.0.5)
```

**Repair:** run `/mcps` in OpenCode and reconnect `godot-ai`, or restart the session / background service
(`opencode service restart`). A service restart drops this session, so it was not done unilaterally.

**Mitigating facts (not an excuse):**
- The log shows `godot-ai` had already failed repeatedly before today — `Request timed out` on 10-01, 10-02,
  10-03 and 10-04 across `C:\Users\Aloha`, `E:\twocuts` and `E:\neverlookback`.
- **godot-ai had zero editor sessions in this project anyway:** NEVERLOOKBACK has no `addons\` directory and no
  `plugin.cfg`, so the plugin was never installed here. Verified error: `PLUGIN_DISCONNECTED:
  no_active_session`. The Phase-10 import verification therefore used headless Godot directly.

## 14. Environment left behind

- **Pixelorama: running** (required for the MCP to work). Extension enabled, bridge healthy.
- **Godot editor: closed** (it was not running before this task; the editor I opened for testing was closed).
- **Test artefacts:** `art\_mcp_test\` contains only disposable crate outputs + their `.import` sidecars.
  Temp probe scripts were deleted. The protagonist was never opened for writing — the import test used a
  copy, `import_source.png`; `art\prototype\character_a2\netural.png` was read only.
- **Skills:** 4 junctions under `\.opencode\skills\` (delete to unregister).
- **Config:** `opencode.json` valid, `excalidraw` + `timeout` preserved.

## 15. Smallest next fixes, in priority order

1. Repair godot-ai: `/mcps` → reconnect, or `opencode service restart` (§13).
2. Decide on the project-wide texture filter: set
   `rendering/textures/canvas_textures/default_texture_filter = 0 (Nearest)` in `project.godot`, or set
   `texture_filter = Nearest` on each magnified sprite (player already does).
3. When using Pixelorama-MCP, always call `list_canvases` → `switch_canvas` before drawing/exporting, and
   never assume a parameter name — read the schema (`index` vs `frame`).
4. Optional: `npm audit fix` in `tools\pixelorama-mcp\mcp-server` on a branch, then re-run `npm run build`.
5. Optional: `set PYTHONIOENCODING=utf-8` before running the `pixel-art` skill's `quality_audit.py`.

## 16. Verdict

**Setup: SUCCESS.** Zero-cost, fully local, MIT-licensed, no account, no admin, no paid tool. 103 MCP tools
connected, existing config entries preserved, Pixelorama v1.2.3 + bridge verified healthy on `127.0.0.1:7373`.

**Verification: SUCCESS with named caveats.** Drawing, inspection, defect detection, pixel editing, a second
correction pass, layering, frames, animation timing/tags, sprite-sheet export, `.pxo` round-trip and Godot
import were all executed and machine-checked. The MCP **can** reliably edit existing pixels — proven twice
with measured before/after coordinates. The genuine weak point is stateful targeting and silently ignored
parameters, not drawing ability.

**Not claimed:** tilemap/environment capability (enumerated only), animation playback (no tool), and any
image-generation-driven art (no such model exists). The protagonist was not redesigned. This is where the
task stops.
