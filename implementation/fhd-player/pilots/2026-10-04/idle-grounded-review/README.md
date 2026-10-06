# Grounded idle, 2026-10-05

The blue walk integration held selected walking phases as the idle sprites.
Several selected phases have a suspended boot. Releasing movement therefore
left the farmer standing in mid-stride. These eight neutral poses replace
those stand-ins; the 64 reviewed walking frames are unchanged.

## Files for integration

- `assets/art_source/player-fhd/idle-blue-grounded/frames/<direction>.png`:
  eight new source-owned neutral idle sprites.
- `sprites/actors/idle_<suffix>_0.png` through `_2.png`: runtime idle slots.
  All three deliberately hold the same grounded pose; no new blink is authored.
- `assets/art_source/player-fhd/walk-blue/frames/<direction>/01..08.png`:
  the unchanged approved blue walking cycle. A walking contact/lift frame
  must never be reused as the stopped pose.

Canvas remains 80×80, ground pivot (40,72), native body height 63–65,
runtime draw scale 0.5 on the 480×270 logical viewport. At 1920×1080 one
native pixel is two screen pixels, for about 128px total character height.
Walking remains eight frames at 100ms each; running uses the same art faster.

Raw source `idle-r1.raw.png` was generated with built-in ImageGen from the
preserved raised-foot edit target and approved walking identity reference.
One measured 0.18 nearest scale is shared by the whole eight-view sheet.
Only garment pixels are mapped to the previously approved RIGHT blue ramp,
under the user's explicit code-paint authorization. The conversion retains
alpha and all non-garment RGBA. No limb is drawn or repaired by code.

## Reproduce / check

```powershell
python implementation/fhd-player/pilots/2026-10-04/idle-grounded-review/build_idle.py
python implementation/fhd-player/pilots/2026-10-04/palette-variants/promote_blue_walk.py
python tools/import_art.py
python implementation/fhd-player/pilots/2026-10-04/palette-variants/promote_blue_walk.py --check
```

The historical `runtime-blue-walk-contract.json` stays sealed; its original
`idle_from_walk_frame` field is historical, no longer used. The new dedicated
`runtime-idle-contract.json` owns standing art. The promotion helper always
loads this contract, so rerunning it cannot restore the raised-foot aliases.
`walk-baseline.json` freezes 192 review/source/runtime walking SHA-256 hashes.

## Review

Open `index.html` through the local server on port 8765. It includes neutral
standing poses, idle → two walking loops → idle, and physical FHD renderer
captures in day and night. Native and FHD display sizes are selectable.
The independent renderer fixture runs unchanged Player.tick and PlayerView
at normal 30Hz, captures every 100ms, and verifies idle/walk family selection
without allowing rendering to modify simulation/save fields.

`runtime-captures/` preserves the original 384 actor crops and 48 full FHD
frames. `runtime-capture-report.json` records all 16 sequences and their
frame traces. The full verification and renderer logs record actual results.
The locomotion regression additionally releases every direction at each of
its eight walking phases: stopping must immediately choose idle frame zero,
change the lifted-leg pixels and leave the ground pivot unchanged.

## Diagonal walking candidates — awaiting motion approval

The user subsequently identified shaking legs during UP-LEFT walking and a
changing rear silhouette during UP-RIGHT walking. `diagonal-candidate/` holds
review candidates, not runtime replacements. All accepted walking PNGs remain
unchanged. The before/after GIF and HTML inspector compare identical phases.

UP-LEFT uses fixed anatomical limb ownership from the sprite_generator joint
guide workflow. Generated R1 still duplicated contact poses; R2 shortened the
supporting calves. R3 supplies frames 1–6 and 8 with a consistent 64px height.
A separate targeted source supplies only frame 7 to remove its passing-foot
dip. The other 15 candidate PNGs are byte-identical after that targeted edit.
Each individual pose has at most three targeted revisions. UP-RIGHT uses its
first generated hip/pocket repair. Native candidate masks map only clothing
onto the approved RIGHT blue ramp; code does not draw limbs or boots.

Raw masters, individual prompts, guide references and per-frame SHA-256 hashes
are saved here and in `diagonal-candidate/validation.json`. The review fixture
injects source textures into the real PlayerView in isolation, then records
normal 30Hz gameplay at 100ms intervals, day and night. It does not write the
runtime walking files. `diagonal-candidate/runtime-captures/` and its renderer
report preserve original evidence; `finalize_evidence.py` checks source
immutability, alpha, palette, geometry and clip timing. These checks do not
prove perfect limb motion; the user's visual walking approval remains pending.

Verification: the initial full run passed 54 gates and failed one unchanged
timing-sensitive input fixture (632s, over budget). The identical targeted
input retry passed all 1,017 cases in 86.9s. No test/core timing was changed.
Both exports, 16,137 headless assertions and 2,533 locomotion assertions passed;
sim3096784529/data3219365985 are unchanged. Both idle and candidate renderer
runs passed 3,472 checks. Original logs retain the first failure and the retry.
