# Accepted art sources

`masters/` contains task 0001's accepted ImageGen identity/style references:
`farmer.png`, `house.png`, `tree.png`, `walker.png`, `style-day.png` and
`style-night.png`. Preserve these original generated pixels; regenerate variants
with the accepted master as a reference instead of repainting these files.

Task 0002 imports the four isolated masters into 18 runtime files: the farmer's
south idle, full house and all nine overhang-aware slices, tree, and walker with
its transitional legacy poses. Task 0003 validates playable pivots/depth sorting
and recuts the 43 unmigrated player frames to the accepted 30 px body scale.
Never overwrite `sprites/` with the large raw images.

Task 0004 replaces the pilot south idle and migrates the remaining locomotion
frames with six authored strips in `player/`: south/north/west idle (three each)
and walk (four each). East mirrors west. All 21 frames are distinct native
cuts on 48x48 with feet at (24,44), 30 px visible height and 20–22 px width.
Task 0005 migrates work to thirteen four-frame strips: chop, mine, till,
plant, water, fish, reel, harvest, carry, craft, trade, collect and repair.
All core verbs have separate art; carry illustrates an existing nearby station
delivery. West is authored, east mirrors west, north/south work uses side art.
Task 0006 replaces the final four reaction frames with authored south poses
and distinct bang/question/note/heart glyphs, plus a separate compact shadow.
The registry now assigns 93 outputs to raster, zero to the owner-sheet cutter
and 155 to ASCII. All 77 player pose frames have accepted raster ownership.

`ownership.json` registers all 248 PNGs with exactly one writer/checker: ASCII,
owner-sheet cutter, or raster importer. `manifest.json` describes every raster
output; `manifest.schema.json` documents its structure. `tools/import_art.py`
validates the structure plus actual image bounds, provenance, animation coverage,
ownership, palette/alpha, derivation cycles and exact runtime bytes. All four
masters retain their task-0001 hashes. Prompt/reference hashes are checked too.

```powershell
python tools/import_art.py           # offline deterministic rebuild + output hashes
python tools/import_art.py --check   # sources, outputs, ownership and view metadata
python tools/gen_sprites.py          # remaining ASCII sprites, atlas and palette sync
python tools/cut_sheet.py            # zero legacy writes; merged metadata still checked
python tools/check_art_pipeline.py   # fault probes; run outside concurrent builds
```

The importer produces `src/ui/raster_art.gd` from the recipes, including each
file's canvas, pivot, cell offset, optional native lamp/chimney points and
animation timing. It also owns `src/ui/player_frames.gd`, merging raster recipes
with the remaining sheet counts into strict COUNT/CANVAS/FEET/SECONDS metadata.
The cutter checks that same canonical table but never writes it. Rebuilds only write
changed bytes. Changing an accepted raw source first requires explicit approval
of its new source/reference hashes in the manifest; generation does not silently
approve an edited source. Recipe/palette changes update output hashes on rebuild.
`--check` never writes or approves anything.

House slices partition the full 64x64 master into columns 24/16/24 and rows
28/16/20. Generated offsets reconstruct it at (-8,-12) relative to its existing
48x48 footprint; no roof pixels are discarded. Task 0003 draws the full house
once at its ground anchor; slices remain checked compatibility outputs. Its
window/chimney points are (32,43)/(49,14) on the 64x64 source canvas. Shared
`ArtPlacement` consumes these points and ground pivots in the view layer.
Farmer idle/walk now use authored frames. Walker bob/reach/fall preserve the explicitly
documented old procedural motion using the new source; 0015 replaces them with
authored motion. These provisional recipes are not claimed as new animation.

When migrating a family, transfer every derived output to raster ownership and
add its recipes in the same change. Accepted terrain tiles feed the legacy atlas
builder through the importer, so atlas checks cannot keep stale ASCII tiles.
Unmigrated outputs keep their original strict byte checks. New output names must
be registered as well; missing/unregistered runtime PNGs fail the raster check.

`masters/master-contract.json` records measured source crop boxes, native review
dimensions, pivots and SHA-256. Exact prompts, reference roles and hashes are
under `implementation/sprites/generation/0001-*`; source review evidence is in
`implementation/sprites/reviews/0001/`.

To regenerate the task 0001 native review/contact sheets:

```powershell
python implementation/sprites/reviews/0001/build_preview.py
```

This does nearest reduction, fixed-canvas placement, binary alpha and mapping
to `tools/palette.py`. It writes review images only; it does not replace runtime
assets or implement the production importer. The original owner sheet in
`docs/sprites_sem_fundo.png` remains unchanged.

Task 0004's exact prompts and ImageGen attempts are in
`implementation/sprites/generation/0004-*`; `0004-generations.json` records
actual returned files, source SHA-256 and accepted/rejected reasons. Preserved
rejected strips live in `player/candidates/`. Native alpha/crop measurements
are in `implementation/sprites/reviews/0004/measured-contract.json`. Rebuild
QA with that folder's `build_review.py`; it never edits source/runtime pixels.
Use `python tools/show_art.py --locomotion --check` for state/facing/frame loops
and add `--out=implementation/shots/sprites/<task-id>/locomotion` for captures.

Task 0005 prompts/provenance are in `generation/0005-*` under the sprite
implementation folder. Fifteen built-in calls produced thirteen accepted strips
and two preserved rejected fishing candidates. `reviews/0005/measured-contract.json`
freezes actual source crops, standing body reference and boot source coordinates.
Each strip uses one body-based scale; `content_anchor_xy` places the boots,
independent of the full tool/line bounds. Do not scale the farmer down to fit a tool.
All 52 work outputs are distinct; canvas/pivot remain 48x48/(24,44).

`PlayerWork` observes the unchanged simulation ticks through read-only driver
signals. Timed actions hold anticipation, show contact on completion and expire
through follow-through/recovery. Return frames shorten for the existing fast
repair cadence. Water/reel/trade start at contact and finish in the ready pose;
movement/cancel remove every pending tool cue. No core/save timer was added.
`python tools/show_art.py --work --check` covers real verbs, both side facings,
completion, interruption, three-tick repeat repair, nearby delivery and exact
4x Sim.advance equivalence. Add an output directory for real-render captures.
`reviews/0005/build_review.py` composes native/3x alpha, phases and capture pages.

Task 0006 sources are `player/react_{bang,question,note,heart}.png` and
`player/shadow.png`. Six built-in calls produced five accepted sources; one
preserved exclamation candidate needed a targeted wider/straighter glyph with
a separated dot. Exact prompts and returned-file/source hashes are in
`implementation/sprites/generation/0006-*`. Body scale remains 30 px, feet
(24,44), canvas 48x48. The shadow is 20x8 with an 18x3 visible silhouette,
uniform palette color and binary alpha; the view supplies transparency.

Measured `bubble_xywh` crops cover every symbol pixel and zero body pixels.
The body shader masks that rectangle while a separate region sprite draws
the same source pixels exactly once, clamped to viewport margins without
moving the farmer. Reaction selection, idle-only suppression and lifetime
remain the existing core rules. `python tools/show_art.py --reactions --check`
checks state selection, suppression, lighting, anchors, four map corners and
shared shadow consumers. Add an output folder for captures and real-render
pixel equivalence of all four split reactions, plus localized shadow contrast.
`reviews/0006/build_review.py` composes actual captures at native/nearest-3x.

Task 0007 adds `terrain/{grass,grass_b,grass_c,grass_d,soil,path,floor,rock}.png`.
Twelve built-in calls produced eight accepted opaque sources and four preserved
rejected candidates. Exact prompts, reference roles, actual returned files and
hashes are under `implementation/sprites/generation/0007-*`. Ground stays 16x16
with pivot (8,16). Soil/path use measured 1152-square sampling crops so their
small connected source marks survive nearest reduction. All other tiles reduce
their full 1254-square source. No pixels are repainted or manually seam-repaired.

The atlas writer consumes these source recipes with a cache local to one build;
it revalidates source hashes on every invocation. `tools/check_terrain_art.py`
proves full native opacity, exact opposing/mixed grass borders, accepted tile
bytes and all 80 atlas cells. Existing water and both edge rows remain unchanged
until task 0008. `tools/show_art.py --terrain --check` covers production material
selection and native actors under Main's day/dusk/night relighting pipeline.

Task 0008 completes water and transitions with four accepted masters:
`terrain/water-loop.png`, `edge-n.png`, `shore-n.png` and `shore-corner-nw.png`.
Six returned ImageGen files include two preserved rejected bank/corner candidates;
exact prompts, references, revisions and returned-file hashes are in
`implementation/sprites/generation/0008-*`. A separate tiny grass-cap generation
returned no image. Its recorded resolution cuts the exact one-pixel endpoint of
the accepted grass fringe onto the native canvas; it invents no replacement art.

The three water crops share one 724-square scale, 16x16 canvas and (8,16) pivot.
Sides and corner caps use explicit clockwise quarter-turn recipes. The optional
`palette_keys` selects named colors from the existing project palette; water's
four approved cool blues preserve the dim returning phase. No palette was added.
`slice_canvas` validates its crop and placement and refuses clipping. Sources,
native PNGs, all atlas cells, side seams and corner contacts are checked exactly.
The unchanged 256x80 atlas places eight corner caps in previously empty row-zero
slots 6-13. Ownership is 120 raster / 136 ASCII / zero player-sheet, 256 PNGs.

`tools/show_art.py --water --check` covers all 16 cardinal masks, all diagonal
combinations, compound joins and production animation metadata without changing
serialized state. Real-render capture mode also measures two automatic water
loops with the original production TileSet. Review details and measured hashes
are in `implementation/sprites/reviews/0008/REVIEW.md`.

Task 0009 preserves the accepted pilot tree and adds ten raw prop sources in
`props/`: a second canopy, matching cut stump, two loose boulders, two layered
stone seams, two iron nodes, cow and hen. Exact built-in prompts/returned files
and hashes are under `implementation/sprites/generation/0009-*`. Static contour
variants share one scale per material; no source or runtime pixels are painted.
Trees retain 40x48/(20,44); resources/stumps use 16x16/(8,14), animals 24x24/(12,22).

WorldView chooses tree/rock/seam/ore variants with a fixed cell hash. The base
appears on 547 of 720 cells and the alternate on 173; selection survives redraw,
harvest and regrowth without consuming simulation RNG. Animals and trees remain
static in this task. `tools/check_prop_art.py` requires all eleven sources,
exact output bytes, distinct same-scale variations, clean alpha and contacts.
`tools/show_art.py --props --check` exercises actual harvesting, resource
regrowth, livestock collection and one-cell placement. Real-render mode adds
pixel comparisons of behind/front tree occlusion. The native/3x QA helper is
`implementation/sprites/reviews/0009/build_review.py`.

Task 0010 replaces every existing crop stage and both tilled-soil materials with
five immutable sources in `crops/`: wheat, corn and carrot four-stage strips,
dry earth and an edit of that same earth for moisture. The twelve plant cuts
use measured transparent gutters and one fixed reduction scale per species.
Wheat/carrot use 16x16/(8,14); corn uses 16x24/(8,22) in all four stages.
Soils use 16x16/(8,16), filling the logical cell. Ground-layer placement reads
these separate pivots through ArtPlacement, keeping plants beneath actors.

Exact prompts, returned files and all five generation records are saved under
`implementation/sprites/generation/0010-*`. Both soil materials use the same
approved brown/shadow palette subset; adding the existing ink color preserved
the wet source's dark channels after an initial conversion failed the unchanged
20-point contrast guard. This was a deterministic import correction, with zero
additional ImageGen calls. The duplicate candidate records that conversion.
The accepted sources remain byte-for-byte identical to the actual tool returns.
Ownership is 144 raster / 116 ASCII / zero player-sheet, 260 runtime PNGs.

Task 0012 adds six farm-station identity masters and four three-state strips in
`buildings/{workshop,kitchen,press,generator,shop,well}/`. Full workshop, kitchen,
press and generator idle/active/hurt share 48x48/(24,44); shop and well use
32x40/(16,36) and 24x32/(12,30). Sixteen exact idle quarters preserve old file
contracts without drawing repeated fragments in the view. Ten byte-identical
ImageGen returns and exact prompt/reference hashes are recorded in
`implementation/sprites/generation/0012-*`; native conversion uses measured
alpha bounds, fixed family scales, nearest sampling and the existing palette.

`tools/check_station_art.py` validates all thirty outputs and actual emission
pixels. `tools/show_art.py --stations --check` exercises real job/fuel/HP states
and original footprints. Final native/3x capture and source preservation
evidence is in `implementation/sprites/reviews/0012/`. The runtime holds an
authored working pose during paid activity; no continuous mechanical loop is
claimed. Ownership is now 184 raster / 96 ASCII / zero player-sheet, 280 PNGs.

Task 0013 adds four immutable tower identity masters and twelve selected
2x2 whole/hurt/fire/wreck sheets in `defences/{gun_tower,flame_tower,mortar,auto_crossbow}`.
Six rejected candidates remain with exact prompts and explicit reasons; all
22 raw files are byte-identical built-in ImageGen returns. Generation records
are `implementation/sprites/generation/0013-*`. Measured cuts may share only
a fully transparent gutter row/column; opaque state pixels never overlap.
Nearest reduction, one fixed scale per level, alpha threshold 128, the existing
palette and measured lower-base contacts produce 48 reproducible 32x48 PNGs.
All levels use pivot (16,44), cell offset (-8,-28), and authored opaque weapon
outlets. L3 gun has two distinct barrel points. Existing 40 tower PNGs migrate,
eight levelled wrecks are added, and all 240 unrelated runtime PNGs stay intact.

`tools/check_tower_art.py` validates the complete replacement and exact bytes.
`tools/show_art.py --towers --check` exercises real placement/upgrades, damage,
firing, particles, launch observers, 4x simulation batches and rubble lifecycle.
Actual-render captures and native/3x/source audits are in
`implementation/sprites/reviews/0013/`. The view remembers destroyed levels
only during the current session: old saves store rubble family alone, so loaded
rubble uses the family's L1 wreck without inventing a save field. Ownership
is now 232 raster / 56 ASCII / zero player-sheet, 288 runtime PNGs.
