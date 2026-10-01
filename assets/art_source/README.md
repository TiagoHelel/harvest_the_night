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

`ownership.json` registers all 217 PNGs with exactly one writer/checker: ASCII,
owner-sheet cutter, or raster importer. `manifest.json` describes every raster
output; `manifest.schema.json` documents its structure. `tools/import_art.py`
validates the structure plus actual image bounds, provenance, animation coverage,
ownership, palette/alpha, derivation cycles and exact runtime bytes. All four
masters retain their task-0001 hashes. Prompt/reference hashes are checked too.

```powershell
python tools/import_art.py           # offline deterministic rebuild + output hashes
python tools/import_art.py --check   # sources, outputs, ownership and view metadata
python tools/gen_sprites.py          # remaining ASCII sprites, atlas and palette sync
python tools/cut_sheet.py            # remaining owner-sheet animations/count table
python tools/check_art_pipeline.py   # fault probes; run outside concurrent builds
```

The importer produces `src/ui/raster_art.gd` from the recipes, including each
file's canvas, pivot, cell offset, optional native lamp/chimney points and
animation timing. Rebuilds only write
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
The three south idle files currently hold the same static master until
0004 authors the idle/walk family. Walker bob/reach/fall preserve the explicitly
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
