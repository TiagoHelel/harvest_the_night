32px UP-RIGHT LOWER-STEP REVIEW — 2026-10-06

Status: approved by the user on 2026-10-06; game integration handed to Claude.
See APPROVAL.json and CLAUDE-APPROVED-WALK-PROMPT.txt.
The user explicitly approved the other seven directions. Their 56 walking
frames remain byte-identical to walk-mirror-review, including up-left.
Up-right phases 2 and 6 remain unchanged; phases 1, 3, 4, 5, 7 and 8 received
targeted built-in ImageGen edits to lower the lifted boot and extend the shin.
No idle, tool activity, production asset or game code changed.

Open index.html through the existing 127.0.0.1:8765 repository server.
Focused before/after is horizontal (old left, candidate right); all-eight
montages show before above and candidate below. Eight frames, 100ms each.
Day/night pictures are actual Godot WorldView/PlayerView/Relight FHD captures.

Canonical candidate exports:
  native-40/walk/<direction>/01..08.png — 40px canvas, pivot (20,36).
  runtime-80/walk/<direction>/01..08.png — exact nearest 2x, pivot (40,72),
    Sprite2D draw scale 0.5 for the current FHD geometry.
  contract.json — sources, hashes, palette, changed phases, approval scope.
  individual-generated/ — the six generated raw single-frame outputs.
  individual-frame-prompts.json — final prompt set and phase identifiers.

Reproduce final exports with export_individual.py, capture with capture.gd
in Godot 4.7.1 using the visible renderer and --fixed-fps 30, then run
build_preview.py and check_export.py. capture.gd is an isolated review fixture.

Whole-sheet attempts r1/r2/r3/r4 were rejected internally for motion issues.
prepare_sheet_experiment.py and tracking-native are experiment history only;
they are not the final export recipe. Do not promote their outputs.

Validation: 58 walking phases preserved; 6 targeted edits; 128 native/runtime
PNG exports; binary alpha; approved RIGHT blue palette restoration; original
source hashes intact; candidate body height within 1px of its original phase.
144 same-camera FHD crops, 576 Godot assertions / 0 failures. Four GIFs with
8 frames at 100ms. Browser frame advance and lighting controls checked.
These checks establish export consistency; the user's approval is in APPROVAL.json.
