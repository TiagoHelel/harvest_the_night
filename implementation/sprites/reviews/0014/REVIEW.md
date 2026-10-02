# 0014 visual and integration review

Reviewed 2026-10-01 at native size and exact nearest 3x. The 42 actual 480x270
Godot captures are indexed in `capture-index.json`; `captures-00..20{,-3x}.png`
place labels outside the captured pixels. Capture mode passed 3,353 assertions
including actual farmer occlusion and mine/actor overlap. Headless mode passed
3,275 assertions. Full verify and fault-suite evidence is saved alongside this
review; final source/capture hashes are in `scope-and-sources.json` and
`frame-review.json`.

## Source decisions

Sixteen built-in ImageGen calls returned retained raw files. No creative pixels
were drawn with Python. Exact submitted prompts, reference hashes, tool arguments,
return locations, alpha measurements and selected roles are in `generation/0014-*`.
Each wall/fence whole asset used exactly three targeted revisions; each hurt
asset used one. Barricade and mine each used an identity master and one state
strip, without revisions. No revision budget was exceeded.

Whole-r3 post/front modules establish taller contacts and broad construction.
Whole-r2 vertical/wreck modules remain selected for their thin north/south
projection and low rubble. Hurt-r1 chipped post/front modules expose broad broken
construction outside the center post; initial hurt retains the vertical break.
Eight sheet selections are partial, rather than treating all returned modules
as accepted. Four unused early candidates keep their original rejection reasons.
Prior full-family rejections of r2 remain recorded separately from the later
partial vertical/wreck acceptance. Both trap masters are immutable references;
their strips own runtime art.

Opened all 20 selected source cuts and two trap masters against light, dark and
checker backgrounds. Source edge haze is thresholded at 128; runtime alpha is
strictly binary. Native conversion uses measured bounds, one shared material
scale, nearest samples and the existing palette. The returned post/front height
is lower than the ideal initial brief after reduction; actual native bounds are
recorded, not represented as the requested 12-pixel front or 28-pixel projection.
The selected taller posts and structural breaks pass the actual native review.

## Visual gates

| Gate | Result and evidence |
|---|---|
| Material and camera | PASS: capped grey masonry, violet mortar, warm timber, dark iron bands, shared upper-left light and thin north/south projection. Light/dark/checker native sheets show all 64 joined states. |
| All joins | PASS: isolated posts, four ends, straight spans, corners, T and cross shapes meet actual occupied neighbors. Every whole/hurt mask appears under day, dusk and night. Mixed stone/wood seams remain joined; no decorative neighboring post marks an empty cell. |
| Damage | PASS: chipped cap and displaced masonry / snapped rails and split post. Native whole/hurt shapes differ without bars. Source cuts show broad damage; the center contact does not hide the whole break. No procedural pinholes or damage tint replaces authored construction. |
| Collapse | PASS: stone, timber and barricade wrecks lie low on their actual destroyed cells. The cell is passable. Saved rubble renders honestly and morning removes it without an invented grid change. |
| Placement and route | PASS: all four legal one-cell previews use matching contacts. A stationary ghost responds to neighbor removal. Existing predicted-route query restores every state byte and its dots remain visible. |
| Mine | PASS: low pressure disc, short depressed/spark trigger, split spent casing. Actual Traps consumption draws once at the original cell; sold or damaged mines do not acquire a false burst. Armed plate sits above a mature corn plot and beneath opaque actor boots. Real pixel comparison requires at least four overlapping actor pixels, zero paint-over and at least three visible exposed mine pixels. |
| Depth and palette | PASS: connected wall obscures farmer only behind its ground contact. Day/dusk/native night scenes retain occupied silhouettes and material difference. Mixed perimeter uses the existing farmhouse/tower atmosphere without changing shaders. |
| Lifecycle | PASS: loaded saves invent no old burst. Rearm, old rubble/old loss receipts, same-count replacement, sale/upgrade precedence, ambiguous external removal, 4x fixed ticks, seven-trigger overflow and expiry are covered. At most six transient drawings survive in the view. |
| Original game views | PASS: noon, dusk, wave, result and tech opened at native and 3x; the new north/south fence is visible in the actual wave. Existing UI and normal enemies are retained for their queued tasks. |

The 84 exact outputs comprise 64 whole/hurt connected masks, twelve source module
inputs, two barrier wrecks, three barricade states and three mine states. Joined
cells use 16x32 canvas / (8,28) pivot / (0,-12) cell offset. Barricade uses
16x24/(8,20), mine 16x16/(8,14). Source-owned composition performs bounded cuts
and alpha-over only; it adds no colors or painted connections. Each material
retains a single scale across every selected whole/hurt/wreck module.

## Verification and boundaries

The initial full run found two legacy art assumptions (alpha must always shrink
under damage/collapse) and an undocumented integer-key sort. Updated authored
barrier assertions require distinct same-canvas standing construction and low
collapsed height; the legacy branch and every rule/hash/input guard remain.
The numeric occupancy-index ordering is now documented beside the sort.
`verify-initial.log` retains those findings; `verify.log` records the final run.
The assertion's type-inference failure was corrected with an explicit bool;
`verify-parse-fix.log` retains that interrupted iteration. Final full verify:
43 passed, zero skipped/failed in 281s, 107 parsed scripts, 6,610 rule assertions,
982 input cases and Windows/Web exports. Simulation 1961000123 and data
407837701 remain unchanged. The final source check additionally requires a
different whole/hurt alpha shape for every mask, rejecting mere tint changes.
All 90 fault/rebuild probes pass and restore their temporary corruption.

Source checking proves exact bytes for every output, all masks, exposed damage,
common scales/contacts and mixed-material boundary overlap. Fault probes run
separately from import/editor/verify, restoring every deliberate corruption.
The audit compares against `4567753`: ten old PNGs changed, 74 added, all 278
other runtime PNGs and protected simulation/save/palette/player/source files
preserved. All 232 previous manifest entries remain byte-for-byte equivalent.
The 293 protected baseline files are unchanged. The staged audit also verifies
118 hashed source/prompt/reference/runtime blobs; scoped Git attributes preserve
the exact saved CRLF prompt bytes instead of silently normalizing them.

These are authored join/damage/outcome drawings. The mine cue plays triggered
for 0.16s, spent for 0.24s, then expires; no continuous trap or wall animation
is claimed. Loaded saves retain only the original rubble family. Normal enemy
masters/motion follow in 0015; Giant/death playback in 0016; shared final night
atmosphere in 0019. No gameplay, collision, balance, save format or RNG changed.
