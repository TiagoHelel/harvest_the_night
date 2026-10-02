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

## 0004 — Authored farmer idle and walking — done 2026-10-01

Generated and integrated six complete strips using built-in ImageGen with the
accepted farmer master: south/north/west idle x3 and walk x4. East mirrors west.
Ten calls total: six accepted strips and four preserved rejected candidates;
south/north walk needed one targeted revision each, west walk two, idle none.
South correction alternates leading boots; north removes front-bib artifacts
and fixes passing legs; west separates opposing arm/boot strides. No API/CLI
fallback or code-drawn sprite generation was used.

Raw sources: `assets/art_source/player/{idle,walk}_{south,north,west}.png`,
candidates in its `candidates/` directory. Exact prompts and recorded returned
files/source SHA-256/decisions: `generation/0004-generations.json` and ten
`0004-*.prompt.txt` files. Every repo source copy matches its actual tool file
byte for byte. Manifest provenance checks source, prompt and reference hashes;
all original 0001 masters, owner sheet and original source prompts are intact.

Measured real source alpha/crops in `reviews/0004/measured-contract.json`;
one common scale per strip, nearest reduction, thresholded alpha and unchanged
shared palette. All 21 native frames are distinct on 48x48 with feet (24,44)
and visible height 30 px. Width 20–22 px allows direction/stride versus the
20 px static pilot. No individual frame stretch or simulation footprint change.
Replaced three provisional south-idle frames and transferred the remaining
18 locomotion outputs from sheet ownership: totals now 36 raster / 25 sheet /
156 ASCII, still 217 exclusively owned PNGs.

The raster importer now singly writes PlayerFrames COUNT/CANVAS/FEET/SECONDS
from merged remaining sheet/raster recipes; the cutter checks that canonical
table but only writes legacy PNGs. PlayerArt reads authored timing metadata;
missing counts report an error rather than becoming idle, and PlayerView
clears a missing texture instead of retaining stale content. All existing
verb bindings and remaining reaction/work paths stay covered.

Extended the isolated Godot art showcase with actual PlayerView playback:
two complete loops per idle/walk/facing, source path/frame order and offsets,
mirrored east, unchanged Player.tick diagonal/facing resolution, release to
idle and turn transitions. Rendering cannot mutate fixture state; no player
save/settings writes. Headless locomotion: 468 checks, zero failed; real-render
locomotion: 540 checks, zero failed, 36 PNGs. Existing placement suite: 445
checks, zero failed. Fault suite: 21 probes passed and restored, including
missing authored walk frame, corrupt player metadata, both deterministic
rebuilds and protection of every raster file from legacy writers.

Full verification PASS: 26 passed, zero skipped/failed in 174s; 104 scripts,
6511 headless assertions, 980 input cases, performance and Windows/Web exports.
Sim hash `1961000123`, data hash `407837701`, both unchanged. Core, balance,
saves and expected hashes were not modified. Logs and fault report are in
`reviews/0004/{verify-full,showcase-check,showcase-capture,captures,fault-probes}.log`
and `fault-probes.json`.

Actual captures: five noon/dusk/wave/result/tech PNGs in
`implementation/shots/sprites/0004/`, plus 36 in `locomotion/`. All 41 opened
at native and nearest 3x on `reviews/0004/captures-00` through `captures-10`.
Native/3x alpha light/dark/checker contacts and all seven four-direction phase
pages inspected: readable identity, alternating stride, no text/tool mirror
issue, steady feet/body/hat and coherent loop wrap. `idle.gif`/`walk.gif` and
3x previews use the actual committed frames and manifest timing. Detailed
criteria PASS and later-task follow-ups are in `reviews/0004/REVIEW.md`.

Queue after completion: 4 done, 16 todo, zero doing/blocked. Next is 0005,
authored farming/gathering/production actions. One task completed this cycle;
the user's active /goal continues automatically toward the remaining backlog.

## 0005 — Authored farming, gathering and production actions — done 2026-10-01

Generated and integrated 13 separate four-frame work strips: chop, mine, till,
plant, water, fish, reel, harvest, carry, craft, trade, collect and repair.
All 52 native frames are distinct. West is authored and east mirrored;
north/south deliberately use side-on work, not claimed four-direction sources.
No verb aliases or one-frame craft placeholders remain. The original farmer
identity master, approved locomotion and owner's sheet remain intact.

Built-in ImageGen made 15 calls: 13 accepted sources and two rejected fishing
candidates retained for provenance. The original rod and first revision did
not fit the common canvas; the second targeted revision shortened the third
pose enough to fit. No action exceeded the three-revision cap. Sources are
`assets/art_source/player/{animation}.png`; rejected fishing attempts are in
`player/candidates/fish-r{0,1}.png`. Exact prompts, tool-returned file paths,
reference paths, decisions and source SHA-256 values are recorded in
`generation/0005-generations.json` and 15 individual call/prompt files. Saved
source copies match the actual tool files. No API/CLI fallback was used.

Frozen measured crops/boot anchors: `reviews/0005/measured-contract.json`.
One common scale per strip gives a 30 px standing recovery body, allowing
natural crouches without per-frame stretching. All outputs use 48x48, feet
(24,44), nearest reduction, alpha threshold 128 and the existing shared
palette. Tools remain inside the canvas without shrinking the farmer or
centering on tool bounds. Manifest provenance and deterministic cuts replace
21 old work PNGs and add 31; totals are now 88 raster / four legacy reaction /
156 ASCII, or 248 exclusively owned runtime PNGs.

PlayerArt binds all twelve core verbs to matching four-frame metadata.
View-only PlayerWork observes unchanged ticks through SimDriver signals:
anticipation while timed work is active, contact at its actual completion,
finite recovery, and shortened phases for existing three-tick repeated repair.
Instant water/reel/trade begin at contact. Nearby actual station delivery can
show carry as a cosmetic cue, without a new verb, crate or inventory rule.
Walking, idle, cancellation, replacement actions and dusk clear stale poses;
repair works at night. Core timers, balance, saves and hash baselines are intact.

Meaningful fixture coverage drives actual Player.tick/Sim.tick and PlayerView:
all frames/facings, complete serialized state unchanged by observers/rendering,
mid-work cancellation for every timed verb, real production delivery, repeated
three-tick repair, and 4x SimDriver equivalence with Sim.advance. Headless work
passes 3749 checks; real rendering passes 3957 with 104 work captures. Fault
suite passes 22 ownership/rebuild probes, including missing repair frame,
byte-identical deterministic rebuilds and protection from legacy writers;
all deliberate corruption is restored.

Full verification PASS: 27 passed, zero skipped/failed in 195 s; 105 scripts,
6609 headless assertions, 980 input cases, performance and Windows/Web exports.
Placement and locomotion remain 476 / 468 checks, zero failed. Raster check:
88 outputs, metadata verified, zero writes. Sim hash `1961000123`, data hash
`407837701`, both unchanged. Logs and fault report are saved in
`reviews/0005/{verify-full,work-check,work-capture,captures,fault-check}.log`
and `fault-probes.json`.

All 109 actual captures (five base plus 104 work) were opened at native and
nearest 3x on `reviews/0005/captures-00` through `captures-27`; final zoom pages
were inspected at original 2880x1728 resolution. Capture files are in
`implementation/shots/sprites/0005/` and its `work/` folder. All 13 raw alpha
pages, 12 native/3x alpha sheets and 16 native/3x west/east phase sheets were
opened: readable gestures/tools, stable identity/feet, clean transparency,
distinct cast/reel and craft/repair, no source clipping. `work-{0,1}.gif` uses
the committed pixels at fixed 90 ms for contact preview, not gameplay timing.

Detailed criteria PASS: `reviews/0005/REVIEW.md`. Existing tree canopies and
the workshop naturally obscure part of tools/hands/crate on the occluded side;
exposed-side captures show complete gestures. Preserve frozen ground sorting
and repeat overlaps in tree/station tasks 0009/0012. Ground noise and night
bloom remain 0007/0019 follow-ups; four legacy reactions belong to 0006.

Queue after completion: 5 done, 15 todo, zero doing/blocked. Next is 0006,
player reactions and ground shadow. One task completed this cycle; the user's
active /goal continues automatically toward the remaining art backlog.

## 0006 — Authored player reactions and contact shadow — done 2026-10-01

Generated and integrated bang, question, note and heart plus the shared ground
shadow. All 77 player pose frames are now raster-owned. Built-in ImageGen made
six actual calls: five accepted sources and one rejected initial bang; one
targeted revision separated its straight stem and dot for native readability.
No asset exceeded the three-revision cap. Raw sources are
`assets/art_source/player/react_{bang,question,note,heart}.png` and `shadow.png`;
the rejected source is preserved in `player/candidates/react_bang-r0.png`.
Exact prompts, actual tool files, reference roles, decisions and source hashes
are in `generation/0006-generations.json` and six individual call/prompt files.
Saved source copies match the returned tool files byte-for-byte. Approved
masters, locomotion/work sources and the owner's sheet were preserved.

Measured crops and boot anchors in `reviews/0006/measured-contract.json` give
30px reaction bodies on 48x48 canvases, feet (24,44), nearest reduction, shared
palette and binary alpha at 128. Actual glyph sizes are bang 3x8, question 5x7,
note 6x8 and heart 6x6. Shadow uses its existing 20x8 canvas with an 18x3 visible
one-color ellipse, one source-proportional uniform reduction, existing opacity
0.42 and placement (0,-1). Raster ownership totals 93 raster / zero legacy
player-sheet / 155 ASCII = 248 runtime PNGs. Zero legacy player writes still
retain strict merged count/canvas/feet checks; shadow is explicitly ground art.

PlayerView draws the existing selected reaction with a source-owned glyph
region and body discard mask. Only the glyph clamps to a two-pixel viewport
margin; body feet, camera, scale and sorting are unchanged. Existing core
selection/priority/45-tick lifetime and idle-only behavior remain. All twelve
work verbs, recovery and walking hide the glyph and reset the mask. Actual
Farming.tick, Fishing.tick, Phases.begin_night and Farm.damage drive crop-ready,
bite, night and destruction captures. Heart uses the available existing kind
without a new automatic trigger. No new player hurt rule was added.

Headless reactions: 690 checks, zero failed. Real rendering: 828 checks, zero
failed with 64 fixture captures. Four real pixel comparisons prove split
body/glyph rendering equals the committed combined PNG; visible/hidden shadow
comparison changes 23 exposed ground pixels with stable boots. Full serialized
state remains unchanged by rendering. Fault suite: 27 fault/rebuild probes,
all intentional corruption restored and deterministic rebuilds byte-identical.

Full verification PASS: 28 passed, zero skipped/failed in 177s; 105 scripts,
6609 headless assertions, 980 input cases, performance and Windows/Web exports.
Placement/locomotion/work remain 476 / 468 / 3749 checks, zero failed. Raster
check: 93 outputs, metadata verified, zero writes. Sim hash `1961000123` and
data hash `407837701`, both unchanged. Logs and detailed criteria PASS are in
`reviews/0006/REVIEW.md` and that folder's verification/fault/capture logs.

All 70 actual Godot captures (64 fixtures plus six Main scenarios) were opened
at native and nearest 3x through `reviews/0006/captures-00` to `captures-17`;
3x pages were inspected at original 2880x1728 resolution. Captures are in
`implementation/shots/sprites/0006/` and `reactions/`. Five final source alpha
pages and all six native/3x alpha sheets were reviewed after the bang revision.
Criteria PASS: consistent identity/feet, clean alpha, distinct symbols under
day/dusk/night lighting, no duplicate glyph/halo/shadow, work unobscured and
complete corner glyphs. Existing body clipping at extreme map boundaries is
unchanged; viewport tests do not claim a new HUD exclusion region. Ground noise,
night bloom and tree/station overlaps remain later-family follow-ups.

Queue after completion: 6 done, 14 todo, zero doing/blocked. Next is 0007,
terrain. One task completed this cycle; the user's active /goal continues
automatically toward the remaining art backlog.

## 0007 — Quiet ground, paths and natural rock terrain — 2026-10-01

Completed the existing eight ground tiles with built-in ImageGen: grass,
grass_b, grass_c, grass_d, soil, path, floor and rock. Clarified the ambiguous
grass wording against the actual generator/view contract: four choices total,
not a fifth invented variant. Raw sources are in `assets/art_source/terrain/`;
twelve actual calls produced eight accepted sources and four rejected originals
preserved in `candidates/`. Each soil/path/floor/rock revision simplified excess
texture or repaired source-authored joins. Exact prompts and call/reference/
returned-file provenance are `generation/0007-*` and `0007-generations.json`.

All accepted sources are 1254-square, alpha 255. Runtime remains 16x16 with
pivot (8,16). Measured 1152-square soil/path crops preserve small joined marks
under nearest reduction; other materials use their complete sources. No painted
seam repair, stretching or palette additions. Source/native SHA-256 values are
in `reviews/0007/measured-contract.json`, the manifest and individual call records.

Moved eight owners to raster and rebuilt the same 256x80 atlas from accepted
source recipes. The atlas builder reuses one validated source build locally per
invocation, with no stale global/runtime cache. All nine migrated atlas cells,
all 80 total cells and every native tile are checked against source rebuilds.
Opposing borders and all mixed grass borders match exactly. Ownership now:
101 raster / 147 ASCII / zero player-sheet, 248 runtime PNGs total. Against
b116b6c only eight tiles plus atlas changed; other 239 PNGs, core, FARM_MAP,
terrain enum, selector, walkability, collision, balance, owner sheet and save
formats are unchanged (`runtime-delta.json`).

Added `--terrain` Godot fixtures using Main's real Relight shader: all materials
and the production weighted grass mix in day/dusk/night with farmer/walker, plus
the unchanged farm. Complete serialized state and every tile/body/feet binding
are checked. Headless: 19609 checks, zero failed; real renderer: 19669 checks,
zero failed, 30 fixture captures. Added source/atlas and material-lighting rows
to verify. Fault/rebuild suite: 33 probes PASS, corruption restored; two builds
identical and legacy writers preserve 101 migrated outputs. New probes cover
terrain source changes/missing files, tile/atlas tampering, seams and alpha holes.

Full verification PASS: 30 passed, zero skipped/failed in 194s, including 105
scripts, 6609 headless assertions, 980 input cases, performance and Windows/Web
exports. Sim `1961000123` and data `407837701` unchanged. Raster rebuild/check:
101 outputs and metadata verified, zero further writes. Logs, hashes and all
criterion results are in `reviews/0007/REVIEW.md` and that folder's evidence.

Opened all eight repeated 8x8 material patches plus mixed grass at native/3x,
accepted source alpha, native-material/atlas sheets, and all 35 actual Godot
captures at native/nearest-3x through `captures-00` to `captures-08`. Original
3x pages are 2880x1728. Captures are under `implementation/shots/sprites/0007/`
and `terrain/`; `before-after{,-3x}.png` compares 0006/0007 noon/dusk/wave.
Visual gates PASS: quieter field, no tile seams/frame, natural sparse rock
instead of brickwork, continuous horizontal dock planks, distinguishable
materials and clear native actors under all three lights. Water/banks/edge art,
station/crop/forest overlaps and broad night bloom remain later-family tasks.

Queue after completion: 7 done, 13 todo, zero doing/blocked. Next is 0008,
water/edges. One sprite task completed this cycle; the active /goal remains
in progress and continues automatically toward the remaining backlog.

## 0008 — Quiet water motion and connected banks/grass edges — 2026-10-01

Completed three water frames, eight static cardinal sides and eight corner
caps with built-in ImageGen sources. Six returned files yielded four accepted
masters and two preserved rejected bank/corner candidates. One revision per
bank/corner corrected native endpoint colors. A separate tiny grass-cap call
returned no image; its recorded resolution cuts the exact one-pixel endpoint
from the accepted fringe. No creative code painting or external API fallback.
Exact prompts, actual returned paths, references and revision decisions are
in `generation/0008-*` / `0008-generations.json`.

Accepted masters in `assets/art_source/terrain/`: water-loop.png (source hash
prefix a77b6a3c52605aa0), edge-n.png (44914576c7532ade), shore-n.png
(20542d78c3e88ef9), shore-corner-nw.png (ba3bf79e8c14620c). Three equal
724-square water crops share one scale; sides reduce full 1254-square sources;
the bank cap uses measured (14,14,720,720). All native canvases/pivots remain
16x16/(8,16). Optional named subsets select the existing palette's cool blues
and matching green/earth contacts. Native water base coverage is 98.0-98.4%;
all three phases are distinct, opaque and have identical calm borders.

Added validated clockwise quarter-turn and bounded slice_canvas derivations.
All 19 raster outputs and every atlas byte match their source rebuilds. Atlas
stays 256x80 with existing rows and N1/E2/S4/W8 masks; eight caps use previously
empty row-zero slots 6-13. WorldView's four corner layers fill only qualifying
exposed diagonal joins, without changing cardinal selection or any map rule.
Banks remain static while three production water phases run at 550 ms each.

Ownership: 120 raster / 136 ASCII / zero player-sheet = 256 runtime PNGs.
Against 97eb240, 12 existing PNGs changed and eight caps were added; the other
236 PNGs, core/FARM_MAP, terrain enum, footprints/walkability/collision, balance,
saves, original owner sheet, palette and PlayerFrames metadata are unchanged.
Complete source/native hashes, recipe geometry and scope are recorded in
`reviews/0008/measured-contract.json` and `runtime-delta.json`.

Water fixtures exhaust 512 cardinal/diagonal/family combinations and map
boundaries with full serialized-state comparisons. Headless: 2201 checks,
zero failed; real renderer: 2288 checks, zero failed. All 16 masks over
soil/path/floor/rock, shore phases, both families' corners, compound joins,
jetty and unchanged farm use Main's day/dusk/night Relight. Frozen phase
captures use a private TileSet; an actual automatic playback check restores
the production TileSet and records A/B/C/A/B/C/A/B over 3.8 seconds, three
unique phases and unchanged state (`water/automatic-loop.json`).

Full verification PASS: 31 passed, zero skipped/failed in 211s using the user's
Godot 4.7.1, including 105 scripts, 6609 headless assertions, 980 input cases,
performance and Windows/Web exports. Sim `1961000123` and data `407837701`
unchanged; raster check writes zero outputs. Fault/rebuild suite: 42 probes
PASS, every deliberate corruption restored. New probes guard palette subsets,
water-source availability, output/cap bytes, rotations, clipped slices, detached
bank pixels and corner profiles. Logs and every visual criterion are in
`reviews/0008/REVIEW.md` and its evidence folder.

Opened all 50 actual 480x270 Godot captures at native/nearest-3x through
`captures-00` to `captures-12`; original 3x pages are 2880x1728. Captures are
under `implementation/shots/sprites/0008/` and `water/`. Also inspected accepted
source alpha on light/dark/checker, native masks/sides/caps, atlas, all three
8x8 repeated water patches and 0007/0008 noon/dusk/wave before-after sheets.
Visual gates PASS: calm subtle water, matching banks, no gaps/popping/swimming
pixels, joined convex/concave/compound contacts, readable timber jetty in all
three lights and stable farm geometry. Crops, stations, forest overlap and broad
night bloom remain scheduled later-family work.

Queue after completion: 8 done, 12 todo, zero doing/blocked. Next is 0009,
trees, rocks, resources and livestock. Exactly one sprite task completed this cycle; the active /goal continues
automatically toward the remaining backlog.

## 2026-10-01 — 0009 Trees, rocks, resources and livestock

Completed the static prop family with ten built-in ImageGen calls, zero targeted
revisions/rejected masters. Immutable accepted sources:
`assets/art_source/props/{tree_b,stump,rock,rock_b,seam,seam_b,ore,ore_b,cow,chicken}.png`.
Exact BASE + TREE/RESOURCE_PROP/ANIMAL prompts, returned files, reference hashes,
raw alpha and decisions are in `generation/0009-*.prompt.txt`, individual call
records and `0009-generations.json`. No painted runtime silhouettes or fallback
generation. Source SHA256 prefixes: tree_b e7b4138f147769e6; stump
04b155a793e485b0; rock d31268fcb2c20f9f; rock_b 1fa07696f592a1ef;
seam 7e92de1560eb2f23; seam_b 5a83f0de1842a9be; ore 732ce8cae8c1641f;
ore_b 06ee39306995017e; cow a22e639050fefdce; chicken fdf30e750796f0d1.
Full source/runtime hashes and measured recipes: `reviews/0009/measured-contract.json`
and `runtime-delta.json`.

Six placeholders migrate to raster ownership; four new independent source-owned
variations share their direct master's scale/canvas/pivot/palette through an
explicit `variant_of` guard. Pilot tree/source and all terrain remain unchanged;
native tree alternative is 36x43 versus original 36x42 at exactly the same
42/1135 scale and (20,44) contact. Stump/resources use 16x16/(8,14), animals
24x24/(12,22). Both seam recipes share the reduced family scale after checking
the wider initial candidate's margin. No per-variant fitting or clipped pixels.
Ownership: 130 raster / 130 ASCII / zero player-sheet, 260 PNGs. Exact scope:
six changed and four added PNGs; other 250 PNGs, original owner sheet, palette,
PlayerFrames, core/FARM_MAP, collisions/footprints, balance, saves and guards
remain unchanged.

WorldView chooses tree/boulder/stone-seam/iron shapes by cell only, consuming no
simulation RNG. All 720 cells select 547 base / 173 alternate per family.
Decorative tree/animal animation was optional and remains static. Actual
Gathering.strike/tick and Livestock.collect fixtures check partial strikes,
exact final yield, tree-to-stump removal, permanent boulder removal, real
regrowth and production readiness/collection. Every redraw compares complete
serialized state. Headless prop fixtures: 8535 checks, zero failed; actual
renderer: 8643 checks, zero failed, including four farmer behind/in-front pixel
comparisons against both tree variants. Shadows remain compact and separate.

Full verify PASS: 33 passed, zero skipped/failed in 215s, Godot 4.7.1 at the
user's supplied path; 105 scripts, 6609 headless assertions, 980 input cases,
performance and Windows/Web exports. Sim `1961000123`, data `407837701`
unchanged; raster source check writes zero files. Fault/rebuild suite: 48 probes
PASS, all deliberate corruption restored. A scale-drift probe exposed a missing
cross-master guard, fixed through `variant_of`; actual-render lookup now uses
logical-cell metadata instead of temporary node names. Initial and final
diagnostic logs are preserved in `reviews/0009/`.

Opened all 53 actual Godot captures at native and original nearest-3x through
`captures-00`–`captures-13`, originals in `implementation/shots/sprites/0009/`
and `props/`. Also inspected all eleven native props on light/dark/checker,
all raw source alpha and 0008/0009 noon/dusk/wave comparisons. Visual gates PASS:
pilot-matching tree species/scale, matching warm stump, label-free distinguishable
mineral silhouettes, recognizable native cow/hen, clean unclipped alpha,
ground contacts, foreground/background occlusion, dense mixed canopy overlap,
harvest/regrowth removal and Main day/dusk/night integration. Complete criteria,
capture hashes and scope: `reviews/0009/REVIEW.md` and `frame-review.json`.
Later crops/buildings/defences, broad night bloom/palette and enemies remain their
scheduled tasks; authored zombie walk/attack/death is 0015 and Giant/death
playback is 0016, as clarified to the user.

Queue after completion: 9 done, 11 todo, zero doing/blocked. Next: 0010,
three crops, four stages and watered soil. Exactly one sprite task completed
this cycle; the active /goal continues automatically toward the remaining backlog.

## 2026-10-01 — 0010 Three crops, four stages and watered soil

Completed all twelve wheat/corn/carrot stages and both tilled-soil materials
with five built-in ImageGen calls, zero targeted revisions/rejected masters.
Accepted immutable sources: `assets/art_source/crops/{wheat,corn,carrot,tilled,tilled_wet}.png`.
Exact BASE + CROP prompts, tool-return paths, references and decisions are in
`generation/0010-*.prompt.txt`, individual call records and `0010-generations.json`.
Source SHA256 prefixes: wheat fe1ecbccbcd3c078; corn 56735130d8c9f10a;
carrot 6d085cca53da6e4f; tilled 059b4694178aa878;
tilled_wet 9eefdaa50a729463d. Full raw/runtime hashes and measured recipes:
`reviews/0010/measured-contract.json` and `runtime-delta.json`.

Each growth family has four measured source cuts sharing one reduction scale,
not independent frame fitting. Unequal source spacing is handled by measured
transparent gutters. Wheat/carrot use 16x16/(8,14), corn 16x24/(8,22) in every
stage, soils 16x16/(8,16). Native heights progress 2/4/8/12 for wheat,
2/4/11/20 for corn and 2/4/6/9 for carrot. The four-pixel mature corn overhang
preserves side margins and the existing walkable ground layer beneath actors.
WorldView now reads the separate crop/soil pivots through ArtPlacement and
keeps logical-cell metadata for real rendering checks. All names are preserved.

The initial four-color soil conversion failed the unchanged native moisture
contrast guard (16.97 average RGB difference). Adding the existing ink shadow
to both identical material subsets preserved the raw wet channels, giving a
28.40-point difference and passing the 20-point requirement. No further
generation was called. The byte-exact
duplicate `crops/candidates/tilled_wet-r0.png` and
`reviews/0010/initial-soil-conversion.json` preserve this conversion evidence.
No palette-table, source painting or runtime painting changes were needed.

Exactly fourteen existing crop PNGs change; the other 246 PNGs remain identical
to `18b4b3e`. Ownership is 144 raster / 116 ASCII / zero player-sheet, 260 PNGs.
Core/FARM_MAP, collision, footprints, growth rates, yields, balance, saves,
determinism guards, palette, owner's original sheet, PlayerFrames, props and
terrain remain unchanged. Crop sway is not part of these static growth frames.

Actual Farming.stage/tick/_water/_harvest checks preserve source selection,
contacts, walkability, exact can use/harvest yield and serialized state around
every redraw. Headless crop showcase: 6,224 checks, zero failed. Actual renderer:
9,248 checks, zero failed, including twelve mature dry-to-wet pixel comparisons
across dawn/day/dusk/night. Carrot/corn/wheat show 151/113/159 changed actual
viewport pixels per light mode; offline wet exposure is 151..251 native pixels
across all stages. Mature plants remain grounded after watering and harvest.

Full verify PASS: 35 passed, zero skipped/failed in 236s; Godot 4.7.1 at the
user's supplied path. All 105 scripts parse; 6,609 headless assertions,
980 input cases, performance and Windows/Web exports pass. Simulation
`1961000123` and data `407837701` remain unchanged; the 144-output raster source
check writes zero files. Fault/rebuild suite: 53 probes PASS, all deliberate
corruption restored. New probes cover missing mature corn/wet soil, corrupted
corn source and per-stage scale/pivot drift. Logs are saved in `reviews/0010/`.

Opened all 41 actual Godot captures at native size and exact nearest 3x through
`captures-00..10` and split 3x columns, with originals in
`implementation/shots/sprites/0010/` and `crops/`. Also inspected the 3x4
growth matrix over dry/wet soil on light/dark/checker backgrounds, all five raw
source alpha comparisons, 8x8 repeat-material patches and 0009/0010
noon/dusk/wave comparisons. Gates PASS: label-free mature species recognition,
progressive growth, unclipped alpha, anchored tall corn, readable neighboring
beds, visible moisture beneath mature foliage, real watering/harvest/maturity
and four production light states. Details/capture hashes: `reviews/0010/REVIEW.md`
and `frame-review.json`. The full production farm view clips its northern row;
dedicated fixtures show every required plant completely. Shared final lighting
refinement remains 0019, enemies 0015 and Giant/death playback 0016.

Queue after completion: 10 done, 10 todo, zero doing/blocked. Next: 0011,
farmhouse visual landmark. Exactly one sprite task completed this cycle;
the active /goal continues automatically toward the remaining backlog.

## 2026-10-01 - 0011 farmhouse as the visual landmark

Completed the full farmhouse family with two built-in ImageGen edits and zero
targeted revisions: refined whole terracotta/timber house and independently
authored local roof/facade damage. Raw sources are byte-identical tool returns
in `assets/art_source/buildings/house/{whole,hurt}.png`. SHA-256:
`1cec572a66451ea3d326ca012623aee83648bad21eea275b4d6b891fb6ded435` and
`0ddfbbb4ed2f219f5a716417c78cf3d619bbe7b19b38379dcb4e3f36de101017`.
Exact prompts, reference roles, original tool paths, initial/final measurements
and accepted decisions are saved in `generation/0011-*`.

Both states share one measured union crop and source scale, 64x64 canvas,
(32,60) ground pivot and (-8,-12) cell offset. Visible bounds are 56x55,
larger than farmer/props. Damage exposes left-slope rafters and local facade
wear, with 148 changed native roof-region pixels. Common central entrance
contact is stable; the independent hurt tread adds only one right edge pixel.
All eighteen compatibility slices exactly reconstruct both complete drawings;
WorldView still draws one roof over nine unchanged occupied/blocking cells.

House HP is separate from occupants. WorldView now observes the existing 75%
wear threshold and Phases.house_full, refreshing whole/hurt automatically
without a logical occupancy change. Boundary fixtures verify 75/74 out of 100,
105/104 out of researched 140, zero HP and restoration. Five validated glass
lamps and the chimney smoke point use the same source offset in both states.
Lighting draws five local warm pools over Main's night ramp, honoring existing
off/steady/full and flashing controls. The roof ridge is not washed out.

Full verify PASS: 37 passed, zero skipped/failed in 220s with the supplied
Godot 4.7.1. All 105 scripts parse; 6,610 headless assertions, 980 input cases,
performance and Windows/Web exports pass. Simulation `1961000123` and data
`407837701` are unchanged. The 154-output raster check writes zero files.
Fault/rebuild run: 61 PASS with all deliberate corruption restored, plus one
count-preserving out-of-canvas lamp probe PASS (62 combined). Future full
fault runs include all 62 probes. Evidence logs are in `reviews/0011/`.

The first complete run found the previous single broad house-light assertion
and a noisy 34359us path-refresh measurement. The assertion now checks five
physical local panes and their combined warm area; no check, budget or
baseline was disabled. Isolated measurement passed at 4657us; final complete
verify passed at 4546us with night tick 607us. Initial/retry logs are preserved.

Opened all 49 actual Godot captures at native size and exact nearest 3x through
`reviews/0011/captures-00..12` and split 3x columns. Originals are in
`implementation/shots/sprites/0011/` and `house/`. Reviewed both raw alpha
comparisons, native/3x whole/hurt on light/dark/checker backgrounds, relative
grounded scale and emission-point overlay. Dedicated showcase: 1,059 headless
checks and 1,193 actual renderer checks, zero failed. Actual pixel comparisons
confirm whole/hurt farmer/walker depth and five window lights without state
writes. Gates PASS: coherent larger roof, localized damage, recognizable
materials, anchored steps, four production light states, ghosts and existing
camera/map boundary clips. Full review/capture hashes: `reviews/0011/REVIEW.md`
and `frame-review.json`.

Scope audit against `a42b530`: ten existing house PNGs changed, ten hurt house
PNGs added, all other 250 runtime PNGs byte-identical. Core, map, collision,
save formats, palette, guards, original owner sheet/pilot masters, props,
terrain and crops are preserved. Ownership: 154 raster + 116 ASCII outputs.
Final shared lighting remains 0019, normal enemies 0015 and Giant/deaths 0016.

Queue after completion: 11 done, 9 todo, zero doing/blocked. Next: 0012,
other farm buildings. Exactly one sprite task completed this cycle;
the active /goal continues automatically toward the remaining backlog.

## 2026-10-01 - 0012 full farm stations and authored activity

Completed workshop, kitchen, press, generator, shop and well with ten built-in
ImageGen calls and zero targeted image revisions. Six identity masters establish
function/materials; four independent three-state strips own idle/active/hurt
production drawings. Raw files are exact tool returns in
`assets/art_source/buildings/{workshop,kitchen,press,generator,shop,well}/`.
Exact prompts, reference roles, returned paths, measured cuts and revision-zero
acceptance decisions are retained in `generation/0012-*`. All ten raw-source
and prompt SHA-256 values, plus every native output hash, are recorded in
`reviews/0012/scope-and-sources.json`. No creative source pixels were painted.

Four production stations share 48x48/(24,44); shop is 32x40/(16,36), well
24x32/(12,30). Each production strip uses one fixed reduction scale and a
measured lower-base contact, so a moving lever does not shift the ground point.
Fourteen full state/fixture PNGs and sixteen exact idle compatibility quarters
are source-owned. The full press/generator now draw once over the original
2x2 anchor, instead of repeating miniatures. Shop and well retain one cell.
Workshop tools/bench/furnace, kitchen oven/cookware, press screw/lever, low
metal generator, awning counter and stone-rim bucket well remain recognizable.

WorldView caches station sprites and reads existing paid Crafting jobs or
Power fuel every 120ms. Queue-only start/cancel swaps their authored textures
without reallocating occupants or changing core state. Stalled jobs stay idle;
below-75%-HP wear takes priority. This supplies authored working poses, not a
continuous multi-frame mechanical loop. Existing bounded furnace/exhaust
effects read the same activity, including damaged running stations. Measured
light/chimney points stay on opaque source pixels in every applicable pose.
Original craft/repair/trade/water targets, collision and logical cells remain.

Final full verify PASS: 39 passed, zero skipped/failed in 287s with the user's
Godot 4.7.1. All 105 scripts parse; 6,610 rule assertions, 982 input cases,
performance and Windows/Web exports pass. Simulation `1961000123` and data
`407837701` are unchanged. The 184-output raster check writes zero files.
Headless station showcase: 3,804 checks, zero failed. Actual renderer: 3,956
checks, zero failed, including all six farmer/walker depth crossings and three
physical off/steady lamp comparisons in both working and damaged-working
night states. Fault/rebuild suite: 68 PASS with all deliberate corruption
restored, plus one in-memory damaged-exhaust guard probe PASS (69 combined).

An initial full verify passed all 39 checks in 247s. A repeat and an isolated
input run exposed the existing transition helper mixing 720 manual ticks with
automatic wall-clock ticks, yielding different watched/skipped hashes. The
fixture now disables/restores automatic processing only during its comparison,
resets through Main so views share the new dictionary, and asserts exactly
720 ticks in both runs. The original hash assertion remains. Verify now reports
the actual failed assertion alongside the count. No runtime/core rule changed.
Initial, failed, isolated and final logs are preserved in `reviews/0012/`.
Existing I18n relabel diagnostics in the isolated log are recorded for UI task
0018; this task does not modify localization.

Opened all 53 actual Godot captures at native 480x270 and exact nearest 3x via
`reviews/0012/captures-00..13` and split columns. Originals are in
`implementation/shots/sprites/0012/` and `stations/`. Coverage includes all
four light states, idle/active/hurt, two independent workshops, real stalled
queues, six ghosts, twenty-four actor depth crossings, queue-only updates,
damaged running night equipment and five standard game views. Also reviewed
all native state sheets over light/dark/checker, ten raw alpha comparisons,
six identity previews, farmhouse/farmer relative scale and source emission
overlay. Gates PASS: label-free function, shared materials/perspective, clean
alpha, stable contacts, recognizable damage, correct previews/interactions,
natural depth and localized real working light. Full decisions and capture
hashes are in `reviews/0012/REVIEW.md` and `frame-review.json`.

Audit against `b9f0298`: 20 existing runtime PNGs changed, ten new full-state
PNGs added, all other 250 runtime PNGs byte-identical. All 229 protected
baseline files and unrelated manifest entries are preserved, including core,
map/save rules, original owner/pilot and previous accepted sources, palette,
PlayerFrames and hash guards. Ownership is 184 raster / 96 ASCII / zero
player-sheet, 280 PNGs. Zombie masters/motion remain 0015, Giant/death playback
0016, shared final atmosphere 0019.

Queue after completion: 12 done, 8 todo, zero doing/blocked. Next: 0013,
tower families at three authored levels. Exactly one sprite task completed
this cycle; the active /goal continues automatically toward the backlog.

## 2026-10-01 - 0013 completed: four authored tower families / three levels

Generated four immutable identity masters and twelve selected 2x2
whole/hurt/fire/wreck sheets through the built-in ImageGen tool. Six evaluated
candidates remain rejected with explicit reasons; all 22 raw returns, exact
submitted prompts, reference hashes, original returned paths and measured cuts
are saved in `assets/art_source/defences/{gun_tower,flame_tower,mortar,auto_crossbow}`
and `generation/0013-*`. Gun L1/L2 r2 correct overlapping cuts and insufficient
construction change; flame L1 r1 and crossbow L1 r1 shorten oversized firing
cues. No asset exceeded two targeted revisions. Python performed deterministic
measurement/crop/nearest/palette/alpha conversion and review composition only;
no creative source pixels were painted. All exact source/prompt/output SHA-256
values are recorded in `reviews/0013/scope-and-sources.json`.

All 48 runtime states share 32x48 canvas, pivot (16,44) and one-cell offset
(-8,-28). Each level uses one fixed reduction scale across its four poses.
State cuts can share a fully transparent gutter row/column, never opaque
pixels. Gun evolves from timber trestle to reinforced receiver/stone footing
and solid two-barrel pedestal; flame gains geared pipe/base and horizontal
copper housing; mortar gains a heavy collar, brace and geared carriage while
remaining low; crossbow gains a feed mechanism and reinforced pedestal while
retaining curved bow limbs/string. All twelve wrecks collapse onto the ground.
Legacy growth/hole/flash/wreck recipes are skipped only for complete migrated
3x4 families; their old ASCII sources remain available for incomplete families.

Source-owned muzzle metadata supplies 39 opaque whole/hurt/fire outlets and
two distinct L3 gun mouths. WorldView, Lighting and the bounded particle pool
use the authored fire pose; actual light visits all 13 firing outlets once and
launches exactly three sparks per outlet. Main connects read-only launch
observers around every fixed SimDriver tick, including 4x batches. Core shots
retain their original cell-center birth and flight/damage data; only drawing
positions start at the weapon mouth and fade toward real flight. Mature loaded
shots acquire no guessed launch history. Presentation caches prune current
shots, including non-observed completion, and remember only standing/rubble
tower levels. Grid-version particle caches detect same-count replacements.

Damage resolves against unchanged levelled HP; existing firing-over-wear
priority remains. Colored legacy upgrade pips are removed from these complete
authored towers. Real Farm.damage renders the matching remembered wreck in a
bounded ground sprite pool, outside occupancy/collision. Morning cleanup frees
sprites/history even without a grid-version change. Loaded saves store rubble
family alone, so a fresh view uses that family's L1 wreck honestly, with no
new save field. Building on old rubble hides its low drawing. This task adds
authored state/event poses, not continuous recoil animation.

Full verify PASS: 41 passed, zero skipped/failed in 282s with the user's Godot
4.7.1. All 106 scripts parse; 6,610 rule assertions, 982 input cases,
performance and Windows/Web exports pass. Simulation `1961000123` and data
`407837701` are unchanged. Raster rebuild checks 232 outputs and writes zero
files; all 56 remaining ASCII sprites match their original maps. Tower source
checker proves 48 independent state bytes, common canvas/contact, exact cuts,
39 opaque outlets and complete legacy migration. Headless showcase passes
1,290 checks; final actual renderer passes 1,341 checks, including real gun/
mortar births, both L3 gun barrels, physical farmer occlusion, actual off/steady
glow and byte-identical 4x observed/unobserved core runs. Pipeline fault suite:
78 PASS, including ten new tower source/state/outlet/scale/contact/incomplete-
migration probes; all deliberate corruptions restored. Final source check and
zero-write rebuild pass after the isolated fault suite.

Opened all 29 actual native 480x270 captures and exact nearest 3x review pages
`reviews/0013/captures-00..14{,-3x}.png`. Originals are in
`implementation/shots/sprites/0013/` and `towers/`: all 48 states under day,
dusk and night, four one-cell ghosts, farmer behind/front, actual gun/mortar/
4x launch, loaded rubble, all firing outlets, mixed defenses at night and the
five required standard game views. Also reviewed all native/enlarged family
states on light/dark/checker, silhouettes, coordinate grids, four identity
masters and sixteen selected raw-alpha comparisons. Final ghost captures show
the entire preview base inside the viewport. Visual gates PASS: label-free
function, structural level differences, palette/camera consistency, clean alpha,
planted contacts, structural wear/collapse, correct source-mouth feedback,
relative scale and depth. Details and final capture hashes are in
`reviews/0013/REVIEW.md` and `frame-review.json`.

Audit against `87079a1`: forty old tower PNGs changed, eight levelled wrecks
added, all other 240 runtime PNGs byte-identical. All 249 protected baseline
files and prior unrelated manifest entries are preserved, including core/map/
save rules, owner's original art, prior accepted sources, PlayerFrames, palette
and hash guards. Ownership is 232 raster / 56 ASCII / zero player-sheet,
288 runtime PNGs. Existing art assertions now follow the explicit authored
canvas/contact/construction and structural-wear/weapon-action contract instead
of legacy band-growth or alpha-count assumptions; all rule/hash/input checks
remain. Pilot ghost and ordered lamp-probe failures were corrected to actual
source placement and order-independent outlet counts. The provenance audit
initially required a colon after the word 'Rejected'; it now accepts the exact
saved rejection prefix while retaining every original reason (`audit-initial.log`).

Queue after completion: 13 done, 7 todo, zero doing/blocked. Next: 0014,
barriers and mine. Normal zombie sprites/animation remain 0015, Giant/death
0016, UI 0018 and shared final atmosphere 0019. Exactly one sprite task
completed this cycle; the active /goal continues automatically toward the backlog.

## 2026-10-01 - 0014 completed: connected barriers, barricades and mine

Generated sixteen immutable raw returns through built-in ImageGen in
`assets/art_source/defences/{wall,fence,barricade,mine}/`. All exact prompts,
reference hashes, tool arguments, return paths, measured alpha cuts and final
decisions are retained in `generation/0014-*`. Four early candidates remain
rejected. Eight sheet selections are partial: whole-r3 post/front, whole-r2
north/south projection and low wreck, hurt-r1 post/front, initial hurt vertical
break. Two trap masters are identity references; two three-state strips own
runtime art. Whole wall/fence used exactly three targeted revisions each and
hurt one each; trap sources used none. No creative source pixels were painted
with Python; it performed measured cuts, fixed nearest/palette/alpha conversion,
source-owned composition and review layout only.

Twelve authored modules compose all 64 cardinal whole/hurt masks on 16x32
canvases, pivot (8,28), cell offset (0,-12). Every material shares one scale
across its selected whole/hurt/wreck modules. Bounded parts preserve their
source pixels and alpha-over; the contact post is last. Taller posts/front
profiles read as masonry or iron-banded timber, with narrow north/south
projection. Broken posts, displaced stone and snapped rails survive native
reduction; whole/hurt alpha shapes differ for every mask. Native height follows
the measured return, not the ideal 12/28-pixel initial brief. Two low barrier
wrecks, three 16x24/(8,20) barricades and three 16x16/(8,14) mine states complete
84 outputs. Ten old PNGs migrate and 74 are added. Complete families disable
old ASCII hole/wreck recipes; all 46 remaining ASCII sprites stay guarded.

WorldView selects neighbors from existing occupancy, including mixed material
joins and legal stationary-pointer previews. Empty/unrelated cells acquire no
decorative post. Actual damage chooses source wear; passable Farm rubble draws
at the destroyed cell in the bounded ground pool, including loaded saves and
morning cleanup. Mines sit above plots and beneath actors. Existing fixed-tick
observers compare real consumption/sprung counts with sell intent, current
structure_lost receipts and new rubble. Old rubble under a rearmed mine does
not suppress a real trigger; ambiguous external removal produces no guessed
location. Up to six view-owned cues show triggered for 0.16s, spent for 0.24s,
then expire. Rearm/load/morning clear cues. No core entity survives merely to
draw feedback; no gameplay, placement, collision, save format or RNG changed.

Full verify PASS: 43 passed, zero skipped/failed in 281s with the user's Godot
4.7.1. All 107 scripts parse; 6,610 rule assertions, 982 input cases,
performance and Windows/Web exports pass. Simulation `1961000123` and data
`407837701` remain unchanged. Raster check proves 316 outputs and zero writes.
Source checker validates all 84 exact outputs, 64 masks, alpha-shape wear,
shared scale/contact, low ruins and at least two actual mixed-material seam
pixels/rows. Headless barrier showcase: 3,275 checks; actual renderer: 3,353
checks. Fixtures cover 256 neighbor combinations, all map corners, real paid
placement/damage, route restoration, farmer depth, crop/mine/actor overlap,
real 4x tick batches, sale/destruction/upgrade distinctions, old receipts,
same-count replacement, seven-trigger overflow and complete cue expiry.

Pipeline suite: 90 fault/rebuild probes PASS, including twelve new missing
barrier/mine source/output, invalid component/cycle/bounds and incomplete
migration probes. All deliberate corruptions restored; final source check
passes. The initial full run found two legacy alpha-count assumptions and an
undocumented integer-key sort. Authored barrier assertions now require distinct
same-canvas standing construction and a low collapsed pile; the legacy branch
and all rule/hash/input checks remain. The new assertion then required an
explicit bool annotation. Both iterations are retained in `verify-initial.log`
and `verify-parse-fix.log`; final `verify.log` passes. Exact submitted CRLF
prompts are protected by scoped Git attributes. Staging audit verifies all
118 hashed source/prompt/reference/runtime blobs without newline conversion.

Opened all 42 actual native captures and exact nearest 3x review pages
`reviews/0014/captures-00..20{,-3x}.png`. Originals are in
`implementation/shots/sprites/0014/` and `barriers/`: all joins/states under
day/dusk/night, four previews, predicted route, loaded ruins, mine outcome
sequence/exclusions/4x/crop layering, farmer depth, mixed night perimeter and
the five required standard views. Also opened all native/enlarged material
sheets on light/dark/checker, source modules/trap silhouettes, twenty selected
raw cuts and two identity masters. Visual gates PASS: function/material/camera,
joined occupancy, structural damage/collapse, clean alpha, grounded contacts,
stable footprint/route and correct actor depth. Details and every final SHA-256
are in `reviews/0014/REVIEW.md`, `frame-review.json` and `scope-and-sources.json`.

Audit against `4567753`: all 278 unrelated runtime PNGs, 293 protected baseline
files and all 232 previous manifest entries are intact, including core/map/save,
owner/player/pilot art, prior accepted sources, palette and hash guards.
Ownership is 316 raster / 46 ASCII / zero player-sheet, 362 runtime PNGs.
The fifteen unrelated pre-existing untracked files remain outside this commit.
These are authored join/damage/outcome poses with a short one-shot mine cue;
no continuous barrier animation is claimed. Normal enemy masters/motion follow
in 0015, Giant/death playback in 0016 and shared final atmosphere in 0019.

Queue after completion: 14 done, 6 todo, zero doing/blocked. Next: 0015,
walker/runner/tank/breaker sprites and motion. Exactly one sprite task completed
this cycle; the active /goal continues automatically toward the backlog.

## 2026-10-02 — 0015: ordinary enemy masters and authored motion

Completed walker, runner, tank and breaker masters plus 4/3/4 walk, attack and
death sources. Twenty-one actual built-in ImageGen returns are preserved in
`assets/art_source/enemies/`: sixteen selected, five rejected attempts archived.
Exact prompts, reference hashes, tool arguments and original return paths are
under `generation/0015-*`. Runner/tank death revision 1 separates overlapping
frames; breaker walk revision 2 preserves its hammer, attack revision 1 separates
tool/body bounds. All returned sources were opened; no asset exceeds revision 2.
The installer performs measured cuts and fixed nearest/palette/binary-alpha
conversion only, with one scale per strip and no Python-painted enemy art.

Forty-eight authored poses and twelve byte-identical old-name aliases replace
the ordinary procedural motion. Ownership becomes 372 raster / 34 ASCII / zero
player-sheet, 406 runtime PNGs. Common 64x48 canvases, pivot (32,44), deliberately
add transparent clearance beyond the pilot 32x40 contract for the runner lunge
and hammer. Visible standing bodies remain about 29 pixels high, near the
farmer's 30; feet and core position do not move with pose or canvas dimensions.
Death sequences progressively collapse at the same scale; playback follows in
0016. Giant's original runtime/source art remains unchanged this cycle.

EnemyMotion is view-owned: actual position deltas advance walk poses; observed
core hits/waits choose contact, recovery and pre-hit poses. It mirrors observed
horizontal travel, retains horizontal facing during vertical movement, and
does not claim four cardinal source directions. Rendering/paused frames cannot
advance the cache; removed entities and new states clear it. Stale chew targets
do not invent attacks. The first core hit stays immediate. No gameplay, RNG,
save fields, collision, balance or core code changed. Hurt modulation retains
the body/material/tool instead of washing the family white.

Full verification PASS: 45 passed, zero skipped/failed in 320 seconds, with
Godot 4.7.1. The soft 300-second duration target reports OVER BUDGET without
failing the command. All 109 scripts parse; 6,611 rule assertions, 982 input
cases, performance and Windows/Web exports pass. Sim `1961000123` and data
`407837701` stay unchanged. Raster source check proves 372 outputs, zero writes;
enemy checker proves 48 real poses, twelve aliases, fixed contacts, shared
strip scale, silhouette differences and actual motion rather than row shifts.
Enemy headless showcase: 1,982 checks; real renderer: 2,040 checks; zero failed.
It covers real movement/hits/waits, all walk/attack frames, mirrors, paused and
4x ticks, state-byte preservation, removal/load reset, hurt and mixed night wave.

The initial full run failed only the older Giant size comparison, which counted
new transparent pose clearance as body width. The assertion now compares visible
alpha bounds for both types and still requires Giant to be wider and taller
than all ordinary bodies. Final full suite passes without hash acceptance or
skipping. Initial debug logs remain with successful logs in `reviews/0015/`.
The raster importer is unchanged; no extra fault-suite run is claimed.

Opened all four native and 3x complete motion sheets, black silhouette reviews,
and 34 real native 480x270 captures paired with exact nearest 3x on 17 pages
`reviews/0015/captures-00..16.png`. Original shots live in
`implementation/shots/sprites/0015/` and `enemies/`. Reviewed daylight/night
identities, black silhouettes, both moving directions, actual attack sequences,
hurt, prepared death textures, mixed dark/moving waves and all five standard
views. Function, contacts, body scale, alpha, movement and depth gates pass.
Existing night lighting makes cloth colors very dark; shape distinguishes the
families there. Shared atmosphere task 0019 should improve this using the current
art. The user explicitly requested preservation of completed sprites; no
additional generation followed that clarification and no previous family was
regenerated. Enlarging a viewport does not recover detail lost at native scale.

Audit against `6e81946` proves 962 protected prior core/art files unchanged,
including owner/pilot/player art, all earlier raw sources and unrelated runtime
PNGs, palette and hash guards. Exact raw/prompt/reference/runtime ownership is
recorded in `reviews/0015/scope-and-sources.json`; staged bytes are checked before
commit. Fifteen unrelated pre-existing untracked files are excluded. Complete
visual findings, revisions and limits are in `reviews/0015/REVIEW.md`.

Queue after completion: 15 done, 5 todo, zero doing/blocked. Next: 0016, Giant and
death playback. Exactly one sprite task completed this cycle; the active /goal
continues automatically toward the backlog while preserving finished families.

## 2026-10-02 - 0016: Giant motion and bounded enemy deaths

Completed only Giant's missing master and 4/3/3/5 walk/wind-up/slam/death family.
Five actual built-in ImageGen returns, all accepted with zero revisions, are
saved in `assets/art_source/enemies/giant/`. Exact prompts, actual submissions,
return paths, source/reference hashes and measured cuts live under
`generation/0016-*`. Sixteen canonical poses and four exact old-name aliases
replace the five legacy procedural Giant outputs. Ownership becomes 392 raster
/ 29 ASCII / zero player-sheet, 421 runtime PNGs. All earlier completed art,
including every ordinary enemy drawing from 0015, is reused unchanged.

The visible Giant master is 43x42, larger than ordinary 29-pixel standing bodies.
Its shared canvas/pivot is 80x64/(40,60): sixteen extra transparent columns beyond
the pilot 64x64 allow the contact fist while preserving planted feet. Strip
scale stays fixed, raised-arm heights are 39/48/55, and collapse heights are
39/33/27/20/16. Source conversion only cuts, resamples nearest, maps the existing
palette and resolves alpha; it does not paint missing poses. ART_DIRECTION and
PIPELINE document the accepted envelope and observation/playback contract.

Real observed movement advances Giant walking/facing. Existing valid target
and wait data drive the tell; actual observed core contact starts slam. Stale
targets cannot invent attacks. Nine cosmetic recovery ticks never postpone a
core step. EnemyDeaths borrows only coordinate Arrays during one core tick,
copies final moved positions for removed enemies, then releases those arrays.
No entity dictionary or dead core entity survives for art. At most 24 cues and
24 reusable y-sorted sprites play once: ordinary four-frame deaths expire at
0.48 seconds, Giant five-frame deaths at 0.60, with 0.12 seconds per frame.
Duplicate observations, skipped tick gaps, load and morning cleanup cannot
replay deaths. No core, balance, collision, map footprint, RNG or save changes.

The actual house capture initially exposed an invisible warning: all three
wind-up phases produced zero target-ring pixels beneath the roof. The ring now
draws above boss/roof and below shots, with its existing target/color/radius/time.
Rejected captures and failure log remain under `reviews/0016/pre-warning-layer/`
and `showcase-house-warning.log`. Wall tells in both directions and every house
phase now pass actual rendered hide/show pixel comparisons. Natural body/roof
occlusion remains; no source regeneration was needed to fix the warning.

Final full verification PASS: 47 passed, zero skipped/failed in 352 seconds,
Godot 4.7.1. The soft 300-second duration target reports OVER BUDGET without
failing. All 111 scripts parse; 6,612 rule assertions, 982 input cases,
performance and Windows/Web exports pass. Sim `1961000123` and data `407837701`
remain unchanged. Raster check proves 392 outputs, zero writes. Giant headless
showcase: 2,433 checks; actual renderer: 2,530 checks; zero failed. It covers
real core movement/waits/hits, all poses/mirrors, valid/stale tells, final
movement-before-removal positions, one-shot death/expiry, 64 actual simultaneous
kills with the 24-sprite cap, load/day cleanup and identical serialized state.
Full death-pool refresh measures 110.6us in capture mode. Night tick is
555us/8,333us and path rebuild 4,246us/33,333us in final verify.

The first full run failed only the old input expectations for procedural
two-frame Giant names and an invalid manually assigned distant tell. The case
now checks four authored steps and lets core begin a real house tell. Focused
input rerun and the final full suite both pass. Initial and successful logs
remain in `reviews/0016/`; no hash baseline acceptance or skipped check was used.
The raster importer is unchanged; no extra fault-suite run is claimed.

Opened six complete light/dark/checker motion sheets at native and exact nearest
3x, and every one of 49 accepted actual 480x270 captures paired with exact 3x
on 25 pages `reviews/0016/captures-00..24.png`. Original views live in
`implementation/shots/sprites/0016/` and `giant/`. Reviewed native day/night
identities and silhouettes, movement with escorts, every tell/slam, house warning
and spent Giant, all five deaths and expiry, capped pool and five standard views.
The Giant's heavy silhouette, raised arm, stable contact and progressive death
pass. Existing shared lighting makes night cloth colors dark; task 0019 should
tune atmosphere using the current art. The user's request to preserve completed
sprites is respected. A larger window alone does not recover native detail.

Audit against `94ce993` proves 1,109 prior core/art files unchanged, including
owner/pilot/player art, all earlier raw sources and runtime families, palette
and hash guards. Exact raw/prompt/reference/output ownership is recorded in
`reviews/0016/scope-and-sources.json`; thirty staged source/prompt/runtime files
match worktree bytes exactly. Prior unrelated generated imports are excluded.
Complete evidence and limits are in `reviews/0016/REVIEW.md`.

Queue after completion: 16 done, 4 todo, zero doing/blocked. Next: 0017, common
effects. Exactly one sprite task completed this cycle; the active /goal continues
automatically toward the backlog while preserving finished families.


## 2026-10-02 - 0017 complete: combat and work effects

Added seven missing raster families with seven actual built-in ImageGen calls
and zero revisions: muzzle, impact, flame, smoke, dust, splash and flare.
Exact raw sources are `assets/art_source/effects/*.png`; prompts, submitted
arguments, reference/source hashes and deterministic cuts are saved under
`generation/0017-*`. All seven sources and 25 distinct converted frames were
opened. Shared strip scales, binary alpha, existing palette and exact pivots
pass source checks. Ownership is 417 raster / 29 ASCII / zero player-sheet,
446 runtime PNGs. All 392 earlier raster entries and completed sprites remain
unchanged; audit against `4f42da7` proves 1,153 protected art/core files exact.

Fixed-tick observations attach one-shots to actual gun outlets, damage,
ignition, flare use and completed work. Useful procedural particles remain.
At most 24 reusable forms share the existing particle capacity. Dust/splashes
render below the farmer; five work peak comparisons change zero opaque actor
pixels. Lazy binding and teardown cover normal Main scene readiness. Authored
enemy deaths replace the duplicate legacy corpse overlay. Halos are limited to
12 separated centers with lower intensity after reviewing glare in a 75-enemy
stress view. This uses existing sprites; no completed art was regenerated.
Live particle density/capacity and steady accessibility settings pass; full,
half and off 90-tick rule states match exactly. Sources/collision/balance/save
formats and palette are preserved.

Final full verify: 49 passed, zero skipped/failed in 368s, Godot 4.7.1;
113 scripts parsed, 6,613 rule assertions, 982 input cases and Windows/Web
exports pass. Soft 300s duration target is over budget without gate failure.
Sim `1961000123` and data `407837701` unchanged. Raster reproduction checks
417 outputs with zero writes. Effects headless: 2,997 checks; actual renderer:
3,156; tower regression: 1,305; all zero failed. The old tower expectation of
three procedural sparks was replaced with exact authored outlet checks.
100 burning actors with full 24-slot/420-total pool: CPU view-update p95 525us
of 16,000us across 240 samples, identical state. GPU cost is excluded.

Opened six native/nearest-3x animation sheets and all 42 actual 480x270 captures
paired on 21 review pages in `reviews/0017/captures-00..20.png`. Views in
`implementation/shots/sprites/0017/` and `effects/` cover every phase, day/night,
real tower shots, smoke, five work actions, crowded fire/flare, deaths/expiry,
a11y and all five standard scenes. Final changed pages were reopened; direct
native busy/work views also pass. Night muzzle/flame/flare retain warm cores,
smoke stays subdued, and ground cues preserve the actor silhouette. Rejected
halo captures and initial failed regression logs remain in the review folder.
Full evidence and measurement limits: `reviews/0017/REVIEW.md`.

Queue: 17 done, 3 todo, zero doing/blocked. Next: 0018. Exactly one task
completed this cycle; the longer goal remains active. The 0019 atmosphere
follow-up will use current art, honoring the user's request not to redo sprites.


## 2026-10-02 - 0018 complete: native resource icons and UI surfaces

Completed all fifteen resource icons with fifteen actual built-in ImageGen
calls and zero revisions. Raw masters are `assets/art_source/ui/*.png`;
`generation/0018-*` preserves exact prompts, submitted arguments, references,
SHA-256 hashes and deterministic cut recipes. The reference sheet and accepted
wood master maintain material consistency. Each source owns a 16x16 inventory
cut and 10x10 compact cut, with maximum visible dimensions 14 and 8, transparent
padding, binary alpha and the existing palette. Thirty distinct outputs replace
the fifteen legacy icons and add compact variants; no completed world, player,
enemy or effect sprites were regenerated.

HUD, tech currency, inventory and market quantity-one buttons use native cuts
while preserving localized names. Existing deterministic UI surfaces retain
three-pixel nine-patch margins, clear normal/hover/pressed/disabled states,
selected tab underline and visible focus. Seven additional tab/check/grip states
stay code-owned. Actual capture review caught and fixed the inventory's bottom
clipping, Godot's default disabled slider grip and Portuguese dusk/money overlap.
Inventory now fits y=9..261 and refreshes translated names on locale change.
The HUD reserves the full dusk label before money at x=144; a day-99 fixture
with balance 1,000,024 also fits. No project resolution or rule changes.

Final full verification: 51 passed, zero skipped/failed in 407s, Godot 4.7.1;
114 scripts parse, 6,613 rule assertions, 982 input cases and Windows/Web exports pass.
The 300s soft target is over budget without a failed gate. Sim `1961000123` and
data `407837701` unchanged. Raster reproduction: 447 outputs, zero writes.
UI headless: 1,948 checks; actual renderer: 10,548; zero failed. Night tick
546us/8,333us and path rebuild 4,264us/33,333us pass; no GPU claim. Initial
failed fixture/full logs remain beside final successful logs; no check disabled.

Opened raw sources and all light/dark/checker native/nearest-3x icon sheets,
and 92 actual 480x270 views paired on `reviews/0018/captures-00..91.png`.
They cover all fifteen resources, button/tab/check/slider states and focus,
inventory, market buy/sell, dusk/night HUD, title/error views, options, tech,
result and the five standard scenes, in English/pt-BR and both themes.
Following final money reflow, reviewed all forty HUD strips and reopened the
five full night captures with animation/shader variation. Other thirty-five
capture bodies are pixel-identical outside the money region. Native legibility,
state distinction, localization fit, alpha/padding and source ownership pass.

Audit against `566a503` proves 1,184 protected core/art files and all 417 prior
raster entries unchanged. Fifteen raw sources match actual tool returns; thirty
cuts are source-owned. Ownership is 447 raster / 21 ASCII / zero player-sheet,
468 runtime PNGs. Scope and source evidence: `reviews/0018/scope-and-sources.json`;
criterion-by-criterion review and limitations: `reviews/0018/REVIEW.md`.
The staged audit proves 75 source/prompt/argument/runtime files byte-exact.
Unrelated previously generated imports are excluded from this task's commit.

Queue after completion: 18 done, 2 todo, zero doing/blocked. Next: 0019 atmosphere,
using accepted sprites. Exactly one task closes this cycle; the longer goal
remains active through 0019 and 0020.

## 0019 — Shared palette and day/night atmosphere — 2026-10-02

Completed the atmosphere integration using accepted art and the existing reference
study. Zero new ImageGen calls, revisions or masters; every completed sprite is
preserved. Audit against `303f38b` proves 1,312 protected files, all 468 runtime
PNGs, all 447 raster entries, previous source/prompt records and 42 palette colours
unchanged. Only day/night ramp parameters and view presentation change; project
resolution, core, save formats, balance, grid and collision remain unchanged.

Night now uses blue/violet tint (.36,.40,.82), lift (.04,.035,.105) and saturation
.76. Game ramps disable the complete brightness exemption, so pale cloth/crops
receive ambient light instead of glowing. Actual muzzle/flame/flare and hot sparks
use an Emissions layer above relight through the existing 24-slot/420-limit pool.
Smoke/impacts remain ambient and ground effects remain below actors. Five measured
window cores retain localized amber light in normal blend beside the existing
small additive halos. UI sits above these layers. Generated palette data agrees
with tools/palette.py; all image reproduction gates write zero files.

Transition now identifies source-owned pivot sprites through logical_cells;
three daytime animals fade and eight towers wake with a restrained 1.45 pulse.
Interrupted reversal preserves the displayed ramp and animal opacity. Standard
photographs settle ambient light without advancing additional simulation ticks.
The new atmosphere fixture restores settings without persistence, never writes a
profile and checks complete state bytes around observers. Actual capture review
caught stale manually refreshed transition observers; final captures refresh lamps
and animal presentation after every phase step.

Final full verify: 52 passed, zero skipped/failed in 405s on Godot 4.7.1, 115 scripts
parse, 6,646 rule assertions, 982 input cases and Windows/Web exports pass. Sim
`1961000123` and data `407837701` remain unchanged. The 300s soft duration target
is exceeded without a failed gate. Night tick 544us/8,333us and path rebuild
4,183us/33,333us pass. Atmosphere has 198 headless / 300 actual-renderer checks;
effects have 2,997 / 3,156; all pass. At 100 burning actors, CPU view p95 is 532us
against 16,000us with unchanged pool budgets; this does not measure GPU cost.

Reviewed 84 actual 480x270 captures at native and nearest 3x: 27 atmosphere,
37 effects and 20 standard scenes in English/pt-BR and both themes. Paired final
farm scenes hold map and actor positions fixed. Material/emission/window probes,
both transitions, reversal, quality 0/1/2, lights off, reduced flashing/density and
skip transition pass. Following observer refresh, 52 previously reviewed frames
are pixel-identical; all 12 changed frames were reopened plus all 20 new standards.
Before diagnostics and initial failed verification logs remain as evidence.

Evidence: `implementation/shots/sprites/0019/{atmosphere,effects}` and standard
scene PNGs; `reviews/0019/REVIEW.md`, capture index, observer pixel comparison,
palette measurements, scope/source hashes and `verify-complete.log`. Five old
brightness-exemption assertions were replaced with actual material/emitter checks;
no gate or hash guard was disabled. Existing alpha, frame ownership and contacts
remain unchanged. Pre-existing untranslated Portuguese result/tech labels are
recorded in review, outside this atmosphere task.

Queue after completion: 19 done, 1 todo, zero doing/blocked. Next: 0020 final audit.
Exactly one task closes this cycle; the longer goal remains active through 0020.

## 0020 - Complete native visual review and delivery catalogue - 2026-10-02

Closed the final sprite task against all twenty original prompt requirements.
Preserved completed art: zero ImageGen calls, revisions, new masters or replaced
runtime PNGs in this cycle. The 468 PNGs, 447 raster entries, accepted raw sources,
prior prompts and deterministic recipes remain byte-identical to `c03c169`.
Core, project resolution, grid, collision, save formats, balance, original owner
sheet/reference and planning sim/data baselines remain unchanged.

The final catalogue records every output's owner, SHA-256, native canvas, visible
bounds, pivot, animation frame/timing, source/prompt lineage, emission points and
compatibility role. Ownership is 447 raster / 21 ASCII / zero owner-sheet. All
sixteen enemy compatibility aliases equal their canonical authored frames.
The unused legacy actors/placeholder.png has no src/scenes reference; all required
runtime families have real textures. DELIVERY.md links sources, nineteen native
contact sheets with their nearest-3x pairs, reproduction commands and limits.
README and PLAYTEST now describe the playable raster-art project.

Two complete offline import/generate/cut cycles in a completely clean managed
checkout of `c03c169` preserved all 1,283 tracked art/source/generated-metadata
files. Both cycles wrote zero outputs and left Git clean. clean-rebuild.json
records command output and every file hash. The temporary worktree is archived.
Final audit compares all these current bytes, rather than only runtime PNGs.

Captured 890 actual 480x270 images through 25 sequential renderer runs covering
every production family, dense beds, all work verbs/facings, structure levels and
states, mixed waves, Giant and deaths, localized effects, real menus, both locales,
themes and accessibility. All 648 new/changed views were opened at native and exact
nearest 3x on 167 pages. All 38 runtime contact pages were also opened. The hashed
visual-review.json ledger has 205/205 accepted pages, zero pending. The remaining
242 views have exact decoded pixel matches to earlier accepted views; reused-review
proves each prior capture remains committed-byte exact and resolves to its saved
native/3x index and review journal. No changed view reuses prior acceptance.

The work fixture now covers thirteen four-frame gestures in all four gameplay
facings (208 captures), instead of west/east only. North/south preserve accepted
lateral gestures; east mirrors west. The automatic water fixture now waits for
six actual phase changes with a 12s failure bound; the original 3.8s window caught
only five on the loaded renderer. Its failure log/trace are retained. Production
550ms timing is unchanged; the final A/B/C/A/B/C trace takes 4.409s/136 frames
with three unique phases and identical serialized state. These two fixture changes
were included in the final full verification; no runtime/view code changed later.

Actual renderer checks: placement 542; locomotion 540; work 7,813; reactions 828;
terrain 19,669; water 2,288; props 8,643; crops 9,248; house 1,193; stations 3,956;
towers 1,356; barriers 3,353; enemies 2,040; Giant 2,530; effects 3,156; UI 10,548;
atmosphere 300. All zero failed. Capture commands restore their isolated settings
and save state; no new gameplay event or rule is introduced for animation.

Final full tools/verify.py: 52 passed, zero skipped/failed in 431s with the user's
Godot 4.7.1. All 115 scripts parse, 6,646 rule assertions and 982 input cases pass;
Windows/Web exports pass in 35.6s. Sim `1961000123`, data `407837701`, unchanged.
The 300s soft verification target is exceeded without a failed gate. Runtime perf
passes: night tick 549us/8,333us, path rebuild 4,260us/33,333us. Captured 100-actor
FX stress uses 24 raster slots within the 420 shared limit; 240 samples give
CPU view p95 532us/16,000us with unchanged state. No GPU cost claim is made.

Concrete criterion decisions and the complete original requirement audit are in
reviews/0020/REVIEW.md and requirements-coverage.json. completion-audit.json proves
all native capture/page pixels, hashed visual decisions, prior-review reuse,
catalogue ownership/source/prompt hashes, exact aliases, clean reproduction and
core/reference preservation. Evidence: implementation/shots/sprites/0020/,
reviews/0020/verify.log, capture-runs.json, capture-index.json, catalogue.json,
visual-review.json, reused-review.json and clean-rebuild.json.

Known limits remain explicit: static trees/animals/banks/crop stages, side-on work,
horizontal enemy facing on vertical movement, authored station/tower state poses,
bounded one-shot deaths/effects, natural canopy/roof/map-edge clipping and existing
untranslated result/tech labels. Enlarging the window does not restore native
detail. No required family, visual criterion or source gate remains incomplete.

Queue after completion: 20 done, zero todo/doing/blocked. This closes exactly task
0020 and completes the longer requested sprite-production goal. Only this task's
files are staged; unrelated prior capture imports remain excluded. No push,
publication, unattended driver or automation is started.
