# 0004 — Authored farmer idle and walking — 2026-10-01

Accepted six ImageGen strips from the unchanged farmer master: idle south,
north and west (three frames each), walk south, north and west (four each).
East uses the runtime west mirror. The production importer owns all 21 PNGs;
no frame is a code-drawn substitute or a copy of the pilot's static master.

## Source and revisions

Ten built-in ImageGen calls produced six accepted strips and four preserved
candidates. South walk r0 repeated the leading boot; r1 alternates it. North
walk r0 put front bib/buttons on the back and kept overly extended passing
legs; r1 uses rear straps without buttons and shorter passing phases. West
walk r0 and r1 did not separate the opposing strides/arms enough; r2 shows the
near arm reaching across the torso and the opposite dark far boot leading.
Each asset stayed within three targeted revisions. Idle strips were accepted
at r0. Candidate sources remain in `assets/art_source/player/candidates/`.

Every raw copy was SHA-256 compared with the tool's actual returned file.
Exact prompts, attempt paths/hashes and decisions are committed in
`generation/0004-generations.json` and the ten `0004-*.prompt.txt` files.
Manifest entries check prompts/references/source hashes. Original masters,
the owner's player sheet and 0001 source prompts remain unchanged.

Actual source images range from 2032–2172 px wide and 724–774 px tall.
`measured-contract.json` freezes real cell/crop/alpha measurements; it does not
assume ImageGen honored the requested equal-cell layout. One scale per strip
reduces the median upright body height to 30 px. Native canvas stays 48x48,
feet (24,44), with no per-frame scale/stretch. Binary alpha and the existing
42-color shared palette are deterministic. `frame-review.json` checks all
21 unique native frames, visible height 30 and bottom contact y=44.

## Inspected gates

All 41 actual Godot PNGs were opened on native and nearest-3x contact pages
`captures-00` through `captures-10`: five real farm shots, 28 first-loop
idle/walk phases in all four facings, four diagonals and four direction turns.
The source results, native-frame contacts and alpha light/dark/checker pages
were also opened. Seven phase pages show committed native frames and mirrored
east; `idle.gif` and `walk.gif` plus 3x versions preserve manifest durations.
QA composition does not repaint any source or runtime pixels.

| Criterion | Result and concrete evidence |
|---|---|
| Farmer identity/materials | PASS — straw hat/band, dark hair, cream sleeves, blue overalls and brown boots remain readable at 480x270. Rear view uses back straps; side views have a clear projecting face. |
| Alpha/outline/palette | PASS — no rectangular backdrop or soft halo on light, dark or checker ground; mapped outline and cloth/skin ramps remain distinct. |
| Three idle frames/direction | PASS — 9 distinct source cuts, subtle blink/breath posture with planted boots; no repeated static master standing in for motion. |
| Four walking phases/direction | PASS — 12 distinct cuts with alternating stride and passing/recovery phases. Native phase pages retain the forward/back arm and boot distinction after reduction. |
| Fixed body/hat scale | PASS — every frame stays 30 px tall with one shared scale per strip. Width 20–22 px reflects direction/stride versus 20 px pilot; the canvas and ground anchor are unchanged. No per-pose refitting. |
| Feet/loop wrap | PASS — contact and sprite offsets stay fixed through two loops per action/facing; returning frame order is 0,1,2[,3],0. West/east extended boots move within the canvas, without translating the body node. |
| Four facings/east mirror | PASS — south, west, north, east rendered; mirrored side has no text, tool or handed object and no canvas-width jump. |
| Stationary/diagonal/turns | PASS — unchanged Player.tick resolves all four diagonal intents and facing; release returns to idle with retained facing. Same view survives east/west/north/south changes without contact drift. |
| Missing frame/metadata | PASS — removal of authored walk_south_2 fails strict check; counts/canvas/pivot corruption fails. Missing count emits an error and clears the body; missing texture clears stale content instead of retaining an idle image. |
| World integration | PASS — noon/dusk/wave/result/tech maintain accepted scale and UI readability. Existing house/tree placement coverage still passes 445 checks. |
| Reproducibility/ownership | PASS — two memory/disk rebuilds agree; legacy writers protect all 36 raster outputs. Registry retains 217 single-owned PNGs (156 ASCII, 25 sheet, 36 raster). |
| Core/save/hash guards | PASS — view-only changes and isolated fixtures; no core, balance, save or expected hash edits. |

## Validation

`verify-full.log`: 26 passed, zero skipped/failed in 174s; 104 parsed scripts,
6511 headless assertions, 980 input cases, performance and Windows/Web exports.
Sim hash 1961000123, data hash 407837701, unchanged. Locomotion fixture:
468 headless checks / 540 real-render checks, zero failures. Farm capture tool:
five written, zero failures. `fault-probes.json`: 21 probes, restored=true.

Known follow-ups: the remaining 25 work/reaction frames retain their accepted
owner-sheet cuts for 0005–0006. Walker authored motion remains 0015. Ground,
buildings, UI and lighting retain their later backlog tasks. These are not
counted as locomotion deliverables or silently replaced with new placeholders.
