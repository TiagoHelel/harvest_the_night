# Sprite production journal

Append new entries below. The planning entry does not complete a production task.

## Planning and visual audit — 2026-10-01

Created a separate 20-task production queue following the original game's
one-task-per-invocation model: source-defined prompts, generated index, status
helper, dependency validation, optional PowerShell driver and append-only journal.
Added art direction, raster source ownership/import design and a generation bank
with shared constraints, 24 family/layout/correction briefs and generation record.
All 20 production prompts remain `todo`; no new runtime sprites were generated
or substituted during this planning request.

Reviewed the original 110 completed tasks, the reference sheet, the owner's
character sheet, existing sprite generators/cutter, palette, runtime rendering
and screenshot/test tools. Captured and opened fresh baseline noon, dusk and
wave images at `implementation/shots/sprites/baseline/` using the supplied Godot
4.7.1 console executable. The main visual problems are inconsistent body scale,
simple repeating ground, weak vegetation/building forms, borrowed animations
and night lighting that reads as dim daytime.

Inventory: 217 PNGs under `sprites/`, 171 ASCII-owned and 46 cutter-owned.
Counts: actors 48 (including ASCII placeholder/shadow), buildings 70, crops 14,
enemies 21, props 17, terrain 20, UI 27. `inventory.json` records dimensions,
encoded SHA-256 and decoded RGBA SHA-256 for each file.

Verification: original `python tools/verify.py` returned FAIL with 18 passes,
0 skips, 5 failures in 173 seconds. Godot import/101 script parses, 6417 rules
assertions, 980 input cases, performance and Windows/Web exports passed. Sim
hash `1961000123` and data hash `407837701` were unchanged. The failing groups
were sprites/player art/font/logo/icon. Read-only regeneration in memory found
48/46/2/1/2 encoded PNG mismatches respectively, all with identical decoded RGBA
pixels. No runtime PNGs or original hash baselines were overwritten. The cause
of historical byte encoding drift is unverified; task 0001 includes normalization
and a verified baseline before production completion.

Plan validation: queue/index/dependencies passed; next is 0001. PowerShell driver
dry run selected the correct runner and local Godot without invoking an agent.
Additional QA passed: next-task selection and interrupted-task resume, rejection
of missing dependencies/cycles/premature completion/empty blocker reasons/
duplicate IDs/multiple active tasks, compilation of all four new Python files,
PowerShell parser, and idempotent prompt generation (zero prompts overwritten).
The generation bank contains 26 named sections: BASE, STRIP and 24 briefs.
Original game queue remains 110 done; sprite queue remains 20 todo.

Scope decision: the user's request for new sprites permits a raster source
pipeline for this new backlog instead of keeping the old ASCII-only art rule.
Preserve accepted generated source images and deterministic cuts so source
ownership checks remain meaningful; untouched assets keep their legacy checks.
The proposed 16 px grid/480x270 viewport remain fixed, while visible actor and
object proportions are validated in a small pilot before mass production.

## 0001 — Direction, scale and identity masters — done 2026-10-01

Generated six accepted raster sources with the built-in ImageGen tool: farmer,
farmhouse, full-canopy tree, walker zombie, a neutral-day style scene and its
lighting-only night study. Sources are saved at `assets/art_source/masters/`.
Exact prompts, tool/ref roles and all source/reference/prompt SHA-256 values
are in `generation/0001-*.prompt.txt` and `generation/0001-record.json`.
Each source was accepted on its first generation; no revision calls were needed.
The owner's sheet and reference sheet were preserved.

Scale: farmer visible 20x30 on a 48x48 canvas (pivot 24,44); house 56x55 on
64x64 (32,60); tree 36x42 on 40x48 (20,44); walker 16x29 on 32x40 (16,36).
Widened the proposed tree canvas from 32 to 40 to preserve the broad canopy
without distortion. Crops/pivots/source hashes are recorded in
`assets/art_source/masters/master-contract.json`. Freeze these source scales
pending playable occlusion/interaction validation in 0003; scene-study sizes
are illustrative, not authoritative measurements.

Palette: added three skin and three blue-cloth colors to the original 36-color
shared palette, then regenerated `src/ui/palette_data.gd`. Existing colors and
light ramps are unchanged. Native review uses nearest reduction, explicit
measured crops, fixed pivots, binary alpha and the 42-color palette. The scoped
`reviews/0001/build_preview.py` writes review files only; the production importer
and runtime ownership migration remain tasks 0002/0003.

Resolved the five pre-existing source-output check failures by regenerating 99
PNG files from their unchanged sources. Each changed file was checked for the
same size and identical decoded RGBA pixels before writing. Old/new encoded
hashes and unchanged pixel hashes are in `reviews/0001/normalization.json`.
The original audit snapshots remain intact. Historical encoding cause remains
unverified; no source check was disabled and no determinism baseline accepted.

Visual review: opened all raw masters, alpha/contact views, native-scale grid,
silhouettes, 480x270 day/night studies and 3x native previews. Accepted farmer
identity, shared perspective/materials, full unclipped forms, clean native alpha,
recognizable silhouettes, coherent source proportions and the same farm under
night light. `reviews/0001/REVIEW.md` records each criterion. Future terrain
should be quieter than the scene-study grass; runtime depth sorting, shadows,
light alignment and full animation coverage belong to later tasks.

Verify: baseline normalization PASS (23 checks, 164s); final full verification
after generation/palette extension PASS (23 checks, 0 skips/failures, 166s),
101 scripts parsed, 6417 headless assertions, 980 input cases, both exports and
performance passed. Sim hash `1961000123`, data hash `407837701`, both unchanged.
Full final log: `reviews/0001/verify-full.log`. All six provenance records match;
native-review rebuilding is byte-identical, all new Python sources compile.

Godot captures: `implementation/shots/sprites/0001/{noon,dusk,wave,result,tech}.png`
opened and reviewed, 5 written / 0 failed. Noon/dusk/wave are pixel-identical to
the archived baseline. Task 0001 creates identity/style sources and repairs the
existing byte checks; it does not claim new art is already shown in gameplay.

Queue after completion: 1 done, 19 todo, 0 doing, 0 blocked. Next task is 0002,
the raster source pipeline. This invocation stops after 0001, per the runner.

## 0002 — Raster source ownership and deterministic importer — done 2026-10-01

Added `tools/import_art.py`, `tools/art_ownership.py`, the manifest/schema and
ownership registry under `assets/art_source/`. Every one of the 217 runtime PNGs
has a single writer/checker: 156 ASCII, 43 owner-sheet, 18 raster. Both legacy
generators exclude migrated outputs in their write and check paths. Raster tiles
are routed into the existing atlas builder rather than read from stale ASCII.
Palette synchronization and unmigrated byte checks remain active. Full verify
now includes a strict raster-source/output/metadata check.

Imported the four accepted ImageGen masters from 0001 without new generation or
revisions. Their original SHA-256 values, prompt hashes and reference hashes
remain unchanged and are checked by the importer. Manifest recipes contain
measured crop/cell bounds, common nearest scale, alpha threshold, shared palette,
canvas, ground pivot, timing and output SHA-256. Generated `src/ui/raster_art.gd`
supplies view metadata, consumed by player/world code instead of copied sizes.
Explicit source approval is required when source/reference pixels change; an
offline rebuild updates recipe output hashes, while --check never writes.

Outputs: actors/idle_south_{0,1,2}; buildings/house and all nine house slices;
props/tree; enemies/walker plus walk_b/attack/death. The house partitions retain
all 64x64 pixels (columns 24/16/24, rows 28/16/20); offsets place them over the
unchanged 48x48 footprint. Farmer canvas 48x48/pivot 24,44; tree 40x48/20,44;
walker 32x40/16,36. Original source sheets, core, balance, saves and hash baseline
files were not changed.

Provisional motion is declared in recipes: the south idle is a static master
hold across three filenames pending authored 0004 frames. Walker's existing
procedural bob/reach/fall now derive from its new raster master, pending authored
0015 strips/death playback. This task completes source import, not those later
animation families. Other player facings/work/reactions remain legacy until
0004–0006. 0003 handles shared ground sorting, house grouping, shadows/lamps,
ghosts and deliberate occlusion/map-boundary showcases.

Rebuild/fault QA: `tools/check_art_pipeline.py` passed 19 integration probes:
two memory and two disk builds are byte-identical/zero writes; legacy writers
preserve all 18 migrated files; source changes/missing sources, raster corruption/
missing runtime frame, corruption in both legacy owners, bad crops/pivots/palette,
duplicate owner/output, animation gaps/canvas drift, missing/cyclic derivatives
are rejected. Every deliberate corruption was restored. Nine slices reconstruct
the exact full-house RGBA. Evidence: `reviews/0002/fault-probes.json`.

Verify: fast PASS (23 passed, exports intentionally skipped, 0 failed, 147s);
final full PASS (24 passed, 0 skipped/failed, 165s), 102 scripts parsed,
6510 headless assertions, 980 input cases, performance and Windows/Web exports.
Sim hash `1961000123`, data hash `407837701`, both unchanged. Logs:
`reviews/0002/verify-fast.log`, `reviews/0002/verify-full.log`.

Visual QA: 5 written/0 failed captures in
`implementation/shots/sprites/0002/{noon,dusk,wave,result,tech}.png`, all opened
at 480x270 and nearest 3x. Opened the owner's sheet, style reference, previous
baseline, source-alpha contact, and new 18-output contact at native/3x. House
roof/facade reconstruct without seams, full trees have readable trunks, walkers
remain visible at night, and UI remains readable. Raster colors/alpha pass;
legacy enemies retain their old rim check while raster walker is checked for
shared-palette material contrast. `reviews/0002/REVIEW.md` records passed gates
and specific later-task checks without claiming unfinished integration.

Queue after completion: 2 done, 18 todo, 0 doing, 0 blocked. Next is 0003,
the playable pilot. One task completed in this cycle; the user's active /goal
continues with the next invocation until the entire art backlog is verified.

## 0003 — Playable pilot, ground pivots and depth sorting — done 2026-10-01

Integrated farmer, house, tree and walker through shared `ArtPlacement` and
manifest-generated metadata. Standing node origins use ground contact, textures
offset by their source pivots, and nested Actors participate in the parent's
y-sort. The full house draws once at its existing 3x3 anchor; checked nine-slice
compatibility outputs remain preserved. Other multi-cell fixtures use whole
textures where available. Logical occupant coverage is checked without requiring
one visual node per cell. Tree/walker shadows align with the same contact.

House window/chimney points (32,43)/(49,14) are stored on its native 64x64
source canvas and emitted into `raster_art.gd`. Lighting and particles consume
the same placement recipe; one house emits chimney smoke once. Previews use
the selected family's logical footprint and redraw when the family changes at
the same cell. This fixes the visually discovered house-to-tower case where a
one-cell tower retained the house's cached 3x3 outline.

The playable pilot exposed a 44-to-30 px farmer size jump whenever the accepted
south idle turned or worked. Recuts of all 43 unmigrated owner-sheet frames now
use one 30 px body reference, 48x48 canvas and (24,44) feet, matching the pilot.
The original `docs/sprites_sem_fundo.png` remains unchanged. Authored idle/walk,
work and reaction families remain 0004–0006 deliverables; provisional static
south idle and procedural walker motion are not claimed as authored animation.

No new ImageGen calls, prompts or source revisions were required by this
integration task. Reused `assets/art_source/masters/{farmer,house,tree,walker}.png`
and their original 0001 prompts/reference roles. All raw source, prompt and
reference SHA-256 values remain unchanged and pass strict provenance checks.
Recipes retain 18 raster-owned outputs; the 43 recuts retain owner-sheet
ownership and exact-byte checks. Core/rules, balance, saves and hash baselines
were not modified.

Added deterministic view-only `src/tools/art_showcase.gd` / `tools/show_art.py`:
18 overlap frames swapping farmer/walker across house/tree; house/tower previews;
four map/camera edges; three crop families x four stages; four tower families x
three levels in whole/damaged/firing states; all 46 player frames, four walker
states and both landmarks on native contact/silhouette pages. Fixtures use
isolated state with no simulation ticks, assert that rendering leaves it
unchanged, and do not write player saves/settings. Full verify now includes
445 placement/coverage checks. Real rendering passes 507 checks and saves
31 showcase PNGs; base captures save five PNGs with zero failures.

Visual review: all 36 captures opened on native/nearest-3x pages in
`reviews/0003/captures-00` through `captures-08`, plus individual key overlaps,
frame sheets, boundaries and noon/dusk/wave. Farmer/walker correctly pass behind
and in front of both landmarks; no duplicated house or roof slice seam; ghost
feet/outline align with their unchanged build cells. Source pixels stay intact
at map limits; the fixed viewport naturally clips decorative top/bottom
overhang rather than moving the camera or changing collision. Accepted body
scale/canvases/pivots are frozen in `ART_DIRECTION.md`. Detailed gates and
later-task legacy-art/night-light follow-ups are in `reviews/0003/REVIEW.md`.

Verification: iterative fast PASS (24 passed, 1 intentional export skip,
0 failed, 149s). Final full after the preview-outline correction PASS:
25 passed, 0 skipped/failed, 170s; 104 scripts parsed, 6511 headless assertions,
980 input cases, performance and Windows/Web exports. Sim hash `1961000123`,
data hash `407837701`, both unchanged. Evidence: `reviews/0003/verify-full.log`,
`showcase-check.log`, `showcase-capture.log`, `captures.log` and native/3x pages.
Actual captures: `implementation/shots/sprites/0003/{noon,dusk,wave,result,tech}.png`
and its `showcase/` folder. QA composition uses nearest resizing only, with no
creative edits to runtime images.

Queue after completion: 3 done, 17 todo, 0 doing, 0 blocked. Next is 0004,
authored farmer idle/walk. One task completed this cycle; the user's active
/goal continues automatically toward the remaining art backlog.
