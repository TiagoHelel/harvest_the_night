# 0007 terrain review — 2026-10-01

Accepted eight built-in ImageGen terrain sources and their exact 16x16 runtime
tiles: grass, grass_b, grass_c, grass_d, soil, path, floor and rock. Four grass
choices total preserve the existing generator/view row contract. The prompt's
ambiguous phrase "grass and its four variants" was clarified to name the four
actual tiles rather than invent a fifth grass choice or alter the selector.

## Sources, revisions and conversion

Raw files: `assets/art_source/terrain/`. Twelve actual built-in calls produced
eight accepted sources and four rejected originals preserved in `candidates/`.
Exact assembled prompts, edit prompts, reference roles, actual returned paths
and hashes are in `generation/0007-*-call.json`, their `.prompt.txt` files and
`0007-generations.json`. Returned source bytes were compared to repository copies.
Style-day and reference-sheet images established materials, not object geometry.
Grass variants used the generated base as a consistency reference.

All eight accepted sources are 1254x1254 RGBA, fully opaque (alpha 255 everywhere).
Native tiles retain canvas 16x16 and pivot (8,16). Full-source nearest/palette
reduction applies to grass, floor and rock. Soil uses measured crop
(46,0,1152,1152); path uses (46,46,1152,1152). These sampling phases retain the
small connected marks in the revised raw sources; full-source reduction missed
some cells. No hand-painted pixels, seam repair or aspect-ratio stretching.
The existing 42-color palette is unchanged.

| Material | Native base coverage | Colors | Border mismatches x/y | Accepted source SHA-256 prefix |
|---|---:|---:|---|---|
| grass | 93.8% | 3 | 0/0 | f9084889428db5ae |
| grass_b | 98.0% | 2 | 0/0 | cfd24bb952e47581 |
| grass_c | 98.0% | 3 | 0/0 | d854a3fba84668d1 |
| grass_d | 97.3% | 3 | 0/0 | 597b415b6712308f |
| soil | 98.8% | 4 | 0/0 | 66b14e30ca511582 |
| path | 99.2% | 3 | 0/0 | aa46572715df423d |
| floor | 85.9% | 3 | 0/0 | d7c1b998f4007529 |
| rock | 98.4% | 3 | 0/0 | 46c3c7f4d4d5bae3 |

Complete source/native hashes and measured contracts: `measured-contract.json`.
Each of soil/path/floor/rock needed one targeted revision, below the three-revision
limit. Rejected soil had scattered marks and one horizontal seam mismatch;
path repeated conspicuous diagonal scuffs; floor had excess fine grain, lost
joins and mismatched borders; rock repeated too many angular marks. Decisions
are recorded on the individual calls. All four rejected originals remain saved.

## Integration and scope

Ownership now covers 248 PNGs: 101 raster, 147 ASCII, zero player-sheet. The
eight materials moved together, including all grass derivatives. The atlas
remains the generator-owned composite and reads rebuilt validated raster
sources, not old maps or potentially stale runtime PNGs. One build-local cache
avoids rebuilding every raster source for each atlas contribution, while every
new invocation validates the source/prompt/reference hashes again.

Atlas remains 256x80: enum row grass/soil/water/rock/path/floor, three water
frames, four grass choices, sixteen grass edges and sixteen shoreline masks.
Nine migrated atlas contributions, including duplicated base grass, match
their accepted sources. `check_terrain_art.py` compares the entire atlas byte
stream, including transparent padding and remaining legacy rows, and every
migrated tile. All grass borders also match each other exactly.

`runtime-delta.json` compares against commit b116b6c: only eight tile PNGs and
the atlas changed; all other 239 runtime PNGs remain byte-identical. Core,
FARM_MAP, terrain enum, walkability, collision, balance, save formats, hash
baselines, the original owner sheet and weighted grass selection are unchanged.
WorldView edits only update comments to describe its current source ownership.

## Automated verification

Full `tools/verify.py`: **30 passed, zero skipped/failed in 194 seconds**.
Godot 4.7.1 from the user-provided folder; 105 scripts, 6609 headless assertions,
980 input cases, performance and Windows/Web exports pass. Sim `1961000123`
and data `407837701` remain unchanged. See `verify.log`.

Terrain fixtures: **19609 headless checks**, zero failed; **19669 real-render
checks**, zero failed. Each of eight materials and weighted mixed grass renders
under day/dusk/night, with native farmer and walker, followed by the unchanged
farm. The fixtures use Main's actual Relight shader and verify every tile
selection, body/feet anchors, source-owned atlas and complete serialized state
before/after rendering. Uniform material maps exist only in isolated fixtures.
See `terrain-check.log` and `terrain-capture.log`.

Fault/rebuild suite: **33 probes pass**, all deliberate corruption restored.
Two memory/on-disk rebuilds are byte-identical; legacy writers cannot overwrite
101 raster outputs. Added probes reject changed/missing accepted terrain
sources in the atlas builder, tampered migrated tile/atlas, opposing-border
mismatches and transparent native holes. The unmigrated ASCII probe now selects
an actual remaining ASCII output. Existing source, animation, owner, pivot,
reaction and house reconstruction guards remain active. See `fault-probes.json`.

## Visual gates actually inspected

All eight raw generations and targeted revisions were inspected before
promotion. `source-alpha.png` checks all eight accepted source alpha ranges;
`native-materials{,-3x}.png` and `atlas{,-3x}.png` show native outputs. Every
`patch-<material>{,-3x}.png` was opened: eight 8x8 repeated material patches
plus the production weighted grass mix. Opposing/mixed borders show no frames,
gaps or seams. The sparse texture leaves actors as the strongest small forms.

All **35 actual 480x270 Godot captures** were opened at native size and nearest
3x via `captures-00` through `captures-08`; the 3x pages were inspected at
original 2880x1728 resolution. Captures are under
`implementation/shots/sprites/0007/terrain/` (30) and the task folder's five
Main scenarios. `frame-review.json` records every capture path/hash.
`before-after{,-3x}.png` was also opened to compare task 0006/0007 noon, dusk
and mid-wave states without editing either capture's pixels.

| Criterion | Result and concrete evidence |
|---|---|
| Calm repeating ground | PASS: 8x8/native/full-farm views remove the old dense speckle field; weighted grass breaks the obvious uniform-repeat test pattern without patch boundaries. |
| Natural rock | PASS: the large rocky farm area has muted gray flecks, without rectangular masonry or high-contrast brick courses. |
| Wood orientation/joins | PASS: two source-authored horizontal joins survive 16px reduction and connect continuously across dock tiles; no square board framing. |
| Materials under three lights | PASS: green lawn, dark soil, lighter path, horizontal timber and gray rock remain distinguishable in day, dusk and night fixture pages. |
| Clear native actors | PASS: hat/face/clothes/boots and walker silhouette remain visible over every material; terrain does not add an outline, glow or second shadow. Night uses the existing actor/ramp behavior. |
| Clean opaque tile alpha | PASS: all eight full native tiles and accepted raw sources are opaque; no halos, holes, clipping or invented background removal. |
| All required states | PASS: every material, all four grass choices, production grass mix and unchanged full farm have day/dusk/night captures; no missing texture fallback. |
| Anchors, footprints and rules | PASS: unchanged actor pivots and material selections checked in Godot; core/map/other runtime art unchanged and both hash guards pass. |
| Deterministic ownership | PASS: source-exact tiles/atlas and all 33 corruption/rebuild probes pass; no retired ASCII derivative remains. |

No terrain generation blocker remains. Water/banks/grass transitions are still
their previous source bytes and belong to 0008. Crops, stations, forest overlap,
enemy motion and overly broad night bloom remain their scheduled later tasks;
this review does not claim that the complete game's visual overhaul is finished.
