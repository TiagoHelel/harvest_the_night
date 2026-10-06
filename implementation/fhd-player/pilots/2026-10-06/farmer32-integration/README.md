# 32px farmer integration - renderer review

The owner chose the "32px" farmer of
`implementation/fhd-enemies/pilots/2026-10-05/16px-review` (contract key
`farmer32`) on 2026-10-06. It is in the game through the normal pipeline:

- `tools/import_art.py` has a `detail_wh` recipe: NEAREST down to that grid
  and back to the crop's own size. The 64 walk and 24 idle manifest entries
  use `[40, 40]` (80 -> 40 -> 80), exact source colours, binary alpha, canvas
  80x80, pivot (40, 72), draw scale 0.5.
- `../../2026-10-04/farmer_density.py` holds the density and the review link.
  Both promoters write the recipe, and their `--check` (verify's "FHD player
  sources") requires every runtime frame to be pixel-identical to the reviewed
  32px frame and to the 32px sample of its unchanged full-detail source.

## Pictures

    godot --path . --fixed-fps 60 --position -4000,-4000 --script \
        res://implementation/fhd-player/pilots/2026-10-06/farmer32-integration/capture.gd
    python implementation/fhd-player/pilots/2026-10-06/farmer32-integration/playback.py

`capture.gd` drives the production WorldView, PlayerView, Relight and Lighting
at 1920x1080 from the real core and writes `implementation/shots/farmer32-1080/`:

| file | what |
|---|---|
| `farmer_{idle,walk,run}_{day,night}.png` | a row per direction (south, north, west, east, SE, SW, NE, NW), a column per authored frame, 240x240 unscaled crops |
| `farmer_stop_start_*.png` | stand, set off east, stop, north-west, stop, run south, stop |
| `farmer_tools_*.png` | walk at the target, stand, the four work frames on the completion clock, put the tool down (day: chop, mine, water, repair; night: repair, the only job offered) |
| `farmer_fishing_day.png` | stand, cast, wait with the rod, bite, catch, stand (fishing is a day job by rule) |
| `*_zombies_walk_*`, `zombies_walk_*` | the four families walking left and right, real `Enemies.tick` |
| `*_zombies_attack_*`, `zombies_attack_*` | real strikes on a paid wall |
| `*_deaths_f*`, `deaths_*` | five real deaths, every frame once (day = a night state relit, as in the Giant showcase) |
| `*_giant_*`, `giant_attack_*` | the Giant's three wind-up and three slam poses with the target ring |
| `playback_*.gif` | the sheets at the game's frame times: walk 0.1 s, run 0.07 s |
| `renderer-report.json` | every farmer crop: texture, pose, body height and lowest pixel against the contact |

The body is measured on the renderer by hiding only the body sprite and
comparing the two frames. Result: idle 128-132 px with the lowest pixel on the
contact in all eight directions, day and night; walk/run 120-128 px, lowest
pixel 0-8 px above the contact (the reviewed stride); tool swings 96-144 px.

## Known gap, not changed here

The tool, fishing and reaction poses are the older 48x48 drawing at full scale:
the same 4x4 screen pixel per art pixel, so they were not resampled, but a
stockier farmer about 120 px tall against the walk's 128. Matching it needs new
authored work poses, which this integration excludes.
