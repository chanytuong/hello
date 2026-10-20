# Natural M1 combo — production design

20 October 2026. Three original authored strikes only, on approved darker B. New experimental native file and review scene; previous candidate and active production art remain intact.

| Stage | Contact / active end | Chain decision | Complete stop duration | Body language |
|---|---|---|---|---|
| Straight L | 0.050 / 0.100 s | 0.1667 s | 0.300 s | L lead step, quiet rear support, hip begins and shoulder finishes the horizontal extension |
| Hook R | 0.0667 / 0.1333 s | 0.200 s | 0.3333 s | Bent arm traverses a horizontal arc; opposite coordinated turn; no deep knee dip |
| Forearm L | 0.100 / 0.1667 s | End | 0.400 s | Folded forearm sweeps horizontally with the stronger short step, followed by deliberate arrest and recoil |

These are prototype authoring budgets, not measurements of reference games. Contact remains fast; the additional time is useful no-chain recoil/foot catch. A full chain skips the first two stop tails. Each Action includes its stop tail, avoiding separate recovery Actions. Three stationary-support copies handle obstructed advance, preserving the same upper-body motions.

Godot owns forward displacement. Curves retain the previous measured small travel budgets (5/2/7 px), verified again in gameplay. Leading L foot advances with strike 1, makes a smaller continuation with the hook, then supports the finisher while R steps through. A no-chain exit catches the trailing foot toward the existing idle base; both feet do not slide together. Root translation remains neutral. Static/solid obstacles and nearby solid character bodies predicted to obstruct the combo choose braced support once per combo. This avoids an attack copy continuing its foot advance when collision clips the actor's travel. Per-victim sight checks prevent the edge of a contact circle from damaging through a thin wall.

Input: one fresh press per strike; 0.22 s bounded request, consumed once at the chain decision. This covers a deliberate fast double tap and the short accepted-hit pause. If no live request exists at the decision, commit to the complete stop tail. Later presses can request a new opener only near readiness and expire; they never rewind to a previous chain pose. Defensive interruption clears every request. Existing valid JUMP/ROLL priority remains immediate, including during accepted-hit pauses; no new cooldown bypass or global time freeze. Reversal is permitted after the damaging window.

All three contacts stay near standing upper-body height. Straight/hook follow evaluated hands; forearm follows an evaluated point on the L forearm segment. A small visible debug volume must agree with that position and contact cel. Diagnostic targets use Iven-height standing silhouettes and explicitly drawn chest hurtboxes; ordinary short enemy assets are not enlarged or modified. Their future proportion correction is separate.

Required coverage: complete one/two/three-hit exits from IDLE and RUN in both facings, early/valid/late/expired input, every stage interrupted in preparation/contact/recovery, hitstop, reversal, wall/prop support, accepted damage/duplicate HurtBoxes and 30/60/120 Hz travel. Produce five actual Godot categories and slow copies: one hit, two hits, three hits, responsiveness and target-height alignment. Open native keys, dense final sequences and encoded output samples; tests alone do not establish visual acceptance.
