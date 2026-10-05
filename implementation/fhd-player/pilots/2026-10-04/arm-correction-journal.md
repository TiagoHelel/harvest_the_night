## 2026-10-05 - Walking arm correction follow-up

User reported a stationary right arm and one down-right pose appearing to have
three arms. Inspected enlarged native contact sheets and raw sources. The far
anatomical right arm in UP-LEFT R7 hung beside the torso throughout the cycle;
DOWN-RIGHT frame4 had doubled near sleeve shapes and an extra far sleeve edge.

Built-in ImageGen made two evaluated edits per direction. UP-LEFT arms-r8 moves
the far arm but leaves near phases4/5/6 inconsistent; arms-r9 fixes their opposite
swing. DOWN-RIGHT arm-frame04-r6 retains doubled near sleeves; arm-frame04-r7
occludes the far shoulder/sleeve behind the torso, leaving only its far forearm.
Raw originals, dimensions, SHA256, exact English prompts and references are
recorded in each generation.json and the two parent arm prompt JSON files.
Sources remain in assets/art_source/player-fhd/pilots/2026-10-04/.

Python only performs binary alpha cleanup, cuts, common nearest calibration,
packing and GIF composition. No hand-painted limbs, reflection or limb warps.
UP-LEFT uses one R7 hat-reference calibration: eight80x80 poses, hats32px,
heights62-65px. DOWN-RIGHT overrides ONLY frame4, hat32px/height64px. Its other
seven accepted frames are byte-identical. Across56 preview inputs,9changed and
47unchanged; assertions enforce that scope. Edited ImageGen poses do not retain
byte-exact pixels in their other regions, despite the prompt preserving design.

Validation: deterministic exporters and targeted scope checker PASS; eight
unique poses per direction, binary alpha, GIF loops8x100ms and slow8x200ms.
Sprite backlog consistency PASS (20prompts); git diff --check PASS. Normal and
slow GIFs inspected in the actual browser, with manual DOWN-RIGHT frame4.
Evidence: arm-corrections-browser.png and down-right-frame4-arms-browser.png.
The existing direction HTMLs and aggregate seven-direction GIF are updated;
new focused review: arm-corrections.html / arm-corrections.gif, with a slow
UP-LEFT before/after comparison. Versioned aggregate: all-walk-directions-arms-r9.gif.

Both repairs await explicit user review. No runtime, simulation, balance,
resolution, collision or queue changes. No full engine suite rerun for these
isolated previews; prior engine verification is not claimed as a new run.
Existing project.godot edits preserved. DOWN-LEFT not started, no push or automation.
