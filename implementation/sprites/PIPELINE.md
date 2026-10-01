# Reproducible raster pipeline

The importer/manifest/ownership registry ship in task 0002. Rebuild with
`python tools/import_art.py`; validate with `python tools/import_art.py --check`.
`assets/art_source/README.md` documents the implemented recipe and migration
commands. Playable depth/occlusion showcases remain the task 0003 deliverable.

## Ownership

The user requested new sprites. For this new backlog, raster generation is an
explicit evolution of the old ASCII-only convention. Preserve reproducibility
by committing the accepted image source and recipe. Do not patch output PNGs
or disable existing checks. Preserve the owner's sheets and original prompts.

Suggested project source location: `assets/art_source/`. Accepted raw sheets,
identity masters and source manifest live there. Prompt text and review results
live in this implementation folder. Runtime PNGs continue to live in `sprites/`
to limit migration work. Rejected candidates are not runtime assets.

Each output has exactly one owner: legacy ASCII generator, legacy player cutter
or raster importer. Introduce an ownership dispatch shared by their write/check
paths and `verify.py`. Migrated names must be excluded from both writes and
checks of their previous owner. A migrated input feeding derived art must also
migrate its slices, states and atlas contributions, or explicitly route those
derivations through the new recipe. Never leave stale old-derived outputs.

Keep generation helpers/palette sync working. In particular, the terrain atlas
must consume accepted tiles, and `palette_data.gd` must still match the palette.
Removing one stale comparison without a new exact-source comparison is not a
valid migration. Cover a migrated asset and an unmigrated asset in verification.

## Manifest contract

Task 0002 creates a schema and validator. Each asset/frame should record:

```json
{
  "id": "actors/idle_south_0",
  "owner": "raster",
  "source": "assets/art_source/player/idle_south.png",
  "source_sha256": "<actual source SHA-256>",
  "crop_xywh": [0, 0, 192, 192],
  "canvas_wh": [48, 48],
  "pivot_xy": [24, 44],
  "content_scale": 0.25,
  "alpha_threshold": 128,
  "palette": "tools/palette.py:COLOURS",
  "animation": "idle_south",
  "frame": 0,
  "seconds": 0.55,
  "loop": true,
  "output": "sprites/actors/idle_south_0.png"
}
```

This is illustrative metadata, not an approved crop. Actual source dimensions,
crop boxes, anchors and scale must be measured after generation. Add consistent
sheet-cell/gutter coordinates, output hashes, tool/recipe version, approved
prompt path and reference source hashes. Reject duplicate owners/IDs, missing
sources, invalid rectangles, inconsistent frame canvases, out-of-range pivots,
unknown colors and missing runtime references. Store positions as native pixels.

## Generate, review, import

1. Open the reference images before using them. Label reference versus edit
   target explicitly in the prompt/tool call.
2. Use built-in ImageGen by default. One call per family master or short strip;
   use the approved master as the visual reference for later states. Request
   `transparent_background=true` for isolated sprites, false for opaque tiles
   and scene/style studies. Do not ask for transparency only in prompt prose.
3. Copy the accepted returned file from the generator's actual output location
   into the repository. Do not assume a destination tool argument or fabricate
   a path. Record the source hash, prompt and revision.
4. Inspect raw alpha and object boundaries. Images generated as pixel art may
   still have irregular spacing, soft alpha and unequal frame sizes. Reject
   malformed strips; use explicit measured boxes rather than guessed row cuts.
5. Deterministic processing: crop, common scale for a family/animation, nearest
   resample, palette mapping, alpha threshold, placement by feet onto the fixed
   canvas, deterministic PNG serialization. Never stretch each frame to fit its
   own bounds. Background removal or creative image repair uses ImageGen;
   Python only handles this explicit production conversion, slicing and QA.
6. Regenerate runtime PNGs and atlas/metadata. Two runs on the same committed
   inputs must produce identical bytes and a clean diff on the second run.
7. Import in Godot; inspect the family in its test scene and in the actual farm.
   Promote only outputs that pass both visual and automated gates.

Generation itself is not deterministic. The committed accepted sources make
subsequent builds deterministic without requiring ImageGen or a network call.

## Godot integration

Props must use a node at the ground/contact pivot with Sprite2D offset relative
to that pivot, rather than sorting by image top-left. Audit Actors' nested
y-sorting explicitly. Draw multi-cell buildings once per logical anchor, or
retain a documented slice scheme that supports roof overhang and correct sort.
Keep placement previews, interaction highlight, shadow and light positions in
agreement. Shadows are separate from the neutral sprite's color ramp.

Larger crop canopies need a deliberate layer/order decision. Use existing
occupancy and state for anchor calculations; do not change the map to hide
render errors. Replace assumptions in player frame checks with real new metadata
while keeping full verb/action coverage. Add view-owned death snapshots/pools
if required; do not retain dead entities in the simulation for an animation.

## Verification

The planning queue is validated by `python implementation/sprites/task.py check`.
Production tasks also run the source importer check added by 0002, then the
repository's `python tools/verify.py` (imports first). Final task requires full
exports; `--fast` is useful during iteration but is not the final ship gate.
Never use `--accept` to dismiss an art-induced hash change. Current expected
hashes are in `tools/determinism_sim_hash.txt` and
`tools/determinism_data_hash.txt`.

Reuse `python tools/shot.py sprites/<task-id> noon dusk wave result tech`.
Add new showcase/screenshot scenarios for silhouettes, every tower level and
damage state, all crop stages, actor directions, work cycles, building occlusion
and UI icon display. Existing five screenshots do not cover all those states.
Capture animation sequences/contact sheets as well as stills.

The screenshot path uses a real rendering backend; `--headless` cannot provide
the necessary viewport image here. Prefer the existing offscreen wrapper with
fixed FPS and seeds. Runtime smoke tests and screenshots should not write over
the player's saves/settings; continue using the existing tool isolation.
