# 0017 - Combat and work effects

Reviewed on 2026-10-02. Existing completed sprites are preserved. This task
adds seven missing effect families and adjusts their playback and layering.

## Sources and conversion

Seven built-in ImageGen calls, zero revisions, produced exact preserved raw
returns in `assets/art_source/effects/`: muzzle, impact, flame, smoke, dust,
splash and flare. Exact prompts, submitted arguments, returned paths, reference
hashes, source hashes and measured cuts are under `generation/0017-*`.
All seven sources were opened. Conversion only crops, resamples nearest,
maps the existing palette and resolves binary alpha; it paints no missing art.
The manifest adds 25 distinct one-shot frames with a shared scale per strip.

| Family | Frames | Canvas | Pivot | Seconds/frame | Peak visible height |
| --- | ---: | --- | --- | ---: | ---: |
| Muzzle | 3 | 12x12 | 6,6 | 0.065 | 8 |
| Impact | 3 | 12x12 | 6,6 | 0.065 | 9 |
| Flame | 4 | 16x20 | 8,18 | 0.14 | 15 |
| Smoke | 4 | 16x20 | 8,18 | 0.14 | 12 |
| Dust | 3 | 16x12 | 8,10 | 0.10 | 7 |
| Splash | 4 | 20x16 | 10,14 | 0.10 | 12 |
| Flare | 4 | 24x24 | 12,12 | 0.10 | 18 |

Ownership is 417 raster / 29 ASCII / zero player-sheet, 446 runtime PNGs.
All 392 previous manifest entries are unchanged. `audit.py` against `4f42da7`
proves 1,153 previous art/core files unchanged and all seven raw returns exact.
The staged audit also checks seven sources, seven prompts and 25 runtime PNGs
against worktree bytes. No core, palette or hash baseline changed.

## Runtime and actual rendering

Fixed-tick before/after observation emits at measured tower outlets, actual
hits, newly burning enemies, real flare use and completed player work. Borrowed
coordinates are released after each tick; records retain only view values.
Duplicate callbacks and skipped tick gaps cannot invent extra contacts.
Periodic chimney/wreck smoke and bounded burning cues supplement useful cheap
procedural particles. Existing authored enemy deaths own their playback;
the legacy corpse overlay no longer duplicates them in WorldView.

At most 24 reusable raster sprites share the existing particle capacity with
procedural pixels. Dust and water use the ground layer below actors. Lazy
binding handles Main's child-before-parent ready order; removing the emitter
releases its borrowed ground children. Actual rendered comparisons confirm
zero changed opaque player/tool pixels in all five work peak captures.

The initial crowded burning view exposed overlapping bright halo bands.
Existing halos now have a maximum of 12 separated centers and lower intensity;
flame sources remain unchanged. Rejected views are in `pre-halo-limit/`.
Final 75-enemy ignition/burning/flare views have localized warm cores, subdued
smoke and no broad additive wash. Simultaneous deaths play once and expire.
Night frame-1 hide/show comparisons retain warm pixels for muzzle (3), flame
(3) and flare (2); smoke mean rendered luma is 0.175. Full source-visible pixel
counts and rendered measurements are in the effects capture JSON reports.

Live Settings tests verify half density, immediate zero/off, smaller capacity,
steady silhouettes without fragment motion, state replacement and unchanged
serialized rules. Full/half/off 90-tick simulations are identical. The 100-actor
stress case fills 24 raster slots within the shared 420 limit: 240 samples,
525us view-update p95 against 16,000us, unchanged state. This measures CPU view
updates, not GPU rendering; `effects/effect-perf.json` records that limitation.

## Verification and visual evidence

Final full `verify-accepted.log`: 49 passed, zero skipped/failed in 368 seconds.
The soft 300-second target reports OVER BUDGET without failing. Godot 4.7.1
parses all 113 scripts; 6,613 rule assertions, 982 input cases, performance and
Windows/Web exports pass. Sim hash `1961000123`, data hash `407837701`, unchanged.
The raster check reproduces 417 outputs with zero writes. Tower outlet checks
pass 1,305 assertions; effects headless passes 2,997; actual capture passes
3,156. The old tower regression was corrected to check the authored forms at
the same outlets rather than require three procedural sparks. Initial failed
logs remain for traceability; no guard was disabled or hash accepted.

Opened all six light/dark/checker animation sheets at native size and exact
nearest 3x. Reviewed all 42 actual 480x270 captures and their nearest 3x views
on 21 review pages, including every family phase, day/night, tower contact and
dissipation, chimney smoke, harvest/water/chop/mine/fish contact and peak,
crowded ignition/fire/flare, four death phases/expiry and accessibility.
Changed pages were reopened after final capture; capture hashes record the
revisions. Critical crowded and work views were also opened directly at 480x270.
All selected task criteria pass. Shared night cloth darkening remains a 0019
atmosphere follow-up using current art; it does not require sprite regeneration.

Exactly one sprite task completed this cycle. Queue: 17 done, 3 todo, zero
doing/blocked. Next is 0018. No push or unattended automation was started.
