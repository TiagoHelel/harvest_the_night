# Approved farmer: directional animation review

This follow-up produces review assets only. The user approved the front-facing
farmer and requested every movement/activity in all four directions, with a
horizontal GIF **before** promotion into the game. Runtime actor bindings,
movement rules, tools, collision and simulation are not changed by this family.

The exact approved identity is `assets/art_source/player-fhd/approved/idle_south.png`
(SHA-256 `4706f5b8163d4be2d3d8f285bdffe970a315a9c770e6b28bef4e74c4993ba6f1`).
Previously approved south-facing idle/walk/run drawings and recipes are reused
unchanged. All other views are generated from that identity using built-in
ImageGen; subsequent activities also reference the generated cardinal idle views.

## Coverage

| Family | Frames per direction | Directions | Total native frames |
| --- | ---: | ---: | ---: |
| Idle | 3 | 4 | 12 |
| Walk | 8 | 4 | 32 |
| Run | 8 | 4 | 32 |
| Chop, mine, till, plant, harvest, water, fish, reel, collect, craft, trade, repair, carry | 4 each | 4 | 208 |
| Total | | 64 animations | 284 |

Front, left, back and right are genuinely separate generated views; east assets
are not runtime flips of west. Walking/running have eight different native
lower-body drawings each. Work strips use four action key poses, not repeated
idle frames. A held rod is present in casting, waiting and reeling drawings.
The casting preview deliberately holds the final waiting pose before recasting.

## Review artifacts

- `todas-animacoes-horizontal.gif`: one 1040x288 horizontal clip cycling through
  all sixteen categories, 3.84 seconds per category / 61.44 seconds total.
- `gifs/<action>-horizontal.gif`: sixteen independently looping horizontal
  four-direction clips, 7.68 seconds each at 25 fps.
- `index.html`: local selector, exact FHD/native scale toggle, downloads and
  complete native contact-sheet links. It loads only the selected animation.
- `contacts/`: all 64 directional contact sheets at an exact nearest 2x scale.
- `review-stills/`: selected original Godot captures plus consecutive phase
  montages retained for visual evidence.
- `captures/<action>/`: all 192 original renderer PNGs per action, retained
  locally and reproducible; excluded from Git to avoid committing 3,072 captures.

The renderer presents standing bodies at 120 physical pixels (60 source-native
pixels enlarged exactly twice), matching the intended FHD actor appearance.
Locomotion uses 96x96 native canvases with (48,88) ground registration. Work uses
128x128 / (64,108) to preserve complete raised tools and contact below the boots.
The body scale stays 60 pixels; extra transparent canvas is tool clearance.
Future runtime promotion must unify padding/metadata before swapping the family.

## Source contract and revisions

Raw sources and all 265 newly cut native frames are in
`assets/art_source/player-fhd/directional/`. Exact prompts and actual call
metadata (including original built-in output paths) are in `prompts/`. The 19
existing front-facing native frames remain in the previous approved directory.
`jobs.json` records the initial atlas layout; `review-contract.json` records the
final source/prompt/output hashes, measured gutters, crops, body scale, foot
anchors, canvas geometry and selected focused revisions.

Only source component selection/crops, uniform nearest reduction, binary alpha and the existing
shared project palette produce the native PNGs. No native sprite is hand-painted
or procedurally substituted. Transparent gutters are measured near the requested
grid boundaries separately for each activity column, so a tool can extend below
the previous row's nominal boundary without leaking into the next farmer.
The largest connected farmer/tool component defines each crop; detached seed
and droplet components are included explicitly for planting/watering. Selection
mask hashes record exactly which original alpha pixels belong to each frame;
no color or tool is drawn to repair a crop. Tools do not determine body scale. Locomotion
registers hat center and a shared ground per source row, retaining raised boots.
Work registers boot contact so torso bending is not cancelled by head alignment.
The crown above the brown hat band is measured separately, and locomotion's
complete outline-to-sole silhouette is bounded to 60 native pixels. Body palette
subsets match the approved front farmer; additional prop colors are action specific.

Revisions kept alongside the originals:

- `run_north-r1`: transparency inspection candidate. Source alpha inspection
  confirmed the brown-looking preview background has zero alpha; raw RGB in
  invisible pixels is not a painted scene in the exported sprites.
- `run_east-r1`: correct the reversed facing in the second stride half.
- `plant-r1`: keep left/right crouching faces oriented toward the reach.
- `repair_west-r1`: make the hammer strike ahead to the left.
- `chop_north-r1`, `mine_north-r1`: strike away from the viewer, partly occluded
  by the hat, rather than below the farmer's boots.

## Reproduce

```powershell
python implementation/fhd-player/directional/build_review.py
. implementation/farm-house/prepare_qa.ps1
& 'C:\Users\Helel\Documents\godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path $env:GODOT_PROJECT_PATH --editor --import --quit
& 'C:\Users\Helel\Documents\godot\Godot_v4.7.1-stable_win64_console.exe' --path $env:GODOT_PROJECT_PATH --fixed-fps 25 --position -4000,-4000 --script res://src/tools/fhd_directional_preview.gd
python implementation/fhd-player/directional/build_review.py --check --encode
```

`--check` validates exact source/prompt/native output hashes, complete direction
counts, unique work poses and all eight distinct lower-body walk/run phases.
GIF encoding validates the dimensions, 192 real renderer inputs and timing.
No game simulation is run by the isolated playback scene.

## Integration boundary

This delivery is a candidate review, not automatic user approval. These PNGs
have not replaced `sprites/actors/` or the registered runtime player family.
Live farm/house day/night composition and actor-family binding happen after
the user validates the previews. The pre-existing broader FHD working-tree
changes and older rejected pilot assets remain separate unfinished work.
