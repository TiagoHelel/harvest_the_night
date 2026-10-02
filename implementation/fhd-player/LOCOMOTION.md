# Approved front-facing farmer: idle, walk and run

The user approved the exact attached compact farmer on 2026-10-02, then requested
eight walking frames, eight running frames and a horizontal GIF comparing idle,
walk and run. That specific animation deliverable is separate from remaining
directions/tool poses and the ongoing game-wide FHD integration.

## Deliverables

- Exact approved identity: `assets/art_source/player-fhd/approved/idle_south.png`.
- Nineteen cut assets: `assets/art_source/player-fhd/approved/frames/`: three idle,
  eight walk and eight run frames, all front-facing south.
- Complete measured recipe: `implementation/fhd-player/locomotion-contract.json`.
- Exact built-in ImageGen prompts and calls: `approved-prompts/`.
- Horizontal GIF: `idle-walk-run-horizontal.gif`, 660x240, 7.68 seconds.
- Original actual Godot renderer sequence: `locomotion-playback/frame-000.png`
  through `frame-191.png`, 25fps.
- Eight-frame contact sheets: `walk_south-contact.png` and `run_south-contact.png`.

## Pixel and motion contract

All frames use a 96x96 source canvas, foot pivot (48,88), one measured reduction
scale per source strip, nearest sampling, binary alpha and the existing project
palette. The physical review draws a standing 60px body at twice native size,
matching its planned 120px FHD appearance. No pose is independently stretched to
fill its cell. Ground contact is measured separately from the lifted boot; hat
center provides horizontal registration instead of the current single support
foot. Running flight phases retain space below both boots.

Walk frames last 120ms, one cycle 960ms. Run frames last 80ms, one cycle 640ms.
Idle uses open 3200ms, closed 120ms, reopening 120ms. The walk revision corrects
its initial misordered support halves. Both cycles have eight distinct lower-body
drawings, not just eight different hats or duplicated sprite files. Contact and
passing transitions are inspected in the saved actual renderer captures.

This task supplies animation artwork and a reproducible preview. It introduces
no sprint action, movement-speed change or substitution of unrelated work art.
The approved eye placement is the one in the user's attached image, not the
later unsolicited eye experiments. Full family/runtime promotion remains part
of the broader FHD follow-up, whose rejected sources are preserved separately.

## Reproduce

From the repository root:

```powershell
python implementation/fhd-player/build_locomotion_preview.py
python implementation/fhd-player/build_locomotion_preview.py --check
$env:GODOT = 'C:\Users\Helel\Documents\godot\Godot_v4.7.1-stable_win64_console.exe'
# Use a QA project/user directory for preview runs; see farm-house/prepare_qa.ps1.
& $env:GODOT --headless --path $env:GODOT_PROJECT_PATH --editor --import --quit
& $env:GODOT --path $env:GODOT_PROJECT_PATH --fixed-fps 25 --position -4000,-4000 --script res://src/tools/fhd_locomotion_preview.gd
python implementation/fhd-player/build_locomotion_preview.py --check --encode
```
