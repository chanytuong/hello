# Protagonist rebuild v3 — checkpoint

**PHASE E = COMPLETE. NEXT = PHASE F — MASTER KEY POSES IN PIXELORAMA.** Execute exactly one phase per turn. Stopped at the Phase E boundary.

## Completed

- **A: skill/support reading.** `skills_read.json` has `count=421`, 421 entries, `read_complete=true`, and `support_read_complete=true`. All 67 selected support files were fully read; their manifest is `support_read.json`. Four optional procedural rig references are absent and unnecessary. The existing `production_rulebook.md` retains the synthesis. Do not repeat these reads.
- **B: project/runtime audit.** `project_runtime_audit.md` records actual engine, viewport, native scale, sprite pivot, frame picker, movement/combat timing, grip and perception sequence, missing visual coverage, and integration constraints. Eight baseline graphical captures are saved. Seven existing suites passed all 122 checks. All 45 source hashes remain unchanged; text snapshots are saved.
- **C: reference sprite/animation audit.** The actual PNG was discovered in refs and matched byte-for-byte by SHA-256 to the supplied Downloads copy. `reference_sprite_audit.md` records identity, alpha/scale limitations, construction, body/flame/motion language, authorship cues, and keep/adapt/reject principles. `reference_animation_audit.md` and `.json` cover all 21 requested criteria for 14 motion/effect groups and 2 static groups. Motion/effect verdicts: 0 PASS, 6 FIX, 8 REPLACE. Static verdicts: 0 PASS, 1 FIX, 1 REPLACE. Total: 16 groups, 0 PASS / 7 FIX / 9 REPLACE. There are 75 motion/effect samples and 10 static samples; these are not verified animation lengths/exposures.

- **D: external research and synthesis.** 24 sources used: eight firsthand game accounts, nine teaching texts, four original motion papers and three original pixel tutorials. All sixteen Phase C groups are mapped to explicit researched remedies; twelve A–L production rules fit the saved controller. Three text-only candidates have fourteen fields and ten scores each. A “Reach, then catch up” = 86/100 and B “Brace, then drive” = 86/100 remain provisional; C “Twist, then unwind” = 80/100 is rejected because readability and feasibility are both 7. No final law or palette was chosen. Sources/read extents, deductions, score gates and preservation are saved.

- **E: final movement law.** Selected B — BRACE, THEN DRIVE after nineteen construction definitions for each candidate,240 state assessments, nine interruption comparisons, six generic tests and twelve analytical construction probes. A is retired for this rebuild; no hybrid. Five invariants and native production constraints are locked. No drawn studies, production raster or runtime tests were performed. Numeric feasibility is not visual approval.

The final sixteen skills were already completed under `agentskill/skills-open-source-main/`: love2d, love2d-fennel, nix, nix-dendritic, nix-packaging, odin-design, odin-gamedev, prd-to-stories, prd-writing, promql, pr-reviewer, python-design, skill-creator, software-design, test-design, test-driven-development. Exact paths and character counts remain in `skills_read.json:last_16`.

## Current project state

No production raster has started. Phase E now locks B — Brace, then drive and the Phase F native geometry/palette-role constraints. No gameplay logic, scenes, existing tests, or project settings changed. No legacy art was deleted or replaced. Changes are confined to audit/research/design/checkpoint artifacts under this directory. Python/Pillow only measured existing PNGs and generated documentary crops, nearest enlargements, alpha diagnostics and a source composite. Phase D additionally decoded existing external artist tutorial GIF frames into documentary PNG views only. No production pixels were drawn.

Pixelorama MCP was live at the end of Phase B, with 103 tools and an untouched unsaved 64 × 64 untitled document. Phases C, D and E did not query, open or edit any Pixelorama canvas. Phase B connectivity remains historical, not reverified. Keep Pixelorama open. The persistent Node REPL previously held a stdio JSON-RPC client to `tools/pixelorama-mcp/mcp-server/dist/index.js`; reconnect that transport only if it has dropped and a later authorized phase needs it. Do not draw anything before Phase F.

Godot editor MCP has no connected session, but the installed Godot 4.7.2 CLI successfully loads and renders the project. The direct graphical probe exited 0; seven headless suites also exited 0. ANGLE fallback and shader-cache directory diagnostics are preserved in `baseline_runtime_raw.json` and are separate from artwork findings. No setup reinstall or global rendering change was performed.

The renderer executable is `C:/Users/Aloha/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe`. Source preservation evidence: `baseline_source_verification.json` (45 checked, zero changed). Legacy PNG metrics: `existing_asset_audit.json` (30 runtime files, all 64 × 64 and alpha 0/255).

## Phase C evidence and uncertainty

Exact audited reference: `E:/neverlookback/refs/Bảng sprite nhân vật đầu lửa pixel art.png`, 1536 × 1024, RGBA, SHA-256 `fe48d42836313d2ec7b8191e943d7b49d85fb00dbd5baee11eb7e1af8980db9d`. Alpha spans 0..253, with 254 levels and no fully opaque pixels. RGB contains a removed presentation backdrop; the alpha mask and #0D0F17 composite were inspected. The reference is inspiration only; no original protagonist, outfit, proportions, poses, flame shapes, layout or frame sequence may be copied. FIX retains principles, not raster/poses.

`reference_inspection/` contains 16 native crops and 16 corresponding 4× nearest enlargements, plus 4 alpha/composite/palette diagnostics. `reference_inspection.py` reproduces them without changing refs or creating game art. `reference_file_metadata.json` stores file identity, transparency, crop coordinates and sample counts. `phase_c_preservation_receipt.json` confirms 45 project sources and 30 legacy runtime PNGs unchanged, and the supplied reference hash unchanged. Existing tests were not rerun; Phase B's baseline evidence remains intact.

Unresolved from the still file: original sprite pixel grid, exact ordering/alternatives, exposures/FPS/holds, loop seams, registered body/head roots, anatomical limb/grip identity, creation provenance, and final runtime-size readability. These uncertainties are recorded and do not make the completed visual audit a production approval. No timed preview or invented playback was created.

## Phase D evidence and uncertainty

- [external_research.md](external_research.md) and [research_sources.json](research_sources.json): 24 primary/testimony/artist sources with actual read extents and transfer exclusions. GDC listings alone and unwatched videos are not counted as motion evidence.
- [research_synthesis.md](research_synthesis.md) and [research_reference_mapping.json](research_reference_mapping.json): actual sixteen-group remedies, low-res/anti-generic craft and twelve testable state rules, plus weapon/Blink constraints.
- [movement_law_candidates.md](movement_law_candidates.md) and [movement_law_candidates.json](movement_law_candidates.json): three text-only directions, complete descriptions, ten-axis scores and mandatory gate rejection. Scores are provisional judgments, not raster QA.
- [research_source_views/](research_source_views/): three unchanged source GIFs, nine documentary PNG snapshots and an inspection manifest. These are not protagonist assets; no source sprites may enter production.
- [phase_d_preservation_receipt.json](phase_d_preservation_receipt.json): 45 project sources, 30 legacy PNGs and supplied reference unchanged; document coverage and score checks passed. No runtime tests rerun, Godot actions or Pixelorama actions in D.

Still unresolved: final law, numeric body construction/palette/gutters, native-scale master proof, stressed-civilian performance validation, run hold foot-slide measurement, mirror grip anchors, hurt direction availability, moving/airborne death and interrupted-smear behavior. Reference grid, timing, ordering, seams and provenance remain unknown. Research does not resolve those missing source facts.

## Phase E decision and evidence

**Selected law: BRACE, THEN DRIVE.** The support leg drives the pelvis while the ribcage stays enclosed beneath the neckward right shoulder, opens briefly for the action, and returns over support before the arms and attached flame settle.

A loses because its defining support catch can be absent when recovery/arrival is cut, leaving a stock lunge; broader head/body excursions reduce grip/flame margins. Both candidates fit analytic frame budgets, and Phase D text scores tied, so those scores did not decide the result. B still requires visible release/reclosure rather than a permanent hunch. No hybrid or final raster approval.

- [final_movement_law.md](final_movement_law.md): one sentence, eight A–H motion laws and five invariants.
- [phase_e_decision_matrix.md](phase_e_decision_matrix.md) and [phase_e_structural_checks.json](phase_e_structural_checks.json): both candidates precisely defined, twelve-state/ten-question checks each, nine true cancel/interrupt contracts, silhouette-family targets, generic tests and analytic joint/occupancy/mirror probes.
- [phase_f_constraints.md](phase_f_constraints.md) and [phase_f_constraints.json](phase_f_constraints.json):64×64 canvas, pivot(32,62), sole row62, full neutral actor56±1 px including head, physical BODY45±1 px, live BODY≤46 px, collapse≤58 px, native layers/anchors and15-color union budget with exact roles.
- [phase_e_preservation_receipt.json](phase_e_preservation_receipt.json): five required evidence documents fully reread,45 sources/30 legacy PNGs/reference and19 prior Phase D artifacts unchanged; completeness/schema and structural checks passed. No Pixelorama, Godot or Python/Pillow action in E.

Right is the anatomical grip/striker in every facing; do not silently swap it under mirroring. BODY/FLAME stay registered; weapon hilt metadata is separate. The analytical coordinates are not a procedural production character.

Clarified saved prop behavior: free pickup is blocked during fight freeze; HELD transformation/lift progresses on its own process path; swing start resolves pre-snap transformation to285 ms. Preserve clocks/exceptions. Player pose and anchor lookup hold during skipped visual updates; progressing prop lift may create a visual grip problem to inspect later.

E resolves the law, dimensions and palette-role budget that were open in D. Still unresolved: actual1×/BODY-only silhouette identity, real anatomical/cluster correction, healthy-civilian tension interpretation, full alternating locomotion, foot sliding, visible strike gap, grip/occlusion across all states, independent lift during freeze, same-phase hurt and moving/airborne collapse. Reference source grid/timing/provenance remain unknown.

## Next turn: Phase F only

Create the master key poses in Pixelorama MCP under the locked law/constraints and the applicable original/current Phase F master list. Verify the existing connection when drawing is needed; reconnect transport only if it has genuinely dropped. Do not redo setup or read all skills.

Use native manually authored raster, separate BODY/FLAME/WEAPON and explicit actual hand/neck/support metadata. Prove body-only and full-composite identity at1×; do not accept coordinate fit as visual evidence. No PIL/Python drawing, procedural geometry, generated/downsampled base, rigid cutout puppeting, auto shading, interpolated frames or gameplay edits.

Phases F through I remain pending: masters, full production animations with at least two real pixel correction passes, visual-only Godot integration and runtime capture/QA. End F by saving useful artifacts/checkpoint and STOP before G. Preserve all legacy assets and all existing gameplay/input/physics/Blink/weapon contracts.
