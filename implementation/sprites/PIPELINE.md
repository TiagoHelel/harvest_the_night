# Reproducible raster pipeline

The importer/manifest/ownership registry ship in task 0002. Rebuild with
`python tools/import_art.py`; validate with `python tools/import_art.py --check`.
`assets/art_source/README.md` documents the implemented recipe and migration
commands. Task 0003 adds playable depth/occlusion fixtures and the shared
`ArtPlacement` view helper; `verify.py` runs its isolated headless checks.

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

Task 0004 makes the raster importer the single writer of `player_frames.gd`.
It merges remaining legacy animation counts with raster manifest counts,
canvases, pivots and durations. `cut_sheet.py --check` validates the same table;
normal cutter runs only write legacy-owned PNGs. A player animation may not
mix source owners or drift from the shared 48x48 canvas/(24,44) ground pivot.

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

`ArtPlacement.place` puts a standing sprite node at the logical footprint's
bottom center, with texture offset equal to the negative manifest pivot.
Player/enemy subtile positions share `ArtPlacement.contact`. Actors have nested
y-sorting enabled. The full house renders once at its 3x3 ground anchor; nine
strictly owned slices remain compatibility outputs rather than simultaneous
drawings. Existing multi-cell fixtures use their full texture when available.
House `light_xy` and `smoke_xy` are native source-canvas points; generated
metadata and `ArtPlacement.emission` keep window glow/chimney smoke aligned.
Build outlines use the selected family's logical footprint and redraw when
the family changes in the same cell. They do not cover the cosmetic overhang.

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

Task 0003's fixtures read isolated fixed state without simulation ticks or
player save writes. They cover both actors crossing house/tree in 18 frames,
house/tower previews, four map/camera corners, all crop stages, tower levels and
damage/fire states, plus actual actor frame and landmark silhouette sheets:

```powershell
python tools/show_art.py --check
python tools/show_art.py --out=implementation/shots/sprites/<task-id>/showcase
python implementation/sprites/reviews/0003/build_review.py
```

The review helper builds native/nearest-3x contact pages from task 0003 captures.
Later family tasks can reuse the showcase's output directory option and extend
fixtures for their specific states. Contact sheets show existing committed
frames; they do not prove a provisional animation has authored motion.

Task 0004 extends that scene with authored locomotion playback:

```powershell
python tools/show_art.py --locomotion --check
python tools/show_art.py --locomotion --out=implementation/shots/sprites/<task-id>/locomotion
python implementation/sprites/reviews/0004/build_review.py
python tools/check_art_pipeline.py --out=implementation/sprites/reviews/<task-id>/fault-probes.json
```

The locomotion fixture uses unchanged `Player.tick` on an isolated intent to
exercise real facing/diagonal resolution, then asserts that rendering cannot
mutate that state. It never writes saves. Two complete loops check every idle
and walk frame in all four directions, ground offsets and mirrored east;
release/turn scenarios check the transition back to idle and contact stability.
The real backend saves 36 viewport images. QA helper pages compose these and
the five farm shots at native size and nearest 3x; phase GIFs show the actual
committed frame bytes at the manifest's idle/walk durations.

The screenshot path uses a real rendering backend; `--headless` cannot provide
the necessary viewport image here. Prefer the existing offscreen wrapper with
fixed FPS and seeds. Runtime smoke tests and screenshots should not write over
the player's saves/settings; continue using the existing tool isolation.

Task 0005 adds complete authored work and real interaction playback:

```powershell
python tools/show_art.py --work --check
python tools/show_art.py --work --out=implementation/shots/sprites/<task-id>/work
python implementation/sprites/reviews/0005/build_review.py
```

Its fixtures invoke unchanged Player.tick for every verb and actual Sim.tick
for production/catch-up. Complete serialized state is compared before/after
every work observer and render, rather than relying only on the sim hash (which
excludes some view fields). Every four-frame strip is shown for west/east;
normal and mid-work cancel/walk, dusk, night repair, three-tick repeated repair,
instant gestures at 4x and station-delivery carry are checked. Source/native
QA covers all thirteen strips on light/dark/checker backgrounds. Manifest
`content_anchor_xy` is a measured native coordinate within the reduced crop,
distinct from its full bounds: a long/raised tool must not move or shrink the farmer.

Task 0006 completes player-sheet migration and adds reaction/shadow fixtures:

```powershell
python tools/show_art.py --reactions --check
python tools/show_art.py --reactions --out=implementation/shots/sprites/<task-id>/reactions
python implementation/sprites/reviews/0006/build_review.py
```

Each reaction remains one held source-owned frame on the common player canvas.
The manifest's optional `bubble_xywh` is a native rectangle covering all separate
glyph pixels and no body pixels. The importer checks connected alpha components
and emits that crop in RasterArt; invalid/empty/body-erasing crops fail. A body
mask plus separate Sprite2D region uses the same committed PNG rather than
inventing a second symbol or resized body. Real-render fixtures compare all four
split reactions pixel-for-pixel with their combined PNGs when unclamped, and
exercise the glyph's viewport margin at four corners without moving the feet.

Fixtures also drive actual crop, fishing-bite, night and destruction selection,
the existing lifetime, all initial facings, day/dusk/night lighting, walking and
every verb's active/return cue suppression. Complete serialized state remains
unchanged by the view. Player/tree/enemy shadow uses stay covered; real-render
comparison measures its small ground contact against a shadow-hidden control.
The owner-sheet cutter now writes zero frames and still validates merged player
metadata. The shared `actors/shadow.png` is ground art, not a PlayerFrames pose.

Task 0007 migrates the eight existing ground materials: four grass choices,
soil, path, floor and rock. Sources are fully opaque and runtime tiles stay
16x16. `gen_sprites.build_atlas()` reads validated raster recipes once per
invocation, rather than using old ASCII maps or cached runtime PNGs for migrated
cells. Its cache is local to a build so missing/changed sources always fail on
the next invocation. Atlas remains 256x80: terrain enum row, three water frames,
four grass choices, sixteen grass-edge masks and sixteen shore masks.

```powershell
python tools/check_terrain_art.py
python tools/show_art.py --terrain --check
python tools/show_art.py --terrain --out=implementation/shots/sprites/<task-id>/terrain
python implementation/sprites/reviews/0007/build_review.py
```

The terrain source checker compares all eight runtime tiles and all atlas bytes
against source rebuilds, verifies opacity, opposing borders and shared borders
between every grass choice. Fixtures render all eight materials plus the actual
weighted grass selection under day/dusk/night with the real Relight shader,
farmer/walker feet and unchanged farm. Complete serialized state is compared
before/after rendering. Uniform maps belong only to these fixtures. No terrain
enum, weighted selector, FARM_MAP, walkability, collision or core rule changes.

Task 0008 adds three source-authored water phases and static transitions. The
2172x724 opaque strip has three equal 724-square crops and one common scale;
the two-pixel calm margin and exact cross-frame borders prevent tile seams.
North grass/bank sources reduce from their full 1254-square canvases. The bank
corner uses measured crop (14,14,720,720), retaining its two-pixel endpoint.
`palette_keys` optionally restricts nearest mapping to named members of the
one unchanged COLOURS table. It does not create another palette.

Only fixed clockwise quarter turns (1,2,3) and bounded `slice_canvas` placement
were added as derivations. A grass corner is the accepted fringe's exact native
endpoint pixel; no cap is painted in code. Rotated sides/caps are byte-exact.
Atlas rows, size, enum and N1/E2/S4/W8 masks remain unchanged. Eight caps use
previously empty row-zero slots 6-13. Four view-only layers add diagonal caps
only when neither adjacent cardinal edge already fills that contact.

```powershell
python tools/check_terrain_art.py
python tools/show_art.py --water --check
python tools/show_art.py --water --out=implementation/shots/sprites/<task-id>/water
python implementation/sprites/reviews/0008/build_review.py
```

Fixtures exhaust 512 cardinal/diagonal/family combinations, map boundaries,
day/dusk/night lighting, soil/path/floor/rock contacts, compound joins and the
unchanged farm. Deterministic phase captures freeze only a private TileSet copy.
The automatic-loop test restores the actual production TileSet and observes
three distinct rendered phases returning twice, with complete serialized state
unchanged. Static banks share no animation. Source/native/atlas bytes, side
connectivity and corner endpoint profiles are guarded by the source checker.

Task 0009 migrates stump/rock/seam/ore/cow/chicken and adds controlled tree,
boulder, stone-seam and iron variants. The accepted pilot tree remains exactly
unchanged. New sources are independent material/species masters, with variants
referencing their accepted parents. Each static material pair shares one scale;
measured source bounds determine placement without stretching or clipping.
The tree variation uses the pilot's exact reduction scale, canvas and contact.
Each alternate has an explicit `variant_of` pointing to its direct master.
The importer rejects missing/cyclic parents, non-source parents and differences
in scale, canvas, pivot or palette. A deliberate scale-drift probe exposed the
missing cross-master guard; the final fault suite exercises its rejection.

```powershell
python tools/check_prop_art.py
python tools/show_art.py --props --check
python tools/show_art.py --props --out=implementation/shots/sprites/<task-id>/props
python implementation/sprites/reviews/0009/build_review.py
```

Every prop remains one logical cell. Manifest pivots drive native ground
placement and depth sorting; tree shadows stay separate. WorldView uses only
cell coordinates for static shape choices. It never consumes RNG or changes
resource readiness, collision, footprint or removal. No decorative tree/animal
animation was added. All required variation files fail offline checks if missing.

The showcase compares complete serialized state around every render, checks
all 720 cells for each variation family, then exercises real Gathering.strike,
Gathering.tick and Livestock.collect. Partial nodes, stumps, removed boulders,
regrown deposits, ready/collected animals, dense canopy overlap and the unchanged
farm render under Main's actual day/dusk/night shader. Real pixel comparisons
confirm farmer occlusion behind both trees and every farmer pixel preserved in
front. The comparison locates sprites by logical-cell metadata, which survives
Godot's temporary node names during redraws.
