# 0015 - Walker, runner, tank and breaker motion

- **Status:** done
- **Depends on:** 0003, 0013
- **Likely files:** assets/art_source/enemies/; sprites/enemies/; src/ui/world_view.gd; generated animation metadata
- **Generation briefs:** WALKER, ENEMY_STRIP

## Goal and requirements

Create four coherent enemy masters and short walk/attack/death strips (4/3/4 starting targets). Walker slouches, runner leans forward, tank has broad heavy mass, breaker has conspicuous arms/tool posture. Derive pose selection from existing state/position deltas in the view only. Replace two-frame row shifts with authored movement. Avoid adding attacks to core merely to play animation. Preserve current filenames through explicit aliases if migrating names.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

All four distinguishable as black silhouettes and in a dark mixed wave. Stable foot anchors; hit flash doesn't erase function. Attack selection reflects available core state, no invented attack timing. Death sources prepared for 0016 playback; motion sequences and verify/hash guards pass.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
