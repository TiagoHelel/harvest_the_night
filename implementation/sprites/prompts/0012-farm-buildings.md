# 0012 - Workshop, kitchen, press, generator, shop and well

- **Status:** todo
- **Depends on:** 0011
- **Likely files:** assets/art_source/buildings/; sprites/buildings/workshop*,kitchen*; sprites/props/press*,generator*,shop.png,well.png; src/ui/world_view.gd
- **Generation briefs:** PRODUCTION_BUILDING, SHOP_WELL

## Goal and requirements

Create recognizable station masters, using tools/furnace for workshop, oven/cookware for kitchen, screw/lever for press, metal engine for generator and counter/awning for shop. Keep current 2x2 anchors and fixture footprints. Migrate quarter-based press/generator sources coherently. Add bounded cosmetic active/idle feedback only where state already exposes activity.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

Every station is identifiable by function and matches house materials/perspective. Whole stations render once without repeated fragments. Inactive, active and damaged states where applicable inspected; interaction targets remain correct. Day/night and verify/hash guards pass.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
