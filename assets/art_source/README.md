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
The registry now assigns 88 outputs to raster, four reaction frames to the
owner-sheet cutter and 156 to ASCII. Reactions remain for task 0006.

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
python tools/cut_sheet.py            # remaining owner-sheet animation PNGs
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
