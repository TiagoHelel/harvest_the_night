# 0009 - Trees, rocks, resources and livestock

- **Status:** done
- **Depends on:** 0008
- **Likely files:** assets/art_source/props/; sprites/props/tree.png,stump.png,rock.png,seam.png,ore.png,cow.png,chicken.png; src/ui/world_view.gd
- **Generation briefs:** TREE, RESOURCE_PROP, ANIMAL

## Goal and requirements

Finish full-canopy trees, cut stumps, rock/stone deposits, iron ore and current cow/chicken. Add controlled visual variations selected by cell in view code without consuming simulation RNG. Keep logical footprints and resource behavior unchanged. Use separate accepted masters per species/material; decorative movement is optional and view-only.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

Tree matches pilot, stump matches trunk, animals have recognizable species at native size. Resource types distinguishable without labels. Foreground/background overlap, density and harvest removal reviewed. No new collision clutter; verify/hash guards pass.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
