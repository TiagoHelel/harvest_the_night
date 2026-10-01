# 0012 - Full farm station review

Reviewed on 2026-10-01 with Godot 4.7.1 from the user's supplied folder.
Ten built-in ImageGen calls produced six identity masters and four short
idle/active/hurt strips. All raw sources equal their original tool returns.
Exact prompts, reference hashes and revision-zero decisions are retained in
`../../generation/0012-*`. No creative pixels were painted or synthesized by
the import scripts. Crops, common family scales, lower-base measurements,
nearest reduction, binary alpha and palette conversion are deterministic.

## Visual decisions

| Criterion | Decision and observed evidence |
| --- | --- |
| Function without labels | PASS: workshop bench/tools and furnace; kitchen cookware/front oven; open tall screw/lever press; low flywheel/metal engine; blue/cream awning counter; stone-rim hoist/bucket well. |
| Shared materials/perspective | PASS: upper-left light, terracotta/timber/stone and ink contours match the accepted house. Generator has metal rather than another roof; press retains its open construction. |
| Relative scale | PASS: native/3x ground-aligned sheet compares all six stations with the 64px farmhouse and 30px farmer. House remains the largest roof. Four production canvases share 48x48/(24,44); shop 32x40/(16,36), well 24x32/(12,30). |
| Transparent source and native output | PASS: all ten raw images viewed over light/dark/checker. Generator strip retains RGB beneath alpha zero; those invisible pixels are not a backdrop. Source alpha maxima 254/255 become unclipped binary native alpha at threshold 128. |
| Authored state distinction | PASS: all twelve production poses reviewed on three backgrounds and in four light states. Furnace/lid/lever/indicator cues distinguish actual activity; local missing roof/worn frame/metal damage remains readable. Each family shares a fixed reduction scale. |
| Working feedback | PASS: real paid jobs/fuel select working art; queue-only start/cancel changes the same cached sprites. Independent workshops can display different activity. Stalled/no-fuel stations stay idle. Hurt takes precedence, and running damaged stations can still emit their existing bounded effects. This task supplies static authored working poses, not continuous frame cycles. |
| Anchors, compatibility and interactions | PASS: six full drawings render once at unchanged bottom contacts. Sixteen old quarters reconstruct the four idle drawings exactly. Production remains 2x2; shop/well remain one cell; craft/repair/trade/water targets and neighboring walkability agree with the original core. |
| Depth, ghosts and edges | PASS: all six stations tested with real farmer and walker behind/in front, including actual opaque-pixel comparisons. Six build previews align with unchanged footprints. Four map corners preserve contacts and logical cells. |
| Day/night | PASS: dawn/day/dusk/night stay recognizable. Actual active furnace/engine off-to-steady pixel tests prove three local lights at authored pixels, without state writes. Idle/stalled jobs have no working glow; bright stove light remains local to the furnace. |

Opened all 53 actual 480x270 captures at native size and exact nearest 3x
through `captures-00..13.png` and their split `-3x-0/-3x-1` columns. These
include 12 family/light states, 24 actor depth crossings, six ghosts, two
queue-only transitions, independent jobs, two stalled states, damaged working
stations at night and five standard
game views. Originals are in `implementation/shots/sprites/0012/` and
`stations/`; `frame-review.json` records every capture hash. Final active-night
and standard views were reopened after correcting source-owned emission points.
Also opened all native state sheets over light/dark/checker, ten raw alpha
comparisons, six master previews, relative-scale sheets and emission overlay.

## Verification and preservation

Actual-render station showcase: 3,956 checks, zero failed. Capture mode adds
opaque-pixel and actual off/steady lamp checks to 3,804 headless fixture checks.
Source check proves all
thirty frame/quarter bytes, distinct states, fixed scale/contact, unclipped
binary alpha and opaque active emission points. The pipeline fault suite
passed all 68 probes and restored every deliberate corruption; six new probes
reject missing production strips/full drawings, stale quarters, missing active
kitchen and scale/contact drift. One additional in-memory probe rejects an
exhaust point outside the damaged generator, changing no disk assets (69
combined probes). Logs, `fault-probes.json` and `emission_probe.json` are retained here.

`scope-and-sources.json` audits baseline `b9f0298`: 20 existing runtime PNGs
changed, ten complete state PNGs added, all other 250 PNGs byte-identical.
All 229 protected baseline files remain identical, including core/map/save
rules, original owner/pilot and prior accepted sources, PlayerFrames, palette
and determinism guards. Previous unrelated manifest entries are unchanged.
Ten exact returned-source and prompt hashes, all native bounds, common scales
and fixed pivots are recorded. Ownership is 184 raster / 96 ASCII / zero
player-sheet, 280 runtime PNGs. Final full-verify results are recorded in the
progress journal and `verify.log`: 39 passed, zero skipped/failed in 287s,
105 parsed scripts, 6,610 rule assertions, 982 input cases, performance and
Windows/Web exports passing. Simulation/data guards remain
`1961000123` / `407837701`; raster rebuild writes zero files.

An initial complete verify passed all 39 checks in 247s. A later repeat found
the existing transition comparison could take extra automatic wall-clock ticks
while its helper also advanced 720 ticks by hand. An isolated input run
reproduced the differing hashes. The helper now disables/restores only the
automatic driver process during that manual comparison, resets through Main
so the views observe the same new dictionary, and asserts exactly 720 ticks
for both watched/skipped sequences. The hash comparison is retained. Failure
reporting now includes the actual failed assertion, rather than only a count.
The failed run and isolated log are preserved as `verify-second.log` and
`input-retry.log`; the final full result is `verify.log`.

The isolated input log also shows existing I18n relabel diagnostics. This task
does not modify localization or core rules; localization/UI work remains 0018.

Normal zombie generation/animation remains 0015; Giant and death playback
remain 0016. Shared final night lighting remains 0019.
