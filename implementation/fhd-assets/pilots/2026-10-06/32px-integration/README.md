# The 320 non-character assets beside the 32px farmer - audit

Request: `../32px-review/CLAUDE-ALL-ASSETS-PROMPT.txt` (2026-10-06). The
gallery's `contract.json` lists 320 runtime PNGs under `sprites/`: 166
buildings/defences, 27 props, 10 interior, 14 crops, 28 terrain, 26 effects
(with the contact shadow) and 49 interface pieces.

## Inventory and ownership

- All 320 paths exist and all 320 SHA-256 match the gallery contract, also
  after the 32px farmer commit (that commit changed only farmer frames).
- Owners in `assets/art_source/ownership.json`: 300 raster (manifest recipes:
  189 sources, 64 composed joins, 34 slices, 12 rotations, 1 slice-to-canvas)
  and 20 ASCII (`tools/gen_sprites.py`: the terrain atlas and 19 UI theme
  pieces). None is unregistered and none is a second copy of another.
- Density: world art is drawn at scale 1.0 on the 480x270 viewport, so one art
  pixel is already 4x4 physical pixels at 1920x1080 - the 32px farmer's. No
  file was resampled, re-imported, recoloured or moved.

## Where the game uses each one

    python implementation/fhd-assets/pilots/2026-10-06/32px-integration/binding_audit.py

The views build texture names at runtime (`<id>_l2`, `fence_join_<mask>`,
`<id>_<dx>_<dy>` ...), so the audit asks them instead of guessing: each probe
in `probe/` extends an existing showcase, or the real `shot.gd` scenarios
(Main.tscn), and records once a frame which inventory textures are alive in
Godot's resource cache. Result (`binding-report.md`, `binding-report.json`):

| role | files |
|---|---|
| drawn at runtime by a real view | 248 |
| terrain atlas source - `atlas.png` is built from it cell for cell and `check_terrain_art.py` compares every cell | 27 |
| wall/fence module composed into the `*_join_*` pieces | 12 |
| exact cut of a whole building master that WorldView draws whole (house 18, press 4, generator 4, kitchen 4, workshop 3); the cuts stay the per-cell fallback | 33 |
| unbound | **0** |

Of the 248, 87 were held during the standard shot scenarios of Main.tscn
itself; the other 161 (tower levels, firing and wrecked states, worn and
joined barriers, crop stages, effects, UI states) during the showcases that
drive the same production views through states the rules produce.

So **no asset binding changed**: every file is used in its intended role
already - upgrades, firing, worn and wrecked states only when the rules put a
building in them (tower, barrier, house and station showcases), modules and
slices only through what they assemble, the atlas as derived support art.

## Real FHD scenes with the 32px farmer

    godot --path . --fixed-fps 60 --position -4000,-4000 --script \
        res://implementation/fhd-assets/pilots/2026-10-06/32px-integration/scenes.gd
    python implementation/fhd-assets/pilots/2026-10-06/32px-integration/scenes_playback.py
    python tools/shot.py assets32-1080/game --fhd

`implementation/shots/assets32-1080/`: the game itself at 1920x1080 -
farmstead, fields (three growth batches), the larger stations, every tower
family at levels one to three with joined and worn walls/fences and a mine, a
night wave, the old pond, the furnished house at noon and at dusk (the house
is a day visit; nightfall sends the farmer out) - by day and by night, plus
GIFs of the running game (trees and animals, fire and lamp, a wave) and the
standard shot set under `game/` (HUD, options, tech, result, pause, build
refusal). `scenes-report.json` records the farmer's texture in each.

Checked in them: one scale throughout (the 128 px farmer against the house,
stall, stations, towers and furniture), feet on the ground, y-sorted
occlusion (a tower lower on screen covers the farmer, he covers the one
above), lit windows and lamps at night, no blur. Measured: 91.5-100% of the
4x4 art-pixel blocks in the world area are single-coloured; the rest is HUD
text over the world, light glows and flashes, and the tree canopies, whose
wind shader blends neighbouring texels on purpose (`ambient_motion.gdshader`,
"smooth subpixel leaf motion") - an ambient shader the request says to keep.

## Changed

- `src/tools/shot.gd`: `farm_extension` and `larger_stations` had kept the
  old yard's coordinates after the farmstead moved to the middle of the farm;
  the farmer stopped at the well and the press and kitchen no longer fitted.
  They now stand the farmer beside the beds and place the three 4x3 stations
  in the nearest room east of the stall. Picture tooling only.
- This folder (audit, probes, scenes) and the shots.
