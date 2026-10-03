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

Most views were generated separately. The revised lateral walk and run follow the
creator repository recommendation: generate right and reflect the complete
source-owned poses to obtain left, with the reflected foot pivot retained. Walking/running have eight different native
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
Locomotion uses 96x96 native canvases with (48,88) ground registration, or
(47,88) for the reflected west walk/run. Work uses
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

### Lateral walking review follow-up

The user accepted all four idle directions and requested replacements for west/
east walking. Following additional feedback, the final workflow imports the
actual `buildDirectionalPrompt` and `STUDIO_ACTIONS` from the local
`sprite-sheet-creator/app/lib/prompts.ts`. `import_creator_prompts.cjs` reads that
repository without changing it; `prompts/creator-provenance.json` pins its SHA-256.
Submitted prompts and calls are retained exactly, including focused revisions.

Reference order follows that builder: accepted facing-right rotation, canonical
farmer design, and accepted front walking. Its four anchor poses use a 2x2 grid.
Four distinct in-between poses complete the requested eight-frame cycle, with
explicit near/far boot material corrections where the generator reused the same
leg. Final sources are `creator-walk-right-keys-r1.png` and
`creator-walk-right-transitions-r2.png`. Left reflects the complete right poses,
as the creator README recommends, rather than regenerating a mismatched gait.

Only sixteen lateral walking frames changed; the remaining 268 native frames,
including approved idle and front/back walking, stay byte-identical. Warm boot
pixels in the generated transitions use the project's brown material ramp so
nearest palette mapping does not turn leather into hat gold. No pixels are
hand-painted. The source check now guards opposite near/far boot positions at
contacts and the support/reach phases (0,1,3,4,5,7), catching the earlier same-leg
cycle that passed simple frame-count/uniqueness tests. This guard is limited to
material separation; actual renderer playback still requires visual review.

`user-review.json` retains idle approval and leaves walking pending. The same
HTML versions image URLs by GIF content hash so revised previews avoid stale
browser images. Full Godot captures, eight consecutive phases and a browser
screenshot remain in `review-stills/`.

### Lateral running review follow-up

The user requested the same repair for left/right running. The reusable
`import_creator_run_prompts.cjs` imports the actual creator repository's `run`
action and directional prompt builder. Exact base/submitted prompts, source
hash and reference roles are in `prompts/creator-run-*`.

Final sources are `creator-run-right-keys-r1.png` and
`creator-run-right-transitions-r2.png`. Four anchors occupy frames 0,2,4,6;
four intermediates occupy frames 1,3,5,7. Foreground/background legs exchange
support, arms pump in opposite directions between stride halves, and both boots
clear the ground during flight phases 2,3,6,7. The contact/support phases
0,1,4,5 remain on the shared ground. Left reflects the complete right drawings.
The first anchors repeated their arm swing; the first intermediates repeated
extended contact and their revision hid the second leg in opposite support.
Focused edits correct those errors without painting native sprites.

Only sixteen lateral run PNGs changed in this follow-up. The other 268 native
frames, including idle, all walking and front/back running, remain byte-identical
to commit `d5a27f7d`. `check_lateral_run.py` and `run-gait-regression.json` retain
the old same-leg negative control and final measurements. All sixteen new
material/contact/flight measurements pass, while the previous cycle fails the
opposite-leg check. Material checks do not establish subjective motion quality.

Real Godot captures refresh `gifs/run-horizontal.gif` (1040x288, 7.68s at 25fps)
and the running section of the 61.44s overview. Native sheets, eight consecutive
actual renderer phases and the browser proof are retained. Run remains pending
user validation in `user-review.json`; runtime actor bindings are unchanged.

This delivery is a candidate review, not automatic user approval. These PNGs
have not replaced `sprites/actors/` or the registered runtime player family.
Live farm/house day/night composition and actor-family binding happen after
the user validates the previews. The pre-existing broader FHD working-tree
changes and older rejected pilot assets remain separate unfinished work.
