# 0016 - Giant wind-up and view-owned death playback

- **Status:** todo
- **Depends on:** 0015
- **Likely files:** sprites/enemies/giant*; src/ui/world_view.gd; src/ui/particles.gd; visual animation metadata
- **Generation briefs:** GIANT

## Goal and requirements

Create Giant master and walk/wind-up/slam/death sequences. Its telegraph must be recognizable before attack and agree with the existing target ring. Implement bounded view-owned death snapshots/pool for enemies removed by core, reusing the existing previous-frame observation approach where appropriate. Play death once, then expire. Trigger state changes only from existing observed data; never keep dead core entities alive for art.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

Boss visible at native size without hiding the target; wind-up distinct from walk. Ordinary and Giant deaths actually play once at the last correct position, don't loop or affect hits/pathing, and obey a hard pool cap. Showcase, boss/night capture, performance and verify/hash guards pass.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
