# 0011 - Farmhouse as the visual landmark

- **Status:** todo
- **Depends on:** 0003, 0009
- **Likely files:** assets/art_source/buildings/house/; sprites/buildings/house*; src/ui/world_view.gd; src/ui/lighting.gd
- **Generation briefs:** HOUSE

## Goal and requirements

Refine pilot house: terracotta roof with readable tile clusters, timber facade, door, chimney and warm windows. Keep the existing 3x3 logical footprint. Roof overhang and damaged appearance must use the agreed anchor pipeline, not nine duplicated buildings. Align window light sources with actual windows, and inspect low-health visual feedback without altering house HP.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

House is recognizable and larger than worker/props; one coherent roof at all camera positions. Windows align with glow, door ground contact matches occupied cells, front/behind overlap works. Whole/hurt/night states reviewed; verify/hash guards pass.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
