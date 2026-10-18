# CHARACTER ART CAPABILITY AUDIT — NEVERLOOKBACK

**Status: CAPABILITY + WORKFLOW AUDIT ONLY. No art generated, no animation, no gameplay,
no Godot scene, no map/chapter, no new character concept. Existing character art
untouched.**

Date: 2026-10-04 · Scope: every skill, MCP and non-MCP capability reachable from this
session that could materially affect 2D pixel character design.

---

# Current Capabilities

## The one-line summary

> This project has an **exceptional specification and QA culture** and **zero
> art-production capability**. 405 skills exist on disk and **none are registered**.
> 123 MCP tools exist and **none can draw a pixel of character art**. 8 language models
> are reachable and **zero are image models**.

## Verified environment facts

| fact | value | how verified |
|---|---|---|
| Python | 3.14.7 | `python --version` |
| Pillow | 12.3.0 | `import PIL` |
| `OPENAI_API_KEY` | **not set** (process or user) | env probe |
| reachable models | **8, all text LLMs, 0 image models** | `opencode.models()` → `total: 8`, all `opencode/*` |
| image-generation tool | **none** | full 123-tool catalog scan (`image`/`generate`/`draw`/`render`/`art` → only screenshots & vector export) |
| MCP servers connected | 4 (godot-ai, excalidraw, browser, opencode) | tool catalog grouping |
| total MCP tools | 123 | catalog enumeration |
| `SKILL.md` files under `agentskill\` | **405** | recursive count |
| skills actually registered | **2** (`opencode`, `report`) | session `available_skills` |
| project MCP config | excalidraw only | `opencode.json` |
| project skill config | **none** | `opencode.json` has no skill key; no `.opencode\` dir |

**Direct answer to the audit's central question:**

> **"Do I currently have a tool that is genuinely good at generating high-quality pixel
> character art?"**
>
> **NO.** Not by a small margin — by the entire margin. There is no image model, no
> diffusion endpoint, no `image_gen`, no API key, and no MCP that renders raster art.
> Everything this project has produced visually was **PIL polygon rasterisation**, which
> is *programmatic drawing*, not character design. Calling it art direction is the
> central mistake this audit exists to correct.

---

# Local Skills

`E:\neverlookback\agentskill\` — 10 roots, 405 `SKILL.md`, tagged `.gdignore` (Godot
ignores the folder). **Critical: none are loaded as skills.** They are inert reference
files; using them requires manually opening and reading them.

## 1. `agent-skill-pixel-art-4.3.0` — the strongest *tooling* on disk

**Real, executable, verified.** `skills/pixel-art/scripts/` = 13 Python+Pillow CLIs:

| script | does | category |
|---|---|---|
| `quality_audit.py` | detects anti-aliasing (0<alpha<255), orphan pixels (8-neighbour), colour-count vs budget, grid alignment | **C — QA** |
| `atlas_pack.py` | packs frames into a grid sheet + JSON frame rects | **B — implementation** |
| `palette_remap.py` | nearest-colour (Euclidean RGB) remap to a palette JSON | **B — enforcement** |
| `palette_extract.py` | frequency-analysis palette extraction | **B/C** |
| `sprite_resize.py` | nearest-neighbour resize | **B** |
| `sprite_mirror.py` | batch flip, 5→8 directions | **B** |
| `gif_export.py`, `export_indexed.py` | GIF / indexed PNG output | **B** |
| `outline_generator.py` | 1px outline pass | **B** |
| `dither.py` | Bayer 2×2 / 4×4 matrices | **B** (background only) |
| `noise_generator.py` | value-noise/fBm, palette-quantised → **genuinely draws tiles with no image model** | **B** |
| `batch_audit.py`, `init_workspace.py` | batch QA, workspace scaffold | **C** |

Plus: 10 palette JSONs (pico-8, gameboy, nes, snes, endesga-32, resurrect-64, sweetie-16,
db32, cga, commodore-64), 7 reference MDs (`sprite_conventions`, `animation_principles`
(12 principles w/ pixel diagrams + frame/FPS tables), `color_theory` (hue ramps, 3:1
contrast, Bayer), `tileset_rules`, `isometric_guide`, `ui_elements`, `particle_effects`),
3 HTML viewers, 730+ example PNG/GIF/JSON.

**Discipline it enforces** (genuinely corrective): *palette first → spec lock → generate
→ audit → export*; no anti-aliasing ever; light source top-right across all assets;
banned-features blacklist (AA, sub-pixel, gradients, partial opacity, blur, Bezier,
off-palette colours).

**HARD LIMITS:** **Zero image generation.** Zero character-drawing procedure — the decision
tree literally says *"Create the sprite as a PNG at the target resolution"* and stops.
The only `putpixel` code in the whole skill is a tile-noise snippet. Scripts audit,
transform, or generate procedural textures — **none draws a figure.** Doc drift: README
claims 11 palettes (10 exist), `lospec-500.json` referenced but absent, folder says
4.3.0 while CHANGELOG's top entry is v5.0.0.

**Verified working** — I ran it: `quality_audit.py --image ...neutral.png --max-colors 12`
correctly returned `Audit: FAIL`, then crashed printing a Unicode warning glyph
(`UnicodeEncodeError` on Windows cp1252). Tooling is real but has a Windows encoding bug.

## 2. `2dimg2motion-main` — animation contract, **inert**

3 Pillow scripts: `standardize_baseline.py` (trim→360px subject), `fullframes_to_gif.py`,
`validate_14frame_pattern.py` (asserts 00..13, keyframes 02/05/08/11, RGBA, 00==13 byte
identity).

Fixed 14-frame contract: `00 → 02 → 05 → 08 → 11 → 13`, insertion plan `1/2/2/2/1`,
chroma-key handling, identity-drift correction, `manifest.json` output.

**The single most reusable artifact in the whole folder:**
`references/motion-prompt-patterns.md` (369 lines) — copy-paste prompt library with
identity lock, topology lock, prop taxonomy, non-humanoid blocks, 9 full action
templates, exclusion clauses. This is exactly the material needed the moment an image
model exists.

**HARD LIMITS:** **Requires an `image_gen` model tool the repo does not ship** (README's
own dependency list admits it). And it *explicitly forbids* the fallback:

> *"Do not use scripts, Pillow, canvas, SVG, bone slicing, rotation/scale/affine
> transforms, limb copy-paste, procedural interpolation, or hand-written drawing to
> create keyframes or in-betweens."*

So this skill **blocks the PIL route this project actually used.** Also no pixel-art,
palette or tileset support; referenced `sample/` and `motion/` folders are not present.

## 3. `game-feel-skill-main` — pure prose, unusually concrete

6-layer diagnostic (Input→Response→Context→Polish→Metaphor→Rules), hard gates
(<100 ms response, never >240 ms, *measure don't estimate*), ADSR envelope model,
complete platformer-jump recipe (falling gravity ≈3× rising), 14-item verification
checklist, feeling-word→cause→first-move table.

**Zero scripts, zero images, zero art coverage.** Relevant only *after* sprites exist —
it governs controller and juice, not drawing.

## 4. `godot-game-studio-agent-main` — verification discipline, no art

4 real PowerShell scripts: `start-godot-project.ps1` (non-destructive scaffold),
`validate-godot-project.ps1` (headless import + run + export, greps for `SCRIPT ERROR`),
`check-godot-env.ps1`, `setup-godot-mcp.ps1` (edits `~/.codex/config.toml`).

**Art footprint = 2 sentences** (`references/asset-pipeline.md`: *"Pixel art should use
explicit filtering and integer-scale assumptions"*). **No sprite import settings, no
`SpriteFrames`, no `AnimationPlayer`, no `.import` guidance, no scene-graph editing.**
Defers to an `imagegen` skill that does not exist on this disk.

## 5. `awesome-gamedev-agent-skills-main` — 74 prose skills + 2 real scripts

**The art content lives almost entirely in one place:**
`skills/disciplines/create-game-assets/`

- `references/art-direction.md` — 10-axis system table, and two rules this project
  badly needed: *"Avoid phrases such as 'beautiful,' cinematic, or high quality without
  observable constraints"* and *"Avoid using a living artist's name as the style
  definition."*
- `references/raster-pipeline.md` — *"enforce a real pixel grid after generation. Remove
  blended pseudo-pixels, single-pixel noise, excess colors, banding… Resize only with
  nearest-neighbor"*; *"request the whole action as one strip or sheet — independent
  frame requests drift more"*; Godot 4.7 nearest-filter import checkpoint.
- `assets/art-direction-brief.md` — fill-in brief: shape language, silhouette priorities,
  value structure, palette roles + exact swatches, edge treatment, motion character,
  **explicit exclusions**.
- `assets/asset-manifest.json` — per-asset schema with
  `visual_locks: ["palette","silhouette","proportions","facing","light-direction"]`.
- `scripts/asset_report.py` — numeric image QA (`--expect-size`, `--require-alpha`,
  `--max-colors`, JSON, exit 1). **C — QA.**
- `scripts/build_preview_sheet.py` — labelled contact-sheet compositor, NEAREST upscale.
  **The only script in three roots that emits an image — and it emits a preview, not art.**

Godot sprite integration is here: `godot-animation` (AnimatedSprite2D + SpriteFrames,
keyframing `frame`), `godot-tilemap` (atlas sources, `.tres`), `godot-shaders`.

**HARD LIMITS:** 74 skills are instructions the model must type; production-path table
admits it: *"No generation/edit tool is available → build the brief and manifest; source
licensed assets or keep explicit greybox placeholders."* **Storyboard: zero matches
repo-wide. Comic presentation: zero matches repo-wide.**

## 6. `codex-skills-main` — best prose library; only path to real image gen

`.system/imagegen/scripts/image_gen.py` — Python CLI, subcommands `generate`,
`edit`, `generate-batch`, default model `gpt-image-2`, **requires `OPENAI_API_KEY`
(confirmed absent)**. Plus `remove_chroma_key.py` (chroma→alpha matting — directly useful
for sprite cleanup later).

Art-direction prose (all `SKILL.md` identity + `references/patterns.md`, **zero scripts,
zero reference images**):

| skill | real focus |
|---|---|
| `pixel-art` | **~780 lines, 11 patterns + anti-patterns**: hue shifting, dither patterns, AA rules, selout, pillow shading, tile seams, 4-vs-12-frame walk cycles, NES/SNES/GBA constraints. Drawn from Pedro Medeiros (saint11) knowledge. Strongest rules set anywhere. |
| `art-consistency` | **character bible + turnaround sheet + pre/post-generation QA checklists** — exactly the anti-drift process missing here |
| `character-design` | silhouette, proportion, read-at-small-size, character-sheet conventions |
| `concept-art` | exploration passes, thumbnails → call, spec/prompt writing |
| `weapon-design` | silhouette + function + era coherence |
| `animation-systems` | state machines, timing/easing, frame counts |
| `color-theory`, `lighting-design`, `combat-design`, `motion-design` | supporting grammar |

**No `art-consistency` / `character-design` / `pixel-art` was used in any previous pass.**
`ai-game-art-generation` contains only pseudo-code ComfyUI/LoRA/IP-Adapter workflows — no
JSON graph, no client, no models. Not actionable.

## 7. `skills-open-source-main` — contains the best art-direction skill found

`game-visuals/SKILL.md`:
> *"You MUST consult this skill when reasoning about visual design decisions that serve
> gameplay — art direction for legibility, color and contrast for communication, palette
> design, making simulation systems visually readable… NOT for shader/VFX… NOT for UI."*

Has a **Problem → Concept routing table** (e.g. *"My game looks muddy or flat"* →
Value/Saturation Contrast → grayscale test), plus `art-direction.md`,
`constrained-palette.md` (*"each colour slot has a job"*), `visual-problems.md`,
`simulation-art.md`. Covers colour cycling, palette shifting, post unification.
**Zero scripts, zero palettes, zero examples.** Also `godot` (real Sprite2D /
AnimatedSprite2D / TileSet code patterns — the actual Godot sprite answer), `godot-shader`,
`level-design`.

## 8. `agents-main` (92 plugins) and `skills-main` (25) — mostly irrelevant

- `agents-main`: dev/ops/business marketplace. Islands: `meigen-ai-design` (image gen via
  `npx meigen@1.4.0` MCP — **needs a provider key or ComfyUI backend, neither present**),
  `ui-visual-validator`, `visual-edit-precision`, `ui-designer`.
- `skills-main`: productivity prose. Marginal: `visual-consistency` (screenshot
  before/after QA), `game-design` (interface bundle), `godot` (dated 4.7 snapshot).

## Skill-coverage matrix (honest)

| topic | where it genuinely exists | depth | usable now? |
|---|---|---|---|
| pixel art **rules** | codex `pixel-art`, pixel-art skill refs | **deep** | yes (manual read) |
| pixel art **tooling** | pixel-art skill scripts (13) | **deep** | **yes — verified running** |
| character design | codex `character-design`, `art-consistency` | medium, prose | yes (manual read) |
| concept art | codex `concept-art` | medium, prose | yes (manual read) |
| silhouette | pixel-art `animation_principles`, `create-game-assets`, `game-visuals` | medium | yes |
| sprite sheets | pixel-art `atlas_pack.py`, `create-game-assets` | **tooling** | **yes** |
| animation | 2dimg2motion, pixel-art `animation_principles` | **deep spec** | **no — blocked on image model** |
| motion / game feel | `game-feel-skill`, `create-game-assets/game-feel` | deep, prose | yes (code-side) |
| colour / palette | pixel-art (10 palettes + remap/extract), `game-visuals`, `color-theory` | **deep + tooling** | **yes** |
| art direction | `game-visuals`, `create-game-assets/art-direction.md` | **deep** | yes |
| Godot sprite integration | `godot-animation`, `godot-tilemap`, `godot` (open-source) | deep, code | yes |
| image **analysis** | `asset_report.py`, `quality_audit.py` | **numeric only** | yes |
| image **generation** | codex `imagegen`, meigen MCP | requires credentials | **NO** |
| visual storytelling | `visual-novel` (systems only) | shallow | limited |
| **storyboard** | — | **absent** | no |
| **comic presentation** | — | **absent** | no |

---

# MCP Tools

4 servers, 123 tools. Audited from the live catalog, not from a remembered list.

## 1. `godot-ai` — 47 tools · **strongest integration + visual QA capability**

| tool | what it really does | helps character design? |
|---|---|---|
| `editor_screenshot` | captures editor 2D viewport / game framebuffer, returns a real image. Sources: `viewport_2d`, `game`, `cinematic` | **YES — visual QA at gameplay scale** |
| `game_manage` | runtime scene-tree inspection, `input_sequence` (frame-timed input), `next_frame`, `suspend/resume` | **YES — deterministic pose capture** |
| `project_run` / `project_manage` | play/stop, error reporting | YES |
| `animation_create` / `animation_manage` | AnimationPlayer clips, property/method tracks, `create_simple`, presets, `validate` | **YES — animation authoring** |
| `filesystem_manage` | `write_text`, **`reimport` textures**, `scan`, search | **YES — sprite import** |
| `scene_*` / `node_*` / `script_*` | full scene graph, properties, patching | YES — Godot integration |
| `resource_manage` | resource search/create/assign (Curve, Environment, gradient/noise textures) | partial |
| `material_manage` | material + **shader authoring/validation** (`shader_create`, `shader_patch`) | partial (no FX by refuse-list) |
| `tileset_manage` | `tileset_get_atlas_image` → **base64 PNG read of a tileset atlas** | YES — asset inspection |
| `editor_state`, `logs_read`, `test_run`, `batch_execute` | state, errors, headless tests | YES — regression |

**Can it inspect images?** Yes — `editor_screenshot` and `tileset_get_atlas_image` return
images I can read. Note `editor_screenshot` exposes a `user_prompt` field *"with Vision
Routing enabled it is sent alongside the image so the vision model can describe what the
agent is looking for"* — a possible separate vision path, not confirmed available.

**Can it create/edit visual references?** **No.** It manipulates Godot resources, nodes,
animations, shaders — never raster art.
**Storyboard?** No.
**Limitations:** requires a live Godot editor session; it is an *integration and capture*
tool, not a *creation* tool.

## 2. `excalidraw` — 26 tools · **useful, but for blocking not for sprites**

`create_element`, `batch_create_elements`, `create_from_mermaid`, `update_element`,
`align/distribute/group/ungroup/duplicate`, `snapshot/restore`, `describe_scene`,
`query_elements`, `set_viewport`, `export_scene`, `export_to_image` (PNG/SVG, headless,
scale 1–4), `get_canvas_screenshot`.

**Real value for this project:** **silhouette boards, mood boards, storyboard panels,
pose-blocking diagrams, reference-pack layouts** — vector shapes at arbitrary scale, then
export to PNG for human review.

**Limits:** hand-drawn vector aesthetic. **Cannot produce pixel art.** Not a character
design tool; it's a *thinking and communication* surface. Its output must never be
mistaken for sprite material.

## 3. `browser` — 45 tools · **reference research + human review**

`navigate`, `snapshot`, `screenshot`, `evaluate`, `find`, `network.*`, `files.get`
(download a file from the web to server-local disk), **`preview`** (opens any file — PNG,
GIF, SVG, MD — in the Review pane for the human), `tabs.*`, `console`, `cpu/heap/trace`.

**Real value:** (a) **external reference research** — I can visit pixel-art references,
game sprite databases, artist galleries and *look* at them; (b) `files.get` to save
reference images into `refs\`; (c) **`preview` is the primary human-approval mechanism** —
every stage gate in the recommended workflow passes through it.

**Limits:** no image generation. Page content is untrusted data.

## 4. `opencode` — 5 tools

`models` (model discovery — **this is how I proved no image model exists**),
`list_mcp_resources` / `read_mcp_resource`, `session_move`, `session_rename`.

## MCP verdict table

| question | answer |
|---|---|
| can any MCP **generate** character art? | **NO** |
| can any MCP **inspect** images? | **YES** — godot-ai screenshots/atlas, excalidraw canvas, browser screenshot/preview |
| can any MCP **edit** visual references? | Partial — excalidraw edits *vector diagrams* only |
| can any MCP **storyboard**? | Partial — excalidraw can lay out panels; no dedicated storyboard tool |
| can any MCP **manipulate Godot assets**? | **YES, strongly** — godot-ai (47 tools) |
| is there a missing MCP that would change the answer? | Only an image-generation MCP would |

---

# Other Tools

| capability | exists? | grade | notes |
|---|---|---|---|
| **Read PNG / reference images** | **YES** | **A + C** | I read `refs\Neverlookback Protagonist Sprite Sheet.png` and every prototype sheet this session. This is *the* core design capability I actually have. |
| **Compare screenshots / A-B review** | **YES** | **A + C** | side-by-side sheets already exist (`slump_refine_compare.png`, `redesign_02_overview.png`) |
| **Visual aesthetic judgment** | **YES, with caveat** | **A** | I can *see* and *critique*. Caveat: without a calibrated positive reference, my critique degrades to reacting against words — which is precisely how the previous pass produced mush. |
| Programmatic PIL drawing | **YES** (Py 3.14 / Pillow 12.3) | **D — NOT suitable for final art** | 1,100-line `gen_character_art.py`: capsule/polygon masks, `paint()`, `seal()` flood-fill, auto cel-rim. Produces the blobby results in `art/prototype/`. Legitimate for *scaffolding, mockups, QA overlays, silhouette tests*. **Not a substitute for drawing.** |
| Writing sprite generators | YES | **B / D** | good for pipeline mechanics, not for design |
| Palette extraction / enforcement | YES (`palette_extract`, `palette_remap`) | **B / C** | genuinely strong |
| Silhouette measurement | YES (write scripts) | **C** | opaque-pixel counting, black-fill render, bounding-box, width-growth ratios — already used well |
| Nearest-neighbour scaling | YES | **B** | |
| **Godot runtime capture** | **YES — strong** | **C** | `godot-ai.editor_screenshot` + 19 existing `tests/capture_*.gd` scripts; 7 test suites / 129 assertions |
| Automated visual probes | YES | **C** | `probe_feel*`, `probe_transform`, `audit_combat` |
| External reference research | YES (browser MCP) | **A** | currently **unused** |
| **Image generation** | **NO** | — | **the decisive gap** |
| Independent vision-model QA | NO | — | only numeric audits; I judge my own work with the same model that made it |

---

# Self-Evaluation

Scores are 0–10. "**Theory**" = I understand and can articulate the rules. "**Production**"
= I can reliably produce professional-looking output. These are deliberately separated.

| skill | score | why |
|---|---|---|
| **character concept design** | **5** | Theory: strong — the A/B/C pass produced genuinely differentiated ideas (slump / knot / hitch; spine, self-hold, shoulder-hitch) which is real conceptual work. Production: without positive visual reference I converge on defaults, and I cannot tell when a concept is *beautiful* vs merely *not-ugly*. |
| **pixel-art character design** | **2** | The weakest link. My actual output is capsule-and-polygon rasterisation — see `qa_zoom_poses.png`: faces are colour smudges, limbs are sausages, clothing is a flat rectangle. I understand cluster/AA/ramp theory completely and still cannot execute it. |
| **silhouette design** | **6** | The one area where programmatic drawing partly works, because silhouette is *shape-level*, not pixel-level. The redesign silhouettes were readable and mutually distinct, and I measured growth (1.67× / 1.53× / 1.39×). Still limited: I generate similar blobs without a reference board. |
| **clothing design** | **3** | I can *name* wardrobe facts (mismatched sneakers, stacked hems, rolled sleeves) but at 64 px they collapsed to 1–2 px and vanished. Designing clothing that *reads* at target scale needs reference images, not adjectives. |
| **palette design** | **6** | Genuinely one of my better areas: `CHARACTER_PALETTE.md` has a semantic rule (dark=real, bone=delusion, saturated=enemy), an 18-swatch luma table, measured contrast ratios per background boundary, per-sprite budgets, and a forbidden-use list — plus honest §9 contradictions. Deducted because the *resulting* palettes read muddy and I had no positive palette reference to calibrate against. |
| **pose design** | **5** | Staging theory is good (line of action, coil→commit→contact→whiff→recovery, disagreement during anticipation, planted lower body). Execution at pixel level is weak; poses read as jointed sticks. |
| **animation design** | **6** | Timing/hold/cadence specification is a real strength — measured beat tables, frame budgets per animation, hold-vs-impact rules, five authored rates as cadence. But I have produced **zero** acceptable animation frames, and `2dimg2motion` is blocked. |
| **sprite-sheet production** | **3** | The *machinery* works (atlas pack + JSON, mirror, index, GIF export). The *frames* are the problem, and frames are what a sprite sheet is. |
| **visual storytelling** | **6** | Storyboard A (identity sheet) and Storyboard B (perception pickup) in `CHARACTER_VISUAL_IDENTITY.md` are genuinely good specs — beats, framing, timing, "must be readable", emotion per beat. But there is **no storyboard/comic skill on disk at all**, and storyboards exist only as markdown tables, never as drawn panels. |
| **Delusion Echo design** | **7** | My strongest design work: echoes derive from the *existing* contact frame (single source of truth), bone channel, α0.40, +12 px, −0.12 rad, behind player, hard cut, 4–6 frames, whiffs never echo, three tiers by entry rhythm, clearance rule vs enemies. Precise, cheap, consistent with the refuse-list. Deducted because `PROTOTYPE_EXIT_REVIEW.md` states the decisive read question *"perception changing vs item powering up"* **has never been seen by a human**. |
| **converting static sprites into animation** | **4** | I hold the correct contract (`2dimg2motion`: 14 frames, keyframes 02/05/08/11, insertion 1/2/2/2/1, identity lock, 7 hard-failure constraints, 18-item acceptance list) and it is **completely inert** without an image model. I can author cadence and timing; I cannot author acceptable frames. |
| **Godot sprite integration** | **8** | My strongest area, and it's not close. godot-ai's 47 tools cover import/reimport, texture filtering, SpriteFrames/AnimationPlayer authoring with `validate`, runtime input sequencing, deterministic `next_frame` capture, screenshots — plus 7 passing suites, 129 assertions and 19 capture scripts already in the repo. |
| **visual QA** | **7** | Methodology is strong: black-fill silhouette QA against both state washes, 4×/5×/7× zoom contact sheets, gameplay-scale runtime capture, colour budgets, `quality_audit`/`asset_report`, palette assertions in the generator. Deducted because most judgment happened **at zoom**, and because I am the only judge of my own output. |

**Pattern:** high on *specification, measurement, integration*; low on *execution of
actual artwork*. I am a strong art director and a weak artist — and previous passes let
the weak artist silently do both jobs.

---

# Why Previous Art Failed

## Evidence reviewed

`art/_source/gen_character_art.py` (1,102 lines), `gen_redesign_02.py`,
`gen_a2_production.py`, `gen_slump_refine.py` · all of `art/prototype/` ·
`design/CHARACTER_VISUAL_IDENTITY.md`, `CHARACTER_PALETTE.md`,
`CHARACTER_REDESIGN_02.md`, `VERTICAL_SLICE_ART_PLAN.md`, `PROTOTYPE_EXIT_REVIEW.md`,
`DELUSION_ECHOES.md` · `refs/` (1 file) · the live sprite sheets themselves.

Every concept sheet carries the same footer: **"programmatic PIL art - no
image-generation model."** `CHARACTER_REDESIGN_02.md` §1 states it outright:
*"All concept art in this pass was drawn programmatically with Python + Pillow (no
image-generation model is available in this environment)."*

## PROCESS FAILURES (dominant — roughly 75%)

1. **Designed from prose instead of visual reference.** The entire chain
   (identity → palette → redesign → production) is text-first. The **one** image in
   `refs\` was used for *"presentation only"* — sheet layout, 5-pose row, silhouette band
   — while its actual design content was *"the declared failure"* and *"deliberately NOT
   taken."* Net visual design reference used: **zero.**
2. **Programmatic PIL art mistaken for art direction.** Capsule/polygon rasterisation is
   the proximate cause of the generic look. Strong *specifications* (5.5 heads, C-spine,
   uneven hem) were rendered through a tool that can only make sausages — so every
   intended distinction degraded.
3. **Negative-only pivoting.** The redesign reacted to a *table of banned words* (no
   anime hair, no cool coat, no blade, no glow). Reacting to "cool" produces "boring";
   "ordinary/tired/collapsed" is the degenerate opposite of "heroic," not a designed
   identity. **Without positive references, negation yields mush.**
4. **No style lock, no artist-specific visual grammar.** Style was defined purely by
   *constraints* (no AA, 3-step cel, 1px outline, ≤24 colours). Constraints reliably
   prevent ugliness; they cannot produce beauty. Nothing supplied the positive grammar —
   cluster shapes, ramp structure, outline weight, face shorthand.
5. **Evaluating at zoom instead of gameplay size.** QA sheets are 4×/5×/7×
   (`build_zoom(..., scale=7)`). Claims like *"readable at 50 px"* were asserted against
   zoomed contact sheets. Detail that only survives at 7× gets locked in.
6. **Full sheets generated before approving one sprite.** `main()` in one run emits
   master sheet + run + dash + attack + silhouette QA + echo test + pickup keyposes + five
   zoom sheets. Huge output surface before any human saw a single neutral sprite.
7. **Weapon baked into pose authoring.** `GRIP_P = (48,32)` — `hand_n=GRIP_P` is pinned
   in ready/dash/contact/recovery/run frames; `draw_weapon()` is called inside sheet
   builders. Body textures were exported body-only (good), but the *poses themselves* were
   authored around one grip, which is what "baking" means here.
8. **Costume specified before body language was approved.** Mismatched shoes, stacked
   hems, rolled sleeves, knee patch were written as prose and drawn as 1–2 px facts at
   64 px. Clothing decisions were locked before anyone confirmed the body read.
9. **Reference set far too weak, negatives never imaged.** 1 image total, and it's a
   presentation sheet rather than native-resolution sprite data. "Anti-anime compliance"
   was a markdown table of words — no images of what to avoid.
10. **No iteration against human aesthetic judgment.** `PROTOTYPE_EXIT_REVIEW.md`:
    *"13 of 24 [criteria] rest entirely on a human Play session that has not happened"*
    and *"RECOMMENDATION: DO NOT START PRODUCTION."* Yet `CHARACTER_REDESIGN_02.md` §9
    proceeded to a production test with 15 runtime frames and runtime capture while its
    own status read *"base direction selected, not final."*
11. **Animation/production started before static identity was approved.** A2 went
    straight to 15 runtime frames + `capture_a2.gd` + player.gd `use_a2` toggle + prop.gd
    swing-arc edits, ahead of the identity sign-off its own document required.
12. **Iteration was scalar, not aesthetic.** Refinement produced A1/A2/A3 — three
    variations of one body — and chose by rubric table. Three adjacent options are not
    exploration; they can't reveal that the whole direction is wrong.
13. **Using the same model as both artist and judge.** No independent vision check. My
    self-QA caught *mechanical* defects (pipe through shin, pipe crossing face, invisible
    black-on-dark ghosts) but never "this looks like clip art."

## TOOL LIMITATIONS (real — roughly 25%)

1. **No image-generation model.** 8 text models, 0 image models, no `image_gen`, no API
   key. This is what *forced* the PIL route. `2dimg2motion` is inert because of it and
   explicitly forbids the PIL substitute, so the project used a method its own animation
   skill bans.
2. **405 skills on disk, 0 registered.** `available_skills` = `opencode`, `report` only.
   `pixel-art`, `game-visuals`, `art-consistency`, `character-design` and
   `create-game-assets` — the exact skills that would have enforced palette-first,
   character bible, turnaround and silhouette gates — were never loaded.
3. **`imagegen` skill referenced by 3 skills does not exist** (`godot-game-studio-agent`,
   `create-game-assets`, router all defer to it).
4. **No independent vision QA.** Only numeric audits (`quality_audit`, `asset_report`)
   can run; neither can judge *aesthetics*.
5. **Minor:** `quality_audit.py` crashes on Windows cp1252 when printing `⚠`.

**Honest split:** the missing image model made the failure *certain* once PIL was chosen.
But failures 1, 3, 4, 5, 6, 9, 10 and 11 would have produced generic art **even with a
perfect image model.** Fix tools and you get *competent* slop; fix process and you get a
chance at something good.

---

# Missing Information

## Ranked: what would most reduce ambiguity

Ranking principle: a reference is valuable in proportion to **how many undecided
questions it closes**. Verbal fields close one question each; a well-chosen image closes
dozens simultaneously.

| # | input | ambiguity it resolves | why it ranks here |
|---|---|---|---|
| **1** | **Images of characters I LIKE** (specific, named) | overall shape language, detail density, proportion register, shading depth, how "designed" vs "lived-in" | closes the largest ambiguity — *what "good" means to this human*. Prose cannot convey taste. |
| **2** | **Images I HATE** (specific) | which defaults to reject | negation needs images, not words. "Not anime" produced mush; three hated sprites would be unambiguous. |
| **3** | **Exact pixel-art style reference at native resolution** (real sprite sheets, 1:1) | cluster style, outline policy, AA tolerance, ramp steps, palette count, how faces are shorthand | **distinct from #1**: fixes *how pixels are made*, not *what the shape is*. Substituting one for the other fails. |
| **4** | **Screenshot of target gameplay scale** (real background at 1:1) | how much detail survives; where the value floor is | directly attacks failure #5 (zoom evaluation) and #8 (costume over-specification). |
| **5** | **Body-proportion reference** | head ratio, leg length, shoulder width | "5.5 heads, not 7" is one sentence; the *visual* delta is enormous and prose barely constrains it. |
| **6** | **Clothing reference images** | which garment facts read at 64 px | prose cannot tell me that "stacked hems" = 1 px or "mismatched sneakers" = invisible. |
| **7** | **Palette reference** | hue temperature, saturation ceiling, step count, dark-mass behaviour | closes the muddiness question; lets me *verify* rather than invent `CHARACTER_PALETTE.md`. |
| **8** | **Pose / staging reference** (contact sheets from admired games) | line-of-action strength, exaggeration degree, how planted the lower body looks | separates "the pose is weak" from "the drawing is weak". |
| **9** | **Mood board** (6–12 images) | the overall register: gritty / clean / painterly / graphic | cheap, high-yield, prevents register drift. |
| **10** | **Age / body type / era / location** | immediate silhouette and wardrobe logic | short text, big effect; clothing must follow from context, not from a shopping list. |
| **11** | **Personality, translated to body language** | posture, gesture vocabulary | only useful as *observable physical facts*. "Tired" is not drawable; "chin ahead of sternum, weight on back foot" is. |
| **12** | **Silhouette board** (approved black shapes) | shape-variety target; prevents same-blob drift | best consumed *after* stage 2, as a comparison set. |
| **13** | **Story information** | only if it changes a visible fact | mostly indirect; don't over-collect. |
| **14** | **Weapon classes** | modularity requirements | high for *engineering*, low for static identity. |
| **15** | **Animation requirements** | frame counts, hold beats, which actions exist | high for *production*, zero for static design. |
| **16** | **Face references** | eye/mouth shorthand | low — 10–12 px head, one eye, 3 states. |
| **17** | **Target resolution / sprite dimensions** | — | already locked (1280×720, 64×64, 56 px, 1:1). Near-zero added value. |

**Key insight — different references close different questions:**

- *style reference* → **how pixels are constructed** (outline, clusters, ramps, AA)
- *character reference* → **what the shape language is** (proportion, silhouette, costume)
- *gameplay-scale screenshot* → **how much survives** (detail budget, value floor)
- *negative reference* → **which defaults are forbidden** (the precise failure of pass 02)
- *palette reference* → **the colour register** (temperature, saturation, steps)

"One mood board" is not enough. Each of these five must exist or its question stays open
and I will invent an answer.

---

# Recommended Human Input Format

Improvements over the proposed structure: **(a)** visual and verbal inputs are *separated*
— mixing them caused the original failure; **(b)** every image carries a "take / don't
take" contract — the one thing `CHARACTER_REDESIGN_02.md` did correctly, generalised;
**(c)** an **ambiguity register** forces me to ask instead of invent; **(d)** explicit
**STOP gates**; **(e)** a hard **readability lock** tied to gameplay scale; **(f)** body
language expressed as *observable physical facts*, not adjectives.

```markdown
# CHARACTER SPEC — <name>   (v1 · all fields required or explicitly "N/A")

═══ A. VERBAL INTENT ═══
CHARACTER PURPOSE:        what they are for, in the game AND in the story
REALITY IMPRESSION:       the mundane read — as PHYSICAL FACTS, not adjectives
                          ✗ "tired and ordinary"   ✓ "chin ahead of sternum, weight on
                          back foot, shoulders not square, hands never leave sleeves"
COMBAT IMPRESSION:        same rule — observable body language
BODY TYPE / AGE / BUILD:  frame, height relative to others, age, fitness
POSTURE (NEUTRAL):        the single most important sentence in this section
ERA / LOCATION / CONTEXT: what their clothes are *for*
PERSONALITY → GESTURE:    only physical consequences; skip inner life
STORY FACTS THAT SHOW:    only facts that change something visible

═══ B. VISUAL — POSITIVE ═══   [folder paths, not descriptions]
MUST LOOK LIKE:           refs/character/like/*.png      (3–8 images)
PIXEL STYLE:              refs/character/pixel_style/*.png (3–6 REAL sprite sheets,
                          native resolution, NOT mockups)
CLOTHING:                 refs/character/clothing/*.png  (4–8)
BODY PROPORTIONS:         refs/character/proportions/*.png (2–4)
POSE LANGUAGE:            refs/character/pose_language/*.png (4–8)
PALETTE:                  refs/character/palette/*.png   (2–4)  + any hex you insist on
GAMEPLAY SCALE:           refs/character/scale/*.png     (1–3 screenshots of the REAL
                          game or its genre at 1:1)

═══ C. VISUAL — NEGATIVE ═══   [images required; word-only bans are rejected]
MUST NOT LOOK LIKE:       refs/character/negative/*.png  (3–8 images I can name and
                          point at — "this hair, this coat, this face, this pose")

═══ D. HARD CONSTRAINTS ═══
GAMEPLAY SIZE:            cell ___×___ · character tall ___ px · ground row ___
                          · facing ___ · scale 1:1 at ___×___
READABILITY LOCK:         "must be identifiable as black fill at ___ px on ___ background"
WEAPON REQUIREMENTS:      classes ___ · grip anchor (x,y) ___ · held rotation ___
                          · WEAPON SEPARATE LAYER: yes/no
ANIMATION REQUIREMENTS:   action → frames → hold beats (from VERTICAL_SLICE_ART_PLAN)
DELUSION ECHO:            derive from existing frame? yes/no · channel · alpha · offset

═══ E. PROCESS ═══
DECISION AUTHORITY:       I decide: ______  ·  human decides: ______  (list explicitly)
STOP GATES:               silhouette / neutral sprite / palette / key poses / gameplay —
                          each needs a human PASS before the next
AMBIGUITY REGISTER:       [AI fills: numbered open questions + my proposed default.
                          I will NOT proceed past a Stage gate with an unanswered item
                          marked "blocking"]
```

**Acceptance rule for this form:** if section B or C contains prose instead of images,
the spec is **not ready**. That single rule would have prevented the original failure.

---

# Correct Art Workflow

Built only from capabilities that exist today (skill scripts, PIL, browser reference
research, excalidraw blocking, my own visual reading, godot-ai capture/integration) plus
one declared external dependency for static sprite generation.

```
refs → art-direction extraction → black silhouettes → [HUMAN]
     → one neutral sprite → [HUMAN] → palette test → [HUMAN]
     → 3 key poses → gameplay-scale review → [HUMAN] → weapon modularity
     → [HUMAN] → animation → Godot integration → visual QA loop
```

| # | stage | INPUT | OUTPUT | responsible | human decision | PASS criteria | FAIL action |
|---|---|---|---|---|---|---|---|
| **0** | **Spec intake** | filled spec (§ above) | accepted spec + ambiguity register | human + me | confirm authority split | all B/C sections are **images**; every field filled or "N/A" | return to human; **no drawing** |
| **1** | **Reference research** | section B/C paths | `refs\` populated (browser `files.get` if needed) | me (browser) | confirm each ref earns its place | ≥3 like, ≥3 negative, ≥3 pixel-style, ≥1 gameplay-scale | collect more |
| **2** | **Art-direction extraction** | the ref pack | **style-grammar doc**: cluster/outline/ramp/AA rules, proportion rules, palette hypothesis, do/don't *with each rule citing a specific image* | me | **APPROVE STYLE GRAMMAR** | every rule traceable to a reference; no uncited rule | re-extract; add refs |
| **3** | **Silhouette set** | style grammar + prose intent | **6–12 solid black shapes**, gameplay scale, no colour/detail, plus a silhouette board | external image AI (or blocking) | **pick / reject silhouettes** | ≥1 approved; distinct from negatives | new variation axis (posture, then proportion, then costume) |
| **4** | **One neutral sprite** | approved silhouette + style grammar | **ONE** neutral pose, native res, transparent bg, **on the real gameplay background at 1:1** | external image AI | **"this is the character"** | reads at 1× on real bg; not mistakable for any negative ref | back to 2 or 3 — **not** forward |
| **5** | **Palette test** | approved neutral | same sprite × 2–3 palette options, on **both** state washes | me (`palette_remap`, `quality_audit`) | **lock palette file** | ≤12/sprite, ≤24 master, all boundaries ≥3:1, dark/white split obvious | re-extract palette; never brighten the sprite to fix it |
| **6** | **Three key poses** | approved neutral + palette | neutral / dash / contact, gameplay scale + black-fill on cyan **and** amber wash | external image AI + me | approve staging | identity delta visible in outline; all three read as black fill | restage poses only — identity held fixed |
| **7** | **Gameplay-scale review** | 3 poses in-engine | `godot-ai.editor_screenshot` (`viewport_2d` / `game`) at 1:1 | me (godot-ai) | **approve at real scale** | separates from floor, cyan, amber, hazard, zone labels in worst case | fix value relationship or pose — **never add detail** |
| **8** | **Weapon modularity** | body-only frames + weapon layer | body frames **with no weapon**, weapon as separate 96×64 layer, hand-anchor JSON + crosshair overlay QA image | me | approve anchor contract | ≥2 weapon classes attach to the same anchors with no body edit | re-author anchors; **reject any body frame containing a weapon** |
| **9** | **Full static set** | approved 3 poses | idle, run, skid, jump/fall/land, dash, attack, pickup, hurt, blink arrival — as **strips**, not independent frames | external image AI | review strips | identity held across all frames; `quality_audit` + `asset_report` pass | regenerate the offending strip only |
| **10** | **Animation authoring** | approved static set | cadence per `CHARACTER_VISUAL_IDENTITY` §5.6/5.7 — holds, no runtime rotation, positions snapped | me | feel review at 60 fps | measured beats reproduce (contact ≈6 frames, transform peak ≈3, arrival ≈7); no seam/pop | re-time; do not redraw |
| **11** | **Godot integration** | frames | NEAREST import, SpriteFrames, AnimationPlayer via `animation_manage` + `validate` | me (godot-ai) | — | 7 suites / 129 assertions still pass; no pixel crawl | revert |
| **12** | **Visual QA loop** | running build | silhouette QA, zoom sheets, gameplay captures, numeric audits | me + **human** | **compare-pairs A–F play session** | `PROTOTYPE_EXIT_REVIEW` items 14–24 answered by eyes | loop to 4/6/7 |

**Two hard rules that make this different from the previous process:**

1. **No stage may be skipped because "the next stage is cheap."** The previous pass ran
   `main()` and produced 8 sheets in one shot; here stage 4 produces *one sprite* and
   stops.
2. **Every gate is a human looking at an image at gameplay scale.** Numeric audits
   (`quality_audit`, `asset_report`, silhouette mass, contrast ratios) are *evidence for*
   the gate, never a *substitute for* it — the same rule `PROTOTYPE_EXIT_REVIEW.md`
   already states for feel, applied to art.

---

# Reference Pack

```
refs\
  Neverlookback Protagonist Sprite Sheet.png      (existing — reclassified, see below)
  character\
    like\              3–8   characters I actively admire (any style)
    negative\          3–8   specific images + 1 line each: WHICH part is banned
    pixel_style\       3–6   real sprite sheets at NATIVE res (not mockups, not AI sheets)
    clothing\          4–8   garments that read at small scale
    proportions\       2–4   head ratio / leg length / shoulder width exemplars
    posture\           3–6   standing neutral: slouch, hitch, fold, weight-back
    pose_language\     4–8   contact sheets: line of action, exaggeration, planted feet
    palette\           2–4   colour registers I like + 1 that I don't
    scale\             1–3   screenshots of this game (or its genre) at 1:1
    silhouette\        4–8   approved black shapes (populated at Stage 3)
    weapon_modularity\ 2–4   bodies holding different weapons, same anchors
    hallucination\     2–4   MY previous failures — what I must not repeat
    mood\              6–12  overall register board
```

| category | count | should demonstrate | **must NOT infer** |
|---|---|---|---|
| `like` | 3–8 | taste: shape language, detail density, proportion register | not a template — extract *principles*, never copy a character |
| `negative` | 3–8 + 1 line each | exactly which element is banned | don't reject the whole image for one bad part; label the part |
| `pixel_style` | 3–6 | cluster style, outline weight, ramp steps, AA policy, face shorthand, palette size | don't copy their palette or their character — **construction rules only** |
| `clothing` | 4–8 | garments whose *identity survives* at 64 px | don't import brand/era detail that vanishes at target scale |
| `proportions` | 2–4 | head:body ratio, leg length, shoulder width | don't average two incompatible ratios |
| `posture` | 3–6 | a neutral that is *specific* rather than "stand here" | don't copy the pose literally — take the weight distribution |
| `pose_language` | 4–8 | line-of-action strength, exaggeration, lower-body honesty | don't stage the same attack — take the *grammar* of staging |
| `palette` | 2–4 | temperature, saturation ceiling, step count, dark-mass behaviour | don't lift hex values wholesale; rebuild against the semantic rule |
| `scale` | 1–3 | **how much detail actually survives at 1:1** | don't design at zoom — this image is the authority |
| `silhouette` | 4–8 | approved shape variety (Stage 3 output) | don't detail-fill; silhouettes are a *gate*, not a style |
| `weapon_modularity` | 2–4 | body unchanged across weapon swaps | don't bake the weapon into the body |
| `hallucination` | 2–4 | my previous outputs that failed — see `art/prototype/` | not to be "improved slightly"; they define the floor |
| `mood` | 6–12 | overall register | not a sprite source |

**Standing rule: references constrain principles; they are never traced, composited, or
copied character-for-character.**

**Reclassification of the existing file:** `refs\Neverlookback Protagonist Sprite Sheet.png`
is an **AI-generated presentation mockup**, not sprite data. It is legitimate as a
*layout / storyboard* reference (5-pose row, silhouette band, palette strip, detail
callouts) — and `CHARACTER_REDESIGN_02.md` already used it correctly for exactly that.
It must **not** be treated as a pixel-style reference: its characters are rendered at
inconsistent scale with anti-aliased edges and no enforceable grid, and its design content
was already declared the failure. It belongs in `mood\` or a new `layout\` category.

---

# Missing Capabilities

## Q: do we need A / B / C / D / E?

**Ranked by expected impact:**

### 1st — **D. external human-made references** (highest impact, near-zero cost)

The actual missing input. Nothing else in this list changes the output as much as 8
correctly-chosen images in `refs\character\like\` and `refs\character\negative\`.
**Do this first. No installation required.**

### 2nd — **C. a dedicated image-generation model/tool**

The actual missing capability. Stated precisely, the missing thing is:

> **A reference-conditioned image model with deterministic output resolution and
> cross-pose character consistency.**

Specifically it must provide:
1. **Professional character concept generation** — full artistic quality, not polygon fill.
2. **Reference conditioning** (image-to-image / IP-Adapter / style ref) so output follows
   *my* pack rather than a text prompt's priors.
3. **Resolution control** — generate at or near **64×64 native**, or at a small multiple
   that downsamples cleanly with nearest-neighbour. High-res-then-downscale is the
   standard route but must be verified per-character.
4. **Consistent-character generation** — same identity across neutral / dash / contact /
   run without redesign (the `art-consistency` turnaround + character-bible process needs
   a model that can honour it).
5. **Transparent or chroma-key background** for sprite extraction
   (`remove_chroma_key.py` already exists for this).

Candidate routes (in order of fit): `codex-skills-main\.system\imagegen` (**already on
disk**, needs `OPENAI_API_KEY`) → `meigen-ai-design` MCP (needs key or ComfyUI) → any
other image MCP. **Note: whichever route, it must also honour the *refusal* —
`2dimg2motion` and `create-game-assets` already assume such a tool exists.**

**Also missing and worth naming:** an **independent vision-QA judge**. Today I grade my
own work. A second opinion — even a cheap vision model asked *"which of these two reads
better at 64 px?"* — would catch the class of defect my self-review never has.

### 3rd — **A. another local skill — but the real action is REGISTRATION, not installation**

405 skills exist; **0 are loaded.** Installing a 406th adds nothing.

Recommended (config change, not a download): register these four so they actually load —

| skill | why |
|---|---|
| `agent-skill-pixel-art-4.3.0` | palette-first / spec-lock / no-AA / audit-before-export discipline + 13 working scripts |
| `skills-open-source-main\game-visuals` | best art-direction routing table found |
| `awesome-gamedev-agent-skills-main\...\create-game-assets` | art-direction brief, visual locks, raster pipeline, QA scripts |
| `codex-skills-main\art-consistency` | character bible + turnaround — directly prevents identity drift |

(`codex-skills-main\pixel-art` is worth reading once for its ~780 lines of patterns.)

### 4th — **B. another MCP**

**Low.** godot-ai (integration + capture), browser (reference research + human preview)
and excalidraw (blocking/storyboard) already cover the non-generation surface. The only
MCP that would change the answer is an **image-generation MCP**, which is category C.

### 5th — **E. none of the above**

Not correct — C is genuinely missing.

## Capabilities that are definitively NOT missing

Palette enforcement (`palette_remap`), pixel QA (`quality_audit`, `asset_report`),
atlas packing, mirroring, nearest-neighbour scaling, silhouette measurement, contact
sheets, GIF export, Godot import/animation/integration, runtime capture, deterministic
frame-timed input, storyboard *specification*, game-feel measurement, reference research,
image **reading**.

## Capabilities that must NOT be faked

PIL drawing must never again be presented as concept art. It is a scaffolding and QA
tool. The distinction is the single most important finding of this audit.

---

# External Image AI vs Local Agent Responsibilities

Splitting static generation from animation/integration is **sound** — and it matches
what the local skills already assume (`create-game-assets`: *"build the brief… source
licensed assets"*; `2dimg2motion`: requires `image_gen`; `godot-game-studio-agent`:
defers to `imagegen`). It works only with hard contracts on both sides.

### 1. What the external image AI should produce

1. Silhouette exploration sets (6–12 black shapes, native resolution).
2. **One approved neutral sprite** — 64×64, transparent/chroma background, facing right,
   ground line at the locked row, **body only, no weapon**.
3. Approved **key poses**: neutral, ready, dash, contact, recovery — each a separate
   file, same cell, same identity.
4. Full strips **as strips** (run, attack, idle) — never independent frames
   (`raster-pipeline.md`: *"independent frame requests drift more"*).
5. A **character turnaround + bible** per `art-consistency`, maintained every round.
6. Clothing / prop call-outs at native resolution.
7. Palette option swatches.

**Never:** animation frames, sprite sheets with baked chrome, backgrounds, glow/FX
(refuse-list), or a weapon inside a body sprite.

### 2. What I should produce

1. Reference pack curation + **art-direction extraction** (style grammar with citations).
2. Spec writing, ambiguity register, stage gates.
3. **Silhouette / readability measurement** — black fill on both state washes, bounding
   box, opaque-pixel growth ratios, distinctness from negatives.
4. **Palette enforcement** — `palette_remap`, colour counting, contrast-ratio tables,
   budget assertions.
5. **Pixel QA** — `quality_audit` (AA, orphan pixels, grid), `asset_report`
   (dimensions, alpha, colour count).
6. **Post-processing** — nearest-neighbour scaling, `sprite_mirror` (5→8 directions),
   `atlas_pack` + JSON, `gif_export`, chroma-key removal.
7. **Hand-anchor and weapon-modularity verification** (overlay QA images).
8. **Animation** — cadence, holds, frame timing per §5.6/5.7, converting measured blend
   rates into frame-hold counts.
9. **Godot integration** — NEAREST import, SpriteFrames, AnimationPlayer tracks +
   `validate`, whole-pixel draw snapping, no runtime rotation.
10. **Runtime capture and visual QA** — `editor_screenshot` at 1:1, gameplay-scale review,
    the 7 suites / 129 assertions, compare-pair play sessions.
11. **Delusion Echo rendering** — from the *existing* contact frame; zero new frames.

### 3. Information that must accompany the sprites

A machine-readable manifest per batch:

```json
{ "cell": [64,64], "ground_row": 62, "facing": "right",
  "anchor_map": "texture_col = game_x + 32, texture_row = game_y + 62",
  "hand_anchor": [48,32], "hold_offset": [16,-30], "hold_rot_deg": -38,
  "palette_file": "design/CHARACTER_PALETTE.md", "max_colors_per_sprite": 12,
  "alpha_policy": "binary: 0 or 255, no partial alpha",
  "aa_policy": "none", "outline": "1px ink, characters only",
  "light_source": "top-right", "weapon_baked": false,
  "frames": ["neutral","run_00", "..."],
  "provenance": { "model": "...", "reference_pack": "refs/character/v1", "seed": "..." },
  "identity_lock": "same character as approved neutral; bible: <path>" }
```

### 4. How weapons must be separated from body sprites

- **Body sprite = body only.** No weapon pixels in any body frame, ever. Reject on sight.
- **Weapon = its own layer** (already the architecture: `prop.gd` owns Reality/Hero),
  cells **96×64**.
- Body frames may *pose the arm* toward the anchor but must not draw the object.
- The **armed silhouette difference is produced by composition** (body + weapon layer),
  which the master sheet must show as a composed preview while the exported textures
  stay body-only.
- Reality vs hero weapon are two variants of one geometry (tube + coupler + elbow DNA),
  never two unrelated objects.

### 5. How hand anchors must be specified

- A **named anchor per frame** in JSON (`hand_n`, `hand_f`) in texture coordinates.
- The anchor must be a **stable pixel across every frame that holds a weapon** — this is
  what `GRIP_P = (48,32)` was reaching for; formalise it rather than hard-coding one point
  into every pose function.
- Ship a **crosshair overlay QA image** per frame so a human can see the anchor.
- Ship the transform (`texture = game + (32, 62)`) so the runtime can verify it.
- **Test:** swap ≥2 weapon classes across the same 3 poses with zero body edits.

### 6. How many body animation archetypes should support many weapons

**Five body archetypes, all weapons:**

| # | archetype | covers | frames (from art plan) |
|---|---|---|---|
| 1 | **Locomotion** | idle, run, skid, jump/fall/land | 4 + 6 + 3 + 4 |
| 2 | **Dash** | dash entry/hold/exit | 3 |
| 3 | **Attack arc** | coil → commit → contact → overshoot → recovery → neutral | 6 (+5 dash→attack) |
| 4 | **Hit / reaction** | hurt, recoil, blink arrival | 3 + 3 |
| 5 | **Reach** | pickup / transform reach & settle | 3 |

**~19 body frames serve every weapon.** Weapons vary only in the **prop layer** (its own
swing orientations, ~5 authored angles) and in *which anchor it attaches to*. If a new
weapon requires new body frames, the modularity contract has failed — except where the
weapon's *weight class* genuinely changes body language, which must be declared as a new
body archetype, not silently redrawn.

### 7. What must NEVER be baked permanently into character sprites

| never bake | why |
|---|---|
| **the weapon** | kills modularity; already violated once via `GRIP_P` pinning |
| **state tints / colours** (cyan, white, orange, red) | state is a layer, not a pixel |
| **FX** — glow, slash, particles, trails, flash | project refuse-list |
| **background / floor / shadow** | sprite must sit on any background |
| **partial alpha or anti-aliasing** | breaks palette and nearest-neighbour scaling |
| **direction** | author right, mirror for left (`sprite_mirror`) |
| **specific enemy / HUD / text** | belongs to other systems |
| **camera effects** (shake, zoom) | runtime only |
| **echo copies** | rendered from the existing frame at runtime |
| **hue-shifted "hero state"** | hero = contrast push on the *same* pixels |

---

# Recommendation

1. **Do not draw anything yet.** Build `refs\character\` first — sections **B** and **C**
   are images, and today both are effectively empty (1 file, reclassified as layout-only).
   That is the single highest-leverage action available and it costs nothing but your
   time.

2. **Register the four useful skills** (`pixel-art`, `game-visuals`,
   `create-game-assets`, `art-consistency`). 405 skills exist and **0 are loaded** — the
   capability is on disk and inert. This is configuration, not installation.

3. **Add an image-generation route** — the one genuinely missing capability. Prefer
   `.system/imagegen` (already present; needs `OPENAI_API_KEY`). State its requirements
   explicitly: reference conditioning, native 64×64 output control, cross-pose identity
   consistency, transparent/chroma background.

4. **Adopt the 13-stage workflow** with human gates at stages 0, 3, 4, 5, 6, 7, 8 and 12.
   The previous process failed primarily because it generated eight sheets in one
   `main()` run before a human saw one sprite.

5. **Enforce the split:** external image AI makes static art; I do direction extraction,
   measurement, palette/pixel enforcement, packaging, animation, Godot integration and
   QA. **PIL drawing is demoted to scaffolding and QA — never concept art.**

6. **Add an independent vision-QA opinion** if any route provides one. I currently grade
   my own work, and my self-review catches mechanical defects while missing aesthetic
   ones — which is exactly the failure mode this audit documents.

**Bottom line:** the skills are *substantial but unregistered and unable to draw*; the
MCPs are *strong at integration and capture but incapable of creation*; what is actually
missing is **(1) your reference images** and **(2) an image-generation model** — in that
order.

---

*End of audit. No character art generated, no sprites modified, no animation created,
no gameplay or Godot scene changed, no map/chapter built, no new character concept.*
