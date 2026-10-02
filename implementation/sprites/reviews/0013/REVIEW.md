# 0013 - Four tower families at three authored levels

Reviewed on 2026-10-01 using the user's Godot 4.7.1. Four immutable identity
masters and twelve selected 2x2 sheets supply all 48 whole/hurt/fire/wreck
drawings. All 22 built-in ImageGen returns are retained: sixteen accepted
sources and six explicitly rejected candidates. Exact submitted prompt text,
reference hashes, original tool paths and measured cuts are in
`../../generation/0013-*`. No creative source pixels were drawn by code.

## Visual evidence

| Requirement | Observed result |
| --- | --- |
| Different tower functions | PASS: gun has long narrow metal barrel, flame has rounded fuel tank and joined supply pipe, mortar is a low upward tube, crossbow has broad curved wooden limbs/string/rail. Silhouettes and all native states were opened. |
| Authored L1/L3 construction | PASS: timber gun trestle becomes solid stone/iron pedestal with two barrels; upright flame tank becomes broad horizontal copper housing; mortar gains collar/brace/geared carriage; crossbow gains reinforced base and geared feed. These are structural changes, with no repeated pixel bands or colored level pips. |
| Authored states | PASS: damage breaks supports/armor and exposes machinery; firing changes the weapon tip/string; each wreck collapses onto a low debris base. Every independently authored state resolves through the actual WorldView state path. Damage can leave extra fallen parts, so alpha area need not decrease until collapse. |
| Camera, palette, scale and alpha | PASS: warm farm timber/copper and cool stone/iron use the existing project palette. All runtime canvases are 32x48 with pivot (16,44). One source reduction scale is shared by the four poses at each level, rather than refitting their bodies. Source alpha was opened on light/dark/checker, runtime alpha is binary and unclipped. Compact weapon cues avoid shrinking the body to fit a long flame/bolt. |
| Stable contact and previews | PASS: all levels/states stay at the unchanged one-cell base. Four build ghosts use the same authored L1 canvas/pivot and complete one-cell frame. The final capture fixture moves them inside the viewport so the base is fully visible. |
| Muzzle, particles and projectile | PASS: 39 whole/hurt/fire outlets are validated on opaque source pixels; L3 gun has two distinct points. Lighting visits all 13 firing outlets once and the real particle pool emits three sparks at each. Real gun/mortar births stay at the core cell center while their first drawn position is the corresponding source mouth. Offset fades over real flight; mature loaded shots use core positions. |
| Depth and relative scale | PASS: the farmhouse remains largest; compact weapons remain subordinate to roofs. Native/3x mixed and farmer-depth captures were opened. Actual opaque-pixel tests show the L3 gun masking the farmer only behind its ground contact. |
| Destruction and morning | PASS: real Farm.damage produces passable rubble. Session history selects all twelve matching wreck levels; morning clears sprites and remembered levels even without a grid-version change. Rebuilding hides old rubble. Saves store only rubble family, so a newly loaded view honestly uses its L1 wreck. No save field was introduced. |
| Day, dusk, night | PASS: all 48 states render under the three existing material light states. Local firing glows track source mouths, with cool restrained crossbow glow. Actual off/steady comparisons brighten measured weapon pixels. Mixed defenses, farmhouse, farmer and old enemies remain recognizable. Final shared atmosphere tuning remains 0019. |

Opened all 29 actual 480x270 captures at native size and exact nearest 3x:
24 isolated tower scenarios plus the five required noon/dusk/wave/result/tech
views. Review pages are `captures-00..14{,-3x}.png`; originals live under
`implementation/shots/sprites/0013/`. Coverage includes all states/light
conditions, four ghosts, two farmer depth orders, gun/mortar/4x launches,
loaded rubble, all outlets and mixed defenses at night. Also opened native
light/dark/checker state cards, enlarged cards, silhouettes, native coordinate
grids, all four identity masters and all sixteen selected source alpha
comparisons. `frame-review.json` records the final capture hashes.

Six retained rejections document actual failures: gun L1's original/r1 strips
and gun L2 r1 had overlapping alpha bounds that prevented clean state cuts;
gun L2 original repeated the L1 construction too closely; flame L1 and crossbow
L1 original firing cues forced undersized bodies during fixed-scale reduction.
Accepted gun L1/L2 r2 use separated 2x2 framing, gun L2 adds a joined stone base
and heavier receiver, flame L1 r1 uses a tiny jet, and crossbow L1 r1 a tiny
released bolt. No asset exceeded two targeted revisions.

## Verification and preservation

Full verify: 41 passed, zero skipped/failed in 282s; 106 scripts parsed,
6,610 core assertions, 982 input cases, performance and Windows/Web exports
passed. Sim/data guards remain `1961000123` / `407837701`. Raster check proves
232 outputs with zero writes; the remaining 56 ASCII sprites match their maps.
Tower source checker proves all 48 distinct state bytes, common canvas/contact,
39 opaque outlets and complete-family legacy migration. Headless tower showcase
passes 1,290 checks; final actual renderer passes 1,341 checks including
physical occlusion and off/steady glow. Real 4x observed simulation matches its
unobserved core control byte for byte. Launch caches are bounded and pruned;
same-count tower replacement refreshes the particle gun cache.

The pipeline fault/rebuild suite passes all 78 probes, including ten new tower
source/state/muzzle/scale/pivot and incomplete-migration probes, with all
deliberate corruption restored. Results and baseline audit are retained alongside
this review. `scope-and-sources.json` compares baseline `87079a1`: forty old
tower PNGs changed, eight levelled wrecks added, all other 240 runtime PNGs and
all protected baseline core/map/save/player/palette/source files unchanged.
All previous unrelated manifest entries remain exact. Ownership is 232 raster /
56 ASCII / zero player-sheet, 288 runtime PNGs.

Existing headless art assertions were updated to the explicit authored
replacement contract: common canvases/contacts and actual structural changes
replace legacy band-growth height expectations; independent structural wear
and weapon action replace assumptions that every damaged pose removes alpha
pixels or that every firing pose adds a gun flash. All original rule/hash/input
checks remain. Initial pilot ghost and lighting probe failures were corrected
to source-owned placement and order-independent outlet counts, with no core
changes. Normal zombies/animation remain 0015, Giant/death 0016 and UI 0018.
