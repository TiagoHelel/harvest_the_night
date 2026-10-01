# 0008 water and transition review — 2026-10-01

Completed three water frames, eight cardinal sides and eight corner caps. All
19 outputs are source-owned raster, integrated in the unchanged 256x80 atlas
and the production WorldView. Cardinal masks remain N1/E2/S4/W8, 0-15.

## Sources and measured conversion

Six actual returned ImageGen files produced four accepted masters and two
rejected candidates, each byte-identical to its returned file. Exact prompts,
reference roles, revision chains and SHA-256 values are in `generation/0008-*`
and `0008-generations.json`. Sources are in `assets/art_source/terrain/`.

| Master | Accepted source SHA-256 prefix | Conversion |
|---|---|---|
| water-loop.png | a77b6a3c52605aa0 | 2172x724 opaque RGB strip; three equal 724-square crops, one common scale. |
| edge-n.png | 44914576c7532ade | Full 1254-square RGBA canvas; native band height 2, matching one-pixel endpoints. |
| shore-n.png | 20542d78c3e88ef9 | Full 1254-square RGBA canvas; native band height 3, matching two-pixel endpoints. |
| shore-corner-nw.png | ba3bf79e8c14620c | Measured (14,14,720,720) crop yields a joined three-pixel L on the native canvas. |

All outputs retain 16x16 canvas and (8,16) pivot. Water uses four existing cool
blue palette colors, including the already-defined cloth blue for its subdued
return phase; restricting to three blues erased that distinct source phase.
The shore cap selects the existing leaf_light/wood_light colors to preserve
the straight bank's exact incoming profile. The shared 42-color palette is
unchanged. Native water base coverage is 98.0%, 98.4%, 98.0%; every frame's
opposing and cross-frame borders agree. See `measured-contract.json` for all
19 recipes, raw/native hashes, bounds, alpha ranges and derivation parents.

The initial bank candidate had one left/right endpoint color mismatch; one
targeted revision fixed it in the raw source. The initial bank corner mapped
green/brown to different colors than the bank; one targeted revision plus a
measured crop and explicit existing-color subset preserved the matching shape.
Both rejected raw candidates remain in `terrain/candidates/`. No asset exceeded
one targeted revision. The separate tiny grass-cap call returned no image
(`0008-edge-corner-failed.json`); its completed resolution is an exact bounded
one-pixel cut from the accepted raster fringe, matching its incoming profile.
No seam painting, alpha painting, invented code-drawn cap or external API fallback.

## Integration and scope

Explicit clockwise quarter-turn derivations produce E/S/W sides and NE/SE/SW
caps. The importer validates allowed turns and bounded canvas slices. Eight
caps occupy formerly empty atlas row-zero slots 6-13; existing enum, water,
grass-choice and 16-mask rows retain their positions. All 80 atlas cells match
their source rebuild; 21 individual raster contributions are compared directly.

WorldView adds four view-only corner layers. A cap draws for a qualifying
diagonal terrain contact only when neither adjoining cardinal side already
fills it. Cardinal edge selection is unchanged. Water's three production
frames last 0.55 seconds each; banks and caps are static.

Ownership totals 120 raster / 136 ASCII / zero player-sheet, 256 runtime PNGs.
Against baseline 97eb240, only 12 existing PNGs changed and eight caps were
added. The other 236 runtime PNGs, core/FARM_MAP, terrain enum, walkability,
collision, balance, saves, hash guards, owner sheet, palette and PlayerFrames
metadata are unchanged (`runtime-delta.json`).

## Verification and visual gates

Water showcase: **2201 headless checks**, **2288 real-render checks**, zero
failed. It exhausts 512 cardinal/diagonal/family combinations and boundaries;
captures all 16 masks over soil/path/floor/rock, all shore phases, both families'
16 corner combinations, compound channels/convex/concave joins, timber jetty
and the unchanged farm, under day/dusk/night through Main's actual Relight.
Every fixture compares complete serialized state before and after rendering.

Deterministic phase captures use only a private TileSet copy. The automatic
test restores the original production TileSet and observes three distinct
rendered phases in 3.8 seconds: A/B/C/A/B/C/A/B, with unchanged serialized
state. `implementation/shots/sprites/0008/water/automatic-loop.json` records
actual viewport pixel hashes; six images show two complete cycles.

Fault/rebuild suite: **42 probes pass**, all deliberate corruption restored.
Two rebuilds match exactly and legacy writers preserve all 120 migrated files.
New probes reject missing water sources without ASCII fallback, altered water
or caps, invalid palette subsets/rotations, clipped slices, detached bank pixels
and mismatched corner contact colors. See `fault-probes.json` and its log.

All **50 actual 480x270 Godot captures** were opened at native size and nearest
3x through `captures-00` to `captures-12`; full 3x pages are 2880x1728. These
include 45 water fixtures/automatic-loop frames and five Main scenarios.
`frame-review.json` lists paths/hashes. All accepted source alpha over light,
dark and checker backgrounds, native sides/caps, atlas and three repeated 8x8
water patches were inspected. `before-after{,-3x}.png` compares 0007/0008
noon/dusk/wave; QA sheets do not modify source or runtime pixels.

| Criterion | Result and evidence |
|---|---|
| All 16 cardinal masks | PASS: both source-exact atlas rows and all four land-contact materials / three water phases rendered under three lights. |
| Convex/concave and compound joins | PASS: all diagonal combinations plus channels, elbows, T joins and jetty contacts show matching endpoint profiles and no gaps. |
| Subtle native water motion | PASS: calm base covers at least 98%; small joined ripples move horizontally by at most one pixel and return with subdued color. |
| No popping/swimming banks | PASS: static sides/caps remain in fixed cells across phase captures; source connectivity/rotations and actual automatic playback pass. |
| Clean alpha and source shapes | PASS: transparent sides/caps retain joined silhouettes without detached pixels or halos; water is fully opaque. |
| Readable jetty/materials | PASS: horizontal brown timber is continuous and distinct from blue water in day/dusk/night; thin banks do not obscure the dock. |
| Stable imports and footprints | PASS: atlas size/rows and nearest/no-mipmap imports preserved; full-farm geometry and serialized state remain unchanged. |
| Deterministic ownership | PASS: all outputs, all atlas bytes and 42 fault/rebuild probes match accepted raw sources. |

Full `tools/verify.py`: **31 passed, zero skipped/failed in 211 seconds** with
the user-provided Godot 4.7.1. All 105 scripts, 6609 headless assertions, 980
input cases, performance and Windows/Web exports pass. Sim `1961000123` and
data `407837701` are unchanged; raster verification writes zero outputs.
See `verify.log`. No unresolved water/transition visual blocker remains. Crops,
stations, forest overlaps and broad night bloom remain their later tasks;
this task does not claim that the whole game's art overhaul is finished.
