# World visibility and idle life — 2026-10-02

The user confirmed 25% more map area, requested zoom and smoother tracking, and
reported motionless trees/animals and odd farmer eyes. The follow-up preserves
the 480x270 viewport and 16px grid. Only three frontal idle PNGs are replaced.

## Behavior

- The farm grows from 40x18 (720 cells) to 45x20 (900 cells). Original coordinates
  are retained; extra meadow and shoreline extend east and south. East spawns
  move to column 44. Map connectivity and every resource's reachability pass.
- Camera tracking reads subtile position every display frame, smooths with a
  delta-time exponential response, and follows both axes within map bounds.
  This removes the former 16px jumps when the player changed cells.
- Mouse wheel and =/- select 0.875x, 1x, 1.25x, 1.5x or 2x; 0 restores 1x.
  All three actions can be rebound. HUD stays at its normal scale; world light
  radii and cell picking use the zoomed transform. Fractional zoom still shows
  nearest-neighbor pixel-size variation; it cannot recover missing source detail.
- Existing trees sway at the canopy, chickens peck, cows move head and tail.
  Fixed ground anchors, phase offsets and a paused cosmetic clock keep the
  movement separate from the simulation. This does not add animal roaming.
- Front/side farmer idle holds open eyes for 3.2s, closes for 0.1s, then reopens
  for 0.16s. The frontal source now reopens both eyes instead of winking.

## Eye correction

Built-in ImageGen edited only the frontal idle strip, using the original idle
and walk sources. Candidate v2 was rejected by the user because its dark eyes
lost all highlights at native scale. It is retained as rejected evidence and
does not feed the manifest. Candidate v3 restores ivory whites and brown pupils;
the original source remains intact. Three common-scale cuts feed the usual
palette/alpha importer, each with its original 48x48 canvas and foot contact.

Accepted source: `assets/art_source/player/idle_south-eyes-v3.png`.
Exact prompt and call are under `implementation/sprites/generation/` with prefix
`visibility-idle-eyes-v3`. `prepare_eyes.py` reproduces native/4x comparisons and
the three recipes without painting or manually changing source pixels. Both open
eye colors remain visible in the native captures, and the wink is gone. The face
still has only a few pixels of detail; no claim of a higher-resolution face is made.

## Save compatibility and gameplay

State version 1 migrates to 2 on load. Terrain and cell-indexed tables are moved
to the new row stride; building/player/entity coordinates, resources, jobs,
regrowth and fuel are preserved. Cached path, tower, power and livestock lists
are rebuilt. Already harvested old trees do not return. Historical v1 golden
saves still load and advance.

The larger map exposed a sealed-tower pathing bug: an enemy more than one cell
from an impassable tower row had neither a house route nor an adjacent target.
When the house is unreachable, enemies now approach a reachable structure using
the existing hunt field before chewing. Normal house routes retain priority.
The giant escape fixture uses its real HP, and passes for walls and towers.

Input tests now wait for zoom settlement instead of assuming frame counts equal
seconds, and reset the camera after the independent manual-pan test. Barrier
fixtures use grid dimensions. The dry-ammunition case permits equal kill counts
on the longer approach while still requiring strictly faster victory and less
house damage with ammunition. Two pre-existing test-fixture mistakes were fixed:
invalid preservation sentinels are removed before simulation, and technology
queries receive the fixture's state rather than its result wrapper.

## Native evidence

`python tools/show_art.py --visibility` captures 274 unmodified 480x270 renderer
frames: camera tracking, default/zoom views and six-second day/night ambient
sequences. `preview.py` composes GIFs with their original timing and nearest-only
contact enlargements. The camera film is 60Hz; ambient films sample at 15Hz.

- `camera.gif`: smooth within-cell tracking, with no tile-sized discontinuities.
- `ambient-day.gif` / `ambient-night.gif`: canopy, hen, cow and farmer playback.
- `ambient-contact.png`: native and 3x phases, including the blink/reopen.
- `eyes-comparison-native.png` / `eyes-comparison-4x.png`: original versus v3.
- `visible-motion.json`: 16 tree, 47 cow and 8 hen distinct sampled native crops.

The headless visibility fixture passes 121 checks; actual renderer capture passes
669 checks. It verifies camera limits, zoom limits, inverse picking, unchanged
simulation bytes, fixed ground contacts and frozen ambient time during pause.

`python tools/verify.py` passes all 53 gates, with zero skips/failures: 6,998
simulation assertions, 985 input cases and successful Windows/Web/playtest
exports. The 465s run exceeds the soft 300s target. Runtime performance passes:
night tick 595us/8,333us, path rebuild 5,601us/33,333us. No GPU benchmark is claimed.

Map/version changes intentionally move sim hash 1961000123 -> 3960053733 and data
hash 407837701 -> 3913993875. These remain stable through the final eye, camera
and ambient revisions. Five Main scene captures (noon, dusk, wave, result, tech)
are in `implementation/shots/world-visibility/`, with 3x copies here. Their HUD,
lighting and occupied cells remain coherent; the pre-existing crowded crop/log
overlay and untranslated tech/result labels remain outside this follow-up.
