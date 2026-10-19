# Iven flame / body palette study — review candidates

2026-10-19. [Three rendered studies](../artifacts/iven_pixel_optimized_redesign/THREE_BODY_PALETTES.png). **Slate / Linen is the selected benchmark hypothesis, pending human visual approval.** All studies reuse the existing flame; no head recoloring or redesign.

The active [flame atlas](../art/iven/movement/flame_atlas.png) contains twelve36×36 cels and five colors. [Measured counts and HSV](../artifacts/iven_pixel_optimized_redesign/ACTUAL_FLAME_PALETTE.json), [actual atlas enlarged](../artifacts/iven_pixel_optimized_redesign/ACTUAL_FLAME_ATLAS_4X.png).

| Flame color | Atlas pixels | Role |
|---|---:|---|
| #cb3540 | 523 | Main crimson mass |
| #a4263c | 477 | Interior / tongue shadow |
| #792436 | 121 | Neck root and deepest shadow |
| #e45143 | 120 | Restrained hot clusters |
| #ee764c | 18 | Sparse orange emphasis |

The central mass is saturated red with a darker attached root. Tongues and separate rising fragments use irregular hard clusters; there is no continuous black cage around the head. Body colors therefore use quiet cool planes and neutral accents. Broad linen highlights remain local, while the flame owns the strong warm saturation. Readability against dark and medium backgrounds matters more than a numeric palette count.

| Candidate | Coat shadow / mid / light | Trousers shadow / mid / light | Intent and tradeoff |
|---|---|---|---|
| **01 Slate / Linen** | #293b50 / #5c7388 / #96a4ac | #262e3a / #485565 / #70808c | Closest to Iven's blue coat; restrained neutral linen and gloves. Main test. |
| 02 Smoke / Steel | #302f45 / #68677f / #a1a1b4 | #262f3b / #455a68 / #708a93 | Cooler violet cloth against steel; risks making glove/coat families too similar. |
| 03 Dust / Teal | #293e47 / #5d7c81 / #9aafaa | #2b303e / #515e6c / #798a96 | Softer green-blue coat; risks blending into cool environmental colors. |

Each study has separate linen, boot, glove, bracer and belt ramps. [Complete palettes](../artifacts/iven_pixel_optimized_redesign/BODY_PALETTES.json) are authored as Blender material bands, not applied by image quantization. The brightest body bands are limited neutral highlights; no emissive glow, colored rim or new saturated accessory is added. Gloves use a quiet violet-gray to separate them from the blue sleeves without competing with the flame. Warm belt accents are desaturated and small.

The comparison uses identical IDLE, RUN and M1 poses, scale, saved camera, directional light and actual Godot-rendered flame layer. Rendered 3× and native views are provided together. Three palettes are alternatives within one source redesign, not three character models. Final choice, perceived warmth hierarchy and contrast against production backgrounds remain human art decisions; this isolated pass does not replace active game art.
