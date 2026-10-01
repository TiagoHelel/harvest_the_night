# 0010 crop growth and watered soil review

Date: 2026-10-01. Built-in ImageGen produced five accepted sources and zero
targeted revisions: three independent four-stage plant strips and two matching
soil materials. Sources are in `assets/art_source/crops/`; exact prompts, tool
return paths, reference hashes, measured recipes and decisions are in
`implementation/sprites/generation/0010-*`. All fourteen runtime filenames are
preserved. No runtime art or source silhouettes were painted by code.

## Visual criteria

All twelve stages were opened at native size and nearest 3x on light, dark and
checker backgrounds, with each stage composited over dry and wet soil. All five
source alpha comparisons and both 8x8 repeat-material patches were inspected.
Native wheat heights are 2/4/8/12; corn 2/4/11/20; carrot 2/4/6/9. Seeds, shoots,
growing plants and ready silhouettes progress without independent stage fitting.
Ready wheat reads by golden heads, corn by its taller broad-leaf stalk and cobs,
and carrot by its low feathery top and orange shoulders, without UI labels.
Alpha is binary at runtime, with side/top margins and no detached background.

Every corn stage shares a 16x24 canvas/(8,22) pivot. Its mature 20-pixel body
overhangs the logical cell upward by four pixels. Wheat/carrot are 16x16/(8,14);
soils are opaque 16x16/(8,16). Dense beds retain readable neighboring cells and
furrow cues; ground-layer plants remain beneath actors. Existing crop walkability
and all one-cell logical contacts survive maturity, watering and harvest.

The original four-color soil import reduced the wet cue too far (16.97 RGB
brightness difference). Both materials now use the same five approved brown/
shadow keys, including the existing ink color, giving a 28.40-point difference
and passing the unchanged 20-point
guard without generating a replacement. `initial-soil-conversion.json` and the
byte-exact duplicate `candidates/tilled_wet-r0.png` preserve this import evidence.
It is not a rejected or revised ImageGen master.

## Actual Godot views and farming behavior

Opened all 41 actual 480x270 captures at native size and exact nearest 3x:
`captures-00..10.png` and split columns `captures-00..10-3x-{0,1}.png` avoid
image-viewer reduction. The last right column is empty. Capture paths and SHA256
are in `frame-review.json`; originals are in
`implementation/shots/sprites/0010/` and `crops/`.

The 36 crop views cover the 3x4 dry/wet matrix, sixty ready crops in adjacent
beds, real watering under all three mature species, harvest removal, actual
Farming.tick maturity and the unchanged production farm in four light states.
The five Main views cover noon/dusk/wave/result/tech; 0009/0010 noon/dusk/wave
comparisons were also opened. Dawn/day/dusk/native night silhouettes remain
distinct, with dark wet channels still visible below the canopy. The normal
production-farm camera clips the far northern crop row; the dedicated matrix
and bed views cover every plant fully.

Capture mode asserts at least 50 changed actual viewport pixels when watering
each mature crop. All twelve comparisons pass: carrot 151, corn 113 and wheat
159 changed pixels in each light mode. Offline exposed dry/wet pixels range
151..251 across stages. Real watering spends one can unit, leaves the same stage
and ground anchor, then restores the complete fixture state. The `watered_light`
views show the restored matrix after these isolated interactions; individual
`moisture_light` views show each actual watering result. Real harvest adds the
unchanged yield, removes only the plant and leaves dry furrows. Actual growth
reaches maturity with unchanged rates. Redraws never change saved/core state.

Headless crop showcase: 6,224 checks, zero failed. Actual renderer: 9,248 checks,
zero failed. Fault/rebuild suite: 53 probes pass, deliberate corruption restored,
including missing ripe corn/wet soil, corrupt raw corn, scale and pivot drift.
Full verification: 35 passed, zero skipped/failed in 236 seconds with Godot
4.7.1 from the user's supplied folder. All 105 scripts parse; 6,609 core
assertions and 980 input cases pass, with performance and Windows/Web exports.
Simulation hash 1961000123 and data hash 407837701 remain unchanged. The raster
check reports 144 exact outputs and zero files written. Full results and scope
are recorded in `verify.log`, `runtime-delta.json` and `soil-metrics.json`.

## Scope and follow-ups

Exactly fourteen existing crop PNGs change; the other 246 remain byte-identical
to `18b4b3e`. Ownership becomes 144 raster / 116 ASCII / zero player-sheet,
260 PNGs. Core/FARM_MAP, collision, growth, yields, balance, saves, determinism
guards, owner's original sheet, PlayerFrames, props, terrain and palette remain
unchanged. Only source-driven ground placement and visual verification are added.
Shared lighting/palette refinement is 0019; zombie walk/attack/death is 0015 and
Giant/death playback is 0016. This task adds static growth states, not sway.
