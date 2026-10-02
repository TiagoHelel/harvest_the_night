# Farmhouse furniture and hearth polish — 2026-10-02

Requested: place the kitchen, hearth and bed against the wall, face the wardrobe
into the room from its wall, animate the fire, and add a bedside cabinet/lamp.

The north-wall furniture now occupies row 3. Bed and lamp artwork have measured
presentation offsets so the headboard and cabinet back meet the wall/floor seam.
The wardrobe occupies the eastern wall with its front facing west; its offset
aligns its rear edge to the inner wall. Floor footprints remain solid. The new
cabinet sits immediately left of the bed's head. Its lamp has a small steady
warm halo. The center of the room and the route to the south door stay open.

Two separate built-in `image_gen.imagegen` calls produced the west-facing
wardrobe and lamp cabinet. Original generated files are preserved in
`assets/art_source/interior/storage-west-v1.png` and
`assets/art_source/interior/nightstand-lamp-v1.png`. Exact prompts are
`storage-west.prompt.txt` and `nightstand-lamp.prompt.txt`; call provenance and
hashes are in `generation.json`. `register_art.py` records measured alpha crops,
native canvases, ground pivots and the reference sheet. The normal
`tools/import_art.py` pipeline performs nearest scaling, project palette mapping
and binary alpha, producing `sprites/interior/storage.png` and `nightstand.png`.
The original modular interior sheet remains unchanged.

The hearth reuses its existing sprite. `src/ui/hearth_flame.gdshader` animates
only the measured 14×10 firebox region; chimney, stones, plants and grate retain
their original pixels. Cosmetic time belongs to HouseView, freezes with pause
and stops when the accessibility setting requests steady lighting. The lamp
halo is steady. Neither writes to simulation state.

Old indoor saves standing under newly placed furniture move deterministically
to the nearest free floor cell during reconciliation, retaining their farm
return position. There is no state version change. The data guard intentionally
moves 3247244688 → 8148086 for revised furniture footprints and the new cabinet.
The simulation guard stays 1270427719; visual offsets and animation are UI-only.

Native review images in `captures/` use the actual renderer at 480×270, including
two fire times. The pixel comparison requires visible flame changes, zero
changes outside the firebox, and exact original colors in stationary opaque
hearth pixels. Main/Portuguese capture:
`../shots/house-polish/house_interior-pt_BR.png`.

Focused verification: 7,581 core assertions, 293 actual-renderer room checks,
and nine house keyboard cases pass. The keyboard test also verifies the flame
freezes under the real pause key. The isolated input harness retains its prior
shutdown warning (four objects/two resources); the complete input run is the
release gate. Full suite output is saved in `verify-pass.log`.

Final verification: **54 passed, zero skipped/failed**; 272 headless room checks,
7,581 core assertions, 996 input cases, and Windows/Web/playtest exports pass.
Runtime budget checks pass (650µs/night tick, 8,481µs/path rebuild). The full
suite takes 608 seconds, exceeding the repository's soft 300-second target.
The final native shader review passes 293 checks after checking original colors.
An audit of 5,746 previously tracked PNGs finds only the requested storage sprite
changed; the original room evidence and all other old artwork remain intact.

Reproduce with GODOT pointing to the installed executable and the dedicated
QA project prepared by `../farm-house/prepare_qa.ps1`:

```powershell
python implementation/house-polish/register_art.py
python tools/import_art.py
python tools/show_art.py --house-visit --out=implementation/house-polish/captures
python tools/shot.py house-polish house_interior --pt_BR
python tools/verify.py
```

This user follow-up leaves the completed backlog statuses unchanged. No new
top-level directory, external publishing, push or scheduled work is needed.

## Follow-up: anchored fire instead of sideways sway

The user found the previous whole-fire distortion looked like dancing. The
shader now keeps horizontal coordinates and the lower three firebox rows fixed.
Separate two-pixel tongues vary height by small independent, smoothly blended
irregular values. The body stays steady while tips grow upward and recede; there
is no periodic left/right displacement. No new sprites or core changes.

The renderer check additionally verifies zero changed pixels in the fixed hot
base. Final native inspection passes 294 checks. The `--fire-loop` option exports
24 real gameplay frames at eight sampled times per second to `fire-fix/`.
`fire-fix/encode_playback.py` encodes those native captures with one shared GIF
palette, avoiding preview color flicker. The four-frame enlarged inspection sheet
is opened; the full room is also captured at native 480x270 with Portuguese UI.
Pause, steady-light accessibility, masonry/source color preservation, and
read-only rendering checks still pass. Full verification is recorded separately
in `fire-fix/verify-pass.log`.

Final follow-up suite: **54 passed, zero skipped/failed**, including 7,581 core
assertions, 996 input cases and Windows/Web/playtest exports. Sim 1270427719 and
data 8148086 remain unchanged. Full duration is 462 seconds (over the soft
300-second suite target); runtime checks pass at 521µs/night tick and
6,980µs/path rebuild. Playback checks all 24 native frames: 23 changing tip
samples, zero base drift and zero changes outside the flame.
