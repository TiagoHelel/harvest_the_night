FINAL BLUE32PX WALK PACK - 2026-10-06

The user approved low-step up-right and instructed Codex to mirror it for
up-left before Claude fetches the ready assets. All64 final poses are here.

Use runtime-80/walk/<direction>/01..08.png: canvas80x80, pivot(40,72),
draw_scale0.5. Native alternative: native-40, canvas40x40, pivot(20,36).
Each animation has8 phases at100ms each, retaining the approved blue palette.

Eight up-left frames are exact whole-canvas horizontal flips of the new
up-right. The other56 phases are byte-identical copies of walk-up-right-low-step.
All3 intended mirror pairs are verified for all8 phases in both size formats.
No recoloring, generation, phase reversal, resampling or runtime double flip.

contract.json records provenance and hashes for128 final PNG exports.
CLAUDE-APPROVED-WALK-PROMPT.txt is the integration handoff.
index.html shows the actual FHD mirrored pair and all8 directions, day/night.

Reproduce PNGs with build.py. Render capture.gd in Godot, then run
build.py --rendered for GIFs/page/checks.144 same-camera FHD crops;576 checks,
0 failures. Four GIFs,8 frames at100ms, binary alpha and exact nearest2x.

This is the latest walking source; Claude performs production integration.
Idle, tool/fishing/reaction sprites and gameplay remain outside these exports.
Original review packs and concurrent integration changes are preserved.
