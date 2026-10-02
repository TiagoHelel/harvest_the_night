# 0019 - Final shared palette and day/night atmosphere

- **Status:** done
- **Depends on:** 0006, 0008, 0009, 0010, 0012, 0017, 0018
- **Likely files:** tools/palette.py; src/ui/palette_data.gd; src/ui/relight.gdshader; src/ui/relight.gd; src/ui/lighting.gd; src/ui/transition.gd
- **Generation briefs:** LIGHTING_STUDY (only if a reference study is needed)

## Goal and requirements

Tune existing dawn/day/dusk/night ramps against the reference and completed assets. Night must be blue/violet with deep but readable shadows and localized amber light. Audit brightness-based warm exemption: white clothes and crops shouldn't glow like fire. Align lamp/shadow/flash positions; avoid duplicate baked night sprites. Keep a11y controls, smooth reality switch and recognizable scene geometry.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

Paired same-farm day/night screenshots communicate a reality change with identical objects. Terrain, paths and enemies remain distinct; bloom does not erase walls/actors. Transition and low-light/accessibility settings reviewed. Palette source and generated data agree; verify/hash guards pass.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
