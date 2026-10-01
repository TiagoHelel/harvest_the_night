# 0009 — Trees, resources and livestock review

Date: 2026-10-01. Baseline: `9cddbfd` (0008). Scope: complete static prop family
and controlled source-owned variations. Tree sway and animal animation are
optional in the task and were not added. Enemy production remains 0015/0016.

## Sources, recipes and runtime scope

Ten built-in ImageGen calls produced ten independent raw PNG masters in
`assets/art_source/props/`. Exact BASE + TREE/RESOURCE_PROP/ANIMAL prompts,
returned-file paths, source/reference hashes, geometry and decisions are in
`generation/0009-*.prompt.txt`, individual `0009-*-call.json` files and
`0009-generations.json`. All calls were evaluated before another generation;
zero targeted revisions or rejected generated candidates. No painted outputs,
opaque backgrounds, API fallback or hand-made replacement pixel silhouettes.

The pilot source and `sprites/props/tree.png` remain byte-identical. Ten new
source-owned outputs replace six ASCII placeholders (stump, rock, seam, ore,
cow, chicken) and add four alternatives (tree_b, rock_b, seam_b, ore_b).
Ownership is 130 raster / 130 ASCII / zero player-sheet outputs, 260 native
PNGs total. The other 250 PNGs, every terrain output, original owner sheet,
palette, PlayerFrames, core/map, balance, save schema and sim/data guards are
unchanged. `runtime-delta.json` records exact scope and hashes.

`measured-contract.json` records crops, shared family scales, raw alpha ranges,
native RGBA hashes, silhouettes and pivots. Native canvases/pivots: tree
40x48/(20,44); stump/resources 16x16/(8,14); animals 24x24/(12,22). The new
tree keeps the pilot's exact 42/1135 source scale and has a 36x43 visible
crown versus the pilot's 36x42; the one-pixel contour difference is preserved
without per-variant stretching. Both have the same root contact and warm bark.
Stone seams share 14/1024 reduction; the initial wider candidate had insufficient
margin, so both family recipes were adjusted together before promotion. Initial
candidate sheets are retained and are not final runtime evidence.

Every static alternate uses `variant_of` plus an independent accepted source.
The generic importer enforces the same scale, canvas, pivot and palette as its
direct master. WorldView selects by an integer cell hash, without RNG, time or
state writes. Exhaustive map selection: 547 base / 173 alternate per family
across 720 cells. Harvest and regrowth choose the same shape for the same cell.

## Visual gates actually inspected

Opened all ten returned masters and their parent references before promotion;
inspected final source alpha on light, dark and checker backgrounds in
`source-alpha-0.png` and `source-alpha-1.png`. Inspected all eleven final props
in `native-light`, `native-dark` and `native-checker`, at native and exact 3x
nearest. All native silhouettes are one connected cluster with binary alpha,
transparent margins, unclipped extremities and exact ground contact.

Opened all 53 actual 480x270 Godot captures through `captures-00`–`captures-13`
at native and original nearest-3x (2880x1728) sizes. The capture list and exact
hashes are in `frame-review.json`; originals are under
`implementation/shots/sprites/0009/props/` plus five ordinary Main scenarios.
Opened `before-after.png` and its original 3x view for 0008/0009 noon/dusk/wave.
Contact-sheet composition is deterministic QA only and never changes sources
or runtime art.

| Criterion | Result and evidence |
|---|---|
| Tree identity and stump | PASS. Broad shaded leaf clusters, warmer upper-left highlights, visible branching trunk/roots. Rounder alternate fits the same species and scale. Warm low stump and cut surface match trunk material. |
| Native species | PASS. Cow has a long cream body, dark patches, muzzle/horns and visible legs; hen has compact body, red comb, beak and tail. Cow silhouette 22x13, hen 11x12; visibly different proportions and body area. |
| Resources without labels | PASS. Loose boulders are taller angular groups; stone seams are low layered shelves; iron has connected warm ochre veins against gray rock. All pairs have distinct authored contours. |
| Alpha and clipping | PASS. No boxed backdrop, painted ground tile, detached pixels or clipped roots/limbs. True raw transparency survives deterministic threshold/palette conversion. |
| Foreground/background | PASS. Both canopies cover farmer/walker behind and let them pass visibly in front at four actual positions under day/dusk/night Relight. Four real-render pixel comparisons verify farmer occlusion behind and zero changed farmer pixels in front. |
| Forest density | PASS. Fifteen mixed trees overlap naturally on unchanged one-cell footprints. Front trunks and farmer remain readable; the production farm retains its original map density. |
| Harvest/removal | PASS. Real partial strikes leave anchored props; final strikes preserve exact yields, tree becomes stump, mined resources disappear without stale drawings. Actual regrowth restores trees/seams/ore at original cells; loose boulders stay removed. |
| Livestock collection | PASS. Real tick/collect preserves animals, products and yields, resets readiness and retains the same grounded art under all three lights. |
| Logical/render separation | PASS. Complete serialized state remains unchanged around rendering and decorative selection, with no extra collision cells. Manifest pivots drive depth, separate compact tree shadows remain. |
| Main integration | PASS. Ordinary noon/dusk/wave/result/tech captures retain layout and readable props, including live combat overhang. |

Night greens remain intentionally dark under the current shared shader; isolated
silhouettes and animal/mineral accents remain readable. Broad combat bloom and
the overall night palette are later 0019 work. Crops/stations/defences still
use their scheduled pre-migration art. The existing pilot walker appears in
overlap fixtures; this task does not claim the 0015 enemy animation family.

## Verification and diagnostic repairs

`props-check.log`: 8535 headless fixture assertions, zero failed.
`props-capture.log`: 8643 actual-render assertions, zero failed, 48 native
prop captures. Ordinary Main capture command wrote five more, zero failed.

`fault-probes.json` / `fault-probes.log`: 48 fault/rebuild probes PASS, all
deliberate corruption restored. Added missing livestock source, missing
alternate without fallback, altered ore output, clipped animal, disconnected
animal pixel and alternate scale-drift rejection. The initial failure exposed
a missing generic cross-master scale guard; `variant_of` now enforces that
contract. Initial capture lookup also assumed transient Godot node names;
logical-cell metadata now locates the actual drawn tree reliably. Initial logs
are preserved, final runs pass without weakening their assertions.

Full-project verification (`verify.log`): PASS, 33 passed, zero skipped/failed
in 215s using the user's Godot 4.7.1. Includes 105 parsed scripts, 6609 headless
assertions, 980 input cases, performance and Windows/Web exports. Simulation
hash `1961000123` and data hash `407837701` remain unchanged; deterministic
raster checking writes zero outputs. The original completed game backlog is
untouched. All task criteria pass; no family gate remains pending.
