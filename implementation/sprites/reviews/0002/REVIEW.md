# 0002 production-import review — 2026-10-01

Accepted task-0001 sources are reused; this task made no ImageGen calls and
changed no approved raw image, original reference/owner sheet, core rule or
determinism baseline. Four masters import into eighteen runtime PNGs.

| Gate | Evidence and result |
| --- | --- |
| One owner per output | PASS: registry covers 217 PNGs: 156 ASCII, 43 owner-sheet, 18 raster. Duplicate/missing owners fail. |
| Sources and approvals | PASS: measured crops, shared nearest scale, native pivots, prompt/source/reference hashes are validated. Sources are committed, rebuilds work offline. |
| Deterministic output | PASS: two builds produce identical bytes; two disk builds write zero outputs. Legacy writers preserve all eighteen new files. |
| Strict corruption checks | PASS: missing/changed source, missing/tampered raster output, tampered ASCII/player output, invalid crop/pivot/palette, duplicate output/owner, frame gaps, canvas drift and missing/cyclic derivations are rejected and restored. See fault-probes.json. |
| House derivatives | PASS: nine slices reconstruct every pixel of the full 64x64 house. Offsets keep its logical 3x3 footprint and preserve roof overhang. All slices migrate with the parent. |
| Native silhouettes/alpha | PASS: opened runtime-contact.png and runtime-contact-3x.png; straw hat/clothes, gabled house, foliage/trunk, slouched walker remain recognizable. Binary transparent edges; no checkerboard baked into art. Full house/tree/master forms are unclipped. |
| Day/dusk/night | PASS for import presentation: opened all five captures at 480x270 and nearest 3x. House is coherent with no slice seams; vegetation has material planes and visible trunks; walkers read on night grass. Current lighting remains the existing shader (unification in 0019). |
| Runtime/view metadata | PASS: offsets/canvases/pivots come from generated RasterArt; player and world consume them. Headless coverage checks every player file against the canvas/pivot from its actual owner. Raster walker uses palette/contrast checks, while other enemies retain legacy rim checks. |
| UI regressions | PASS: result and tech screens opened at native/3x; readable payout, controls and tabs, with imported art in the background. |
| Animation status | EXPLICITLY PROVISIONAL: south idle holds one master across three filenames. Walker bob/reach/fall derive from the new raster image via the documented old recipes. Full authored cycles belong to 0004/0015; this importer task does not claim they are finished. |
| Full integration review | 0003: sorting behind/in front of the house/tree, grouping the house anchor, map-edge canopies, shadows/lamps/ghosts, and showcases. Other farmer actions still use the 44px legacy sheet pending 0004–0006, so captures can show a larger west-facing farmer. |

Capture files: implementation/shots/sprites/0002/{noon,dusk,wave,result,tech}.png.
Nearest previews: this folder's {noon,dusk,wave,result,tech}-3x.png.
Production contact sheet: runtime-contact.png, runtime-contact-3x.png.
