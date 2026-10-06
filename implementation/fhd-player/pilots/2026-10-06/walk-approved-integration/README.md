# Final approved eight-direction walk - game integration, 2026-10-06

Request: `../walk-final-mirrored/CLAUDE-APPROVED-WALK-PROMPT.txt`, the latest
handoff. It supersedes `../walk-up-right-low-step/CLAUDE-APPROVED-WALK-PROMPT.txt`,
whose integration was underway and was switched to the final pack. The pack in
`../walk-final-mirrored/runtime-80/walk` (contract.json, README.txt,
checks.json) is now the farmer's walk in the game, for all eight directions:

| pack folder | engine animation | against the previous runtime |
|---|---|---|
| down | walk_south | unchanged |
| right | walk_east | unchanged |
| up | walk_north | unchanged |
| left | walk_west | all 8 phases: the exact mirror of right |
| down-right | walk_south_east | all 8 phases: the exact mirror of down-left |
| up-right | walk_north_east | phases 1, 3, 4, 5, 7, 8: the approved lower boots; 2 and 6 unchanged |
| up-left | walk_north_west | all 8 phases: the exact mirror of the NEW up-right |
| down-left | walk_south_west | unchanged |

Files 01..08 are engine frames 0..7 at 0.1 s; running plays the same phases at
`PlayerArt.RUN_FRAME_SECONDS` (0.07 s). The mirrors are already in the pixels
and each folder is bound as it is - nothing is flipped again. The old up-left
still stored in walk-up-right-low-step is not used.

## Pipeline

- `../../2026-10-04/palette-variants/promote_blue_walk.py` checks all 128
  exports of the pack against its `contract.json`, traces every pose to the
  approved walk-up-right-low-step frame it copies (up-left: flips, from the new
  up-right), checks the three mirror pairs - right/left, down-left/down-right,
  up-right/up-left - in every phase at both sizes and runtime-80 as native-40
  at exactly 2x. It copies the 64 runtime-80 frames to versioned owned sources
  (`assets/art_source/player-fhd/walk-blue-32px/2026-10-06/<folder>/NN.png`)
  and writes their manifest entries: exact source colours, binary alpha,
  80x80, pivot (40, 72), draw scale 0.5, `detail_wh` [40, 40] - pixel-idempotent
  on this art (checked), so the 32px guard stays without a second reduction.
  The references pin the approved frame, the final pack contract, the owner's
  approval record and the full-detail master each frame descends from; those
  masters (`walk-blue/frames`) are untouched and still hash-frozen.
- Its `--check` (verify's "FHD player sources") requires every generated walk
  PNG to be RGBA pixel-identical to its approved frame, in phase order, at
  0.1 s, with every blue garment pixel in the approved twelve-colour palette,
  and the three mirror pairs exact on the generated PNGs. Tried on purpose and
  refused: the old up-left (as game frame and as owned source), the 2026-10-05
  walk and the up-right from before the lower boots.
- `tools/import_art.py` regenerated `sprites/actors`: against the last commit
  30 frames changed (left 8, down-right 8, up-right 6, up-left 8), the other 34
  and all idle frames are byte-identical; RasterArt/PlayerFrames came out
  identical (no canvas, pivot or timing moved). A second promoter run leaves
  manifest, ownership and contract byte-identical and a second import writes
  nothing.
- Idle stays on the independent grounded poses (`promote_idle.py`), whose
  check holds the frozen masters and reviews by hash, the runtime walks at
  32px, and that no idle slot equals any walk phase of its direction.

## Renderer review

    godot --path . --fixed-fps 60 --position -4000,-4000 --script \
        res://implementation/fhd-player/pilots/2026-10-06/walk-approved-integration/capture.gd
    python implementation/fhd-player/pilots/2026-10-06/walk-approved-integration/playback.py

The production WorldView/PlayerView/Relight/Lighting at 1920x1080, driven by
`Player.tick`: `implementation/shots/walk-approved-1080/` holds idle, walk and
run sheets for day and night (rows: south, north, west, east, south-east,
south-west, north-east, north-west; walk/run rows have a ninth column, the step
after phase 8, which is phase 1 again), stop/start strips and GIFs at 0.1 s and
0.07 s. 1,798 checks, 0 failed. Measured on the renderer (body sprite hidden
and compared):

| direction | body height | lowest pixel vs contact |
|---|---|---|
| north | 128 px | on it |
| south, east, west, north-east, north-west | 124-128 px | 0-4 px above |
| south-east, south-west | 120-124 px | 4-8 px above |
| idle, all eight | 128-132 px | on it |

North-west now measures exactly as north-east, its mirror. The 8 -> 1 wrap
shows the same frame at the same size as phase 1 in every direction. The two
lower diagonals stand one to two art pixels above the pivot through their
whole cycle: that is the approved drawings' registration (down-right is the
exact mirror of down-left), kept as approved since this task forbids
repainting or re-registering frames.
