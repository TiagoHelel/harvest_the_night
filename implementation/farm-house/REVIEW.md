# Farm enlargement and enterable farmhouse — review

## Delivered behavior

- Exterior house, shop, workshop, kitchen, press and generator reuse the preceding
  accepted raster art at 2x integer scale. Logical footprints, ground pivots,
  placement previews, lights and chimney outlets follow the enlarged structures.
- Farm: 45x20 (900) → 45x25 (1,125), exactly +25%. Five clear southern rows add
  225 cells connected to the porch without chopping trees. Clear grass/soil after
  enlarged fixtures: 591 → 787. Grass remains circulation/building ground.
- Actual planting beds: 48 → 60, exactly +25%. The additional 4x3 plot lies at
  columns 30–33, rows 20–22, where crops remain above the bottom HUD. Native
  gameplay tilling, planting, growth and harvest are checked on these map cells.
- Interact (Space/Enter by default) at the porch enters a furnished 20x13 room:
  kitchen, dining table, hearth, bed, storage, rug and houseplant. The same farmer,
  zoom, smooth camera and pause are reused. Furniture has solid collision.
- Walk through the southern door, or interact beside it, to return to the exact
  outside position. Farm growth and production continue. Visits are during the
  day; starting defence returns outdoors. Indoor coordinates cannot operate
  outdoor building controls, workshop panels or tutorial pointers.
- State version 3 migrates both original 40x18 and preceding 45x20 saves, keeping
  crops, inventory, queued work and production. Obstructed old stations retain
  compact saved footprints. A farmhouse with crops in its expansion relocates
  to the southern meadow rather than deleting them.

## Art provenance and native inspection

One transparent modular sheet was generated with built-in `image_gen.imagegen`,
preserved at `assets/art_source/interior/farmhouse-v1.png`. Exact submitted prompt:
`implementation/farm-house/interior.prompt.txt`; call metadata: `generation.json`.
Nine measured cuts are registered by `register_art.py` in the existing manifest
and raster ownership system. Run `python tools/import_art.py` to reproduce them.
`asset-audit.txt` verifies all 468 preceding tracked PNGs are byte-identical.

Inspected actual 480x270 Godot images: all eight Main scenarios under
`implementation/shots/farm-house/`, plus six entry/movement/zoom/return pictures
under `implementation/farm-house/captures/`. These are native renderer captures,
not concept pictures. The porch hint is below the farmer, and outdoor tutorial
prompts disappear indoors. Kitchen/cabinet/bed sizes read against the real farmer.

Furniture currently decorates and blocks the room; sleep, indoor storage and
indoor cooking actions are outside this request. Existing farmer, enemies,
terrain, exterior art and viewport resolution are preserved.

## Reproduce safely

```powershell
$env:GODOT = 'C:\Users\Helel\Documents\godot\Godot_v4.7.1-stable_win64_console.exe'
& implementation/farm-house/prepare_qa.ps1
python tools/verify.py
python tools/show_art.py --house-visit
python tools/shot.py farm-house noon dusk wave result tech house_interior farm_extension larger_stations --pt_BR
```

The optional QA mirror directs save/profile fixtures to a separate user folder;
resources are junctions to the real repository. Windows/Web/playtest export checks
use the actual project settings, keeping the QA user directory out of releases.
Default verification behavior is unchanged when GODOT_PROJECT_PATH is unset.

## Verification

Final `python tools/verify.py`: **54 passed, zero skipped/failed**, including
Windows/Web/playtest exports. 122 scripts parse; 7,577 core assertions and
995 input cases pass. Sim 1270427719 and data 3247244688 are stable after the
intentional migration/map baseline update. Total 479s exceeds the soft 300s
suite target; runtime performance checks pass. Log: `verify-pass.log`. Focused native room
verification passes 273 checks; keyboard entry/walk/collision/pause/zoom/exit/night
passes 8 cases. Eight Main screenshots and six native room captures are saved.
The existing headless/input harness retains ObjectDB/resource teardown warnings;
these are reported separately from its assertion/exit result.
