# 0010 - Three crops, four stages and watered soil

- **Status:** done
- **Depends on:** 0008
- **Likely files:** assets/art_source/crops/; sprites/crops/; src/ui/world_view.gd
- **Generation briefs:** CROP

## Goal and requirements

Replace wheat/corn/carrot stages 0–3, tilled and tilled_wet. Species must differ in silhouette/color; stages progress clearly from seed to harvest. Preserve water readability beneath foliage. Mature corn may use taller canvas if anchor/layering is correct and neighboring beds remain legible. No growth/balance changes.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

A 3x4 stage matrix plus dry/wet soil and dense beds is inspected. Ready crops are readable without UI text; no misplaced crop after watering. No giant canopy hiding neighboring interactive cells. Dawn/day/night captures and verify/hash guards pass.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
