# CHARACTER PALETTE — NEVERLOOKBACK

**Phase 3 of the first real character art test.**
Authority: this file operationalises `CHARACTER_VISUAL_IDENTITY.md` §3 ("approximate
swatches; final swatches chosen with the first sprite"). It does **not** overwrite the
identity doc — where the two differ, the delta is stated in §9 with reasons.

---

## 1. The semantic rule (unchanged, restated)

- **Reality = dark, desaturated, slightly warm-neutral.** The ordinary person is a dark
  mass in a grey world.
- **Delusion = bone-white only.** One accent hue, no second "power" colour, no hue shift
  on state change — hero state is a contrast push, not a new colour.
- **Enemies = saturated mid-value.** Their colour lives on their own channel and never
  appears on the protagonist.
- **World = cyan / amber / hazard red.** Belongs to the arena, never to an actor.

---

## 2. Master palette — 18 colours total (budget ≤ 24)

Luma = gamma-space luma `0.299R + 0.587G + 0.114B` (0–255), the pixel-art convention
referenced by the skill's 3:1 contrast rule.

| # | Swatch | Hex | Channel | Role | Luma |
|---|--------|-----|---------|------|------|
| 1 | ink | `#12131A` | protagonist | 1 px outline of every body part; silhouette edge | 19.6 |
| 2 | coat dark | `#232835` | protagonist | jacket shadow step (bottom-left) | 40.0 |
| 3 | coat base | `#2E3547` | protagonist | jacket base — the dominant value of the character | 53.0 |
| 4 | coat light | `#465064` | protagonist | jacket light step (top-right rim) **and** the dull reality seam stitch | 79.3 |
| 5 | trousers dark | `#1A1E29` | protagonist | leg shadow step | 30.1 |
| 6 | trousers base | `#262C3A` | protagonist | leg base (one step darker than the coat — locked rule) | 43.8 |
| 7 | trousers light | `#343B4B` | protagonist | leg light step (top-right) | 58.7 |
| 8 | hair dark | `#1D2030` | protagonist | hair mass base (near-ink, slightly blue) | 33.0 |
| 9 | hair light | `#313649` | protagonist | hair top/back rim — the head's separation against dark sky | 54.7 |
| 10 | skin base | `#C2977A` | protagonist | face + hands (ashen warm, deliberately not rosy) | 160.5 |
| 11 | skin dark | `#6A4E3E` | protagonist | face/hand shadow step | 84.6 |
| 12 | bone white | `#F4F6FA` | perception | hero eye slit, armed seam, Delusion Echoes — **the only accent** | 245.9 |
| 13 | pipe grey | `#999EA8` | world-object | reality object (matches prop `Color(0.6,0.62,0.66)`) | 157.6 |
| 14 | blade white | `#FAFDFF` | world-object | hero weapon body (matches prop `Color(0.98,0.99,1.0)`) | 252.3 |
| 15 | grip dark | `#332E29` | world-object | weapon grip (matches prop `Color(0.2,0.18,0.16)`) | 46.9 |
| 16 | guard | `#423A35` | world-object | weapon guard (matches prop `Color(0.26,0.23,0.21)`) | 59.7 |
| 17 | enemy red | `#E64D73` | enemy (existing) | melee chaser body — reference only, not authored here | 127.1 |
| 18 | enemy purple | `#A666F2` | enemy (existing) | ranged body — reference only, not authored here | 137.1 |

Reserve slots (not used by this test, may be claimed by later art): 6.
World colors recorded for contrast testing only, never drawn on actors:
floor/walls `#4C5261` (81.9), platform cyan `#73CCE6` (180.3), blockers amber `#E68C4D`
(159.8), hazard `#FF3340`, clear color `#0D0F17` (15.3).

---

## 3. Protagonist sprite budget — ≤ 12 colours at once

**Neutral / reality state — 11 colours:**
ink, coat dark, coat base, coat light, trousers dark, trousers base, trousers light,
hair dark, hair light, skin base, skin dark.

**Armed / perception state — 12 colours:** the 11 above **+ bone white**
(eye slit 1 px, seam re-coloured, nothing else).

Rules that keep the count honest:

- The bone-white channel is **additive and exclusive**: it appears only in perception
  states and never replaces a reality colour except the seam stitch (brighten, not add).
- Hands reuse the two skin colours — no separate glove/hand tones.
- Shoes reuse `ink` + `trousers dark` — no ninth clothing tone.
- The weapon (pipe / blade / grip / guard) is a **separate sprite layer** owned by
  `prop.gd`; its four colours are counted in the master palette (§2) but are never
  present inside the body cell.

---

## 4. Colour roles

- **Outline (`ink`)** — 1 px, characters and weapons only, never background. It is the
  separation organ against every bright background (floor, cyan, amber). Darkest colour
  on any actor; **not** pure black (skill rule: outline darker than the darkest fill but
  off-black), slightly blue-shifted to sit in the same hue family as the coat.
- **Skin** — face and hands only, the only warm-neutral value in the upper half of the
  sprite. It is what the eye finds first at a glance (read-order §5).
- **Hair** — two steps, near-ink. `hair light` is functionally required: it is the rim
  that keeps the head readable against the near-black clear color.
- **Clothing** — coat 3 steps (largest area → full ramp), trousers 3 steps (legs are the
  star → full ramp). Both dark and desaturated; the coat sits one step above the
  trousers, per the locked rule "trousers one step darker than jacket".
- **Seam** — reality = `coat light` as a dull 1 px stitch (1.5:1 against the coat, a
  deliberately quiet detail); hero state = bone white (7.4:1 against hair, a loud leak).
- **Bone white** — perception only: eye slit, armed seam, echo copies. Brightness, never
  emission: flat fill, no glow pass, no gradient, no second white.

---

## 5. Value hierarchy and read order

Bright → dark (gamma luma):

`blade 253 → bone 246 → skin 160 / pipe 158 → skin dark 85 → coat light 79 →
guard 60 → trousers light 59 / hair light 55 → coat base 53 → grip 47 →
trousers base 44 → coat dark 40 → hair dark 33 → trousers dark 30 →
ink 19.6 → clear 15.3`

\* skin dark sits between the clothing steps by design — the shadow side of the face
falls toward the coat's value, which is what makes the head read as lit from one side.

**Intended read order at gameplay distance:** player silhouette (outline vs background)
→ face (warm pop) → weapon/blade line (brightest) → enemies (saturated) → world.

---

## 6. Measured separation vs backgrounds

Method: gamma luma ratio `brighter / darker`, both from §2. The skill's
"≥ 3:1 between adjacent colours that need to be distinguishable" is applied at **zone
boundaries**; internal cel steps are addressed in §7.

| Boundary | Ratio | Verdict |
|---|---|---|
| coat base vs clear color `#0D0F17` (jump/air play — the common case) | 3.5 : 1 | pass |
| coat light rim vs clear color | 5.2 : 1 | pass |
| trousers base vs clear color | 2.9 : 1 | ≈ pass (outline invisible here, see §9) |
| ink outline vs floor `#4C5261` | 4.2 : 1 | pass |
| ink outline vs platform cyan | 9.2 : 1 | pass |
| ink outline vs blocker amber | 8.2 : 1 | pass |
| whole mass vs cyan (dark on bright) | 3.4 : 1 | pass |
| whole mass vs amber | 3.0 : 1 | pass |
| skin base vs coat base (face vs jacket — zone boundary) | 3.0 : 1 | pass |
| bone white vs hair (eye slit location) | 7.4 : 1 | pass |
| bone white vs floor (echo over ground) | 3.0 : 1 | pass |
| skin base vs enemy red | 1.3 : 1 | accepted: different channel + hue, never adjacent on screen by design (echo keeps 10 px clearance from enemy core per `DELUSION_ECHOES`) |

Contrast is checked **before** colour is finalised; if a later sprite fails a boundary
above, the swatch changes — the pose is never "fixed with brightness" (art-plan rule).

---

## 7. Cel system

- **3 steps per material: dark / base / light, light source top-right**, hard edges,
  1 px steps, no gradients, no rim-light pass, no glow.
- **Full 3-step ramps on the two large materials** (coat, trousers) because they carry
  the run/dash pose read.
- **Documented deviation:** skin and hair hold **2 steps** (base + one) instead of 3.
  Reason: the ≤ 12 per-sprite cap is the harder rule, and on a 10 px face / 8 px hair
  mass a third step buys ~1 px of information while costing a slot the legs need.
  The outline supplies the third value at every edge.
- **Internal cel steps are compressed** (coat ≈ 1.3–1.5:1, trousers ≈ 1.3–1.5:1) — a
  direct consequence of the locked "dark, desaturated reality base". The skill's 3:1
  cannot be met inside a near-black mass without abandoning the identity; separation
  *across* the mass is carried by the 1 px ink outline between parts (every part is
  outlined where it overlaps another part), not by fill-to-fill contrast.
- **No dither on any character pixel**; no anti-aliasing anywhere; whole-pixel
  placement only. Alpha exists only on the echo layer (rendered copy, not drawn pixels).

---

## 8. Forbidden overuse

- ❌ Bone white as a whole-sprite fill, outline, glow, trail, or background wash.
- ❌ A second accent hue for "power" — no gold, no red-tinged hero state.
- ❌ Saturated colours (enemy red/purple, cyan, amber, hazard red) on the protagonist.
- ❌ Hue shift on state change (hero = contrast push only).
- ❌ Skin tones on anything but face/hands; skin never used as a clothing step.
- ❌ More than 12 colours on the protagonist at once; more than 18 in the master
  palette without a documented slot claim.
- ❌ 4th cel step, gradient blends, soft shadows, particle glow, dither on characters.
- ❌ Fixing a readability failure by brightening the character (change value
  *relationship* to background, or fix the pose/silhouette instead).

---

## 9. Known weak points and contradictions (documented, not silently fixed)

1. **Outline vs clear color:** the project's clear color is `#0D0F17` (luma 15.3), so the
   `ink` outline (19.6) is only 1.3:1 against the sky — effectively invisible during
   airborne play, which is most of this game. *Accepted with mitigations:* against dark
   sky the separation is carried by the coat base (3.5:1), the coat/hair light rims
   (5.2 / 3.6:1) and the face (10.5:1); the outline does its job against floor, cyan and
   amber. The light steps are therefore **not** optional decoration — if a redraw drops
   them, the head and shoulders detach from the sky.
2. **Trousers base vs clear color is 2.9:1** (just under 3). Legs mostly stand on the
   floor line where the outline (4.2:1) separates them; the weakest instant is a
   fully-airborne dark-leg silhouette against the sky. Flagged for PHASE 11 observation.
3. **Cel-step compression** inside the dark mass — explained in §7; this is a chosen
   deviation, not an oversight.
4. **Weapon trailing direction:** `CHARACTER_VISUAL_IDENTITY.md` §1.6 says the armed
   rest "trails low and behind", but `prop.gd` geometry (`HOLD_OFFSET (16,-30)`,
   `HOLD_ROT -0.66`) puts the grip forward at hip height with the tip up-forward.
   Carried to `MASTER_CHARACTER_SHEET.md` (§ contradictions) — the runtime geometry is
   not changed by this art test.
5. **Graybox state colours retired:** the prototype's `body_vis` cyan / white / orange /
   red state colours are placeholder presentation, not palette entries. Frames replace
   them for run/dash/attack; the hurt flash keeps a temporary tint until a hurt pose
   exists (noted in `ANIMATION_TEST_01.md`).
