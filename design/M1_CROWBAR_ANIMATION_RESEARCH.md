# Crowbar M1 — research before implementation

20 October 2026 · NEVERLOOKBACK. Current brief supersedes the failed unarmed direction; produce three isolated weapon attacks and six gameplay QA categories, then stop before production replacement.

Checkpoint `0bfe20a` preserves the natural unarmed implementation. A fresh 11,574-file baseline protects prior sources and candidate assets. No applicable AGENTS.md was found. Enumerated 14 packages / 447 skills and read the relevant Blender animation/rendering and shared execution/review guidance, combat/animation-system patterns and failure checks, Godot animation/transition guidance, pixel sprite conventions and animation principles. Read the Iven production guides and prior combat reports. The current brief explicitly selects palette B; historical guide approval wording does not supersede it.

## Evidence standard

Observed means decoded images actually opened, including new timestamped contiguous boards. Documentation means a named author's published account. Proposed means Iven construction, not a claim about a reference game's implementation. No controller latency, internal hitboxes or universal cancellation rules are inferred from video rate. Study excerpts remain attributed evidence outside the game build and confer no license to import artwork.

## Supplied Dead Cells clip

Source: developer-supplied `36bf9305-e30d-4e9a-8e22-36fa9bf5c3a6.mp4`, SHA-256 `92241b09d8f5b5ca740b347a8b90a69d46fd058f3799f6912ceceb243fe17985`. Previously fully decoded: 835 frames, 34.462 s video. No original uploader, public URL or exact weapon identity was supplied. [Source receipt](../artifacts/m1_combat_rebuild/research/USER_VIDEO_SOURCE.json). [New board/source-frame index](../artifacts/m1_crowbar/research/USER_BOARD_INDEX.json).

Three overview boards were opened across the whole clip, then selected consecutive ranges received detailed review. This is frame examination, not playing Dead Cells or a claim of watching every frame.

| Source interval | Observed motion | Useful consequence / limit |
|---|---|---|
| 0.000–0.619 s, f0–15 | Clip begins with a bright blade already in hand. Gather lowers the blade, a broad low arc is followed by a raised/extended follow-through, then another gathered shape. Spare arm separates from the striking arm. | Strong pose-to-pose direction changes; the clip cannot establish how the first weapon appearance was triggered. Do not copy its low sword strike into Iven. |
| 0.661–1.277 s, f16–31 | Blade remains visible through ready, lowered preparation, bright sweeping arc, extended follow-through and gathered continuation. Body and arms change together. | Preserve the same rigid weapon and grip across the shared recoil, with no disappearance or neutral reset. VFX obscure parts of the exact path. [Consecutive board](../artifacts/m1_crowbar/research/USER_OPENING_B.png). |
| 1.319–1.938 s, f32–47 | One follow-through returns into a gathered shape and another sweep. Support is compact; there is no extended theatrical recovery between visible actions. | Plan each useful recoil as the next preparation. Without an input trace these do not prove one-/two-button stop rules. [Consecutive board](../artifacts/m1_crowbar/research/USER_OPENING_C.png). |
| 14.944–15.479 s, f362–375, then 15.521–15.562 s, f376–377 | Travel/approach shows no comparable bright extended blade. A large bright blade becomes legible with the raised preparation at f376, followed by further body/weapon change. | A quick pose-level weapon handoff is visually supported in this example. Finger grip and implementation mechanism cannot be resolved. It does not establish every weapon's convention or input delay. [Entry board](../artifacts/m1_crowbar/research/USER_WEAPON_ENTRY.png). |
| 15.644–16.097 s | Contact/victim blood and displayed damage are followed by a different broad weapon direction and another visible reaction. | Align Iven's contact and accepted damage; use the previous recoil to prepare the reverse swing. Do not copy reach or damage values. |
| 19.232–19.356 s, f466–469; 19.397–19.852 s, f470–481 | Extended blade/follow-through is followed by a lowered ready shape without the long bright blade, then low rotating/travelling poses and upright travel. | Weapon removal can coincide with recovery/movement. This visible succession does not prove a cancel, and the low movement is not labelled RUN. [Recovery board](../artifacts/m1_crowbar/research/USER_RECOVERY_A.png). |

The hand/weapon relationship is visible as a rigid extension, but exact finger placement is too small/occluded to trace. Iven's grip will therefore be constructed from its evaluated native hand, then checked in both facings. The video supplies visible recoveries, but **exact stopping after one or two inputs is unresolved**; Iven's one/two/three outcomes will be authored and demonstrated independently.

## Additional actual gameplay and access limits

- **Dead Cells fast melee:** reopened Modesto's [Twin Daggers showcase](https://www.youtube.com/watch?v=zGDEChmcLKI), selected 59.7–60.33 s landmarks from the previously downloaded source. Compact gathered/rising shapes and a broader weapon arc follow a ledge/door event. Effects obscure exact hand ownership. [Frame board](../artifacts/m1_combat_rebuild/research/weapons/twin_daggers_CROPPED_LANDMARKS.png), [source receipt](../artifacts/m1_combat_rebuild/research/weapons/twin_daggers_SOURCE.json). Transfer varied silhouettes and short recovery routes, not dagger anatomy or measured cancels.
- **Crowbar-specific footage searched:** located [Modesto, Crowbar Showcase Season 2](https://www.youtube.com/watch?v=6irbFh3ASFY) and [DocFirebird, Crowbar showcase](https://www.youtube.com/watch?v=w2qyAu9aVEg). Ordinary retrieval returned HTTP 429/sign-in checks for both. No authentication or access restriction was bypassed; **no Crowbar-specific gameplay frame/timestamp is claimed inspected**. [Retrieval receipts](../artifacts/m1_crowbar/research/). An ordinary Steam news API lookup was also unavailable. This is a reference gap, not evidence that all Dead Cells weapons share the supplied sword's visibility or cancel rules.
- **Katana ZERO:** reopened the previously verified Studio 51 door sequence, [Stuf Lane](https://www.youtube.com/watch?v=zAomU01utGU), 26.967–27.25 s. Door strike, later throw and crossing gunfire are separate events; no standard punch/crowbar combo was verified. [Consecutive frames](../artifacts/combat_reference_research/KZ_DOOR_NATIVE.png). Transfer brief causal events and rapid movement return only; tutorial freezes are not hitstop.

## Fresh primary documentation

All four pages below were retrieved online before implementation (HTTP 200); [text hashes/access receipts](../artifacts/m1_crowbar/research/DOCUMENT_SOURCE.json).

- [Thomas Vasseur, Motion Twin, 25 January 2018](https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i-): simple 3D/FBX production, very small renders without antialiasing, convincing timed landmarks before interpolation, and rapid retakes. Use the existing Iven pipeline and judge native semantic poses first.
- Eric Williams [Part 1](https://www.derekdaniels.com/attack-animations-part-1): anticipation, unmistakable connection and follow-through. Give each crowbar strike its own connection silhouette and show the weapon through the useful phases.
- Williams [Part 2](https://www.derekdaniels.com/attack-animations-part-2): explicit timing sections and tested acceleration/deceleration. Separate short contact startup from the optional stop tail; Godot owns the small advance.
- Williams [Part 3](https://www.derekdaniels.com/attack-animations-part-3): reactions/displacement must leave the victim where a follow-up can connect. Validate accepted HP deltas and attack-specific recoil on diagnostic humanoid-height targets.

These are design principles, not Dead Cells input measurements. Do not import God of War exaggeration, long weapon commitment or a new reaction system.

## Original tool design proposal

Opened two real compact pry-bar photographs: the [Stanley Wonder Bar listing](https://mektronics.com.au/products/stanley-wonder-bar-black-300mm-12in) and [Bahco mini pry-bar listing](https://mekomaskinisater.se/products/mini-kofot). They show an uninterrupted practical shaft, bent claw and flat working end; the fork is secondary to the hooked outline. [Images/provenance](../artifacts/m1_crowbar/research/PHYSICAL_REFERENCES.json). They are shape analogues, not calibrated turnarounds or reusable textures.

Propose one original approximately 0.6 m rigid steel bar: simple shaft, short hooked head, restrained three-band dark metal. No branding, yellow paint, inventory or summon sequence. Attach it to the existing anatomical R hand and bake it with the body. First swing crosses forward, second reverses that arc, third drives the hooked end at standing upper-body height. Retain compact support/hip/chest contribution and natural one/two-hit stop continuations. Use weapon-free movement and an attack-only visibility rule; native renders and actual gameplay will determine whether the grip, trajectories and removal read clearly.
