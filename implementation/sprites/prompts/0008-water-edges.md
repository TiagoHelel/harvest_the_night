# 0008 - Water motion, banks and connected terrain edges

- **Status:** done
- **Depends on:** 0007
- **Likely files:** sprites/terrain/water*; sprites/terrain/edge_*; sprites/terrain/shore_*; tools/gen_sprites.py; src/ui/world_view.gd
- **Generation briefs:** WATER

## Goal and requirements

Create three coherent water frames and coordinated bank/grass-to-soil/path edge art. Respect N=1/E=2/S=4/W=8 and all 16 masks. Inspect convex/concave corners and compound joins; add required corner metadata only in the view/import pipeline. Preserve atlas and nearest/no-mipmap import. The jetty should remain readable over water.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

All 16 masks, animation loop and representative corners are shown in the showcase. No edge popping, mismatched wave direction, gaps or swimming bank pixels. Water motion stays subtle at native size; actual farm captures and verify/hash guards pass.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
