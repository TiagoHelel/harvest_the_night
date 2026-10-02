# 0018 - Resource icons and restrained UI surfaces

- **Status:** done
- **Depends on:** 0010, 0013
- **Likely files:** assets/art_source/ui/; sprites/ui/; src/ui/ui_kit.gd; src/ui/day_hud.gd; src/ui/night_hud.gd
- **Generation briefs:** ICON, UI_SURFACE

## Goal and requirements

Replace all 15 resource/tech icons from the actual inventory: wood, stone, iron, food, fish, oil, wheat, corn, carrot, meat, gunpowder, incendiary, money, energy and tech. Match world materials and optimize for actual display size. Refine existing panel/button/tab/check/slider surfaces without baking text into images or altering localization/layout scope. Preserve nine-patch margins, state contrast and accessibility focus visibility.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

All icons distinct at HUD scale and under both themes. Normal/hover/pressed/disabled/focus/tabs are distinguishable. Existing menus/tech/result/options fit English and pt-BR with no new clipping. Capture real screens, source checks and verify/hash guards pass.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
