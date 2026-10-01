# Playable pilot review — 2026-10-01

Task 0003 integrates the four accepted task-0001 masters. No new ImageGen
generation or source revision was needed. Original masters, prompt/reference
hashes and the owner's source sheet are preserved. Runtime conversion remains
source-owned: 18 raster outputs and 43 transitional owner-sheet player poses.

Opened the 36 real Godot captures in native and nearest-3x contact pages
`captures-00` through `captures-08`, including a second review of page 03 after
correcting the same-cell house-to-tower preview outline. Individually opened
noon/dusk/wave at 3x and key overlap endpoints, boundaries and frame sheets.
Source/alpha gates remain those recorded in 0001/0002; unchanged raster masters
and exact output bytes pass the strict importer again.

| Criterion | Result and evidence |
|---|---|
| Actual farm consistency | PASS: noon/dusk/wave retain one recognizable farm, a full roof/facade and broad tree canopy. All farmer poses now share the 30 px body reference instead of reverting to 44 px while moving/working. |
| Farmer behind/in front of house and tree | PASS: both subject sets traverse -24 through +24 px in nine increments. Back poses disappear behind the landmark; front poses draw over facade/trunk with feet at the shared ground origin. |
| Walker nested depth sorting | PASS: the same traversal swaps walker/farmer landmarks. Nested Actors participate in Occupants' y-sort; no always-front container or reverse ordering. |
| One full house | PASS: one 64x64 drawing covers nine logical cells, source pivot (32,60), and the full roof has no slice seams. Strict compatibility slices remain checked but are not drawn nine times. |
| Shadow/window/chimney alignment | PASS: tree/walker shadows remain at the ground origin; farmer shadow matches the same contact. House glow and chimney use source-owned native points (32,43)/(49,14), with smoke emitted once per house. |
| Build preview and outline | PASS: house preview covers its existing 3x3 base; tower covers one cell. Changing family at the same cell invalidates the cached outline. Roof/barrel overhang does not enlarge collision. |
| Map/camera bounds | PASS: four extreme anchors retain one complete texture and correct contact, without repeated slices, wrap or changed camera limits. The fixed 480x270 viewport naturally crops roof/facade at its decorative top/bottom border; the source pixels remain intact. |
| Crop/tower states | PASS for showcase coverage: three crops x four stages, alternating dry/wet soil, and four tower families x three levels in whole/damaged/firing states. These are existing legacy families awaiting 0010/0013 artwork. |
| Frames and silhouettes | PASS for pilot scale/coverage: all 46 player frames, four transitional walker states, house and tree appear on two native contact pages and two black-alpha pages. Tools fit their canvas; no new authored motion is claimed here. |
| Source and rules preservation | PASS: strict raster and owner-sheet byte checks, placement assertions, full verifier and original sim/data hash guards. |

Evidence: five base captures in `implementation/shots/sprites/0003/`, 31 fixtures
in its `showcase/` folder, logs beside this review, and native/3x review pages.
`tools/show_art.py --check` passes 445 checks; real capture passes 507 checks.
Full verifier results are recorded in `verify-full.log` and the progress journal.

Follow-ups are already assigned to later tasks: 0004–0006 authored farmer
motion/work/reactions, 0010/0013 crop/tower art, 0012 buildings, 0015 authored
walker/death playback, 0019 quieter ground/night emission tuning. Static south
idle holds and procedural walker poses remain explicitly transitional.
