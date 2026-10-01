# 0004 - Player idle and walking in every direction

- **Status:** todo
- **Depends on:** 0003
- **Likely files:** assets/art_source/player/; sprites/actors/; src/ui/player_frames.gd; src/ui/player_art.gd; src/ui/player_view.gd; tools/cut_sheet.py
- **Generation briefs:** PLAYER_MASTER, PLAYER_STRIP

## Goal and requirements

Generate south/north/west idle strips (3 frames each) and walk strips (4 each), using the accepted farmer master. East may mirror west after checking handedness. Keep equal canvas/body scale and stable feet. Migrate all locomotion outputs from the legacy cutter, generate COUNT/CANVAS/FEET metadata, preserve runtime path coverage and bind state-driven facing. Document any final change from pilot dimensions.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

All four facings, stationary/diagonal movement and direction changes are inspected. Walk loop is smooth, feet don't drift, hat/body don't resize, east has no mirrored text. Missing frame cannot silently become idle. Native contact sheets and runtime sequences saved; verify/hash guards pass.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
