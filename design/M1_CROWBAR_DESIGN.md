# Crowbar M1 — experimental production design

20 October 2026. One original rigid mesh, one anatomical R-hand grip, three attacks with shared recoil/next preparation and complete stop tails. The candidate is isolated; no production replacement or M2.

| Attack | Proposed contact / active end | Chain decision | Complete stop | Action |
|---|---|---|---|---|
| Quick horizontal swing | .050 / .100 s | .1667 s | .300 s | IVEN_M1_CROWBAR_1 |
| Reverse swing | .0667 / .1333 s | .200 s | .3333 s | IVEN_M1_CROWBAR_2 |
| Hooked driving finish | .100 / .1667 s | End | .400 s | IVEN_M1_CROWBAR_3 |

Timing budgets are Iven proposals, not reference measurements. Stop recovery is inside each Action. Three braced support copies handle blocked advance; no new bones or running-punch variants. Small Godot-owned advance begins with the visible step: 5/2/7 px free, zero braced. Preserve the existing bounded fresh-press chain decision, immediate valid jump/roll, selection suppression and stale-request clearing.

The first swing sweeps across the torso; recoil leaves the crowbar across the body for the reverse. The finisher starts from that reverse follow-through, gathers more visibly and drives the hook forward with stronger hip/chest alignment. No downward enemy-height correction, spin, leap or long overhead commitment.

Weapon visibility is part of the rendered attack state. The same mesh is rigidly attached to the R hand for every frame, visible from the first attack cel through every shared chain pose. During a no-chain stop the hand withdraws near the body and the bar turns out of profile before removal at the final short return. Movement sprites never contain it. An interrupted attack returns immediately to weapon-free movement; there is no independent runtime weapon sprite to linger.

Hit geometry will be projected from the evaluated shaft and hook segments of the displayed cel, using narrow capsules only in active windows. Multiple segments share the existing victim guard/attack instance. Check actual radius and accepted contact against the visible tool; do not keep the old punch circle or invent a long fixed reach. Diagnostic targets retain the intended 60/64 px humanoid dimensions; original enemies remain untouched.

Keep the exact camera/pixel scale and 82×82 cell if the actual weapon bounds fit. Investigate attack-only overscan only if necessary; never shrink the character or refit the camera. Check both actual facing orientations, grip residual, silhouette, interpolated path, complete stops and all cancellation phases before delivery.
