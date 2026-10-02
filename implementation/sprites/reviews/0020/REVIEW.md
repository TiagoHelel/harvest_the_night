# 0020 - Whole-game native visual audit

Reviewed 2026-10-02 with the user's Godot 4.7.1 Compatibility renderer.
This closes the complete sprite queue against the original twenty prompts.
Zero ImageGen calls, new masters or replaced runtime sprites in this cycle.
The user's completed-art preservation constraint is honored.

## Current visual evidence

`capture-index.json` covers 890 freshly rendered 480x270 images, not enlarged
window screenshots. All 648 new/changed images were opened on 167 pages with
native pixels above exact nearest 3x copies. `visual-review.json` records each
opened page's SHA-256 and concrete visual decision. Another 38 opened contact
pages cover every one of the 468 runtime outputs at native and nearest 3x.
All 205 required pages are accepted. QA labels are outside captured pixels.

`reused-review.json` accounts for 242 remaining views: decoded pixels match
their earlier accepted captures exactly; each prior capture remains identical
to committed `c03c169` bytes, appears in its family's saved review index and
resolves to an inspected native/3x review journal. Reuse counts: UI 36,
standard screens 35, effects 31, water 30, atmosphere 27, enemies 26,
stations 16, barriers 14, crops 12, towers 10, Giant 2, house 2, props 1.
No pixel difference is treated as prior acceptance.

| Final criterion | Decision and concrete evidence |
| --- | --- |
| Farm identity, perspective and scale | PASS. Placement/props/house/stations and ordinary noon/dusk/wave views retain the straw-hat farmer, full foliage, warm timber/terracotta roofs and quiet ground. House is the largest roof. Standing actors stay about 30px; larger transparent canvases provide pose clearance. |
| Source alpha, silhouettes and palette | PASS. All runtime contact sheets are opened; source hashes still match accepted family reviews, which include raw light/dark/checker comparisons. Raster edges are binary alpha and contours have no opaque backdrop. Complete frame strips preserve fixed scale/feet. Native visible bounds and source lineage are catalogued. |
| All work verbs and facings | PASS. 208 actual work frames: thirteen gestures x four frames x south/west/north/east. Axe, pick and hoe have distinct tool silhouettes; plant/harvest/pail/craft/hammer/crate/transaction/rod gestures retain their purpose. Correct targets change through real core ticks. Feet stay planted. North/south intentionally use side-on work, east mirrors west. Natural tree/roof/awning occlusion is retained. Instant water/reel/trade begin at contact, then return to ready. Cancellation, movement and fast repair remain checked. |
| Locomotion and reactions | PASS. 36 locomotion and 64 reaction views cover four facings, diagonals, release/turn, idle loops, four symbols, actual events/lifetime, all map corners, split-body equivalence and suppression during work/walking. Glyphs fit the viewport; bodies keep their existing natural boundary clipping. No duplicate glyph/shadow. |
| Ground, water and corners | PASS. 30 terrain and 45 water views cover eight quiet materials, repeated patches, all 16 cardinal masks, convex/concave caps, compound joins and jetty. Banks stay static; only restrained ripples move. Actual production TileSet trace is A/B/C/A/B/C over 136 frames in 4.409s, with unchanged state. |
| Props, removal and density | PASS. 48 views cover paired canopies/mineral forms, fifteen-tree overlap, livestock, partial/final harvesting, removals and real regrowth. Farmer/walker cross both tree variants correctly; stumps remain at trunk contacts. Cow and hen have distinct native forms. |
| Dense crop beds | PASS. 36 views cover three species x four stages, dry/wet soil, sixty adjacent ready crops, real watering/growth/harvest and four light states. Golden wheat, taller corn and low carrot remain distinct. Wet furrows stay exposed; plants remain below actors. |
| Every structure, level and state | PASS. House 44, stations 48, towers 24 and barriers 37 views. Whole/hurt house has one coherent roof over the same 3x3 base and five aligned window cores. Six stations have distinct functions; paid/stalled/hurt activity follows existing state. Four towers x three levels x four states show construction changes, matching mouths/ghosts and low wrecks. All sixteen joined wall/fence masks, barricades and armed/triggered/spent mines keep their legal cells and actor depth. |
| Mixed enemies and Giant | PASS. 29 ordinary and 44 Giant views cover four distinct silhouettes, both horizontal facings, real walks/attacks, hurt and mixed night waves. Giant's raised fist clearly differs from walking; the actual warning remains visible above the house. Source bodies retain accepted scale; no core attack timing is invented. |
| Death playback and crowded effects | PASS. All five families fall once at their final observed coordinates and expire. Stress removes 64 entities with a hard 24-cue cap. 37 effect views cover seven one-shot families, real outlets/work, 75 ignitions/deaths, subdued smoke, localized warm fire and density/flashing controls. Ground effects do not cover opaque player/tool pixels. |
| Menus, locales, themes and accessibility | PASS. 64 standard/title views and 36 UI fixture views cover English/pt-BR, normal/high contrast, fifteen icons at 16/10px, hover/pressed/disabled/focus, inventory/shop, tech/result, pause, four options tabs and title/error states. Captures fit the viewport. Existing untranslated result/tech labels remain a recorded content limit. |
| Shared reality switch | PASS. All 27 atmosphere views are exactly identical to accepted final 0019 captures. Same-object dawn/day/dusk/night, both transitions, interrupted reversal, lamps off, quality 0/1/2, reduced flashing/density/motion and skipped transition remain covered. Pale clothes/crops receive ambient light; warm cores belong to fire/windows. |

## Requirement audit across the original queue

The family reviews below are accepted historical production evidence, supplemented
by the current all-family source/runtime gates and fresh final rendering. Early
provisional player/enemy/building forms are superseded by their later authored
families; those historical placeholders are not counted as final deliverables.
`requirements-coverage.json` preserves every original requirement and done gate
verbatim, with the concrete evidence assessment and hashed review/verification.

| Prompt | Requirements and authoritative evidence |
| --- | --- |
| 0001 | Baseline PNG encoding normalization, day/night studies, four identity masters, exact prompts/hashes and frozen scale: `../0001/REVIEW.md`, generation/0001 record, master-contract.json and progress journal; final references/core are preserved. |
| 0002 | Manifest, measured conversion, generated metadata, one-owner dispatch and migrated derivatives: current raster/legacy/cutter gates, catalogue and clean rebuild. `../0002/fault-probes.json` proves 19 rejection/rebuild probes with corruption restored; later `../0014/fault-probes.json` extends to 90. Original sheets are preserved. |
| 0003 | Ground pivots, nested sorting, single building anchors, shadows, lamps, ghosts, bounds and deterministic showcases: current placement captures and 542 actual renderer checks; `../0003/REVIEW.md`. |
| 0004 | Authored south/north/west 3-frame idle and 4-frame walk; east mirror, diagonal/turn/cancel and strict missing-frame behavior: catalogue, locomotion views, 540 renderer checks and `../0004/REVIEW.md`. |
| 0005 | Thirteen purposeful 4-frame strips, no work aliases, existing contact timing and cancellation: current complete four-facing work matrix, 7,813 renderer checks, PlayerWork/PlayerView and `../0005/REVIEW.md`. |
| 0006 | Four existing reactions, idle suppression, bounded glyphs and one separate contact shadow: reaction captures, 828 renderer checks and `../0006/REVIEW.md`. Heart availability does not invent a trigger. |
| 0007 | Four grass choices plus soil/path/floor/rock, exact 16px tiles/atlas and unchanged map: terrain captures, 19,669 renderer checks, source/atlas gate and `../0007/REVIEW.md`. |
| 0008 | Three water phases, all cardinal masks/diagonal caps/compound joins and jetty: water captures/automatic-loop.json, 2,288 renderer checks, exact source atlas and `../0008/REVIEW.md`. |
| 0009 | Full trees/stumps, mineral/animal masters, cell-selected variants without RNG and actual gathering/removal: props captures, 8,643 renderer checks and `../0009/REVIEW.md`. Decorative motion was optional. |
| 0010 | Three crops x four stages, dry/wet soil and grounded tall corn: dense/stage/moisture captures, 9,248 renderer checks, source/moisture gate and `../0010/REVIEW.md`. |
| 0011 | Full house/independent damage, unchanged 3x3 footprint, aligned five glass lamps and HP wear: house views, 1,193 renderer checks, eighteen exact slices and `../0011/REVIEW.md`. |
| 0012 | Six functional station masters, four idle/active/hurt families and coherent quarters/interaction targets: station views, 3,956 renderer checks, sixteen exact quarters and `../0012/REVIEW.md`. |
| 0013 | Four tower families x three structural levels x whole/hurt/fire/wreck, measured mouths and complete legacy replacement: tower views, 1,356 renderer checks, 48 authored cuts/39 outlets and `../0013/REVIEW.md`. |
| 0014 | All joined occupancy masks, authored breaks/low ruins, barricades and mine lifecycle: barrier views, 3,353 renderer checks, 84 source-owned outputs and `../0014/REVIEW.md`. |
| 0015 | Four enemy masters with 4/3/4 motion, real observed movement/targets and explicit aliases: enemy views, 2,040 renderer checks, 48 authored poses/twelve exact aliases and `../0015/REVIEW.md`. |
| 0016 | Giant master/4 walk/3 wind-up/3 slam/5 death and actual one-shot ordinary/Giant removal: Giant views, 2,530 renderer checks, EnemyMotion/EnemyDeaths, four exact aliases and `../0016/REVIEW.md`. |
| 0017 | Seven small FX families, source outlets, bounded/shared capacity, reduced motion/density and unchanged rules: effect views, 3,156 renderer checks, effect-perf.json and `../0017/REVIEW.md`. |
| 0018 | All fifteen material icons, native HUD sizes, nine-patch/button/tab/check/slider states and locale/theme fit: UI/standard/title views, 10,548 renderer checks, thirty icon cuts/nineteen UI sources and `../0018/REVIEW.md`. |
| 0019 | Shared palette/ambient ramps, localized emission, same-farm reality change and transition/a11y: final atmosphere views, 300 renderer checks, palette/emission probes and `../0019/REVIEW.md`; all accepted images preserved. |
| 0020 | Full farm and every above family/state, clean offline reproduction, catalogue/contact sheets and concrete limits: current review ledger, reused-review proof, catalogue, clean-rebuild.json, completion-audit.json, DELIVERY.md and verify.log. |

## Reproduction, verification and scope

`clean-rebuild.json` records two normal offline import/generate/cut cycles in a
clean checkout of `c03c169`: 1,283 tracked sources/art/metadata files, identical
bytes, zero outputs written, initially/finally clean. The temporary managed
worktree has been archived. Current runtime art and rebuild recipes still match
that commit. The catalogue covers 447 raster and 21 ASCII outputs, sixteen
byte-exact compatibility aliases, every canvas/pivot/frame and source link.
The unused legacy actors/placeholder.png has no src/scenes reference. No required
family falls back to it; all actual fixtures assert their required textures.

`verify.log`: **52 passed, zero skipped/failed in 431s**, including Windows/Web
exports (35.6s), 115 script parses, 6,646 rule assertions and 982 input cases.
Sim **1961000123** and data **407837701** remain unchanged from planning.
The 300s soft verification duration target is exceeded; no test gate fails.
Night tick is 549us/8,333us and path rebuild 4,260us/33,333us. The captured
100-burning-actor FX case uses 24 raster slots inside the 420 shared limit;
240 samples give CPU view-update p95 532us/16,000us. GPU cost is not measured.

Two verification-fixture corrections complete coverage without editing art:
work now exercises all four gameplay facings instead of west/east only; the
automatic water test observes six actual phase changes with a 12s failure bound
instead of assuming a loaded renderer completes them within 3.8s. Production
550ms water timing is unchanged. The initial five-phase failure and its trace
remain saved; the final six-phase run passes. All 25 sequential renderer command
runs succeed without script errors. Settings/save isolation is preserved.

Core, grid, collisions, save format, balance, project resolution and both owner
reference files remain unchanged against planning. Original raw sources,
submitted prompts and generation records are preserved. Runtime/view code has
not changed after the final full verification; only closeout evidence/docs follow.

## Explicit limits

Trees, animals, banks and crop stages are static. Work north/south uses accepted
side poses; enemies retain horizontal facing while moving vertically. Station
activity and tower fire are authored state/event drawings, not continuous loops.
The native viewport limits face/tool detail; enlarging a window cannot recover
discarded pixels. Natural roof/canopy and map-edge clipping is preserved.
Loaded tower ruins use their family's L1 form because saves carry no level.
These are documented choices, not missing promised sprite families. No unresolved
visual-contract gate remains. This is a prototype art delivery, not a shipping
or localization-completeness claim.
