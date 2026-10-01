# 0011 farmhouse review

Date: 2026-10-01. Runtime baseline: `a42b530` (completed 0010).

Two built-in ImageGen edits produced an entire terracotta/timber farmhouse and
an independently authored damage state. The whole request used the accepted
pilot and repository reference sheet; damage used the new whole raw master as
its sole edit target. Two calls, zero targeted revisions. Raw tool files were
copied byte for byte to `assets/art_source/buildings/house/whole.png` and
`hurt.png`, with exact prompts and tool paths in `generation/0011-*-call.json`.
Their SHA-256 values are
`1cec572a66451ea3d326ca012623aee83648bad21eea275b4d6b891fb6ded435` and
`0ddfbbb4ed2f219f5a716417c78cf3d619bbe7b19b38379dcb4e3f36de101017`.

## Native contract and review

Both 1254x1254 raw sources have alpha range 0..255. Final cuts share the measured
source crop (114,134,1082,1053), expressed as x,y,width,height, and scale
0.05180388529139685. Initial individual measurements are retained separately;
the shared union crop was chosen before promotion to avoid a one-row refit.
Runtime canvases are 64x64 with (32,60) pivot and (-8,-12) cell offset. Both
visible native bounds are (4,5)..(60,60), width 56 and height 55.

Opened light/dark/checker native and exact nearest 3x comparisons, both final
3x candidates, raw source alpha comparisons, common ground/relative scale
sheet and the measured emission overlay. Whole and hurt keep the same gabled
roof, facade, front steps and right chimney. Damage concentrates on the left
roof slope: missing tiles expose a dark rafter patch with localized facade
wear, surviving reduction as 148 changed roof-region pixels. Both are larger
than the 30px farmer and 42/43px tree bodies. Windows stay readable and side
margins remain transparent; there is no painted ground halo.

Independent sources vary stair stone colors and one right edge pixel at the
bottom tread. Bottom contact stays at y=59, shared tread x=24..34, centers
29/29.5. Source validation measures actual alpha grounding rather than requiring
identical RGB across two independently authored stone surfaces. No runtime or
raw image was painted to satisfy that check.

## Production integration and actual captures

WorldView chooses `house_hurt` below the existing 75% wear threshold using the
separate `house_hp` field and Phases.house_full. HP-only changes now refresh the
view even when occupants are unchanged. Fixtures cover 75/74 out of 100 and
105/104 out of the researched 140, zero HP and restoration to full HP. No core,
HP, collision, save or balance change is introduced. Each house still occupies
nine original cells and draws exactly one full texture. Eighteen compatibility
slices exactly reconstruct the whole and damaged canvases.

Five validated glass lamps are at (32,33), (19,45), (41,45), (30,45), (52,46).
The local night glow radius is 0.9 tiles and strength 0.26, above Main's actual
night ramp, with existing off/steady/full controls. Smoke is at (51,12) in
both states and follows the existing chimney emitter.

Opened all 49 actual 480x270 Godot captures at native size and exact nearest 3x
via `captures-00..12` and both split 3x columns. Originals are in
`implementation/shots/sprites/0011/house/` (44) plus the five required Main
scenarios. `frame-review.json` records every original capture's hash.
The dedicated house showcase passed 1,059 headless checks and 1,193 actual
renderer checks, including serialized-state equality around drawing and
lights. Pixel comparisons confirm both whole/hurt facades occlude farmer and
walker behind, preserve every opaque actor pixel in front, illuminate each
physical pane and leave the roof ridge unchanged by local glows.

Visual gates PASS: recognizable coherent roof, material planes, larger landmark
scale, localized damage, stable ground/door contact, five aligned warm windows,
dawn/day/dusk/night readability, actor depth, whole previews, unchanged 3x3
blocking and coherent camera clipping at all four map corners. The north/south
edge fixtures naturally clip the roof/base at existing camera bounds, and their
debug captions cross the upper strip; centered fixtures show the entire asset.
Main result/technology UI obscures the farm by design. None is source clipping.

Final common light/palette refinement remains 0019. Other buildings remain
0012, normal enemies 0015 and Giant/death playback 0016.

## Verification

Fault/rebuild probes: 61 PASS, all deliberate corruption restored, plus one
count-preserving out-of-canvas lamp probe PASS (`window-probe.json`). The nine
new checks cover missing house damage source/output, tampered hurt slice,
state scale drift, missing/empty/unequal/out-of-canvas glass metadata and exact hurt
slice reconstruction. Full project verification and scope audit are recorded
in the accompanying logs and `runtime-delta.json`.

Full verification PASS: 37 passed, zero skipped/failed in 220s, including
6,610 headless assertions, 980 input cases and Windows/Web exports. Simulation
`1961000123` and data `407837701` are unchanged. The 154-output raster check
writes zero files. Final performance: night tick 607us, path rebuild 4546us,
with unchanged budgets/baselines.

The first full run found the legacy single-pool assertion and one noisy
performance measurement (path refresh 34359us). The old assertion was replaced
by checks for five local glass lamps and larger combined warm area than one
burning zombie; no check or timing ceiling was disabled. The isolated repeat
measured 4657us, and the final complete run passed at 4546us. Initial logs are
preserved in `verify-first.log`, `headless-retry.log` and `perf-retry.log`.

The scope audit preserves core, palette, guard baselines, owner sheet, original
pilot masters, props, terrain and crops. Only the ten existing house PNGs
changed and ten independent damage PNGs were added; the other 250 runtime
PNGs are byte-identical. Ownership is 154 raster and 116 ASCII outputs.
