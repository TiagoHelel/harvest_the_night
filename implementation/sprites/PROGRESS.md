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
