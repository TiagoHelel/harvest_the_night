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

## Crop growth and soil moisture (0010)

Three independent four-stage sources own `wheat/corn/carrot_0..3`. Measure the
actual alpha gutters rather than assuming equal source quarters. Each species
shares one source reduction scale across all four stages; source plants are
never fitted independently into their runtime cells. Wheat/carrot canvases are
16x16 with (8,14) contact; all corn stages use 16x24 with (8,22) contact.
The mature corn extends four native pixels above its logical cell, with side
margins. The existing ground layer, row order and single-cell gameplay remain.
Soil is an opaque 16x16 tile with (8,16) contact. WorldView calls ArtPlacement
for both drawings, so watering and changing stages preserve their ground point.

```powershell
python tools/check_crop_art.py
python tools/show_art.py --crops --check
python tools/show_art.py --crops --out=implementation/shots/sprites/<task-id>/crops
python implementation/sprites/reviews/0010/build_review.py
```

The source check verifies all fourteen exact outputs, progressive native body
heights, unclipped binary alpha, required pivots and exposed wet material under
every stage. Dry/wet average RGB brightness must differ by at least 20.
The Godot showcase checks real Farming.stage/tick/_water/_harvest, exact harvest
yields/can consumption, existing walkability and serialized-state equality
around every redraw. Capture mode also compares actual dry/wet viewport pixels
under each mature crop in dawn/day/dusk/night lighting. Soil and foliage retain
different manifest offsets without gaining occupants, collision or shadow nodes.

## Farmhouse damage and lamps (0011)

Two independent accepted raw masters in `assets/art_source/buildings/house/`
own `house` and `house_hurt`. Both use the same measured crop/scale and 64x64
canvas, (32,60) pivot and (-8,-12) corner offset. Eighteen compatibility slices
reconstruct the two full drawings exactly; the view still groups the nine
unchanged occupied cells into one house. Original pilot masters are preserved.

House HP lives in `state.house_hp`, outside occupants. WorldView refreshes on
its existing 75% wear threshold and uses Phases.house_full for researched HP
upgrades. No render operation changes HP, collision, rules or save fields.
Window metadata contains five validated glass regions/points. ArtPlacement
maps them through the same corner offset; Lighting draws one local glow per
pane over Main's night ramp, respecting off/steady/full and flashing settings.
The smoke point (51,12) uses the same source transform in both states.

```powershell
python tools/check_house_art.py
python tools/show_art.py --house --check
python tools/show_art.py --house --out=implementation/shots/sprites/<task-id>/house
python implementation/sprites/reviews/0011/build_review.py
```

Source checks cover all twenty outputs, eighteen slice reconstructions,
localized native roof damage, readable glass and shared entrance contact.
The showcase checks HP-only refresh and upgrades, four production light
states, both actor subjects behind/in front, previews and camera bounds.
Capture mode compares actual occlusion pixels and off/steady window glows;
full serialized state stays identical around all rendering/lighting checks.

## Full farm stations and real activity (0012)

Six immutable identity masters and four independent idle/active/hurt strips
live in `assets/art_source/buildings/{workshop,kitchen,press,generator,shop,well}`.
The ten exact built-in ImageGen prompts/returns are recorded in `generation/0012-*`.
The measured transparent gutters determine three disjoint state cuts. Use one
fixed source scale and the measured lower-base contact per family; moving
levers must not shift the ground point or force per-frame fitting. The four
production canvases are 48x48/(24,44), shop 32x40/(16,36), well 24x32/(12,30).
Fourteen complete frames and sixteen exact idle quarters are raster-owned.
Ownership after this migration is 184 raster / 96 ASCII / zero player-sheet.

WorldView draws each full 2x2 station once and caches its Sprite2D. Every 120ms
the view reads existing Crafting.busy/is_stalled/progress_at or Power.is_running
and changes only its texture. No nodes, simulation fields or job timers are
added. The existing below-75%-HP hurt state has priority. Building.anchor_of
resolves real interaction/fuel cells; shop and well remain one cell. Lighting
and the existing bounded smoke pool read that same activity. Source-owned
light/smoke metadata is measured on actual opaque active pixels; the source
checker rejects points outside the drawing or on an inactive indicator.

```powershell
python tools/check_station_art.py
python tools/show_art.py --stations --check
python tools/show_art.py --stations --out=implementation/shots/sprites/<task-id>/stations
python implementation/sprites/reviews/0012/build_review.py
python implementation/sprites/reviews/0012/audit.py
```

The checker proves distinct authored states, common scale/canvas/contact,
binary alpha, exact runtime bytes and reconstruction of all four idle drawings
from compatibility quarters. The showcase covers four production light states,
real paid/stalled jobs, queue-only cache updates, independent stations, HP
thresholds, previews, map edges and both farmer/walker depth orders. Capture
mode compares actual occlusion and active off/steady lamp pixels while proving
serialized state unchanged. No continuous mechanical animation was introduced.

## Authored tower levels, states and launch points (0013)

Four identity masters establish tower materials/camera. Twelve selected raw
2x2 sheets provide whole/hurt/fire/wreck in top-left/top-right/bottom-left/
bottom-right order, at each of three levels. Preserve the six rejected returns
and their reasons. Every selected cut has its own measured alpha bounds and
ground contact; all four poses at a level share one reduction scale, common
32x48 canvas and pivot (16,44). A shared transparent gutter pixel is allowed
at rectangular boundaries, but never shared opaque pixels. The importer
validates all single/multiple muzzle points, their weapon region and opaque
source pixels. RasterArt exports those points and identifies complete towers.

Only families with all 3x4 raster owners disable legacy growth/hole/flash/wreck
recipes. Keep the other 56 legacy recipes guarded. WorldView draws authored
upgrades without level pips, resolves damage against the original levelled HP
and retains existing firing priority. Lighting and the bounded particle pool
use each fire-frame outlet. Main connects read-only WorldView launch observers
around every fixed SimDriver tick, including 4x batches. Only drawing positions
are displaced from the source muzzle; the offset fades over real flight. Core
positions, targeting, damage, projectile dictionaries and balance stay intact.
Loaded mature shots have no guessed launch history. Launch caches prune when
shots disappear, including non-observed skip-night completion.

WorldView remembers the standing tower family/level and reuses a bounded
ground-level Sprite2D pool for actual Farm rubble. Morning cleanup frees both
sprites and remembered levels, even when grid_version does not change. A fresh
save view has only rubble family and uses its L1 wreck; do not change save
formats merely to retain a cosmetic level. Rebuilding on rubble hides it under
the new occupant. Particle gun-cell caches use occupancy version so same-count
replacement is observable.

```powershell
python tools/check_tower_art.py
python tools/show_art.py --towers --check
python tools/show_art.py --towers --out=implementation/shots/sprites/<task-id>/towers
python implementation/sprites/reviews/0013/build_review.py
python implementation/sprites/reviews/0013/audit.py
```

The actual-render showcase covers all 48 states under day/dusk/night, four
one-cell previews, actor depth, projectile births and two-barrel L3 gun output,
real destruction, loaded rubble, morning cleanup and mixed defenses at night.
It compares off/steady glow at actual source points and serialized state around
rendering. Source and runtime gates are integrated into full verify. Run fault
probes separately from any import/editor/verify process; always restore bytes.

## Authored connected barriers and ground traps (0014)

Keep all sixteen ImageGen returns and exact prompt/reference hashes. Eight raw
sheets contribute selected modules, rather than accepting every module of each
sheet. Whole-r3 provides taller post/front profiles; whole-r2 provides narrow
vertical projection and low rubble. Hurt-r1 contributes readable broken posts
and front spans; initial hurt contributes the matching vertical break. Four
unused early candidates retain explicit rejection reasons. Trap masters remain
identity references and their state strips own the three runtime drawings.

One fixed scale per material applies across whole/hurt/wreck cuts. `compose`
derivations contain 1..5 source-owned parts, each with a validated parent,
slice and placement. Alpha composition adds no colors, holes, growth or painted
pixels. A source post is the primary parent and last component. N1/E2/S4/W8
selects all sixteen occupied-neighbor masks, whole and hurt, on 16x32/(8,28)
canvases. Narrow north/south projections meet at 16-pixel cell intervals.
Existing mixed wall/fence neighbors connect; unrelated structures do not.

Barricade whole/hurt/wreck uses 16x24/(8,20); armed/triggered/spent mine uses
16x16/(8,14). Low ruins stay outside occupancy. Mines sit above plots and below
actors. The existing fixed-tick view observers compare actual mine disappearance
with Traps.sprung, sale intent, current structure_lost receipts and new rubble.
Old rubble under rearmed mines does not suppress a real trigger. Ambiguous
external removals produce no guessed location. At most six view-owned cues show
triggered for 0.16s then spent for 0.24s; rearm, load, morning and expiry prune
them. No new core/save fields or gameplay timing are introduced.

```powershell
python tools/check_barrier_art.py
python tools/show_art.py --barriers --check
python tools/show_art.py --barriers --out=implementation/shots/sprites/<task-id>/barriers
python implementation/sprites/reviews/0014/build_review.py
python implementation/sprites/reviews/0014/audit.py
```

Full verify includes source and real-state gates. Capture mode checks actual
farmer/barrier occlusion and mine/actor/crop pixels, all joins under day/dusk/night,
legal previews, route restoration, loaded ruins and identical 4x simulation bytes.
Run the fault suite in isolation from import/editor/verify and restore all bytes.

## Giant motion and bounded enemy deaths (0016)

Five exact ImageGen returns own Giant master/walk/wind-up/slam/death. Preserve
their raw alpha, exact prompts, reference hashes and actual submission arguments
under `assets/art_source/enemies/giant/` and `generation/0016-*`. Measured cuts
use one scale per strip, nearest/palette conversion and binary alpha. All sixteen
canonical poses share 80x64/(40,60); four old names are exact output aliases.
This transparent envelope admits the ground-contact fist without changing
the 43x42 standing body, feet or logical cell. Ordinary 0015 outputs are reused.

EnemyMotion observes actual movement and valid core targets/waits. It rejects
stale/distant tells and uses observed contact to start the three slam poses.
The nine-tick cosmetic slam recovery may accompany subsequent core movement;
it never delays a core step. The warning ring renders above actors/roof only
while the real tell is valid. No new attack timing or simulation field exists.

EnemyDeaths borrows only each coordinate Array across one fixed core tick.
Existing in-place movement updates it before traps/projectiles remove the ID.
Immediately afterward, missing tracked IDs become copied Vector2i/kind/facing
cues and all borrowed arrays are released. Entity dictionaries are never held.
At most 24 cues and 24 lazily allocated y-sorted sprites survive. Each frame
lasts 0.12 render seconds, then ordinary four-frame deaths expire at 0.48s and
Giant five-frame deaths at 0.60s. A full pool replaces its oldest cue. Duplicate
observation, skipped tick gaps, new state and day cleanup cannot replay deaths.

```powershell
python tools/check_giant_art.py
python tools/show_art.py --giant --check
python tools/show_art.py --giant --out=implementation/shots/sprites/<task-id>/giant
python implementation/sprites/reviews/0016/build_review.py
python implementation/sprites/reviews/0016/capture_review.py
python implementation/sprites/reviews/0016/audit.py
```

Full verify covers source ownership, both walking directions, all real wall
and house tell/contact phases, warning visibility, movement-before-death final
coordinates, one-shot expiry, 64 simultaneous removals/24-cue cap, load/day
cleanup, performance and identical serialized core state. Review full 480x270
captures beside exact 3x nearest views; enlarged windows alone do not restore
detail discarded by native sprite conversion. The raster importer is unchanged.
## Task 0017: localized combat and work forms

Seven transparent ImageGen strips own 25 new runtime frames under
`sprites/effects/`. No completed source or runtime family is replaced. One
fixed reduction scale per strip preserves expansion and dissipation; alpha128,
nearest reduction and the shared palette are the only image conversions.

| Family | Frames | Canvas | Pivot | Seconds per frame |
| --- | --- | --- | --- | --- |
| muzzle | 3 | 12x12 | 6,6 | 0.065 |
| impact | 3 | 12x12 | 6,6 | 0.065 |
| flame | 4 | 16x20 | 8,18 | 0.14 |
| smoke | 4 | 16x20 | 8,18 | 0.14 |
| dust | 3 | 16x12 | 8,10 | 0.10 |
| splash | 4 | 20x16 | 10,14 | 0.10 |
| flare | 4 | 24x24 | 12,12 | 0.10 |

All are one-shots. PixelEffects observes fixed ticks through Particles, with
borrowed coordinate Arrays released after each observation. Reload rises emit
at the measured levelled outlets, including powered reloads; hurt/burning
transitions, real ability counts and PlayerWork completion observations supply
the other contacts. It never retains a core entity or writes a state/save field.
Render frames cannot repeat a shot. Chimneys remain grouped by building anchor.

At most 24 lazily reused Sprite2D forms reserve at most a quarter of the shared
`video/max_particles` budget; the remaining slots keep the effective cheap
procedural pixels. Lower density uses emission credits; zero hides all effects
immediately. Live `a11y/flashing=false` holds the first form with a gentle fade,
suppresses fragment drift and stops light wobble. State replacement clears cues.
Periodic flames are limited to three actors per beat. Nearby burning actors
share at most 12 separated, subdued light halos, avoiding additive wave glare.
Juice keeps hit numbers/shake but delegates tracked enemy deaths to WorldView.
Dust and splash sprites use WorldView's existing ground layer below actors,
so work effects cannot cover an opaque farmer/tool pixel. Binding occurs on
first playback because Main's child emitter readies before the parent builds
that layer. Removing the emitter also releases its borrowed ground children.

```powershell
python tools/check_effect_art.py
python tools/show_art.py --effects --check
python tools/show_art.py --effects --out=implementation/shots/sprites/<task-id>/effects
python implementation/sprites/reviews/0017/build_review.py
python implementation/sprites/reviews/0017/audit.py
```

Full verify includes source/frame and actual-state/contact/a11y gates. Capture
mode compares imported PNG pixels and real native hide/show pixels, warm fire
and subdued smoke at day/night, chimney/outlet placement, real work, real flare,
75 simultaneous ignitions/deaths and all frame expiry. A 100-actor saturated FX
benchmark measures view update CPU separately from GPU; full perf still covers
the existing complete world budgets. Full/half/off 90-tick core controls must
remain byte-identical. The exact raw/tool/prompt/reference ledger is preserved.

## Native UI family (0018)

Fifteen raw transparent tool returns in `assets/art_source/ui/` each own two
static outputs: `ui/icon_<resource>` at 16x16/(8,8), and `ui/hud_<resource>` at
10x10/(5,5). The two recipes use the exact same measured source crop with
different explicit nearest scales, threshold 128 and the unchanged 42-color
palette. Canonical cuts fit fourteen visible pixels; compact cuts fit eight,
leaving clear internal margins. No runtime resize or theme tint is permitted
for these material icons. Each `0018-*-arguments.json` preserves the exact
built-in request, and each call ledger hashes raw/prompt/reference/output bytes.
Always read prompt and JSON metadata as UTF-8 on Windows.

`tools/ui_surfaces.py` refines the established ASCII kit through `sprite_maps`.
Panel/button/tab mid-edge profiles retain three-pixel margins, center fields
remain flat, and the focus ring stays transparent inside. New explicit tab,
checkbox-disabled and slider-highlight/disabled sources remain ASCII-owned.
The ownership registry now has 447 raster and 21 ASCII runtime outputs.

```powershell
python tools/check_ui_art.py
python tools/show_art.py --ui --check
python tools/show_art.py --ui --out=implementation/shots/sprites/<task-id>/ui
python implementation/sprites/reviews/0018/build_review.py
python implementation/sprites/reviews/0018/audit.py
```

The UI fixture renders all fifteen full/compact icons, engine control states,
keyboard focus, day/night HUD and actual inventory/shop panels in English and
pt-BR under both themes. It compares every opaque displayed icon pixel to its
native source, checks real menu labels/bounds, preserves observer state bytes
and verifies day-only money hides while power remains visible after dark.
The full localized dusk label and large balances must remain separated.
The full verifier includes both source and UI-display gates. Real standard,
tech/result/pause/options/title captures supplement the fixture; visual review
still decides legibility, state contrast and material identity.
