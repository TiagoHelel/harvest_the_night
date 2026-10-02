# 0014 - Connected defences, barricades and mine

- **Status:** done
- **Depends on:** 0013
- **Likely files:** sprites/buildings/wall*,fence*,barricade*,mine*; src/ui/world_view.gd; assets/art_source/defences/
- **Generation briefs:** WALL_TRAP

## Goal and requirements

Create coherent horizontal/vertical, corner/end/junction wall and fence variants selected from existing occupancy in the view. Produce barricade and armed/triggered mine visuals using existing trap state. Author hurt/wrecks that read as broken construction rather than pixel noise. Keep legal placement and pathing identical; avoid decorative posts suggesting blocked cells that remain open.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

Connected perimeter and all joins inspected. Hurt versus whole identifiable without bars; ruins lie on correct cells. Mine readability under actors/crops and build-preview route remain correct. No changed pathing hashes; full verify passes.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
