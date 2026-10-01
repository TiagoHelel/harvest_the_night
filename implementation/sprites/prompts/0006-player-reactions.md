# 0006 - Player reactions and ground shadow

- **Status:** todo
- **Depends on:** 0005
- **Likely files:** sprites/actors/react_*; sprites/actors/shadow.png; src/ui/player_art.gd; src/ui/player_view.gd
- **Generation briefs:** PLAYER_REACTION

## Goal and requirements

Create the existing bang, question, note and heart reactions in the new style. Preserve existing reaction-state selection and idle-only behavior. Separate bubble/body layers if useful but keep paths/metadata consistent. Match the shadow to the new body and feet; no painted halo or double shadow. No new reaction rules.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

Crop-ready, hurt/night and destruction reactions are inspected through existing and showcase scenarios. Bubbles fit viewport and survive night lighting; work poses remain unobscured. Correct stable foot anchor and clean alpha; verify/hash guards pass.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
