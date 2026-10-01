# 0005 — Player work actions

Accepted on 2026-10-01. All task gates pass. Sources and runtime frames are
complete; the remaining player reactions belong to 0006.

## Authored family and visual gates

Thirteen separate four-frame strips produce 52 distinct 48x48 runtime frames.
There are no work-action aliases and no one-frame craft placeholder. West is
authored, east mirrors it, and north/south deliberately use the documented
side-on work pose. This is not four-direction action source art.

| Animation | Reviewed gesture | Result |
|---|---|---|
| chop | Raised broad axe, left contact, follow-through, recovery | PASS |
| mine | Pick swing with pointed head, low contact and recovery | PASS |
| till | Hoe lowered to the soil, low pull and recovery | PASS |
| plant | Crouch, hand planting seeds, rising and recovery | PASS |
| water | Compact watering can, pour, return and ready pose | PASS |
| fish | Compact rod casting arc and follow-through | PASS |
| reel | Straight held rod and distinct winding/pulling hands | PASS |
| harvest | Reach down, gather into basket, lift and recover | PASS |
| carry | Small crate and four distinct balancing/arm poses | PASS |
| craft | Hands assemble a small wooden part, separate from repair | PASS |
| trade | Hand/coin transaction at the shop | PASS |
| collect | Reach down and lift a small milk pail, without a spout | PASS |
| repair | Compact hammer strike, follow-through and recovery | PASS |

The farmer retains the approved hat, face, overalls, boots and warm skin.
Tools fit the common canvas without shrinking the body or centering on the
combined tool bounds. Feet remain at (24,44). One common scale per source
strip sets the standing recovery body to 30 px; natural crouching poses are
shorter. Measured crop/boot anchors and source hashes are frozen in
`measured-contract.json`. The importer uses nearest sampling, alpha threshold
128 and the existing shared palette. No frame is independently stretched.

All 13 raw source alpha pages were opened on light/dark/checker backgrounds.
All 12 native/3x alpha sheets and all 16 native/3x west/east phase sheets were
opened. Silhouettes, transparent edges, tool attachment and canvas clearance
pass. The approved owner sheet and identity references were also inspected.

All 109 actual Godot captures were opened at native size and nearest 3x on
`captures-00` through `captures-27`: five noon/dusk/wave/result/tech captures
and 104 work captures covering every frame of all 13 animations in west/east.
The final 3x pages were inspected at their original 2880x1728 dimensions.
`frame-review.json` enumerates the captures and native bounds. `work-0.gif`
and `work-1.gif` illustrate the committed pixels at a fixed 90 ms per frame;
they are contact previews, not recordings of actual gameplay timing.

Existing depth sorting naturally hides part of the axe/farmer under tree
canopies and part of hands/crate behind the workshop on its occluded side.
Exposed-side captures show the complete tools and gestures; this is scene
overlap, not truncated source pixels. Retain the frozen ground pivots and
repeat these contacts when trees and stations are replaced in 0009/0012.
Existing ground noise and night bloom remain the 0007/0019 follow-ups.

## Provenance and ownership

Built-in ImageGen made 15 actual calls: 13 accepted sources and two preserved
rejected fishing candidates. The first rod exceeded available canvas space;
the first revision still needed 27 left pixels where 24 were available. The
second targeted revision shortened the third-pose rod to fit. No other action
needed a revision; no asset exceeded the three-revision limit.

Accepted raw sources are `assets/art_source/player/{animation}.png`.
Rejected files are `assets/art_source/player/candidates/fish-r{0,1}.png`.
Exact prompts, references, returned paths, decisions and source SHA-256 values
are in `generation/0005-generations.json` and the 15 individual call/prompt
records. Source copies were checked against the actual returned tool files.
The original identity masters, owner sheet and original prompt sources remain
intact. No API/CLI fallback or code-drawn replacement art was used.

The 52 work outputs replace 21 old files and add 31. Ownership now covers
88 raster, four remaining legacy player reaction and 156 ASCII outputs:
248 exclusively owned runtime PNGs. Deterministic rebuilds are byte-identical;
legacy writers cannot overwrite any migrated raster file. Metadata declares
four frames, common canvas/feet and non-looping 0.09 s authored timing for
every work strip. Carry is a presentation cue outside the twelve core verbs.

## Runtime and behavioral gates

`PlayerWork` observes the unchanged fixed simulation ticks before/after each
tick through `SimDriver` signals. Active timed work holds anticipation;
contact begins on the existing completion tick, including repeated actions.
Follow-through and recovery are finite. Fast three-tick repair shortens its
presentation phases to fit within the existing cycle. Instant water/reel/trade
start at contact and finish with the ready frame. Invalid requests do not
manufacture fishing/shop cues. A nearby real station delivery can show carry;
it creates no new crate, inventory rule or core verb.

All twelve known verbs bind to their own animations. Idle/walk, cancellation,
replacement actions and dusk clear stale work; repair also works at night.
The fixture drives actual Player.tick/Sim.tick and the actual PlayerView,
checks all phases and facing bindings, compares complete serialized state
before/after observers/rendering, tests mid-action cancellation for every
timed verb, and compares a 4x SimDriver batch against unchanged Sim.advance.
Real station production and repeated three-tick repair are exercised.
Rendering at higher speeds may expose fewer intermediate video frames;
simulation timing and completion are unchanged.

## Verification evidence

| Check | Result | Evidence |
|---|---|---|
| Full verification, including Windows/Web exports | 27 passed, 0 skipped/failed, 195 s | `verify-full.log` |
| Script parsing | 105 scripts, 0 failed | `verify-full.log` |
| Headless suite and inputs | 6609 assertions; 980 cases; 0 failed | `verify-full.log` |
| Work fixture, headless | 3749 checks, 0 failed | `work-check.log` |
| Work fixture, real renderer | 3957 checks, 0 failed; 104 captures | `work-capture.log` |
| Base captures | 5 captures, 0 failed | `captures.log` |
| Ownership/rebuild/fault guards | 22 probes pass; all corruption restored | `fault-check.log`, `fault-probes.json` |
| Raster check | 88 outputs, metadata verified, 0 writes | `verify-full.log` |
| Existing placement/locomotion | 476 / 468 checks, 0 failed | `verify-full.log` |
| Simulation/data hashes | 1961000123 / 407837701, unchanged | `verify-full.log` |

Core simulation, balance, grid/collision footprints, save formats and expected
hash baselines were not changed. Detailed source SHA-256 values remain in the
generation registry and manifest. The next sprite task is 0006.
