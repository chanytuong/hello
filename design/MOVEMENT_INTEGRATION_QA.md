# Movement integration — ready for human playtest

2026-10-18, Asia/Saigon. **Playable Godot prototype; human feel and visual approval pending.**
F5 now opens `labs/motion_swap_lab.tscn` (the active ability's lab — see
`design/MOTION_SWAP_LAB_QA.md`); the movement scene in this document is
`scenes/movement_test.tscn`, which still opens normally with F6. Both use the real
CharacterBody2D player, terrain collision and Godot input, with five visual states.
No new Blender animation, rig edit, enemy or combat feature was created for the
movement work; the ability that ships is **Motion Swap** (Blink is retired and
removed).

## Play and review

Open `E:\neverlookback\project.godot` in Godot 4.7.2 and press **F5**.
Alternatively open `scenes/movement_test.tscn` and press F6.

- A/D or arrows: move. Space/W/Up: jump; release early for the existing jump cut.
- Shift/L: ground roll. R: reset to the runway.
- Run, release to skid, then move again before recovery finishes. Jump during skid.
- Compare a stationary jump with a running jump; hold movement through touchdown.
- Walk off the runway into the gap; jump just after leaving the edge to check coyote time.
- Press jump just before touchdown, then test a fresh press immediately after touchdown.
- Roll from idle with no direction held, then roll while running. Repeat facing left.
- Roll into the left boundary or cross the gap and roll into the right wall.
- Press jump during a roll. Try jump and roll together. Watch the neck through the inverted cels.
- Use the two raised platforms and right ledge to repeat takeoff/fall tests.

Review [actual Godot capture](../artifacts/movement_integration/MOVEMENT_GAMEPLAY.mp4)
(1280×720, 30 FPS, 1,016 frames, 33.87 s),
[native + 4× moving crops](../artifacts/movement_integration/NATIVE_AND_4X_MOTION.gif)
(480 decoded cels, 16 s), and
[state sheet](../artifacts/movement_integration/NATIVE_AND_4X_STATES.png).
Human review should decide responsiveness, roll commitment, RUN cadence versus
travel speed, skid recovery timing and flame follow-through. No manual feel PASS is claimed.

## Audit and implementation

The old launch scene used an eight-frame PixelLab run and legacy attack/dash
drawings. Its controller already had acceleration, reversal, gravity, jump cut,
coyote time and jump buffering. These functions were reused. Its dash granted
i-frames and allowed an air dash, so the new movement mode has a separate ground
roll path; it never calls the old dash/attack routines.

Changed:

- `project.godot`: launch the movement test. Old `scenes/main.tscn` remains available.
- `scripts/player.gd`: opt-in `movement_preview` mode on the existing player;
  shared original run/jump functions, ground roll and test-room reset.
- `scenes/movement_test.tscn`, `scripts/movement_test.gd`: instance the original
  `player.tscn`, add a runway, 90 px gap, three raised surfaces and boundary walls.
- `scripts/iven_movement_visual.gd`: five states, one physics-driven animation clock,
  exact direction-specific cells and frame-specific neck positions.
- `scripts/iven_flame.gd`, `shaders/iven_flame.gdshader`: port the existing V3 spring
  controller and nearest pixel deformation; integrate roll attachment angles.
- `art/iven/movement/`: two PNG atlases, SpriteFrames resource, anchors and asset manifest.
- `maincharacter/.gdignore`, `agentskill/.gdignore`: exclude source/research files
  from runtime import. The initial import otherwise stopped on an unset Blender
  importer path. Existing source files remain in place.
- `tests/test_movement_integration.gd`, `tools/movement/`: reproducible input replay,
  lossless packing, capture assembly and engine validation.

No Git repository is configured. Pre-edit project/controller/player/main scene
copies are in `artifacts/movement_integration/checkpoint/`.

## Asset inventory and timing

All body cells are transparent **82×82**, untrimmed, scale **1 native pixel = 1 Godot unit**,
approximately 60 px body height. Common floor pivot: **(40.499926, 75.579577)**.
The 108 packed tiles match their source RGBA bytes exactly. No resize, recolor,
new facing render or camera reconstruction was performed. Left/right use separate
existing renders. Source metadata retains the exact `RESEARCH_Y75_P00` orthographic
camera matrix and 2.22000003 scale. Runtime imports are lossless, no mipmaps, nearest.

| Visual state | Existing source | Frames / playback | Acceptance status |
|---|---|---|---|
| IDLE | R2 `STANDING.png`, existing skid endpoint | 1 held | **TEMPORARY**, no approved idle loop found |
| RUN | R2 `RUN_01..18`, `RUN_COMPULSIVE_PURSUIT` | 18 / 30 FPS, 0.60 s loop | Approved baseline per developer; drawings/Action unchanged |
| SKID_STOP | `run_skid_stop/frames/*/82/body_0006..0018` | 13 / 30 FPS, 0.433 s | Approved baseline per developer; drawings/Action unchanged |
| JUMP | Latest R2 `AIR.png` | 1 held through ascent/descent | **TEMPORARY**, no human approval recorded |
| DODGE_ROLL | Processed `dodge_roll/body/*/ROLL_01..21` | 21 / 30 FPS, 0.70 s | **TEMPORARY** review candidate; raw FBX not used at runtime |
| Flame | Existing V3, 36×36, 12 authored cels | 60–90 ms authored holds; 0.88 s base loop | **TEMPORARY** review candidate; artwork unchanged |

No FALL/LAND sprites or new Actions were added. Latest jump approval was not
invented. See `art/iven/movement/asset_manifest.json` for individual source paths,
camera metadata and status. Roll FBX licensing remains unverified; resolve source
provenance before commercial release.

## Input priorities and transitions

**Jump > roll > skid.** Jump impulse happens on the accepting physics tick.
Simultaneous fresh jump/roll consumes jump and clears pending roll intent.
Jump cancels roll or skid immediately. Walking off an edge cancels the ground
roll and uses JUMP. Roll is ground-only, commits its facing for 0.70 s, retains
gravity/collision, and resumes current direction input on completion. No held
input means IDLE at the roll endpoint, without a forced RUN flash. The existing
`dash` input action supplies Shift/L; it means roll in this scene.

Release above 200 px/s starts the existing skid clip. Its recovery is visual only:
new movement, jump or roll interrupts it immediately. It does not force sliding
or block input. RUN uses actual achieved ground motion to select the running
state; pushing against a wall becomes idle. State changes reset the clock;
unchanged states advance their frames without restarting playback each tick.

## Physics preserved and roll displacement

Unchanged: run **280**, acceleration **2600**, reverse acceleration **4200**,
friction **3200**, air control **0.7**, jump **−640**, rise gravity **1600**,
fall multiplier **1.8**, coyote **0.10 s**, jump buffer **0.12 s**, cut **0.45**,
60 Hz physics. Existing capsule remains radius **14**, height **44**, offset **(0,−22)**.

New ground roll uses current run speed **280 px/s** for **0.70 s**, existing
**0.80 s** cooldown and **0.12 s** input buffer. Unobstructed measured travel is
**196 px**. Horizontal displacement is applied once through `move_and_slide()`;
the supplied sprites are in place. Wall collision blocks it. An idle roll sets
horizontal velocity to zero at its endpoint; no i-frames or damage immunity
are granted. Legacy dash/combat behavior remains unchanged in old main.tscn.

## Flame attachment and visual inspection

Reused V3 cel drawings, palette, variable holds, spring constants and continuous
clock. Velocity/acceleration drive upper deformation; fixed root rows do not
move. Per-frame neck anchors follow both facing exports. The roll additionally
uses its actual exported neck-to-tip direction. A small angular limit bends the
attachment toward world-up when necessary to keep existing flame pixels above
the support plane; the neck root never shifts to solve contact.

Terrain draws behind Iven so it cannot conceal intersections. In the final
capture, **73,206 sampled rendered flame pixels** on grounded frames include
**0 pixels at/below the floor**. Root rounding error is at most **0.6745 native px**.
Both [right](../artifacts/movement_integration/ROLL_ATTACHMENT_RIGHT.png) and
[left](../artifacts/movement_integration/ROLL_ATTACHMENT_LEFT.png) sheets show
all 21 actual runtime roll drawings. Inspected those, native/4× states and
[decoded motion samples](../artifacts/movement_integration/DECODED_MOTION_CHECK.png).
The flame stays attached through inversion and reforms during locomotion.
The body uses existing head-filtered renders; no 3D head was added.

## Tests and evidence

Godot **4.7.2**, Windows Compatibility renderer via ANGLE / Intel HD Graphics 4600.
Final import, startup smoke and movement replay: **PASS**, no script/resource
errors. Final headless and graphical replays each pass **166 assertions over
2,032 samples / 26 scenarios**. Position/velocity differences are **0.0**, with
identical state/frame choices. The isolated graphical replay received **0 live
keyboard events**. Earlier failed runs and diagnostics are retained separately.

| Requested case, both directions | Final result |
|---|---|
| Idle → run → skid → idle | PASS |
| Run → jump → run | PASS |
| Standing jump | PASS; immediate impulse |
| Walk off ledge | PASS; gravity and airborne visual |
| Run → roll → run | PASS |
| Idle → roll → idle | PASS; no forced run |
| Fast reversal | PASS |
| Jump immediately after landing | PASS; pre-landing buffer also tested |
| Roll into wall | PASS; original capsule blocks |
| Flame in every state | PASS in sampled support/anchor envelope; visual review pending |

Also passed roll/skid jump interruption and simultaneous jump/roll priority.
The suites that guard this work — runtime, identity, arena, feel, strand, weapon —
all pass, plus `test_motion_swap` (the swap contract) and `test_motion_swap_lab`
(the six-zone lab, 95 checks). These are regression checks; no combat feature was
implemented for the movement work. *(The old `killblink` suite was deleted with
Blink.)*

**Known flake in this suite, recorded not hidden:** this replay is frame-exact, and
on this machine repeated runs on unchanged code report 0, 1 or 2 failures, always a
different landing-timing assertion, always 166 assertions / 2032 samples. It is
input/physics frame alignment drifting by one tick under load — not a behaviour
change (see `design/MOTION_SWAP_LAB_QA.md` §9 for the measured runs and the reason
the Motion Swap work cannot be the cause: none of the files in this scene's
dependency set were changed by it).

The skill's PowerShell validator was attempted but aborts on its Git check in
this non-Git checkout. The compatible Python runner performed the engine gates
and saved [final engine receipt](../artifacts/movement_integration/FINAL_ENGINE_RECEIPT.json).
See [graphical assertions](../artifacts/movement_integration/graphical_results.json),
[media/source checks](../artifacts/movement_integration/media_validation.json)
and `graphical_trace.json`. All 118 tracked source assets remain unchanged.
MP4 fully decodes; all 480 GIF cels were decoded. No exported-build, performance
benchmark or hands-on gameplay-feel approval is claimed.

Reproduce engine checks: `python tools/movement/validate.py`. Graphical replay:
run the installed Godot console executable with
`--path E:/neverlookback --resolution 1280x720 --fixed-fps 60 --script res://tests/test_movement_integration.gd -- --capture`.
Then `python tools/movement/make_evidence.py` assembles the actual framebuffers.

## Remaining acceptance limits

- IDLE, jump, roll and V3 flame are visibly labeled temporary; source approval
  and roll-source licensing are unresolved.
- Source costume deformation and the roll's documented subpixel toe scuff are
  retained. No rig/weight repair or pixel cleanup was attempted.
- The standing capsule stays tall during the low roll; crouch clearance is not implemented.
- Skid's 0.433 s visual recovery outlasts the preserved physics braking interval.
  It never holds controls. RUN cadence remains source 30 FPS; speed/stride feel
  needs the human playtest rather than an unrequested art/timing pass.
- Flame ground limiting is verified for this flat/platform test envelope;
  wall/ceiling flame contact and arbitrary sloped terrain are not validated.

**STOP for human playtest and visual review. No combat or additional animation work follows.**
