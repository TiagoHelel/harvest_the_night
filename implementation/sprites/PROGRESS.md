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
